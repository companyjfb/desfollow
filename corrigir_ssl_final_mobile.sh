#!/bin/bash

echo "🔧 CORREÇÃO SSL FINAL PARA MOBILE - DESFOLLOW"
echo "============================================="

# Parar nginx
echo "📋 1. Parando nginx..."
sudo systemctl stop nginx

# Corrigir configuração SSL removendo OCSP que está causando problemas
echo "📋 2. Corrigindo configuração nginx (removendo OCSP problemático)..."
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# CONFIGURAÇÃO NGINX SSL MÓVEL FINAL - DESFOLLOW
# Frontend: desfollow.com.br + www.desfollow.com.br
# API: api.desfollow.com.br
# =====================================================

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
    
    # Configurações SSL otimizadas para Safari Mobile
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    
    # Headers de segurança otimizados
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Configurações de performance
    client_max_body_size 10M;
    client_body_timeout 60s;
    client_header_timeout 60s;
    keepalive_timeout 65s;
    send_timeout 60s;
    
    # Diretório do frontend
    root /var/www/html;
    index index.html;
    
    # Logs
    access_log /var/log/nginx/frontend_ssl_access.log;
    error_log /var/log/nginx/frontend_ssl_error.log;
    
    # Configurações para arquivos estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary "Accept-Encoding";
        try_files $uri =404;
    }
    
    # Fallback para imagens faltando (evitar 404)
    location ~* /lovable-uploads/ {
        try_files $uri /placeholder-image.png;
    }
    
    # React Router - todas as rotas SPA
    location / {
        try_files $uri $uri/ /index.html;
        
        # Headers anti-cache para HTML
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
    
    # Bloquear acesso à API
    location /api {
        return 404;
    }
}

# API - HTTP (redirect para HTTPS)
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# API - HTTPS
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL da API
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    
    # Configurações SSL otimizadas para Safari Mobile
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    
    # Timeouts para mobile
    proxy_connect_timeout 300s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;
    proxy_buffering off;
    proxy_request_buffering off;
    
    # Logs da API
    access_log /var/log/nginx/api_ssl_access.log;
    error_log /var/log/nginx/api_ssl_error.log;
    
    # CORS e proxy para backend
    location / {
        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '$http_origin' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'Accept, Authorization, Cache-Control, Content-Type, DNT, If-Modified-Since, Keep-Alive, Origin, User-Agent, X-Requested-With' always;
            add_header 'Access-Control-Allow-Credentials' 'true' always;
            add_header 'Access-Control-Max-Age' 86400 always;
            return 204;
        }
        
        # CORS para requests normais
        add_header 'Access-Control-Allow-Origin' '$http_origin' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Accept, Authorization, Cache-Control, Content-Type, DNT, If-Modified-Since, Keep-Alive, Origin, User-Agent, X-Requested-With' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        
        # Proxy para o backend
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
    }
}
EOF

# Testar configuração
echo "📋 3. Testando configuração..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração válida"
    
    # Iniciar nginx
    echo "📋 4. Iniciando nginx..."
    sudo systemctl start nginx
    sudo systemctl reload nginx
    
    # Aguardar alguns segundos
    sleep 3
    
    # Teste final
    echo "📋 5. Teste final..."
    echo "Testando HTTPS:"
    curl -sI https://desfollow.com.br --connect-timeout 10 --max-time 15 | head -3
    
    echo ""
    echo "✅ CORREÇÃO SSL MÓVEL CONCLUÍDA!"
    echo "================================="
    echo "🔗 Frontend: https://desfollow.com.br"
    echo "🔗 API: https://api.desfollow.com.br"
    echo ""
    echo "📱 PROBLEMAS CORRIGIDOS:"
    echo "• Removido OCSP Stapling problemático"
    echo "• Simplificados ciphers para compatibilidade máxima"
    echo "• Adicionado fallback para imagens faltando"
    echo "• Otimizado CORS dinâmico"
    echo "• Reduzido session timeout"
    
else
    echo "❌ Erro na configuração"
    sudo nginx -t
fi