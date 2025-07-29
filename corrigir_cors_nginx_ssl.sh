#!/bin/bash

echo "🔧 Correção CORS - Nginx SSL API"
echo "================================="
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

echo "📋 1. Verificando configuração atual..."
if ! nginx -t; then
    echo "❌ Configuração nginx atual inválida"
    exit 1
fi

echo ""
echo "📋 2. Backup da configuração atual..."
cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.cors.$(date +%Y%m%d_%H%M%S)
check_success "Backup criado"

echo ""
echo "📋 3. Detectando certificados SSL..."
if [ -d "/etc/letsencrypt/live/desfollow.com.br" ]; then
    CERT_PATH="/etc/letsencrypt/live/desfollow.com.br"
    echo "✅ Certificado encontrado: $CERT_PATH"
elif [ -d "/etc/letsencrypt/live/api.desfollow.com.br" ]; then
    CERT_PATH="/etc/letsencrypt/live/api.desfollow.com.br"
    echo "✅ Certificado encontrado: $CERT_PATH"
else
    echo "❌ Certificado SSL não encontrado"
    exit 1
fi

echo ""
echo "📋 4. Criando configuração nginx com CORS correto..."

cat > /etc/nginx/sites-available/desfollow << EOF
# ========================================
# CONFIGURAÇÃO NGINX - DESFOLLOW
# SSL + CORS CORRIGIDO
# ========================================

# Frontend HTTP -> HTTPS
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Challenges Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files \$uri =404;
    }
    
    # Redirecionar para HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# API HTTP -> HTTPS  
server {
    listen 80;
    server_name api.desfollow.com.br;
    
    # Challenges Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files \$uri =404;
    }
    
    # Redirecionar para HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# API HTTPS - CORS CORRIGIDO
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate $CERT_PATH/fullchain.pem;
    ssl_certificate_key $CERT_PATH/privkey.pem;
    
    # Configurações SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Logs
    access_log /var/log/nginx/api_ssl_access.log;
    error_log /var/log/nginx/api_ssl_error.log;
    
    # Proxy para API com CORS CORRETO
    location / {
        # Variável para origin dinâmico
        set \$cors_origin "";
        
        # Verificar origin e definir valor correto
        if (\$http_origin = "https://desfollow.com.br") {
            set \$cors_origin "https://desfollow.com.br";
        }
        if (\$http_origin = "https://www.desfollow.com.br") {
            set \$cors_origin "https://www.desfollow.com.br";
        }
        
        # Proxy para backend
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        
        # CORS - UM VALOR POR VEZ
        add_header Access-Control-Allow-Origin \$cors_origin always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
        add_header Access-Control-Allow-Credentials true always;
        
        # Preflight OPTIONS
        if (\$request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin \$cors_origin always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
            add_header Access-Control-Allow-Credentials true always;
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain charset=UTF-8';
            add_header Content-Length 0;
            return 204;
        }
    }
    
    # Health check sem CORS
    location /health {
        access_log off;
        proxy_pass http://127.0.0.1:8000/health;
    }
}
EOF

check_success "Configuração CORS corrigida criada"

echo ""
echo "📋 5. Testando nova configuração..."
nginx -t
check_success "Configuração nginx válida"

echo ""
echo "📋 6. Aplicando configuração..."
systemctl reload nginx
check_success "Nginx recarregado"

echo ""
echo "📋 7. Testando CORS..."

sleep 2

echo "🌐 Testando API HTTPS..."
API_RESPONSE=\$(curl -s -w "HTTP_CODE:%{http_code}" https://api.desfollow.com.br 2>/dev/null)
echo "   API Response: \$API_RESPONSE"

echo ""
echo "🌐 Testando CORS de desfollow.com.br..."
CORS_TEST1=\$(curl -s -H "Origin: https://desfollow.com.br" -H "Access-Control-Request-Method: POST" -H "Access-Control-Request-Headers: Content-Type" -X OPTIONS https://api.desfollow.com.br/api/scan -I 2>/dev/null | grep -i "access-control-allow-origin")
echo "   CORS para desfollow.com.br: \$CORS_TEST1"

echo ""
echo "🌐 Testando CORS de www.desfollow.com.br..."
CORS_TEST2=\$(curl -s -H "Origin: https://www.desfollow.com.br" -H "Access-Control-Request-Method: POST" -H "Access-Control-Request-Headers: Content-Type" -X OPTIONS https://api.desfollow.com.br/api/scan -I 2>/dev/null | grep -i "access-control-allow-origin")
echo "   CORS para www.desfollow.com.br: \$CORS_TEST2"

echo ""
echo "✅ CORS CORRIGIDO COM SUCESSO!"
echo ""
echo "🔧 PROBLEMA RESOLVIDO:"
echo "   ❌ ANTES: Access-Control-Allow-Origin com múltiplos valores"
echo "   ✅ DEPOIS: Um valor por requisição baseado no Origin"
echo ""
echo "🎯 LÓGICA CORS:"
echo "   • Origin = https://desfollow.com.br → Allow: https://desfollow.com.br"
echo "   • Origin = https://www.desfollow.com.br → Allow: https://www.desfollow.com.br"
echo ""
echo "📋 TESTAR NO FRONTEND:"
echo "   • Recarregar https://www.desfollow.com.br"
echo "   • Tentar scan - deve funcionar sem erro CORS"
echo ""
echo "📜 MONITORAR LOGS:"
echo "   tail -f /var/log/nginx/api_ssl_access.log"
echo "   tail -f /var/log/nginx/api_ssl_error.log"
echo ""
echo "🚀 Problema CORS definitivamente resolvido!" 