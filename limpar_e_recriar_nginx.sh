#!/bin/bash

echo "🧹 LIMPANDO E RECRIANDO NGINX DO ZERO"
echo "====================================="

# Parar nginx
echo "📋 1. Parando nginx..."
sudo systemctl stop nginx

# Remover TODAS as configurações conflitantes
echo "📋 2. Removendo configurações conflitantes..."
sudo rm -f /etc/nginx/sites-enabled/*
sudo rm -f /etc/nginx/sites-available/default
sudo rm -f /etc/nginx/sites-available/desfollow*

# Verificar se frontend está copiado
echo "📋 3. Verificando frontend..."
if [ ! -f /var/www/desfollow/index.html ]; then
    echo "Copiando frontend..."
    sudo mkdir -p /var/www/desfollow
    sudo cp -r dist/* /var/www/desfollow/
    sudo chown -R www-data:www-data /var/www/desfollow
    sudo chmod -R 755 /var/www/desfollow
fi

# Criar configuração ÚNICA e limpa
echo "📋 4. Criando configuração única..."
sudo tee /etc/nginx/sites-available/desfollow-clean > /dev/null << 'EOF'
# FRONTEND PRINCIPAL
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    root /var/www/desfollow;
    index index.html;
    
    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Static assets cache
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}

# BACKEND API
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name api.desfollow.com.br;
    
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    
    # CORS
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

# Ativar APENAS esta configuração
echo "📋 5. Ativando configuração..."
sudo ln -s /etc/nginx/sites-available/desfollow-clean /etc/nginx/sites-enabled/

# Verificar que não há outras configurações
echo "📋 6. Verificando configurações ativas..."
sudo ls -la /etc/nginx/sites-enabled/

# Testar configuração
echo "📋 7. Testando configuração..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração limpa OK!"
    
    # Iniciar nginx
    echo "📋 8. Iniciando nginx..."
    sudo systemctl start nginx
    
    sleep 3
    
    # Verificar se está rodando
    echo "📋 9. Verificando status..."
    sudo systemctl status nginx --no-pager | head -5
    
    # Testar endpoints
    echo "📋 10. Testando endpoints finais..."
    echo "• Frontend principal:"
    curl -s -o /dev/null -w "Status: %{http_code}\n" http://desfollow.com.br
    echo "• Frontend www:"
    curl -s -o /dev/null -w "Status: %{http_code}\n" http://www.desfollow.com.br
    echo "• API:"
    curl -s -o /dev/null -w "Status: %{http_code}\n" https://api.desfollow.com.br/health
    
    echo ""
    echo "✅ NGINX LIMPO E RECONFIGURADO!"
    echo "🌐 Frontend: http://desfollow.com.br"
    echo "🌐 Frontend WWW: http://www.desfollow.com.br"  
    echo "🔧 API: https://api.desfollow.com.br"
    echo ""
    echo "⚠️  Se ainda mostrar API, aguarde 1-2 minutos para propagação DNS"
    
else
    echo "❌ Erro na configuração!"
    sudo nginx -t
fi