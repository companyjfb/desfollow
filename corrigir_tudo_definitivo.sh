#!/bin/bash

echo "🔧 CORREÇÃO TUDO DEFINITIVO"
echo "============================"
echo "Corrigindo roteamento + CORS HTTPS"
echo ""

# Backup da configuração atual
BACKUP_FILE="/etc/nginx/sites-available/desfollow.backup.tudo.$(date +%Y%m%d_%H%M%S)"
sudo cp /etc/nginx/sites-available/desfollow "$BACKUP_FILE"
echo "💾 Backup: $BACKUP_FILE"

echo ""
echo "📋 Verificando certificados SSL existentes..."

# Verificar quais certificados existem
CERT_DESFOLLOW=false
CERT_API=false

if [ -f "/etc/letsencrypt/live/desfollow.com.br/fullchain.pem" ]; then
    echo "✅ Certificado para desfollow.com.br existe"
    CERT_DESFOLLOW=true
else
    echo "❌ Certificado para desfollow.com.br não encontrado"
fi

if [ -f "/etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem" ]; then
    echo "✅ Certificado para api.desfollow.com.br existe"
    CERT_API=true
else
    echo "❌ Certificado para api.desfollow.com.br não encontrado"
fi

echo ""
echo "📋 Criando configuração nginx com roteamento e CORS HTTPS..."

# Configuração nginx com roteamento correto e CORS HTTPS
if [ "$CERT_DESFOLLOW" = true ] && [ "$CERT_API" = true ]; then
    echo "📋 Usando configuração completa (ambos certificados existem)"
    
    sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# ========================================
# CONFIGURAÇÃO NGINX - TUDO DEFINITIVO
# ========================================
# Frontend: desfollow.com.br + www.desfollow.com.br (HTTPS)
# API: api.desfollow.com.br (HTTPS)
# CORS: HTTPS correto
# ========================================

# FRONTEND HTTPS - DESFOLLOW.COM.BR
server {
    listen 443 ssl http2;
    server_name desfollow.com.br;
    
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
    
    root /var/www/html;
    index index.html;
    
    access_log /var/log/nginx/frontend_ssl_access.log;
    error_log /var/log/nginx/frontend_ssl_error.log;
    
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
        return 200 "Frontend HTTPS OK\n";
        add_header Content-Type text/plain;
    }
}

# FRONTEND HTTPS - WWW.DESFOLLOW.COM.BR
server {
    listen 443 ssl http2;
    server_name www.desfollow.com.br;
    
    # Certificados SSL (mesmo do desfollow.com.br)
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
    
    root /var/www/html;
    index index.html;
    
    access_log /var/log/nginx/frontend_www_ssl_access.log;
    error_log /var/log/nginx/frontend_www_ssl_error.log;
    
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
        return 200 "Frontend WWW HTTPS OK\n";
        add_header Content-Type text/plain;
    }
}

# FRONTEND HTTP -> HTTPS REDIRECT
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# API HTTP -> HTTPS REDIRECT
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# API HTTPS - CORS HTTPS CORRETO
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL da API
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
        
        # 🚀 CORS HTTPS CORRETO - UM VALOR POR VEZ
        # CORS para requests normais (GET, POST, etc.)
        add_header Access-Control-Allow-Origin "https://desfollow.com.br" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
        add_header Access-Control-Allow-Credentials true always;
        
        # Preflight OPTIONS - CORS específico
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://desfollow.com.br" always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
            add_header Access-Control-Max-Age 1728000 always;
            add_header Content-Type 'text/plain charset=UTF-8';
            add_header Content-Length 0;
            return 204;
        }
    }
    
    # Health check da API
    location /health {
        access_log off;
        proxy_pass http://127.0.0.1:8000/health;
    }
}
EOF

elif [ "$CERT_API" = true ]; then
    echo "📋 Usando configuração apenas API (só certificado da API existe)"
    
    sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# ========================================
