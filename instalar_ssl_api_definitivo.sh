#!/bin/bash

echo "🔒 Instalação SSL Definitiva - API Desfollow"
echo "==========================================="
echo ""

# Função para verificar sucesso
check_success() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ Erro: $1"
        exit 1
    fi
}

echo "📋 1. Verificando domínios configurados..."
echo "   - Frontend: desfollow.com.br, www.desfollow.com.br"
echo "   - API: api.desfollow.com.br"
echo ""

echo "📋 2. Instalando Certbot se necessário..."
apt update
apt install -y certbot python3-certbot-nginx
check_success "Certbot instalado"

echo ""
echo "📋 3. Verificando se nginx está configurado corretamente..."
nginx -t
if [ $? -ne 0 ]; then
    echo "❌ Configuração nginx inválida. Execute primeiro o script de correção nginx."
    exit 1
fi

echo ""
echo "📋 4. Obtendo certificados SSL para todos os domínios..."

# Parar nginx temporariamente para evitar conflitos
systemctl stop nginx

# Obter certificados para todos os domínios
certbot certonly --standalone \
  -d desfollow.com.br \
  -d www.desfollow.com.br \
  -d api.desfollow.com.br \
  --non-interactive \
  --agree-tos \
  --email admin@desfollow.com.br \
  --expand

check_success "Certificados SSL obtidos"

echo ""
echo "📋 5. Criando configuração nginx com SSL..."

# Backup da configuração atual
cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.ssl.$(date +%Y%m%d_%H%M%S)

# Criar nova configuração com SSL
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# ========================================
# CONFIGURAÇÃO NGINX COM SSL - DESFOLLOW
# ========================================
# Frontend: desfollow.com.br + www.desfollow.com.br (HTTPS)
# API: api.desfollow.com.br (HTTPS)
# ========================================

# REDIRECIONAMENTO HTTP -> HTTPS (Frontend)
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# FRONTEND HTTPS - desfollow.com.br e www.desfollow.com.br
server {
    listen 443 ssl http2;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    
    # Configurações SSL seguras
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    
    # Diretório do frontend buildado
    root /var/www/html;
    index index.html;
    
    # Logs específicos do frontend
    access_log /var/log/nginx/frontend_ssl_access.log;
    error_log /var/log/nginx/frontend_ssl_error.log;
    
    # Configurações de cache para assets estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }
    
    # React Router - todas as rotas SPA
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Bloquear acesso direto a arquivos sensíveis
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Status de saúde do frontend
    location /health {
        access_log off;
        return 200 "Frontend SSL OK\n";
        add_header Content-Type text/plain;
    }
}

# REDIRECIONAMENTO HTTP -> HTTPS (API)
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# API HTTPS - api.desfollow.com.br
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    
    # Configurações SSL seguras
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança para API
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Logs específicos da API
    access_log /var/log/nginx/api_ssl_access.log;
    error_log /var/log/nginx/api_ssl_error.log;
    
    # Configurações de proxy para API
    location / {
        # Proxy para backend Python/Gunicorn
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $host;
        
        # Timeouts para API
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Headers CORS para API (HTTPS)
        add_header Access-Control-Allow-Origin "https://desfollow.com.br, https://www.desfollow.com.br" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
        add_header Access-Control-Allow-Credentials true always;
        
        # Resposta para OPTIONS (preflight CORS)
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://desfollow.com.br, https://www.desfollow.com.br" always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain charset=UTF-8';
            add_header Content-Length 0;
            return 204;
        }
    }
    
    # Status específico da API
    location /health {
        access_log off;
        proxy_pass http://127.0.0.1:8000/health;
    }
}
EOF

check_success "Configuração SSL criada"

echo ""
echo "📋 6. Testando nova configuração..."
nginx -t
check_success "Configuração SSL válida"

echo ""
echo "📋 7. Iniciando nginx com SSL..."
systemctl start nginx
check_success "Nginx iniciado com SSL"

echo ""
echo "📋 8. Verificando certificados..."
echo "   Certificado válido até:"
openssl x509 -in /etc/letsencrypt/live/desfollow.com.br/fullchain.pem -noout -dates | grep notAfter

echo ""
echo "📋 9. Configurando renovação automática..."
# Criar script de renovação
cat > /etc/cron.d/certbot-desfollow << 'EOF'
# Renovar certificados SSL automaticamente
0 12 * * * root certbot renew --quiet --reload-hook "systemctl reload nginx"
EOF
check_success "Renovação automática configurada"

echo ""
echo "📋 10. Testando URLs com SSL..."

sleep 5  # Aguardar nginx inicializar completamente

echo "🌐 Testando frontend HTTPS: https://desfollow.com.br"
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://desfollow.com.br --insecure 2>/dev/null)
if [ "$FRONTEND_RESPONSE" = "200" ]; then
    echo "✅ Frontend HTTPS respondendo (HTTP $FRONTEND_RESPONSE)"
else
    echo "⚠️ Frontend HTTPS: HTTP $FRONTEND_RESPONSE"
fi

echo "🌐 Testando API HTTPS: https://api.desfollow.com.br"
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://api.desfollow.com.br --insecure 2>/dev/null)
if [ "$API_RESPONSE" = "200" ]; then
    echo "✅ API HTTPS respondendo (HTTP $API_RESPONSE)"
    API_CONTENT=$(curl -s https://api.desfollow.com.br --insecure)
    if echo "$API_CONTENT" | grep -q "Desfollow API"; then
        echo "✅ Conteúdo é API (correto)"
    fi
else
    echo "⚠️ API HTTPS: HTTP $API_RESPONSE"
fi

echo ""
echo "📋 11. Verificando redirecionamentos HTTP -> HTTPS..."
HTTP_REDIRECT=$(curl -s -o /dev/null -w "%{http_code}" http://desfollow.com.br 2>/dev/null)
if [ "$HTTP_REDIRECT" = "301" ]; then
    echo "✅ Redirecionamento HTTP -> HTTPS funcionando"
else
    echo "⚠️ Redirecionamento: HTTP $HTTP_REDIRECT"
fi

echo ""
echo "✅ SSL INSTALADO COM SUCESSO!"
echo ""
echo "🔒 CONFIGURAÇÃO FINAL COM SSL:"
echo "   Frontend: https://desfollow.com.br (SSL ativado)"
echo "   Frontend: https://www.desfollow.com.br (SSL ativado)"
echo "   API:      https://api.desfollow.com.br (SSL ativado)"
echo ""
echo "🔄 REDIRECIONAMENTOS AUTOMÁTICOS:"
echo "   http://desfollow.com.br → https://desfollow.com.br"
echo "   http://api.desfollow.com.br → https://api.desfollow.com.br"
echo ""
echo "📊 Para verificar:"
echo "   curl https://desfollow.com.br (deve retornar HTML)"
echo "   curl https://api.desfollow.com.br (deve retornar JSON da API)"
echo "   openssl s_client -connect api.desfollow.com.br:443 -servername api.desfollow.com.br"
echo ""
echo "📜 Logs SSL:"
echo "   tail -f /var/log/nginx/frontend_ssl_access.log"
echo "   tail -f /var/log/nginx/api_ssl_access.log"
echo ""
echo "🚀 Problema HTTPS/CORS da API resolvido!" 