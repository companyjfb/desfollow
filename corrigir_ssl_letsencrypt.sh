#!/bin/bash

echo "🔒 Correção SSL - Método Webroot para Desfollow"
echo "=============================================="
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

echo "📋 1. Verificando status atual do nginx..."
systemctl status nginx --no-pager -l

echo ""
echo "📋 2. Criando diretório para challenges Let's Encrypt..."
mkdir -p /var/www/html/.well-known/acme-challenge
chown -R www-data:www-data /var/www/html/.well-known
chmod -R 755 /var/www/html/.well-known
check_success "Diretório de challenges criado"

echo ""
echo "📋 3. Configurando nginx temporário para SSL..."

# Backup da configuração atual
cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.$(date +%Y%m%d_%H%M%S)

# Criar configuração temporária que funciona com Let's Encrypt
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Configuração temporária para obtenção de certificados SSL
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    root /var/www/html;
    index index.html;
    
    # CRITICAL: Local para challenges Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files $uri =404;
    }
    
    # Resto do frontend
    location / {
        try_files $uri $uri/ /index.html;
    }
}

# API temporária (só HTTP por enquanto)
server {
    listen 80;
    server_name api.desfollow.com.br;
    
    # CRITICAL: Local para challenges Let's Encrypt  
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files $uri =404;
    }
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

check_success "Configuração temporária criada"

echo ""
echo "📋 4. Testando configuração nginx..."
nginx -t
check_success "Configuração nginx válida"

echo ""
echo "📋 5. Recarregando nginx..."
systemctl reload nginx
check_success "Nginx recarregado"

echo ""
echo "📋 6. Testando se challenge path está funcionando..."
echo "test-file" > /var/www/html/.well-known/acme-challenge/test
CHALLENGE_TEST=$(curl -s http://desfollow.com.br/.well-known/acme-challenge/test 2>/dev/null)
if [ "$CHALLENGE_TEST" = "test-file" ]; then
    echo "✅ Challenge path funcionando"
    rm /var/www/html/.well-known/acme-challenge/test
else
    echo "❌ Challenge path não está funcionando"
    echo "Response: $CHALLENGE_TEST"
    exit 1
fi

echo ""
echo "📋 7. Obtendo certificados SSL com método webroot..."

# Usar webroot ao invés de standalone
certbot certonly \
  --webroot \
  --webroot-path=/var/www/html \
  -d desfollow.com.br \
  -d www.desfollow.com.br \
  -d api.desfollow.com.br \
  --email admin@desfollow.com.br \
  --agree-tos \
  --non-interactive \
  --expand

check_success "Certificados SSL obtidos com webroot"

echo ""
echo "📋 8. Criando configuração final com SSL..."

cat > /etc/nginx/sites-available/desfollow << 'EOF'
# ========================================
# CONFIGURAÇÃO FINAL NGINX COM SSL - DESFOLLOW
# ========================================

# Redirecionamento HTTP -> HTTPS (Frontend)
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Manter challenge path para renovações
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files $uri =404;
    }
    
    # Redirecionar resto para HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# FRONTEND HTTPS
server {
    listen 443 ssl http2;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    
    # Configurações SSL modernas
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    
    # Frontend
    root /var/www/html;
    index index.html;
    
    # Logs SSL
    access_log /var/log/nginx/frontend_ssl_access.log;
    error_log /var/log/nginx/frontend_ssl_error.log;
    
    # Cache para assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }
    
    # React Router SPA
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Bloquear arquivos sensíveis
    location ~ /\. {
        deny all;
    }
}

# Redirecionamento HTTP -> HTTPS (API)
server {
    listen 80;
    server_name api.desfollow.com.br;
    
    # Manter challenge path para renovações
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files $uri =404;
    }
    
    # Redirecionar resto para HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# API HTTPS
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    
    # Configurações SSL modernas
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Logs SSL API
    access_log /var/log/nginx/api_ssl_access.log;
    error_log /var/log/nginx/api_ssl_error.log;
    
    # Proxy para API
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        
        # CORS para HTTPS
        add_header Access-Control-Allow-Origin "https://desfollow.com.br, https://www.desfollow.com.br" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
        add_header Access-Control-Allow-Credentials true always;
        
        # OPTIONS preflight
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
}
EOF

check_success "Configuração final SSL criada"

echo ""
echo "📋 9. Testando configuração final..."
nginx -t
check_success "Configuração final válida"

echo ""
echo "📋 10. Aplicando configuração final..."
systemctl reload nginx
check_success "Nginx SSL ativado"

echo ""
echo "📋 11. Configurando renovação automática..."
cat > /etc/cron.d/certbot-renew << 'EOF'
# Renovar certificados SSL automaticamente
0 12 * * * root certbot renew --quiet --post-hook "systemctl reload nginx"
EOF
check_success "Renovação automática configurada"

echo ""
echo "📋 12. Testando URLs finais..."

sleep 3

echo "🌐 Testando HTTPS frontend..."
FRONTEND_HTTPS=$(curl -s -o /dev/null -w "%{http_code}" https://desfollow.com.br --insecure 2>/dev/null)
echo "   Frontend HTTPS: $FRONTEND_HTTPS"

echo "🌐 Testando HTTPS API..."
API_HTTPS=$(curl -s -o /dev/null -w "%{http_code}" https://api.desfollow.com.br --insecure 2>/dev/null)
echo "   API HTTPS: $API_HTTPS"

echo "🌐 Testando redirecionamentos..."
REDIRECT_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://desfollow.com.br 2>/dev/null)
echo "   HTTP -> HTTPS redirect: $REDIRECT_TEST"

echo ""
echo "✅ SSL CONFIGURADO COM SUCESSO!"
echo ""
echo "🔒 URLs FINAIS:"
echo "   https://desfollow.com.br (Frontend)"
echo "   https://www.desfollow.com.br (Frontend)"  
echo "   https://api.desfollow.com.br (API)"
echo ""
echo "🔄 REDIRECIONAMENTOS AUTOMÁTICOS:"
echo "   http:// → https:// (todos os domínios)"
echo ""
echo "📜 VERIFICAR LOGS:"
echo "   tail -f /var/log/nginx/frontend_ssl_access.log"
echo "   tail -f /var/log/nginx/api_ssl_access.log"
echo ""
echo "🔍 TESTAR CERTIFICADOS:"
echo "   curl https://api.desfollow.com.br"
echo "   openssl s_client -connect api.desfollow.com.br:443"
echo ""
echo "🚀 Problema SSL/CORS resolvido definitivamente!" 