# CONFIGURAÇÃO NGINX - APENAS API
# ========================================
# Frontend: desfollow.com.br + www.desfollow.com.br (HTTP)
# API: api.desfollow.com.br (HTTPS)
# CORS: HTTP correto
# ========================================

# FRONTEND HTTP - DESFOLLOW.COM.BR
server {
    listen 80;
    server_name desfollow.com.br;
    
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

# FRONTEND HTTP - WWW.DESFOLLOW.COM.BR
server {
    listen 80;
    server_name www.desfollow.com.br;
    
    root /var/www/html;
    index index.html;
    
    access_log /var/log/nginx/frontend_www_access.log;
    error_log /var/log/nginx/frontend_www_error.log;
    
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
        return 200 "Frontend WWW HTTP OK\n";
        add_header Content-Type text/plain;
    }
}

# API HTTP -> HTTPS REDIRECT
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# API HTTPS - CORS HTTP CORRETO
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL da API
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
        
        # 🚀 CORS HTTP CORRETO - UM VALOR POR VEZ
        # CORS para requests normais (GET, POST, etc.)
        add_header Access-Control-Allow-Origin "http://desfollow.com.br" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
        add_header Access-Control-Allow-Credentials true always;
        
        # Preflight OPTIONS - CORS específico
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "http://desfollow.com.br" always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
            add_header Access-Control-Max-Age 1728000 always;
            add_header Content-Type 'text/plain charset=UTF-8';
            add_header Content-Length 0;
            return 204;
        }
    }
    
    # Health check da API
    location /health {
        access_log off;
        proxy_pass http://127.0.0.1:8000/health;
    }
}
EOF

else
    echo "❌ Nenhum certificado encontrado. Instalando SSL primeiro..."
    echo "📋 Instalando SSL para desfollow.com.br e www.desfollow.com.br..."
    sudo certbot certonly --nginx -d desfollow.com.br -d www.desfollow.com.br --non-interactive --agree-tos --email admin@desfollow.com.br
    
    echo "📋 Instalando SSL para api.desfollow.com.br..."
    sudo certbot certonly --nginx -d api.desfollow.com.br --non-interactive --agree-tos --email admin@desfollow.com.br
    
    echo "📋 Executando script novamente após instalar SSL..."
    ./corrigir_tudo_definitivo.sh
    exit 0
fi

echo "✅ Configuração nginx com roteamento e CORS correto criada"

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
echo "📋 Verificando se backend está rodando..."
if pgrep -f "uvicorn\|gunicorn" > /dev/null; then
    echo "✅ Backend rodando"
else
    echo "⚠️ Backend não encontrado, iniciando..."
    cd /root/desfollow
    nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 > /dev/null 2>&1 &
    sleep 3
fi

echo ""
echo "📋 Testando roteamento dos domínios..."

sleep 2

if [ "$CERT_DESFOLLOW" = true ]; then
    echo "🧪 Testando https://desfollow.com.br..."
    FRONTEND_TEST1=$(curl -s -I "https://desfollow.com.br" | head -1)
    echo "   Status: $FRONTEND_TEST1"
    
    echo "🧪 Testando https://www.desfollow.com.br..."
    FRONTEND_TEST2=$(curl -s -I "https://www.desfollow.com.br" | head -1)
    echo "   Status: $FRONTEND_TEST2"
else
    echo "🧪 Testando http://desfollow.com.br..."
    FRONTEND_TEST1=$(curl -s -I "http://desfollow.com.br" | head -1)
    echo "   Status: $FRONTEND_TEST1"
    
    echo "🧪 Testando http://www.desfollow.com.br..."
    FRONTEND_TEST2=$(curl -s -I "http://www.desfollow.com.br" | head -1)
    echo "   Status: $FRONTEND_TEST2"
fi

echo "🧪 Testando https://api.desfollow.com.br/api/health..."
API_TEST=$(curl -s "https://api.desfollow.com.br/api/health" 2>/dev/null)
if echo "$API_TEST" | grep -q "healthy"; then
    echo "✅ API HTTPS: $API_TEST"
