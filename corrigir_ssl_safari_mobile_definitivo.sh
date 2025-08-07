#!/bin/bash

echo "🔧 CORREÇÃO SSL SAFARI MOBILE DEFINITIVA - DESFOLLOW"
echo "==================================================="

# Parar nginx
echo "📋 1. Parando nginx..."
sudo systemctl stop nginx

# Corrigir configuração com ciphers específicos para Safari mobile
echo "📋 2. Aplicando configuração SSL otimizada para Safari Mobile..."
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# CONFIGURAÇÃO NGINX SSL SAFARI MOBILE - DESFOLLOW
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
    
    # Configurações SSL ESPECÍFICAS para Safari Mobile iOS
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA;
    ssl_prefer_server_ciphers on;
    ssl_ecdh_curve secp384r1;
    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;
    
    # Configurações adicionais para compatibilidade
    ssl_buffer_size 8k;
    ssl_early_data off;
    
    # Headers de segurança otimizados para mobile
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Configurações de performance móvel
    client_max_body_size 10M;
    client_body_timeout 60s;
    client_header_timeout 60s;
    keepalive_timeout 65s;
    send_timeout 60s;
    
    # Compressão otimizada
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    # Diretório do frontend
    root /var/www/html;
    index index.html;
    
    # Logs
    access_log /var/log/nginx/frontend_ssl_access.log;
    error_log /var/log/nginx/frontend_ssl_error.log;
    
    # Configurações para arquivos estáticos com headers otimizados
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary "Accept-Encoding";
        add_header Access-Control-Allow-Origin "*";
        try_files $uri =404;
    }
    
    # Fallback para imagens faltando
    location ~* /lovable-uploads/ {
        try_files $uri /favicon.ico;
        expires 1d;
        add_header Cache-Control "public";
    }
    
    # React Router - todas as rotas SPA
    location / {
        try_files $uri $uri/ /index.html;
        
        # Headers específicos para HTML (sem cache)
        location ~* \.html$ {
            add_header Cache-Control "no-cache, no-store, must-revalidate";
            add_header Pragma "no-cache";
            add_header Expires "0";
        }
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
    
    # Configurações SSL ESPECÍFICAS para Safari Mobile iOS (API)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA;
    ssl_prefer_server_ciphers on;
    ssl_ecdh_curve secp384r1;
    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;
    ssl_buffer_size 8k;
    ssl_early_data off;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
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
    
    # Aguardar
    sleep 5
    
    # Teste específico de ciphers
    echo "📋 5. Testando negociação de ciphers..."
    echo "Teste cipher AES128-GCM-SHA256:"
    timeout 10 openssl s_client -connect desfollow.com.br:443 -cipher ECDHE-RSA-AES128-GCM-SHA256 < /dev/null 2>/dev/null | grep -E "(Cipher|Protocol|Verify return code)"
    
    echo ""
    echo "Teste TLS 1.2 com cipher específico:"
    timeout 10 openssl s_client -connect desfollow.com.br:443 -tls1_2 -cipher ECDHE-RSA-AES128-GCM-SHA256 < /dev/null 2>/dev/null | grep -E "(Cipher|Protocol|Verify return code)"
    
    echo ""
    echo "✅ CORREÇÃO SSL SAFARI MOBILE CONCLUÍDA!"
    echo "========================================"
    echo "🔗 Frontend: https://desfollow.com.br"
    echo "🔗 API: https://api.desfollow.com.br"
    echo ""
    echo "📱 CORREÇÕES APLICADAS:"
    echo "• Ciphers específicos para Safari iOS"
    echo "• ssl_prefer_server_ciphers ON"
    echo "• Curve secp384r1 para compatibilidade"
    echo "• Buffer SSL otimizado"
    echo "• Early data desabilitado"
    echo "• Fallback para imagens 404"
    echo "• Compressão gzip otimizada"
    
else
    echo "❌ Erro na configuração"
    sudo nginx -t
fi