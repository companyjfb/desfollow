#!/bin/bash

echo "🔧 Corrigindo configuração final do Nginx..."
echo "==========================================="

# Fazer backup da configuração atual
echo "📋 Fazendo backup da configuração atual..."
cp /etc/nginx/sites-enabled/desfollow /etc/nginx/sites-enabled/desfollow.backup.$(date +%Y%m%d_%H%M%S)

# Remover configurações duplicadas
echo "🧹 Removendo configurações duplicadas..."
rm -f /etc/nginx/sites-enabled/desfollow.backup.*

# Criar configuração limpa apenas para api.desfollow.com.br
echo "🔧 Criando configuração limpa..."

cat > /etc/nginx/sites-enabled/desfollow << 'EOF'
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
    
    echo "✅ Nginx corrigido!"
    echo "🔌 API: https://api.desfollow.com.br"
else
    echo "❌ Erro na configuração do Nginx"
    echo "Restaurando backup..."
    cp /etc/nginx/sites-enabled/desfollow.backup.* /etc/nginx/sites-enabled/desfollow
    nginx -t
    systemctl reload nginx
    exit 1
fi

echo ""
echo "🔍 Testando API..."
curl -I https://api.desfollow.com.br/health

echo ""
echo "✅ Configuração final concluída!" 