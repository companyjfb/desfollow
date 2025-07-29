#!/bin/bash

echo "🔧 Correção Rápida - Nginx Sintaxe..."
echo "===================================="
echo ""

# Criar configuração corrigida sem add_header dentro de if
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Configuração Corrigida - Frontend + API + CORS

# Frontend HTTP (desfollow.com.br e www.desfollow.com.br)
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;

    # Headers de segurança e CORS
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Access-Control-Allow-Origin "*" always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization" always;

    # Configuração do frontend React
    root /var/www/desfollow;
    index index.html;

    # SPA - Single Page Application
    location / {
        try_files $uri $uri/ /index.html;
        
        # Cache para arquivos estáticos
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # API Proxy - CORS simplificado
    location /api/ {
        # Preflight requests
        if ($request_method = 'OPTIONS') {
            return 204;
        }

        # Proxy para API local
        proxy_pass http://127.0.0.1:8000/api/;
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
    access_log /var/log/nginx/desfollow_frontend_access.log;
    error_log /var/log/nginx/desfollow_frontend_error.log;
}

# API HTTP - Redirecionar para HTTPS
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# API HTTPS - Acesso direto à API
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;

    # SSL (se certificado existir)
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Headers de segurança e CORS
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header Access-Control-Allow-Origin "*" always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization" always;

    # Preflight requests
    if ($request_method = 'OPTIONS') {
        return 204;
    }

    # Proxy para API
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
    access_log /var/log/nginx/desfollow_api_ssl_access.log;
    error_log /var/log/nginx/desfollow_api_ssl_error.log;
}
EOF

echo "✅ Configuração corrigida criada!"
echo ""

# Testar sintaxe
echo "🔍 Testando sintaxe do Nginx..."
if nginx -t; then
    echo "✅ Sintaxe OK!"
    
    # Recarregar nginx
    echo "🔄 Recarregando Nginx..."
    systemctl reload nginx
    echo "✅ Nginx recarregado!"
    
    echo ""
    echo "🔍 Testando rapidamente..."
    echo "Frontend:"
    curl -s http://desfollow.com.br/ | head -1
    echo ""
    echo "API:"
    curl -s http://desfollow.com.br/api/health 2>/dev/null | head -1 || echo "API ainda inicializando..."
    
else
    echo "❌ Ainda há erros de sintaxe"
    echo "Verifique o erro acima"
fi

echo ""
echo "✅ Correção rápida concluída!" 