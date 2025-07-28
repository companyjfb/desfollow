#!/bin/bash

echo "🔧 Corrigindo configuração do Nginx..."

# Backup da configuração atual
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Adicionar rate limiting zones no http block
sed -i '/http {/a\    # Rate limiting zones\n    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;\n    limit_req_zone $binary_remote_addr zone=login:10m rate=5r/s;' /etc/nginx/nginx.conf

# Criar configuração correta do site
cat > /etc/nginx/sites-available/desfollow << 'EOF'
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
        limit_req zone=api burst=20 nodelay;
        
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

    # Configuração específica para autenticação
    location /api/auth/ {
        limit_req zone=login burst=10 nodelay;
        
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Configuração para health check
    location /health {
        access_log off;
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
    }

    # Logs
    access_log /var/log/nginx/desfollow_access.log;
    error_log /var/log/nginx/desfollow_error.log;
}
EOF

# Testar configuração
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração do Nginx válida"
    systemctl restart nginx
    echo "✅ Nginx reiniciado com sucesso"
else
    echo "❌ Erro na configuração do Nginx"
    echo "Restaurando backup..."
    cp /etc/nginx/nginx.conf.backup /etc/nginx/nginx.conf
    exit 1
fi 