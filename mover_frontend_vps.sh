#!/bin/bash

echo "🚀 Movendo frontend para o VPS..."
echo "=================================="

# Verificar se o diretório dist existe
if [ ! -d "dist" ]; then
    echo "❌ Diretório dist não encontrado!"
    echo "Execute 'npm run build' primeiro"
    exit 1
fi

# Criar diretório para o frontend
echo "📁 Criando diretório para o frontend..."
mkdir -p /var/www/desfollow

# Copiar arquivos do frontend
echo "📋 Copiando arquivos do frontend..."
cp -r dist/* /var/www/desfollow/

# Definir permissões
echo "🔐 Definindo permissões..."
chown -R www-data:www-data /var/www/desfollow
chmod -R 755 /var/www/desfollow

# Atualizar configuração do Nginx para servir frontend
echo "🔧 Atualizando configuração do Nginx..."

cat > /etc/nginx/sites-enabled/desfollow << 'EOF'
# Configuração HTTP para desfollow.com.br (frontend)
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;

    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' https://api.desfollow.com.br http: https: data: blob: 'unsafe-inline'" always;

    # Configuração para servir arquivos estáticos do frontend
    root /var/www/desfollow;
    index index.html;

    # Configuração para SPA (Single Page Application)
    location / {
        try_files $uri $uri/ /index.html;
        
        # Headers para cache de arquivos estáticos
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Logs
    access_log /var/log/nginx/desfollow_frontend_access.log;
    error_log /var/log/nginx/desfollow_frontend_error.log;
}

# Configuração HTTP para api.desfollow.com.br
server {
    listen 80;
    server_name api.desfollow.com.br;

    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Configuração da API
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Logs
    access_log /var/log/nginx/desfollow_api_access.log;
    error_log /var/log/nginx/desfollow_api_error.log;
}

# Configuração HTTPS para desfollow.com.br (frontend)
server {
    listen 443 ssl http2;
    server_name desfollow.com.br www.desfollow.com.br;

    # SSL Configuration (será configurado pelo certbot)
    # ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;

    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' https://api.desfollow.com.br http: https: data: blob: 'unsafe-inline'" always;

    # Configuração para servir arquivos estáticos do frontend
    root /var/www/desfollow;
    index index.html;

    # Configuração para SPA (Single Page Application)
    location / {
        try_files $uri $uri/ /index.html;
        
        # Headers para cache de arquivos estáticos
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Logs
    access_log /var/log/nginx/desfollow_frontend_access.log;
    error_log /var/log/nginx/desfollow_frontend_error.log;
}

# Configuração HTTPS para api.desfollow.com.br
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;

    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Configuração da API
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Logs
    access_log /var/log/nginx/desfollow_api_access.log;
    error_log /var/log/nginx/desfollow_api_error.log;
}
EOF

# Testar configuração
echo "🔍 Testando configuração do Nginx..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração válida!"
    
    # Recarregar Nginx
    echo "🔄 Recarregando Nginx..."
    systemctl reload nginx
    
    echo "✅ Frontend movido com sucesso!"
    echo "🌐 Frontend: http://desfollow.com.br"
    echo "🔌 API: https://api.desfollow.com.br"
else
    echo "❌ Erro na configuração do Nginx"
    exit 1
fi

echo ""
echo "🔍 Testando frontend..."
curl -I http://desfollow.com.br

echo ""
echo "✅ Frontend movido para o VPS!" 