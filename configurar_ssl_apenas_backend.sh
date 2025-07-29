#!/bin/bash

echo "🔒 CONFIGURANDO SSL APENAS PARA BACKEND (API)"
echo "============================================"

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Execute como root: sudo $0"
    exit 1
fi

echo "📋 1. Fazendo backup da configuração atual..."
cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.backend-ssl.$(date +%Y%m%d_%H%M%S) 2>/dev/null || echo "⚠️ Arquivo não encontrado"

echo "📋 2. Verificando se certificado da API já existe..."
if [ -f "/etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem" ]; then
    echo "✅ Certificado API já existe!"
    API_CERT_EXISTS=true
else
    echo "❌ Certificado API não existe. Criando..."
    API_CERT_EXISTS=false
fi

echo "📋 3. Criando configuração Nginx - Frontend HTTP + API HTTPS..."
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Configuração Nginx - Frontend HTTP + API HTTPS
# Frontend: HTTP (www.desfollow.com.br)
# API: HTTPS (api.desfollow.com.br)

# ============================================
# FRONTEND HTTP (www.desfollow.com.br)
# ============================================
server {
    listen 80;
    server_name www.desfollow.com.br desfollow.com.br;

    # Headers de segurança para Frontend
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

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

    # Let's Encrypt validation (caso precise no futuro)
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files $uri =404;
    }

    # Logs do Frontend
    access_log /var/log/nginx/frontend_access.log;
    error_log /var/log/nginx/frontend_error.log;
}

# ============================================
# API HTTP (redirecionamento para HTTPS)
# ============================================
server {
    listen 80;
    server_name api.desfollow.com.br;
    
    # Let's Encrypt validation
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files $uri =404;
    }
    
    # Redirecionamento para HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
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

    # Logs da API
    access_log /var/log/nginx/api_access.log;
    error_log /var/log/nginx/api_error.log;
}
EOF

echo "📋 4. Verificando se precisa criar certificado para API..."
if [ "$API_CERT_EXISTS" = false ]; then
    echo "🔧 Criando certificado para api.desfollow.com.br..."
    
    # Ativar configuração temporária primeiro
    rm -f /etc/nginx/sites-enabled/desfollow
    ln -sf /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/
    
    # Testar configuração
    if nginx -t; then
        systemctl reload nginx
        echo "✅ Nginx recarregado"
    else
        echo "❌ Erro na configuração Nginx!"
        nginx -t 2>&1
        exit 1
    fi
    
    # Criar diretório para validação
    mkdir -p /var/www/html/.well-known/acme-challenge
    chown -R www-data:www-data /var/www/html
    
    # Criar certificado
    certbot certonly --webroot -w /var/www/html -d api.desfollow.com.br --non-interactive --agree-tos --email admin@desfollow.com.br
    
    if [ $? -eq 0 ]; then
        echo "✅ Certificado criado para api.desfollow.com.br!"
    else
        echo "❌ Falha ao criar certificado para api.desfollow.com.br"
        echo "📋 Tentando método standalone..."
        
        # Parar nginx e tentar standalone
        systemctl stop nginx
        certbot certonly --standalone -d api.desfollow.com.br --non-interactive --agree-tos --email admin@desfollow.com.br
        systemctl start nginx
        
        if [ $? -eq 0 ]; then
            echo "✅ Certificado criado com método standalone!"
        else
            echo "❌ Falha total ao criar certificado"
            tail -20 /var/log/letsencrypt/letsencrypt.log
            exit 1
        fi
    fi
fi

echo "📋 5. Ativando configuração final..."
rm -f /etc/nginx/sites-enabled/desfollow
ln -sf /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/

echo "📋 6. Testando configuração final..."
if nginx -t; then
    echo "✅ Configuração Nginx válida!"
else
    echo "❌ Erro na configuração Nginx!"
    nginx -t 2>&1
    echo "📋 Restaurando backup..."
    if ls /etc/nginx/sites-available/desfollow.backup.backend-ssl.* 1> /dev/null 2>&1; then
        latest_backup=$(ls -t /etc/nginx/sites-available/desfollow.backup.backend-ssl.* | head -1)
        cp "$latest_backup" /etc/nginx/sites-available/desfollow
        ln -sf /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/
    fi
    exit 1
fi

echo "📋 7. Recarregando Nginx..."
systemctl reload nginx

echo "📋 8. Verificando status dos serviços..."
echo "🔍 Nginx:"
systemctl status nginx --no-pager -l | head -3

echo "🔍 FastAPI (Backend):"
systemctl status desfollow --no-pager -l | head -3

echo ""
echo "✅ CONFIGURAÇÃO BACKEND SSL APLICADA COM SUCESSO!"
echo "==============================================="
echo "🌐 Frontend (HTTP): http://www.desfollow.com.br"
echo "🔌 API (HTTPS): https://api.desfollow.com.br"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "1. Fazer build do frontend: ./buildar_e_mover_frontend.sh"
echo "2. Testar frontend: curl -I http://www.desfollow.com.br"
echo "3. Testar API: curl -I https://api.desfollow.com.br/api/health"
echo ""
echo "📋 Configuração CORS:"
echo "   - Frontend HTTP: http://www.desfollow.com.br"
echo "   - API HTTPS: https://api.desfollow.com.br"
echo "   - Sem problemas de mixed content"
echo ""
echo "📋 COMANDOS ÚTEIS:"
echo "   tail -f /var/log/nginx/frontend_error.log"
echo "   tail -f /var/log/nginx/api_error.log"
echo "   certbot certificates" 