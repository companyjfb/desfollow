#!/bin/bash

echo "🌐 CONFIGURANDO FRONTEND E BACKEND SEPARADOS"
echo "============================================"

# Atualizar repositório
echo "📋 1. Atualizando repositório..."
git pull origin main

# Buildar frontend
echo "📋 2. Buildando frontend..."
npm install
npm run build

# Criar diretório para o frontend
echo "📋 3. Preparando diretório do frontend..."
sudo mkdir -p /var/www/desfollow
sudo rm -rf /var/www/desfollow/*
sudo cp -r dist/* /var/www/desfollow/
sudo chown -R www-data:www-data /var/www/desfollow
sudo chmod -R 755 /var/www/desfollow

# Configurar Nginx com frontend e backend separados
echo "📋 4. Configurando Nginx..."
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# Frontend - desfollow.com.br e www.desfollow.com.br
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Servir frontend diretamente
    root /var/www/desfollow;
    index index.html;
    
    # Try files para SPA (Single Page Application)
    location / {
        try_files $uri $uri/ /index.html;
        
        # Headers de segurança
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        
        # Headers de cache para assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Rota específica para API (redirecionar para subdomínio)
    location /api {
        return 301 https://api.desfollow.com.br$request_uri;
    }
    
    location /health {
        return 301 https://api.desfollow.com.br$request_uri;
    }
    
    location /docs {
        return 301 https://api.desfollow.com.br$request_uri;
    }
}

# Backend API - api.desfollow.com.br
server {
    listen 80;
    server_name api.desfollow.com.br;
    
    # Redirecionar HTTP para HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    
    # Configurações SSL seguras
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    
    # Handle preflight requests
    location / {
        # CORS headers para o frontend
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' 'http://desfollow.com.br';
            add_header 'Access-Control-Allow-Origin' 'http://www.desfollow.com.br';
            add_header 'Access-Control-Allow-Origin' 'https://desfollow.com.br';
            add_header 'Access-Control-Allow-Origin' 'https://www.desfollow.com.br';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE';
            add_header 'Access-Control-Allow-Headers' 'Origin, Content-Type, Accept, Authorization, X-Requested-With';
            add_header 'Access-Control-Allow-Credentials' 'true';
            add_header 'Content-Length' 0;
            add_header 'Content-Type' 'text/plain';
            return 204;
        }
        
        # CORS headers para todas as respostas
        add_header 'Access-Control-Allow-Origin' 'http://desfollow.com.br';
        add_header 'Access-Control-Allow-Origin' 'http://www.desfollow.com.br';
        add_header 'Access-Control-Allow-Origin' 'https://desfollow.com.br';
        add_header 'Access-Control-Allow-Origin' 'https://www.desfollow.com.br';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE';
        add_header 'Access-Control-Allow-Headers' 'Origin, Content-Type, Accept, Authorization, X-Requested-With';
        add_header 'Access-Control-Allow-Credentials' 'true';
        
        # Proxy para o backend Python
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $server_name;
        
        # Timeouts
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        proxy_buffering off;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

# Testar configuração
echo "📋 5. Testando configuração do Nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração Nginx OK!"
    
    # Reiniciar Nginx
    echo "📋 6. Reiniciando Nginx..."
    sudo systemctl reload nginx
    
    # Verificar serviços
    echo "📋 7. Verificando serviços..."
    sudo systemctl status nginx --no-pager | head -10
    sudo systemctl status desfollow --no-pager | head -10
    
    # Testar endpoints
    echo "📋 8. Testando endpoints..."
    echo "• Frontend (desfollow.com.br):"
    curl -I http://desfollow.com.br 2>/dev/null | head -3
    echo "• Frontend (www.desfollow.com.br):"
    curl -I http://www.desfollow.com.br 2>/dev/null | head -3
    echo "• Backend API (HTTPS):"
    curl -I https://api.desfollow.com.br/health 2>/dev/null | head -3
    
    echo ""
    echo "✅ CONFIGURAÇÃO CONCLUÍDA!"
    echo "🌐 Frontend: http://desfollow.com.br e http://www.desfollow.com.br"
    echo "🔧 API Backend: https://api.desfollow.com.br"
    echo "📁 Arquivos frontend em: /var/www/desfollow"
    
else
    echo "❌ Erro na configuração do Nginx!"
    sudo nginx -t
fi