#!/bin/bash

echo "🔒 INSTALAÇÃO SSL PARA API"
echo "=========================="
echo "Instalando SSL apenas para api.desfollow.com.br"
echo ""

# Verificar se o certbot está instalado
if ! command -v certbot &> /dev/null; then
    echo "📋 Instalando Certbot..."
    apt update
    apt install -y certbot python3-certbot-nginx
    echo "✅ Certbot instalado"
else
    echo "✅ Certbot já está instalado"
fi

echo ""
echo "📋 Verificando configuração atual do nginx..."

# Backup da configuração atual
BACKUP_FILE="/etc/nginx/sites-available/desfollow.backup.ssl-api.$(date +%Y%m%d_%H%M%S)"
echo "💾 Backup: $BACKUP_FILE"
cp /etc/nginx/sites-available/desfollow $BACKUP_FILE
echo "✅ Backup criado"

echo ""
echo "📋 Criando configuração nginx com SSL apenas para API..."

# Criar configuração nginx com SSL apenas para API
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Configuração para desfollow.com.br
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Redirecionar para HTTPS
    return 301 https://www.desfollow.com.br$request_uri;
}

# Configuração para www.desfollow.com.br (FRONTEND) - SEM SSL
server {
    listen 80;
    server_name www.desfollow.com.br;
    
    # Configuração do frontend
    root /var/www/html;
    index index.html index.htm;
    
    # Configurações de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'; img-src 'self' data: blob: https://*.cdninstagram.com https://*.instagram.com https://*.fbcdn.net;" always;
    
    # Configuração para SPA (Single Page Application)
    location / {
        try_files $uri $uri/ /index.html;
        
        # Headers para CORS
        add_header Access-Control-Allow-Origin "https://www.desfollow.com.br" always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization" always;
        add_header Access-Control-Expose-Headers "Content-Length,Content-Range" always;
    }
    
    # Configuração para arquivos estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }
    
    # Configuração para imagens do Instagram (permitir CORS)
    location ~* \.(png|jpg|jpeg|gif|webp)$ {
        # Headers CORS específicos para imagens
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range" always;
        add_header Access-Control-Expose-Headers "Content-Length,Content-Range" always;
        
        # Cache para imagens
        expires 1d;
        add_header Cache-Control "public, max-age=86400";
        
        try_files $uri =404;
    }
    
    # Configuração para API (proxy para api.desfollow.com.br)
    location /api/ {
        proxy_pass https://api.desfollow.com.br;
        proxy_set_header Host api.desfollow.com.br;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Headers para CORS da API
        add_header Access-Control-Allow-Origin "https://www.desfollow.com.br" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization" always;
        add_header Access-Control-Expose-Headers "Content-Length,Content-Range" always;
        
        # Tratamento especial para OPTIONS (preflight)
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://www.desfollow.com.br" always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization" always;
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type "text/plain; charset=utf-8";
            add_header Content-Length 0;
            return 204;
        }
    }
    
    # Configuração para imagens do Instagram (proxy)
    location /proxy-image {
        proxy_pass https://api.desfollow.com.br;
        proxy_set_header Host api.desfollow.com.br;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Configuração para api.desfollow.com.br (BACKEND) - COM SSL
server {
    listen 80;
    server_name api.desfollow.com.br;
    
    # Configuração do backend
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Headers para CORS da API
        add_header Access-Control-Allow-Origin "https://www.desfollow.com.br" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization" always;
        add_header Access-Control-Expose-Headers "Content-Length,Content-Range" always;
        
        # Tratamento especial para OPTIONS (preflight)
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://www.desfollow.com.br" always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization" always;
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type "text/plain; charset=utf-8";
            add_header Content-Length 0;
            return 204;
        }
    }
}
EOF

echo "✅ Configuração nginx criada"

echo ""
echo "📋 Testando configuração..."
nginx -t
if [ $? -eq 0 ]; then
    echo "✅ Configuração nginx válida!"
else
    echo "❌ Erro na configuração nginx"
    exit 1
fi

echo ""
echo "📋 Recarregando nginx..."
systemctl reload nginx
if [ $? -eq 0 ]; then
    echo "✅ Nginx recarregado com sucesso!"
else
    echo "❌ Erro ao recarregar nginx"
    exit 1
fi

echo ""
echo "📋 Instalando SSL para api.desfollow.com.br..."
certbot --nginx -d api.desfollow.com.br --non-interactive --agree-tos --email admin@desfollow.com.br

if [ $? -eq 0 ]; then
    echo "✅ SSL instalado com sucesso para api.desfollow.com.br!"
else
    echo "❌ Erro ao instalar SSL"
    echo "📋 Verificando se o domínio está apontando para este servidor..."
    echo "📋 Certifique-se de que api.desfollow.com.br está apontando para este IP:"
    curl -s ifconfig.me
    exit 1
fi

echo ""
echo "📋 Verificando se backend está rodando..."
systemctl status desfollow-backend
if [ $? -eq 0 ]; then
    echo "✅ Backend está rodando"
else
    echo "📋 Reiniciando backend..."
    systemctl restart desfollow-backend
    systemctl status desfollow-backend
fi

echo ""
echo "📋 Testando SSL da API..."
echo "🧪 Testando https://api.desfollow.com.br..."
curl -s -I https://api.desfollow.com.br | head -5

echo ""
echo "✅ SSL INSTALADO COM SUCESSO!"
echo ""
echo "🔗 CONFIGURAÇÃO FINAL:"
echo "   Frontend: http://www.desfollow.com.br (HTTP - SSL via Hostinger)"
echo "   API:      https://api.desfollow.com.br (HTTPS - SSL próprio)"
echo ""
echo "🔄 CORS CONFIGURADO:"
echo "   ✅ Aceita apenas: https://www.desfollow.com.br"
echo "   ✅ API: https://api.desfollow.com.br"
echo ""
echo "📜 Backup salvo em: $BACKUP_FILE"
echo ""
echo "🚀 SSL FUNCIONANDO!" 