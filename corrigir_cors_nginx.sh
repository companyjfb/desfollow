#!/bin/bash

echo "🔧 Corrigindo headers CORS duplicados..."
echo "========================================"

# Fazer backup da configuração atual
echo "📋 Fazendo backup da configuração atual..."
cp /etc/nginx/sites-enabled/desfollow /etc/nginx/sites-enabled/desfollow.backup.$(date +%Y%m%d_%H%M%S)

# Criar nova configuração sem headers CORS duplicados
echo "🔧 Criando nova configuração Nginx..."

cat > /etc/nginx/sites-enabled/desfollow << 'EOF'
# Configuração para o frontend (desfollow.com.br)
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

# Configuração para o backend (api.desfollow.com.br)
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

# Configuração HTTPS para o frontend
server {
    listen 443 ssl http2;
    server_name desfollow.com.br www.desfollow.com.br;

    # SSL Configuration (já configurado pelo certbot)
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;

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

# Configuração HTTPS para o backend
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;

    # SSL Configuration (já configurado pelo certbot)
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
    
    echo "✅ CORS corrigido!"
    echo "🌐 Teste: https://desfollow.com.br"
else
    echo "❌ Erro na configuração do Nginx"
    echo "Restaurando backup..."
    cp /etc/nginx/sites-enabled/desfollow.backup.* /etc/nginx/sites-enabled/desfollow
    nginx -t
    systemctl reload nginx
    exit 1
fi

echo ""
echo "🔍 Testando CORS..."
curl -H "Origin: https://desfollow.com.br" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     -I https://api.desfollow.com.br/api/scan

echo ""
echo "✅ Correção CORS concluída!" 