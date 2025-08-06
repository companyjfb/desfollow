#!/bin/bash

echo "🔧 CORREÇÃO FINAL NGINX - SINTAXE CORRETA"
echo "========================================="

# Criar configuração nginx com sintaxe correta
echo "📋 1. Criando configuração nginx correta..."
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# FRONTEND - Domínios principais
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name desfollow.com.br www.desfollow.com.br _;
    
    root /var/www/desfollow;
    index index.html index.htm;
    
    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
    
    # SPA - Single Page Application routing
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Cache para assets estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
}

# BACKEND API - Subdomínio com SSL
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # SSL
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Headers CORS
    add_header Access-Control-Allow-Origin "*";
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS, PUT, DELETE";
    add_header Access-Control-Allow-Headers "Origin, Content-Type, Accept, Authorization, X-Requested-With";
    add_header Access-Control-Allow-Credentials "true";
    
    # Proxy para backend
    location / {
        # Handle OPTIONS requests
        if ($request_method = OPTIONS) {
            return 204;
        }
        
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        proxy_buffering off;
    }
}
EOF

echo "📋 2. Testando configuração..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração OK!"
    
    echo "📋 3. Iniciando nginx..."
    sudo systemctl start nginx
    sudo systemctl enable nginx
    
    sleep 3
    
    echo "📋 4. Verificando status..."
    sudo systemctl status nginx --no-pager | head -5
    
    echo "📋 5. Testando endpoints..."
    echo "• Frontend:"
    curl -I http://desfollow.com.br 2>/dev/null | head -2
    echo "• API:"
    curl -I https://api.desfollow.com.br/health 2>/dev/null | head -2
    
    echo ""
    echo "✅ NGINX CONFIGURADO COM SUCESSO!"
    echo "🌐 Frontend: http://desfollow.com.br"
    echo "🔧 API: https://api.desfollow.com.br"
    
else
    echo "❌ Erro na configuração!"
    sudo nginx -t
fi