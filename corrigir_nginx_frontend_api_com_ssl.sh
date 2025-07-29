#!/bin/bash

echo "🔒 CONFIGURANDO NGINX COM SSL - FRONTEND E API"
echo "============================================="

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Execute como root: sudo $0"
    exit 1
fi

echo "📋 1. Verificando certificados SSL..."
CERT_DESFOLLOW=false
CERT_API=false

if [ -f "/etc/letsencrypt/live/desfollow.com.br/fullchain.pem" ]; then
    echo "✅ Certificado desfollow.com.br encontrado"
    CERT_DESFOLLOW=true
else
    echo "❌ Certificado desfollow.com.br NÃO encontrado"
fi

if [ -f "/etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem" ]; then
    echo "✅ Certificado api.desfollow.com.br encontrado"
    CERT_API=true
else
    echo "❌ Certificado api.desfollow.com.br NÃO encontrado"
fi

if [ "$CERT_DESFOLLOW" = false ] || [ "$CERT_API" = false ]; then
    echo ""
    echo "❌ CERTIFICADOS SSL NECESSÁRIOS NÃO ENCONTRADOS!"
    echo "📋 Execute primeiro: ./verificar_e_configurar_ssl.sh"
    exit 1
fi

echo "📋 2. Fazendo backup da configuração atual..."
cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || echo "⚠️ Arquivo não encontrado, continuando..."

echo "📋 3. Verificando estrutura de diretórios..."
mkdir -p /var/www/html/desfollow
mkdir -p /var/log/nginx

echo "📋 4. Removendo configuração antiga..."
rm -f /etc/nginx/sites-enabled/desfollow
rm -f /etc/nginx/sites-available/desfollow

echo "📋 5. Adicionando rate limiting no nginx.conf..."
if ! grep -q "limit_req_zone.*api:" /etc/nginx/nginx.conf; then
    echo "📋 Adicionando rate limiting zones ao nginx.conf..."
    sed -i '/http {/a\\n\t# Rate limiting zones for Desfollow\n\tlimit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;\n\tlimit_req_zone $binary_remote_addr zone=login:10m rate=5r/s;' /etc/nginx/nginx.conf
fi

echo "📋 6. Criando configuração Nginx com SSL..."
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Configuração Nginx Completa para Desfollow com SSL
# Frontend: www.desfollow.com.br, desfollow.com.br
# API: api.desfollow.com.br

# ============================================
# REDIRECIONAMENTO HTTP PARA HTTPS
# ============================================
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br api.desfollow.com.br;
    
    # Redirecionamento para HTTPS
    return 301 https://$server_name$request_uri;
}

# ============================================
# FRONTEND HTTPS (www.desfollow.com.br)
# ============================================
server {
    listen 443 ssl http2;
    server_name www.desfollow.com.br desfollow.com.br;

    # SSL Configuration (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Headers de segurança para Frontend
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' https://api.desfollow.com.br; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:;" always;

    # Diretório do frontend (arquivos estáticos do React)
    root /var/www/html/desfollow;
    index index.html;

    # Configuração para SPA (Single Page Application)
    location / {
        try_files $uri $uri/ /index.html;
        
        # Cache para arquivos estáticos
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Logs do Frontend
    access_log /var/log/nginx/frontend_access.log;
    error_log /var/log/nginx/frontend_error.log;
}

# ============================================
# API HTTPS (api.desfollow.com.br)
# ============================================
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;

    # SSL Configuration (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Headers de segurança para API
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # IMPORTANTE: NÃO adicionar Access-Control-Allow-Origin aqui
    # O FastAPI já gerencia CORS corretamente

    # Configuração da API (FastAPI)
    location / {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Configuração específica para autenticação
    location /api/auth/ {
        limit_req zone=login burst=10 nodelay;
        
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }

    # Configuração para health check
    location /api/health {
        access_log off;
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }

    # Logs da API
    access_log /var/log/nginx/api_access.log;
    error_log /var/log/nginx/api_error.log;
}
EOF

echo "📋 7. Ativando nova configuração..."
ln -sf /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/

echo "📋 8. Testando configuração Nginx..."
if nginx -t; then
    echo "✅ Configuração Nginx válida!"
else
    echo "❌ Erro na configuração Nginx!"
    echo "📋 Mostrando erro detalhado:"
    nginx -t 2>&1
    echo "📋 Restaurando backup..."
    rm -f /etc/nginx/sites-enabled/desfollow
    if ls /etc/nginx/sites-available/desfollow.backup.* 1> /dev/null 2>&1; then
        latest_backup=$(ls -t /etc/nginx/sites-available/desfollow.backup.* | head -1)
        cp "$latest_backup" /etc/nginx/sites-available/desfollow
        ln -sf /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/
    fi
    exit 1
fi

echo "📋 9. Verificando se frontend está construído..."
if [ ! -f "/var/www/html/desfollow/index.html" ]; then
    echo "⚠️ Frontend não encontrado em /var/www/html/desfollow/"
    echo "📋 É necessário fazer build e mover arquivos do frontend!"
    echo "📋 Execute: ./buildar_e_mover_frontend.sh"
fi

echo "📋 10. Recarregando Nginx..."
systemctl reload nginx

echo "📋 11. Verificando status dos serviços..."
echo "🔍 Nginx:"
systemctl status nginx --no-pager -l | head -5

echo "🔍 FastAPI (Backend):"
systemctl status desfollow --no-pager -l | head -5

echo ""
echo "✅ CONFIGURAÇÃO SSL APLICADA COM SUCESSO!"
echo "======================================="
echo "🌐 Frontend: https://www.desfollow.com.br"
echo "🌐 Frontend: https://desfollow.com.br" 
echo "🔌 API: https://api.desfollow.com.br"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "1. Fazer build do frontend: ./buildar_e_mover_frontend.sh"
echo "2. Testar frontend: curl -I https://www.desfollow.com.br"
echo "3. Testar API: curl -I https://api.desfollow.com.br/api/health"
echo "4. Verificar SSL: openssl s_client -connect desfollow.com.br:443"
echo ""
echo "📋 COMANDOS ÚTEIS:"
echo "   tail -f /var/log/nginx/frontend_error.log"
echo "   tail -f /var/log/nginx/api_error.log"
echo "   certbot certificates" 