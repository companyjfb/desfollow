#!/bin/bash

echo "🔒 INSTALANDO SSL COMPLETO PARA TODOS OS DOMÍNIOS"
echo "================================================"

# Parar nginx
echo "📋 1. Parando nginx..."
sudo systemctl stop nginx

# Instalar SSL para todos os domínios
echo "📋 2. Instalando SSL para todos os domínios..."
sudo certbot certonly \
  --standalone \
  --non-interactive \
  --agree-tos \
  --email jordankjfb@gmail.com \
  --domains desfollow.com.br,www.desfollow.com.br,api.desfollow.com.br \
  --force-renewal

# Criar configuração com SSL para todos
echo "📋 3. Configurando nginx com SSL completo..."
sudo tee /etc/nginx/sites-available/desfollow-ssl > /dev/null << 'EOF'
# FRONTEND - HTTP redirect to HTTPS
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# FRONTEND - HTTPS
server {
    listen 443 ssl;
    server_name desfollow.com.br www.desfollow.com.br;
    
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    
    root /var/www/desfollow;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}

# BACKEND API - HTTP redirect to HTTPS
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# BACKEND API - HTTPS
server {
    listen 443 ssl;
    server_name api.desfollow.com.br;
    
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    
    add_header Access-Control-Allow-Origin "*";
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS, PUT, DELETE";
    add_header Access-Control-Allow-Headers "Origin, Content-Type, Accept, Authorization";
    
    location / {
        if ($request_method = OPTIONS) {
            return 204;
        }
        
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Remover configuração antiga e ativar nova
echo "📋 4. Ativando nova configuração..."
sudo rm -f /etc/nginx/sites-enabled/desfollow-clean
sudo ln -s /etc/nginx/sites-available/desfollow-ssl /etc/nginx/sites-enabled/

# Testar configuração
echo "📋 5. Testando configuração..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração OK!"
    
    # Iniciar nginx
    echo "📋 6. Iniciando nginx..."
    sudo systemctl start nginx
    
    sleep 5
    
    # Testar HTTPS
    echo "📋 7. Testando HTTPS..."
    echo "• Frontend HTTPS:"
    curl -s -o /dev/null -w "Status: %{http_code}\n" https://desfollow.com.br
    echo "• API HTTPS:"
    curl -s -o /dev/null -w "Status: %{http_code}\n" https://api.desfollow.com.br/health
    
    echo ""
    echo "✅ SSL COMPLETO INSTALADO!"
    echo "🌐 Frontend: https://desfollow.com.br"
    echo "🌐 Frontend WWW: https://www.desfollow.com.br"  
    echo "🔧 API: https://api.desfollow.com.br"
    echo ""
    echo "🎉 Agora tudo funcionará com HTTPS!"
    
else
    echo "❌ Erro na configuração!"
    sudo nginx -t
fi