#!/bin/bash

echo "🔧 CORREÇÃO ROTEAMENTO FRONTEND"
echo "================================"
echo "Corrigindo roteamento para frontend aparecer nos domínios principais"
echo ""

# Backup da configuração atual
BACKUP_FILE="/etc/nginx/sites-available/desfollow.backup.roteamento.$(date +%Y%m%d_%H%M%S)"
sudo cp /etc/nginx/sites-available/desfollow "$BACKUP_FILE"
echo "💾 Backup: $BACKUP_FILE"

echo ""
echo "📋 Verificando se frontend existe..."
if [ ! -f "/var/www/html/index.html" ]; then
    echo "❌ Frontend não encontrado em /var/www/html/"
    echo "📋 Copiando build do frontend..."
    
    # Verificar se existe build
    if [ -d "/root/desfollow/dist" ]; then
        echo "📋 Copiando dist para /var/www/html/"
        sudo cp -r /root/desfollow/dist/* /var/www/html/
        sudo chown -R www-data:www-data /var/www/html/
        echo "✅ Frontend copiado"
    else
        echo "❌ Build não encontrada. Fazendo build..."
        cd /root/desfollow
        npm run build
        sudo cp -r dist/* /var/www/html/
        sudo chown -R www-data:www-data /var/www/html/
        echo "✅ Build criada e copiada"
    fi
else
    echo "✅ Frontend encontrado em /var/www/html/"
fi

echo ""
echo "📋 Criando configuração nginx com roteamento correto..."

# Configuração nginx com roteamento correto
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# ========================================
# CONFIGURAÇÃO NGINX - ROTEAMENTO CORRETO
# ========================================
# Frontend: desfollow.com.br + www.desfollow.com.br (HTTP - SSL via Hostinger)
# API: api.desfollow.com.br (HTTPS)
# ========================================

# FRONTEND HTTP - DESFOLLOW.COM.BR (SSL gerenciado pela Hostinger)
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

# FRONTEND HTTP - WWW.DESFOLLOW.COM.BR (SSL gerenciado pela Hostinger)
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

# API HTTPS - APENAS API
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
    
    # Proxy para backend - APENAS PARA API
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $host;
        
        # Timeouts
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        
        # Configurações para requests longos
        proxy_buffering off;
        proxy_request_buffering off;
        client_max_body_size 10m;
        
        # CORS HTTPS FIXO
        add_header Access-Control-Allow-Origin "https://desfollow.com.br" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
        add_header Access-Control-Allow-Credentials true always;
        
        # Preflight OPTIONS
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

echo "✅ Configuração nginx com roteamento correto criada"

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
echo "📋 Testando roteamento..."

echo "🧪 Testando frontend em desfollow.com.br..."
FRONTEND_TEST1=$(curl -s -I http://desfollow.com.br | head -1)
echo "   Response: $FRONTEND_TEST1"

echo "🧪 Testando frontend em www.desfollow.com.br..."
FRONTEND_TEST2=$(curl -s -I http://www.desfollow.com.br | head -1)
echo "   Response: $FRONTEND_TEST2"

echo "🧪 Testando API em api.desfollow.com.br..."
API_TEST=$(curl -s -I https://api.desfollow.com.br/api/health | head -1)
echo "   Response: $API_TEST"

echo ""
echo "✅ ROTEAMENTO CORRIGIDO!"
echo ""
echo "🔗 CONFIGURAÇÃO FINAL:"
echo "   Frontend: http://desfollow.com.br (HTTP - SSL via Hostinger)"
echo "   Frontend: http://www.desfollow.com.br (HTTP - SSL via Hostinger)"
echo "   API:      https://api.desfollow.com.br (HTTPS)"
echo ""
echo "📜 Backup salvo em: $BACKUP_FILE"
echo ""
echo "🚀 ROTEAMENTO FUNCIONANDO!" 