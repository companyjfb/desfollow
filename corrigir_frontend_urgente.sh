#!/bin/bash

echo "🚨 CORREÇÃO URGENTE - FRONTEND NOS DOMÍNIOS PRINCIPAIS"
echo "======================================================="

# Atualizar código
echo "📋 1. Atualizando código..."
git pull origin main

# Buildar frontend atualizado
echo "📋 2. Buildando frontend..."
npm install
npm run build

# Limpar e copiar frontend
echo "📋 3. Copiando frontend para servidor web..."
sudo rm -rf /var/www/desfollow/*
sudo mkdir -p /var/www/desfollow
sudo cp -r dist/* /var/www/desfollow/
sudo chown -R www-data:www-data /var/www/desfollow
sudo chmod -R 755 /var/www/desfollow

# Verificar se arquivos foram copiados
echo "📋 4. Verificando arquivos frontend..."
sudo ls -la /var/www/desfollow/

# Parar nginx temporariamente
echo "📋 5. Parando nginx..."
sudo systemctl stop nginx

# Criar configuração limpa e simples
echo "📋 6. Criando configuração Nginx limpa..."
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# FRONTEND - Domínios principais
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name desfollow.com.br www.desfollow.com.br _;
    
    root /var/www/desfollow;
    index index.html index.htm;
    
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
    
    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
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
    
    # CORS para todos os métodos
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
    add_header 'Access-Control-Allow-Headers' 'Origin, Content-Type, Accept, Authorization, X-Requested-With' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    
    # Handle OPTIONS preflight
    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE';
        add_header 'Access-Control-Allow-Headers' 'Origin, Content-Type, Accept, Authorization, X-Requested-With';
        add_header 'Access-Control-Max-Age' 1728000;
        add_header 'Content-Type' 'text/plain charset=UTF-8';
        add_header 'Content-Length' 0;
        return 204;
    }
    
    # Proxy para backend
    location / {
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

# Remover configuração default que pode conflitar
sudo rm -f /etc/nginx/sites-enabled/default

# Verificar se link simbólico existe
if [ ! -L /etc/nginx/sites-enabled/desfollow ]; then
    sudo ln -s /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/
fi

# Testar configuração
echo "📋 7. Testando configuração..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração OK! Iniciando nginx..."
    sudo systemctl start nginx
    sudo systemctl enable nginx
    
    # Aguardar nginx inicializar
    sleep 3
    
    echo "📋 8. Verificando serviços..."
    sudo systemctl status nginx --no-pager | head -5
    sudo systemctl status desfollow --no-pager | head -5
    
    echo "📋 9. Testando endpoints..."
    echo "• Frontend principal:"
    curl -I http://desfollow.com.br 2>/dev/null | head -3
    echo "• Frontend www:"
    curl -I http://www.desfollow.com.br 2>/dev/null | head -3
    echo "• API backend:"
    curl -I https://api.desfollow.com.br/health 2>/dev/null | head -3
    
    echo ""
    echo "✅ CORREÇÃO APLICADA!"
    echo "🌐 Frontend: http://desfollow.com.br"
    echo "🌐 Frontend WWW: http://www.desfollow.com.br"
    echo "🔧 API: https://api.desfollow.com.br"
    
else
    echo "❌ Erro na configuração!"
    sudo nginx -t
fi