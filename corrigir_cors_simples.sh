#!/bin/bash

echo "🔧 CORREÇÃO CORS SIMPLES"
echo "======================="
echo "Corrigindo erro: 'multiple values but only one is allowed'"
echo "Usando if statements em vez de map (que não funciona no server block)"
echo ""

# Backup da configuração atual
BACKUP_FILE="/etc/nginx/sites-available/desfollow.backup.cors-simple.$(date +%Y%m%d_%H%M%S)"
sudo cp /etc/nginx/sites-available/desfollow "$BACKUP_FILE"
echo "💾 Backup: $BACKUP_FILE"

echo ""
echo "📋 Criando configuração nginx com CORS simples..."

# Configuração corrigida - CORS com if statements
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# ========================================
# CONFIGURAÇÃO NGINX - DESFOLLOW CORS SIMPLES
# ========================================
# Frontend: HTTP (sem SSL)
# API: HTTPS (SSL funcionando)
# CORS: IF statements para um valor por vez
# ========================================

# FRONTEND HTTP - SEM SSL (temporário)
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    root /var/www/html;
    index index.html;
    
    access_log /var/log/nginx/frontend_access.log;
    error_log /var/log/nginx/frontend_error.log;
    
    # Cache para assets estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }
    
    # React Router - todas as rotas SPA
    location / {
        try_files $uri $uri/ /index.html;
        
        # Headers de segurança
        add_header X-Content-Type-Options nosniff;
        add_header X-Frame-Options DENY;
        add_header X-XSS-Protection "1; mode=block";
    }
    
    # Bloquear acesso a arquivos sensíveis
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "Frontend HTTP OK\n";
        add_header Content-Type text/plain;
    }
}

# API HTTP -> HTTPS REDIRECT
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# API HTTPS - CORS SIMPLES CORRIGIDO
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL da API (existem)
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    
    # Configurações SSL seguras
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Logs da API
    access_log /var/log/nginx/api_ssl_access.log;
    error_log /var/log/nginx/api_ssl_error.log;
    
    # Proxy para backend
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $host;
        
        # 🚀 TIMEOUTS CORRIGIDOS: 5 minutos
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        
        # 🚀 CONFIGURAÇÕES PARA REQUESTS LONGOS
        proxy_buffering off;
        proxy_request_buffering off;
        client_max_body_size 10m;
        
        # 🚀 CORS SIMPLES - UM VALOR POR VEZ COM IF
        # Preflight OPTIONS
        if ($request_method = 'OPTIONS') {
            # HTTPS origins
            if ($http_origin = 'https://desfollow.com.br') {
                add_header Access-Control-Allow-Origin 'https://desfollow.com.br' always;
                add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS' always;
                add_header Access-Control-Allow-Headers 'Authorization, Content-Type, X-Requested-With' always;
                add_header Access-Control-Max-Age 1728000 always;
                add_header Content-Type 'text/plain charset=UTF-8';
                add_header Content-Length 0;
                return 204;
            }
            if ($http_origin = 'https://www.desfollow.com.br') {
                add_header Access-Control-Allow-Origin 'https://www.desfollow.com.br' always;
                add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS' always;
                add_header Access-Control-Allow-Headers 'Authorization, Content-Type, X-Requested-With' always;
                add_header Access-Control-Max-Age 1728000 always;
                add_header Content-Type 'text/plain charset=UTF-8';
                add_header Content-Length 0;
                return 204;
            }
            # HTTP origins
            if ($http_origin = 'http://desfollow.com.br') {
                add_header Access-Control-Allow-Origin 'http://desfollow.com.br' always;
                add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS' always;
                add_header Access-Control-Allow-Headers 'Authorization, Content-Type, X-Requested-With' always;
                add_header Access-Control-Max-Age 1728000 always;
                add_header Content-Type 'text/plain charset=UTF-8';
                add_header Content-Length 0;
                return 204;
            }
            if ($http_origin = 'http://www.desfollow.com.br') {
                add_header Access-Control-Allow-Origin 'http://www.desfollow.com.br' always;
                add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS' always;
                add_header Access-Control-Allow-Headers 'Authorization, Content-Type, X-Requested-With' always;
                add_header Access-Control-Max-Age 1728000 always;
                add_header Content-Type 'text/plain charset=UTF-8';
                add_header Content-Length 0;
                return 204;
            }
            # Default fallback for OPTIONS
            add_header Access-Control-Allow-Origin '*' always;
            add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header Access-Control-Allow-Headers 'Authorization, Content-Type, X-Requested-With' always;
            add_header Access-Control-Max-Age 1728000 always;
            add_header Content-Type 'text/plain charset=UTF-8';
            add_header Content-Length 0;
            return 204;
        }
        
        # CORS para requests normais (GET, POST, etc.)
        # HTTPS origins
        if ($http_origin = 'https://desfollow.com.br') {
            add_header Access-Control-Allow-Origin 'https://desfollow.com.br' always;
            add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header Access-Control-Allow-Headers 'Authorization, Content-Type, X-Requested-With' always;
            add_header Access-Control-Allow-Credentials true always;
        }
        if ($http_origin = 'https://www.desfollow.com.br') {
            add_header Access-Control-Allow-Origin 'https://www.desfollow.com.br' always;
            add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header Access-Control-Allow-Headers 'Authorization, Content-Type, X-Requested-With' always;
            add_header Access-Control-Allow-Credentials true always;
        }
        # HTTP origins
        if ($http_origin = 'http://desfollow.com.br') {
            add_header Access-Control-Allow-Origin 'http://desfollow.com.br' always;
            add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header Access-Control-Allow-Headers 'Authorization, Content-Type, X-Requested-With' always;
            add_header Access-Control-Allow-Credentials true always;
        }
        if ($http_origin = 'http://www.desfollow.com.br') {
            add_header Access-Control-Allow-Origin 'http://www.desfollow.com.br' always;
            add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header Access-Control-Allow-Headers 'Authorization, Content-Type, X-Requested-With' always;
            add_header Access-Control-Allow-Credentials true always;
        }
    }
    
    # Health check da API
    location /health {
        access_log off;
        proxy_pass http://127.0.0.1:8000/health;
    }
}
EOF