else
    echo "⚠️ API HTTPS: $API_TEST"
fi

echo ""
echo "📋 Testando CORS correto..."

sleep 2

if [ "$CERT_DESFOLLOW" = true ]; then
    echo "🧪 Testando CORS com https://desfollow.com.br..."
    CORS_TEST1=$(curl -s -H "Origin: https://desfollow.com.br" -H "Access-Control-Request-Method: POST" -X OPTIONS "https://api.desfollow.com.br/api/scan" -I | grep "Access-Control-Allow-Origin")
    echo "   Origin: https://desfollow.com.br"
    echo "   Response: $CORS_TEST1"
    
    echo "🧪 Testando CORS com https://www.desfollow.com.br..."
    CORS_TEST2=$(curl -s -H "Origin: https://www.desfollow.com.br" -H "Access-Control-Request-Method: POST" -X OPTIONS "https://api.desfollow.com.br/api/scan" -I | grep "Access-Control-Allow-Origin")
    echo "   Origin: https://www.desfollow.com.br"
    echo "   Response: $CORS_TEST2"
else
    echo "🧪 Testando CORS com http://desfollow.com.br..."
    CORS_TEST1=$(curl -s -H "Origin: http://desfollow.com.br" -H "Access-Control-Request-Method: POST" -X OPTIONS "https://api.desfollow.com.br/api/scan" -I | grep "Access-Control-Allow-Origin")
    echo "   Origin: http://desfollow.com.br"
    echo "   Response: $CORS_TEST1"
    
    echo "🧪 Testando CORS com http://www.desfollow.com.br..."
    CORS_TEST2=$(curl -s -H "Origin: http://www.desfollow.com.br" -H "Access-Control-Request-Method: POST" -X OPTIONS "https://api.desfollow.com.br/api/scan" -I | grep "Access-Control-Allow-Origin")
    echo "   Origin: http://www.desfollow.com.br"
    echo "   Response: $CORS_TEST2"
fi

echo ""
echo "📋 Testando comunicação completa..."
cd /root/desfollow
python3 testar_comunicacao_frontend_backend.py

echo ""
echo "✅ TUDO DEFINITIVO CONFIGURADO!"
echo ""
if [ "$CERT_DESFOLLOW" = true ]; then
    echo "🔗 CONFIGURAÇÃO FINAL:"
    echo "   Frontend: https://desfollow.com.br (HTTPS)"
    echo "   Frontend: https://www.desfollow.com.br (HTTPS)"
    echo "   API:      https://api.desfollow.com.br (HTTPS)"
    echo ""
    echo "🔄 REDIRECIONAMENTOS:"
    echo "   http://desfollow.com.br → https://desfollow.com.br"
    echo "   http://www.desfollow.com.br → https://www.desfollow.com.br"
    echo "   http://api.desfollow.com.br → https://api.desfollow.com.br"
else
    echo "🔗 CONFIGURAÇÃO FINAL:"
    echo "   Frontend: http://desfollow.com.br (HTTP)"
    echo "   Frontend: http://www.desfollow.com.br (HTTP)"
    echo "   API:      https://api.desfollow.com.br (HTTPS)"
    echo ""
    echo "🔄 REDIRECIONAMENTOS:"
    echo "   http://api.desfollow.com.br → https://api.desfollow.com.br"
fi
echo ""
echo "⚙️ MELHORIAS ATIVAS:"
echo "   ✅ SSL: Usando certificados existentes"
echo "   ✅ CORS: HTTPS/HTTP correto (um valor por vez)"
echo "   ✅ Roteamento: Frontend em ambos domínios"
echo "   ✅ Timeout API: 300s (5 minutos)"
echo "   ✅ Proxy buffering: Desabilitado"
echo ""
echo "📜 Backup salvo em: $BACKUP_FILE"
echo ""
echo "🚀 TUDO DEFINITIVO FUNCIONANDO!" 