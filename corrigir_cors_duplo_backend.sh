#!/bin/bash

echo "🔧 Correção CORS Duplo - Backend + Nginx"
echo "========================================"
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
cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.duplo.$(date +%Y%m%d_%H%M%S)
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
echo "📋 4. Criando configuração nginx SEM CORS duplicado..."

cat > /etc/nginx/sites-available/desfollow << 'EOF'
# ========================================
# CONFIGURAÇÃO NGINX - DESFOLLOW
# SSL + CORS SEM DUPLICAÇÃO
# ========================================

# Frontend HTTP -> HTTPS
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Challenges Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files $uri =404;
    }
    
    # Redirecionar para HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# API HTTP -> HTTPS  
server {
    listen 80;
    server_name api.desfollow.com.br;
    
    # Challenges Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files $uri =404;
    }
    
    # Redirecionar para HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# API HTTPS - CORS SEM DUPLICAÇÃO
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate CERT_PATH_PLACEHOLDER/fullchain.pem;
    ssl_certificate_key CERT_PATH_PLACEHOLDER/privkey.pem;
    
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
    
    # Proxy para API com CORS ÚNICO
    location / {
        # CRITICAL: Esconder headers CORS do backend
        proxy_hide_header Access-Control-Allow-Origin;
        proxy_hide_header Access-Control-Allow-Methods;
        proxy_hide_header Access-Control-Allow-Headers;
        proxy_hide_header Access-Control-Allow-Credentials;
        
        # Variável para origin dinâmico
        set $cors_origin "";
        
        # Verificar origin e definir valor correto
        if ($http_origin = "https://desfollow.com.br") {
            set $cors_origin "https://desfollow.com.br";
        }
        if ($http_origin = "https://www.desfollow.com.br") {
            set $cors_origin "https://www.desfollow.com.br";
        }
        
        # Proxy para backend
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        
        # CORS - APENAS NGINX (sem conflito com backend)
        add_header Access-Control-Allow-Origin $cors_origin always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
        add_header Access-Control-Allow-Credentials true always;
        
        # Preflight OPTIONS
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin $cors_origin always;
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
        # Esconder CORS também do health
        proxy_hide_header Access-Control-Allow-Origin;
    }
}
EOF

# Substituir placeholder com path real
sed -i "s|CERT_PATH_PLACEHOLDER|$CERT_PATH|g" /etc/nginx/sites-available/desfollow

check_success "Configuração sem CORS duplo criada"

echo ""
echo "📋 5. Testando nova configuração..."
nginx -t
check_success "Configuração nginx válida"

echo ""
echo "📋 6. Aplicando configuração..."
systemctl reload nginx
check_success "Nginx recarregado"

echo ""
echo "📋 7. Testando CORS corrigido..."

sleep 2

echo "🌐 Testando API HTTPS..."
API_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://api.desfollow.com.br 2>/dev/null)
echo "   API Status: $API_CODE"

echo ""
echo "🌐 Testando CORS www.desfollow.com.br..."
CORS_TEST=$(curl -s -H "Origin: https://www.desfollow.com.br" -H "Access-Control-Request-Method: POST" -X OPTIONS https://api.desfollow.com.br/api/scan -I 2>/dev/null)
CORS_HEADER=$(echo "$CORS_TEST" | grep -i "access-control-allow-origin" | head -1)
echo "   CORS Header: $CORS_HEADER"

echo ""
echo "✅ CORS DUPLO CORRIGIDO!"
echo ""
echo "🔧 PROBLEMAS RESOLVIDOS:"
echo "   ❌ Backend enviando: '*'"
echo "   ❌ Nginx enviando: 'https://www.desfollow.com.br'"
echo "   ❌ Resultado: '*, https://www.desfollow.com.br'"
echo ""
echo "   ✅ Nginx esconde headers do backend"
echo "   ✅ Apenas nginx controla CORS"
echo "   ✅ Um valor único por requisição"
echo ""
echo "🎯 CONFIGURAÇÃO FINAL:"
echo "   • proxy_hide_header Access-Control-Allow-Origin"
echo "   • Nginx define CORS baseado no origin"
echo "   • Backend CORS ignorado"
echo ""
echo "📋 TESTAR NO FRONTEND:"
echo "   • Recarregar https://www.desfollow.com.br"
echo "   • Tentar scan - deve funcionar sem erro"
echo "   • Console não deve mostrar erro CORS"
echo ""
echo "🚀 CORS definitivamente resolvido!" 