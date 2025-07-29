#!/bin/bash

echo "🔧 Corrigindo Nginx para servir frontend..."
echo "==========================================="

echo "📋 Configuração atual do Nginx:"
cat /etc/nginx/sites-available/default

echo ""
echo "🔧 Criando nova configuração..."

# Fazer backup da configuração atual
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup

# Criar nova configuração
cat > /etc/nginx/sites-available/default << 'EOF'
# Configuração para desfollow.com.br e www.desfollow.com.br (Frontend)
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    root /var/www/html;
    index index.html index.htm;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Configurações de cache para arquivos estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}

# Configuração para api.desfollow.com.br (Backend)
server {
    listen 80;
    server_name api.desfollow.com.br;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Configuração HTTPS para api.desfollow.com.br
server {
    listen 443 ssl;
    server_name api.desfollow.com.br;
    
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo "✅ Nova configuração criada!"

echo ""
echo "🔧 Testando configuração do Nginx:"
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração válida!"
    
    echo ""
    echo "🔧 Copiando frontend para /var/www/html..."
    
    # Criar diretório se não existir
    mkdir -p /var/www/html
    
    # Copiar arquivos do frontend
    cp -r /root/desfollow/dist/* /var/www/html/ 2>/dev/null || {
        echo "❌ Diretório dist não encontrado, copiando arquivos do build..."
        cp -r /root/desfollow/build/* /var/www/html/ 2>/dev/null || {
            echo "❌ Diretório build não encontrado, criando index.html básico..."
            cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Desfollow - Em Manutenção</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .container { max-width: 600px; margin: 0 auto; }
        .status { color: #666; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Desfollow</h1>
        <p class="status">Frontend em configuração...</p>
        <p>API está funcionando em: <a href="https://api.desfollow.com.br">api.desfollow.com.br</a></p>
    </div>
</body>
</html>
HTML
        }
    }
    
    echo "✅ Frontend copiado!"
    
    echo ""
    echo "🔧 Definindo permissões..."
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    
    echo ""
    echo "🔧 Recarregando Nginx..."
    systemctl reload nginx
    
    echo ""
    echo "📊 Status do Nginx:"
    systemctl status nginx --no-pager
    
    echo ""
    echo "🔍 Testando frontend:"
    curl -I http://localhost/
    
    echo ""
    echo "🔍 Testando API:"
    curl -I http://localhost:8000/api/health
    
else
    echo "❌ Configuração inválida! Restaurando backup..."
    cp /etc/nginx/sites-available/default.backup /etc/nginx/sites-available/default
fi

echo ""
echo "✅ Correção do Nginx concluída!" 