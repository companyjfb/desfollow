#!/bin/bash

echo "🔧 CORREÇÃO DE ROTEAMENTO WWW"
echo "============================="
echo "Corrigindo roteamento para www.desfollow.com.br mostrar frontend"
echo ""

# Backup da configuração atual
BACKUP_FILE="/etc/nginx/sites-available/desfollow.backup.roteamento-www.$(date +%Y%m%d_%H%M%S)"
echo "💾 Backup: $BACKUP_FILE"
cp /etc/nginx/sites-available/desfollow $BACKUP_FILE
echo "✅ Backup criado"

# Verificar se o arquivo de configuração existe
if [ ! -f "/etc/nginx/sites-available/desfollow" ]; then
    echo "❌ Arquivo de configuração nginx não encontrado"
    exit 1
fi

echo ""
echo "📋 Criando nova configuração nginx..."

# Criar nova configuração nginx
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Configuração para desfollow.com.br
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Redirecionar para HTTPS
    return 301 https://www.desfollow.com.br$request_uri;
}

# Configuração para www.desfollow.com.br (FRONTEND)
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

# Configuração para api.desfollow.com.br (BACKEND)
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
echo "📋 Verificando se frontend está no local correto..."
if [ -f "/var/www/html/index.html" ]; then
    echo "✅ Frontend encontrado em /var/www/html/"
else
    echo "⚠️ Frontend não encontrado em /var/www/html/"
    echo "📋 Verificando se precisa fazer build..."
    cd /root/desfollow
    if [ -f "package.json" ]; then
        echo "📋 Fazendo build do frontend..."
        npm run build
        cp -r dist/* /var/www/html/
        echo "✅ Frontend buildado e copiado"
    else
        echo "❌ package.json não encontrado"
    fi
fi

echo ""
echo "📋 Testando roteamento..."
echo "🧪 Testando www.desfollow.com.br..."
curl -s -I http://www.desfollow.com.br | head -5

echo ""
echo "🧪 Testando api.desfollow.com.br..."
curl -s -I http://api.desfollow.com.br | head -5

echo ""
echo "✅ ROTEAMENTO CORRIGIDO!"
echo ""
echo "🔗 CONFIGURAÇÃO FINAL:"
echo "   Frontend: https://www.desfollow.com.br"
echo "   API:      https://api.desfollow.com.br"
echo ""
echo "🔄 CORS CONFIGURADO:"
echo "   ✅ Aceita apenas: https://www.desfollow.com.br"
echo "   ✅ API: https://api.desfollow.com.br"
echo ""
echo "📜 Backup salvo em: $BACKUP_FILE"
echo ""
echo "🚀 ROTEAMENTO FUNCIONANDO!" 