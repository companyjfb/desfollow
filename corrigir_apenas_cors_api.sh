#!/bin/bash

echo "🔧 CORRIGINDO APENAS CORS DA API - MANTENDO SSL ATUAL"
echo "=================================================="

# Parar nginx
echo "📋 1. Parando nginx..."
sudo systemctl stop nginx

# Backup da configuração atual
echo "📋 2. Fazendo backup da configuração atual..."
sudo cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.$(date +%Y%m%d_%H%M%S)

# Verificar configuração atual
echo "📋 3. Verificando configuração SSL atual..."
if grep -q "ssl_certificate" /etc/nginx/sites-available/desfollow; then
    echo "✅ SSL já configurado, mantendo configuração existente"
    
    # Extrair configuração SSL atual do frontend
    FRONTEND_SSL_CERT=$(grep "ssl_certificate " /etc/nginx/sites-available/desfollow | grep -E "(desfollow\.com\.br|www\.desfollow)" | head -1 | awk '{print $2}' | sed 's/;//')
    FRONTEND_SSL_KEY=$(grep "ssl_certificate_key" /etc/nginx/sites-available/desfollow | grep -E "(desfollow\.com\.br|www\.desfollow)" | head -1 | awk '{print $2}' | sed 's/;//')
    
    # Extrair configuração SSL atual da API
    API_SSL_CERT=$(grep "ssl_certificate " /etc/nginx/sites-available/desfollow | grep -E "api\.desfollow" | head -1 | awk '{print $2}' | sed 's/;//')
    API_SSL_KEY=$(grep "ssl_certificate_key" /etc/nginx/sites-available/desfollow | grep -E "api\.desfollow" | head -1 | awk '{print $2}' | sed 's/;//')
    
    echo "Frontend SSL Cert: $FRONTEND_SSL_CERT"
    echo "Frontend SSL Key: $FRONTEND_SSL_KEY"
    echo "API SSL Cert: $API_SSL_CERT"
    echo "API SSL Key: $API_SSL_KEY"
    
else
    echo "❌ SSL não encontrado na configuração atual"
    exit 1
fi

# Criar nova configuração mantendo SSL e ajustando CORS
echo "📋 4. Aplicando nova configuração com CORS corrigido..."
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << EOF
# CONFIGURAÇÃO NGINX - CORS CORRIGIDO - SSL HOSTINGER MANTIDO
# ==========================================================

# HTTP para HTTPS redirect
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    return 301 https://\$server_name\$request_uri;
}

# FRONTEND HTTPS - SSL MANTIDO
server {
    listen 443 ssl http2;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Certificados SSL (mantendo os atuais)
    ssl_certificate $FRONTEND_SSL_CERT;
    ssl_certificate_key $FRONTEND_SSL_KEY;
    
    # SSL básico
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Diretório
    root /var/www/desfollow;
    index index.html;
    
    # Logs
    access_log /var/log/nginx/frontend_access.log;
    error_log /var/log/nginx/frontend_error.log;
    
    # Servir arquivos
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}

# API HTTPS - CORS TOTAL
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL da API (mantendo os atuais)
    ssl_certificate $API_SSL_CERT;
    ssl_certificate_key $API_SSL_KEY;
    
    # SSL básico
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Logs
    access_log /var/log/nginx/api_access.log;
    error_log /var/log/nginx/api_error.log;
    
    # IMPORTANTE: Configuração CORS TOTAL
    location / {
        # Headers CORS SEMPRE
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        
        # Handle preflight OPTIONS requests
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
            add_header 'Access-Control-Max-Age' 1728000 always;
            add_header 'Content-Type' 'text/plain; charset=utf-8' always;
            add_header 'Content-Length' 0 always;
            return 204;
        }
        
        # Proxy para backend
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        # Timeouts
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        proxy_buffering off;
        proxy_request_buffering off;
        
        # Esconder headers CORS do backend para evitar duplicação
        proxy_hide_header 'Access-Control-Allow-Origin';
        proxy_hide_header 'Access-Control-Allow-Methods';
        proxy_hide_header 'Access-Control-Allow-Headers';
        proxy_hide_header 'Access-Control-Allow-Credentials';
        proxy_hide_header 'Access-Control-Expose-Headers';
    }
}
EOF

# Testar configuração
echo "📋 5. Testando configuração nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração nginx válida"
    
    # Iniciar nginx
    echo "📋 6. Iniciando nginx..."
    sudo systemctl start nginx
    
    # Aguardar
    sleep 3
    
    # Testes específicos de CORS
    echo "📋 7. Testando CORS..."
    
    echo "Teste OPTIONS para /api/scan:"
    curl -X OPTIONS \
         -H "Origin: https://www.desfollow.com.br" \
         -H "Access-Control-Request-Method: POST" \
         -H "Access-Control-Request-Headers: Content-Type" \
         -I \
         https://api.desfollow.com.br/api/scan 2>/dev/null | grep -i "access-control\|HTTP/"
    
    echo ""
    echo "Teste GET para API:"
    curl -H "Origin: https://www.desfollow.com.br" \
         -I \
         https://api.desfollow.com.br/api/status 2>/dev/null | grep -i "access-control\|HTTP/"
    
    echo ""
    echo "✅ CORS CORRIGIDO - SSL MANTIDO!"
    echo "==============================="
    echo "🔗 Frontend: https://desfollow.com.br"
    echo "🔗 API: https://api.desfollow.com.br"
    echo ""
    echo "📱 MUDANÇAS:"
    echo "• SSL: Mantido (Hostinger Lifetime SSL)"
    echo "• CORS: Corrigido completamente"
    echo "• Headers: Access-Control-Allow-Origin: *"
    echo "• Preflight: OPTIONS requests tratadas"
    echo "• Backend: Headers CORS escondidos (evita duplicação)"
    
else
    echo "❌ Erro na configuração nginx"
    sudo nginx -t
    echo ""
    echo "📋 Restaurando backup..."
    sudo cp /etc/nginx/sites-available/desfollow.backup.* /etc/nginx/sites-available/desfollow 2>/dev/null || echo "Backup não encontrado"
fi

echo ""
echo "📋 8. TESTE:"
echo "Agora teste o scan no frontend. Deve funcionar sem erro de CORS!"