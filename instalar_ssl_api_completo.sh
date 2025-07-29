#!/bin/bash
echo "🔒 Instalando SSL no api.desfollow.com.br..."
echo "============================================="
echo ""

echo "📋 Verificando se certbot está instalado..."
if ! command -v certbot &> /dev/null; then
    echo "❌ Certbot não encontrado! Instalando..."
    apt-get update
    apt-get install -y certbot python3-certbot-nginx
    echo "✅ Certbot instalado!"
else
    echo "✅ Certbot já está instalado!"
fi
echo ""

echo "🔧 Verificando configuração atual do Nginx..."
nginx -t
echo ""

echo "📋 Status atual do Nginx..."
systemctl status nginx --no-pager -l
echo ""

echo "🔒 Instalando certificado SSL para api.desfollow.com.br..."
certbot --nginx -d api.desfollow.com.br --non-interactive --agree-tos --email admin@desfollow.com.br
echo ""

echo "📋 Verificando se o certificado foi instalado..."
if [ -f "/etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem" ]; then
    echo "✅ Certificado SSL instalado com sucesso!"
    echo "📄 Caminho: /etc/letsencrypt/live/api.desfollow.com.br/"
else
    echo "❌ Certificado não foi instalado corretamente!"
    echo "🔍 Verificando logs do certbot..."
    journalctl -u certbot --no-pager -n 20
    exit 1
fi
echo ""

echo "🔧 Atualizando configuração do Nginx para HTTPS..."
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Configuração para desfollow.com.br (frontend)
server {
    listen 80;
    listen [::]:80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    root /var/www/desfollow;
    index index.html;
    
    # Configurações de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Configurações de cache para arquivos estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Configuração para SPA (Single Page Application)
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Configurações de compressão
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss;
}

# Configuração para api.desfollow.com.br (backend) - HTTP
server {
    listen 80;
    listen [::]:80;
    server_name api.desfollow.com.br;
    
    # Redirecionar HTTP para HTTPS
    return 301 https://$server_name$request_uri;
}

# Configuração para api.desfollow.com.br (backend) - HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    
    # Configurações SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Configurações de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Proxy para o backend
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Configurações de timeout
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

echo "✅ Configuração do Nginx atualizada!"
echo ""

echo "🔄 Recarregando Nginx..."
systemctl reload nginx
echo ""

echo "📋 Verificando status do Nginx..."
systemctl status nginx --no-pager -l
echo ""

echo "🧪 Testando conectividade HTTPS..."
echo "📊 Testando api.desfollow.com.br..."
curl -I https://api.desfollow.com.br 2>/dev/null | head -5
echo ""

echo "🔍 Verificando certificado SSL..."
openssl s_client -connect api.desfollow.com.br:443 -servername api.desfollow.com.br < /dev/null 2>/dev/null | openssl x509 -noout -dates
echo ""

echo "✅ SSL instalado com sucesso!"
echo ""
echo "🧪 Teste agora:"
echo "   - https://api.desfollow.com.br"
echo "   - https://api.desfollow.com.br/health"
echo ""
echo "📋 Para verificar se está funcionando:"
echo "   curl -I https://api.desfollow.com.br"
echo "   curl https://api.desfollow.com.br/health" 