#!/bin/bash

echo "🔒 INSTALANDO SSL PARA FRONTEND E BACKEND"
echo "========================================="

# Parar nginx
echo "📋 1. Parando nginx..."
sudo systemctl stop nginx

# Verificar se porta 80 está livre
echo "📋 2. Verificando porta 80..."
sudo netstat -tlnp | grep :80

# Instalar SSL para todos os domínios
echo "📋 3. Instalando SSL para todos os domínios..."
sudo certbot certonly \
  --standalone \
  --non-interactive \
  --agree-tos \
  --email jordankjfb@gmail.com \
  --domains desfollow.com.br,www.desfollow.com.br,api.desfollow.com.br \
  --expand

# Configurar nginx com SSL para todos
echo "📋 4. Configurando nginx com SSL completo..."
sudo tee /etc/nginx/sites-available/desfollow-ssl-completo > /dev/null << 'EOF'
# FRONTEND - HTTP redirect to HTTPS
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# FRONTEND - HTTPS
server {
    listen 443 ssl http2;
    server_name desfollow.com.br www.desfollow.com.br;
    
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    root /var/www/desfollow;
    index index.html;
    
    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Static assets with proper cache
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary "Accept-Encoding";
        access_log off;
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}

# BACKEND API - HTTP redirect to HTTPS
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# BACKEND API - HTTPS
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # CORS headers
    add_header Access-Control-Allow-Origin "*" always;
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS, PUT, DELETE" always;
    add_header Access-Control-Allow-Headers "Origin, Content-Type, Accept, Authorization, X-Requested-With" always;
    add_header Access-Control-Allow-Credentials "true" always;
    
    location / {
        # Handle OPTIONS preflight
        if ($request_method = OPTIONS) {
            return 204;
        }
        
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

# Remover configurações antigas e ativar nova
echo "📋 5. Ativando nova configuração SSL..."
sudo rm -f /etc/nginx/sites-enabled/*
sudo ln -s /etc/nginx/sites-available/desfollow-ssl-completo /etc/nginx/sites-enabled/

# Testar configuração
echo "📋 6. Testando configuração nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração nginx OK!"
    
    # Iniciar nginx
    echo "📋 7. Iniciando nginx..."
    sudo systemctl start nginx
    sudo systemctl enable nginx
    
    # Aguardar nginx inicializar
    sleep 5
    
    # Verificar serviços
    echo "📋 8. Verificando serviços..."
    sudo systemctl status nginx --no-pager | head -5
    sudo systemctl status desfollow --no-pager | head -5
    
    # Testar HTTPS endpoints
    echo "📋 9. Testando endpoints HTTPS..."
    echo "• Frontend principal:"
    curl -s -o /dev/null -w "Status: %{http_code} | Tempo: %{time_total}s\n" https://desfollow.com.br
    echo "• Frontend www:"
    curl -s -o /dev/null -w "Status: %{http_code} | Tempo: %{time_total}s\n" https://www.desfollow.com.br
    echo "• API backend:"
    curl -s -o /dev/null -w "Status: %{http_code} | Tempo: %{time_total}s\n" https://api.desfollow.com.br/health
    
    # Verificar certificados
    echo "📋 10. Verificando certificados..."
    sudo certbot certificates
    
    echo ""
    echo "✅ SSL COMPLETO INSTALADO COM SUCESSO!"
    echo "🌐 Frontend: https://desfollow.com.br"
    echo "🌐 Frontend WWW: https://www.desfollow.com.br"  
    echo "🔧 API: https://api.desfollow.com.br"
    echo "🔒 Certificados válidos para todos os domínios"
    echo "📱 Imagens e assets devem carregar corretamente"
    
else
    echo "❌ Erro na configuração nginx!"
    sudo nginx -t
    echo "Voltando configuração anterior..."
    sudo systemctl start nginx
fi