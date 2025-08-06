#!/bin/bash

echo "🔒 INSTALANDO SSL APENAS PARA API.DESFOLLOW.COM.BR"
echo "================================================="

# Atualizar repositório
echo "📋 1. Atualizando repositório..."
git pull origin main

# Parar serviços que podem conflitar
echo "📋 2. Parando serviços que conflitam..."
sudo systemctl stop nginx
sudo pkill -f gunicorn
sudo pkill -f python3

# Verificar se porta 80 está livre
echo "📋 3. Verificando porta 80..."
sudo netstat -tlnp | grep :80

# Instalar SSL apenas para api.desfollow.com.br
echo "📋 4. Instalando SSL para api.desfollow.com.br..."
sudo certbot certonly \
  --standalone \
  --non-interactive \
  --agree-tos \
  --email jordankjfb@gmail.com \
  --domains api.desfollow.com.br \
  --force-renewal

# Configurar Nginx para HTTPS apenas na API
echo "📋 5. Configurando Nginx para HTTPS..."
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# Configuração para api.desfollow.com.br com SSL
server {
    listen 80;
    server_name api.desfollow.com.br;
    
    # Redirecionar HTTP para HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    
    # Configurações SSL seguras
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    
    # CORS headers para o frontend
    add_header 'Access-Control-Allow-Origin' 'https://desfollow.com.br' always;
    add_header 'Access-Control-Allow-Origin' 'https://www.desfollow.com.br' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
    add_header 'Access-Control-Allow-Headers' 'Origin, Content-Type, Accept, Authorization, X-Requested-With' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    
    # Handle preflight requests
    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' 'https://desfollow.com.br' always;
        add_header 'Access-Control-Allow-Origin' 'https://www.desfollow.com.br' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
        add_header 'Access-Control-Allow-Headers' 'Origin, Content-Type, Accept, Authorization, X-Requested-With' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        add_header 'Content-Length' 0;
        add_header 'Content-Type' 'text/plain';
        return 204;
    }
    
    # Proxy para o backend Python
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $server_name;
        
        # Timeouts
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        proxy_buffering off;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # Security headers for API responses
    location ~* \.(json|api)$ {
        add_header 'Access-Control-Allow-Origin' 'https://desfollow.com.br' always;
        add_header 'Access-Control-Allow-Origin' 'https://www.desfollow.com.br' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
    }
}
EOF

# Testar configuração do Nginx
echo "📋 6. Testando configuração do Nginx..."
sudo nginx -t

# Reiniciar serviços
echo "📋 7. Reiniciando serviços..."
sudo systemctl restart nginx
sudo systemctl enable nginx

# Iniciar backend
echo "📋 8. Iniciando backend..."
cd /root/desfollow/backend
source venv/bin/activate
nohup gunicorn --config gunicorn.conf.py app.main:app > /dev/null 2>&1 &

# Aguardar backend inicializar
sleep 5

# Verificar se os serviços estão rodando
echo "📋 9. Verificando serviços..."
echo "• Nginx:"
sudo systemctl status nginx --no-pager -l
echo "• Backend:"
ps aux | grep gunicorn | grep -v grep

# Testar HTTPS
echo "📋 10. Testando HTTPS..."
echo "• Testando SSL:"
curl -I https://api.desfollow.com.br/health 2>/dev/null | head -5
echo "• Testando redirecionamento HTTP -> HTTPS:"
curl -I http://api.desfollow.com.br/health 2>/dev/null | head -3

# Verificar certificado
echo "📋 11. Verificando certificado..."
echo | openssl s_client -servername api.desfollow.com.br -connect api.desfollow.com.br:443 2>/dev/null | openssl x509 -noout -dates

echo ""
echo "✅ SSL INSTALADO COM SUCESSO!"
echo "🌐 API agora disponível em: https://api.desfollow.com.br"
echo "🔒 Certificado válido para api.desfollow.com.br"
echo "🔄 HTTP automaticamente redirecionado para HTTPS"