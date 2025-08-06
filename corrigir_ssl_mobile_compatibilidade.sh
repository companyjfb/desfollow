#!/bin/bash

echo "🔧 CORRIGINDO SSL PARA COMPATIBILIDADE MÓVEL - DESFOLLOW"
echo "========================================================"

# Parar nginx
echo "📋 1. Parando nginx..."
sudo systemctl stop nginx

# Gerar certificados para desfollow.com.br (domínio principal)
echo "📋 2. Gerando certificados SSL para desfollow.com.br..."
sudo certbot certonly --standalone -d desfollow.com.br -d www.desfollow.com.br --email jordanbitencourt@gmail.com --agree-tos --no-eff-email --force-renewal

# Criar configuração nginx otimizada para mobile
echo "📋 3. Criando configuração nginx otimizada para mobile..."
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# CONFIGURAÇÃO NGINX SSL MÓVEL COMPATÍVEL - DESFOLLOW
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
    
    # Configurações SSL compatíveis com Safari Mobile
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 24h;
    ssl_session_tickets off;
    
    # OCSP Stapling para melhor performance mobile
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/desfollow.com.br/chain.pem;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    
    # Headers de segurança otimizados para mobile
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options DENY always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Configurações de performance para mobile
    client_max_body_size 10M;
    client_body_timeout 60s;
    client_header_timeout 60s;
    keepalive_timeout 65s;
    send_timeout 60s;
    
    # Diretório do frontend buildado
    root /var/www/html;
    index index.html;
    
    # Logs específicos do frontend
    access_log /var/log/nginx/frontend_ssl_access.log;
    error_log /var/log/nginx/frontend_ssl_error.log;
    
    # Configurações de cache para assets estáticos (otimizado mobile)
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary "Accept-Encoding";
        try_files $uri =404;
    }
    
    # React Router - todas as rotas SPA
    location / {
        try_files $uri $uri/ /index.html;
        
        # Headers para prevenir cache de HTML
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
    
    # Bloquear acesso direto à API no frontend
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
    
    # Configurações SSL compatíveis com Safari Mobile
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 24h;
    ssl_session_tickets off;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/api.desfollow.com.br/chain.pem;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options DENY always;
    
    # Configurações de timeout para mobile
    proxy_connect_timeout 300s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;
    proxy_buffering off;
    proxy_request_buffering off;
    
    # Logs da API
    access_log /var/log/nginx/api_ssl_access.log;
    error_log /var/log/nginx/api_ssl_error.log;
    
    # CORS Headers otimizados
    location / {
        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' 'https://desfollow.com.br' always;
            add_header 'Access-Control-Allow-Origin' 'https://www.desfollow.com.br' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'Accept, Authorization, Cache-Control, Content-Type, DNT, If-Modified-Since, Keep-Alive, Origin, User-Agent, X-Requested-With' always;
            add_header 'Access-Control-Max-Age' 86400 always;
            return 204;
        }
        
        # CORS para requests normais
        add_header 'Access-Control-Allow-Origin' 'https://desfollow.com.br' always;
        add_header 'Access-Control-Allow-Origin' 'https://www.desfollow.com.br' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Accept, Authorization, Cache-Control, Content-Type, DNT, If-Modified-Since, Keep-Alive, Origin, User-Agent, X-Requested-With' always;
        
        # Proxy para o backend
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Remover configuração antiga
echo "📋 4. Removendo configurações antigas..."
sudo rm -f /etc/nginx/sites-enabled/desfollow-www
sudo rm -f /etc/nginx/sites-available/desfollow-www

# Ativar nova configuração
echo "📋 5. Ativando nova configuração..."
sudo ln -sf /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/

# Testar configuração
echo "📋 6. Testando configuração nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração nginx válida"
    
    # Iniciar nginx
    echo "📋 7. Iniciando nginx..."
    sudo systemctl start nginx
    sudo systemctl reload nginx
    
    echo ""
    echo "✅ CORREÇÃO SSL MÓVEL CONCLUÍDA!"
    echo "================================="
    echo "🔗 Frontend: https://desfollow.com.br"
    echo "🔗 API: https://api.desfollow.com.br"
    echo ""
    echo "📱 MELHORIAS APLICADAS:"
    echo "• Certificado SSL completo com fullchain"
    echo "• Ciphers compatíveis com Safari Mobile"
    echo "• OCSP Stapling habilitado"
    echo "• Headers de segurança otimizados"
    echo "• Timeouts ajustados para mobile"
    echo "• Cache otimizado para performance"
    
else
    echo "❌ Erro na configuração nginx"
    sudo nginx -t
fi