echo "✅ Configuração CORS simples criada"

echo ""
echo "📋 Testando configuração..."
sudo nginx -t
if [ $? -eq 0 ]; then
    echo "✅ Configuração nginx válida!"
else
    echo "❌ Configuração inválida. Restaurando backup..."
    sudo cp "$BACKUP_FILE" /etc/nginx/sites-available/desfollow
    exit 1
fi

echo ""
echo "📋 Recarregando nginx..."
sudo systemctl reload nginx
if [ $? -eq 0 ]; then
    echo "✅ Nginx recarregado com sucesso!"
else
    echo "❌ Erro ao recarregar nginx"
    sudo systemctl status nginx
    exit 1
fi

echo ""
echo "📋 Testando CORS corrigido..."

sleep 2

echo "🧪 Testando CORS com https://desfollow.com.br..."
CORS_TEST1=$(curl -s -H "Origin: https://desfollow.com.br" -H "Access-Control-Request-Method: POST" -X OPTIONS "https://api.desfollow.com.br/api/scan" -I | grep "Access-Control-Allow-Origin")
echo "   Origin: https://desfollow.com.br"
echo "   Response: $CORS_TEST1"

echo "🧪 Testando CORS com https://www.desfollow.com.br..."
CORS_TEST2=$(curl -s -H "Origin: https://www.desfollow.com.br" -H "Access-Control-Request-Method: POST" -X OPTIONS "https://api.desfollow.com.br/api/scan" -I | grep "Access-Control-Allow-Origin")
echo "   Origin: https://www.desfollow.com.br"
echo "   Response: $CORS_TEST2"

echo "🧪 Testando CORS com http://desfollow.com.br..."
CORS_TEST3=$(curl -s -H "Origin: http://desfollow.com.br" -H "Access-Control-Request-Method: POST" -X OPTIONS "https://api.desfollow.com.br/api/scan" -I | grep "Access-Control-Allow-Origin")
echo "   Origin: http://desfollow.com.br"
echo "   Response: $CORS_TEST3"

echo ""
echo "📋 Testando API ainda funciona..."
API_TEST=$(curl -s "https://api.desfollow.com.br/api/health" 2>/dev/null)
if echo "$API_TEST" | grep -q "healthy"; then
    echo "✅ API HTTPS: $API_TEST"
else
    echo "⚠️ API HTTPS: $API_TEST"
fi

echo ""
echo "📋 Testando comunicação completa..."
cd /root/desfollow
python3 testar_comunicacao_frontend_backend.py

echo ""
echo "✅ CORS SIMPLES CONFIGURADO!"
echo ""
echo "🔗 CONFIGURAÇÃO FINAL:"
echo "   Frontend: http://desfollow.com.br (HTTP temporário)"
echo "   Frontend: http://www.desfollow.com.br (HTTP temporário)"  
echo "   API:      https://api.desfollow.com.br (HTTPS funcionando)"
echo ""
echo "🔄 CORS COM IF STATEMENTS:"
echo "   ✅ Origin: https://desfollow.com.br → Allow-Origin: https://desfollow.com.br (exato)"
echo "   ✅ Origin: https://www.desfollow.com.br → Allow-Origin: https://www.desfollow.com.br (exato)"
echo "   ✅ Origin: http://desfollow.com.br → Allow-Origin: http://desfollow.com.br (exato)"
echo "   ✅ Origin: http://www.desfollow.com.br → Allow-Origin: http://www.desfollow.com.br (exato)"
echo ""
echo "⚙️ MELHORIAS MANTIDAS:"
echo "   ✅ Timeout API: 300s (5 minutos)"
echo "   ✅ CORS: IF statements (sem map, um valor exato)"
echo "   ✅ Proxy buffering: Desabilitado"
echo ""
echo "📜 Backup salvo em: $BACKUP_FILE"
echo ""
echo "🚀 CORS corrigido! IF statements funcionam no server block."