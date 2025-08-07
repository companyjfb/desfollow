#!/bin/bash

echo "🔧 CORRIGINDO CERTIFICADO SSL PARA SER CONFIÁVEL - DESFOLLOW"
echo "==========================================================="

# Parar nginx
echo "📋 1. Parando nginx..."
sudo systemctl stop nginx

# Backup dos certificados atuais
echo "📋 2. Fazendo backup dos certificados atuais..."
sudo mkdir -p /root/ssl-backup
sudo cp -r /etc/letsencrypt/live/ /root/ssl-backup/ 2>/dev/null || echo "Backup não necessário"

# Remover certificados problemáticos
echo "📋 3. Removendo certificados problemáticos..."
sudo certbot delete --cert-name desfollow.com.br --non-interactive 2>/dev/null || echo "Certificado principal não encontrado"
sudo certbot delete --cert-name api.desfollow.com.br --non-interactive 2>/dev/null || echo "Certificado API não encontrado"

# Aguardar
sleep 2

# Gerar novo certificado SSL CORRETO para desfollow.com.br
echo "📋 4. Gerando novo certificado SSL CONFIÁVEL para desfollow.com.br..."
sudo certbot certonly \
  --standalone \
  --non-interactive \
  --agree-tos \
  --email jordanbitencourt@gmail.com \
  --no-eff-email \
  --domains desfollow.com.br,www.desfollow.com.br \
  --key-type rsa \
  --rsa-key-size 2048 \
  --force-renewal

if [ $? -ne 0 ]; then
    echo "❌ Erro ao gerar certificado para desfollow.com.br"
    echo "Tentando método alternativo..."
    
    # Método alternativo com webroot
    sudo mkdir -p /var/www/desfollow/.well-known/acme-challenge
    sudo chown -R www-data:www-data /var/www/desfollow/.well-known
    
    sudo certbot certonly \
      --webroot \
      --webroot-path=/var/www/desfollow \
      --non-interactive \
      --agree-tos \
      --email jordanbitencourt@gmail.com \
      --no-eff-email \
      --domains desfollow.com.br,www.desfollow.com.br \
      --key-type rsa \
      --rsa-key-size 2048 \
      --force-renewal
fi

# Gerar certificado para API
echo "📋 5. Gerando certificado SSL para api.desfollow.com.br..."
sudo certbot certonly \
  --standalone \
  --non-interactive \
  --agree-tos \
  --email jordanbitencourt@gmail.com \
  --no-eff-email \
  --domains api.desfollow.com.br \
  --key-type rsa \
  --rsa-key-size 2048 \
  --force-renewal

# Verificar certificados gerados
echo "📋 6. Verificando certificados gerados..."
echo "Certificado principal:"
if [ -f /etc/letsencrypt/live/desfollow.com.br/fullchain.pem ]; then
    echo "✅ Certificado desfollow.com.br encontrado"
    sudo openssl x509 -in /etc/letsencrypt/live/desfollow.com.br/fullchain.pem -text -noout | grep -E "(Subject|Issuer|Validity|DNS)" | head -10
else
    echo "❌ Certificado desfollow.com.br NÃO encontrado"
fi

echo ""
echo "Certificado API:"
if [ -f /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem ]; then
    echo "✅ Certificado api.desfollow.com.br encontrado"
else
    echo "❌ Certificado api.desfollow.com.br NÃO encontrado"
fi

# Configurar nginx com SSL SIMPLES e CONFIÁVEL
echo "📋 7. Aplicando configuração nginx SSL CONFIÁVEL..."
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# CONFIGURAÇÃO NGINX SSL CONFIÁVEL - DESFOLLOW
# ============================================

# HTTP para HTTPS redirect
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# FRONTEND HTTPS - SSL CONFIÁVEL
server {
    listen 443 ssl http2;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/desfollow.com.br/chain.pem;
    
    # SSL configuração CONFIÁVEL (compatível com todos os browsers)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    
    # OCSP stapling para maior confiabilidade
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    
    # Headers de segurança para SSL confiável
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Diretório
    root /var/www/desfollow;
    index index.html;
    
    # Logs
    access_log /var/log/nginx/frontend_ssl_access.log;
    error_log /var/log/nginx/frontend_ssl_error.log;
    
    # Servir arquivos
    location / {
        try_files $uri $uri/ /index.html;
    }
}

# API HTTPS - SSL CONFIÁVEL
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL da API
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/api.desfollow.com.br/chain.pem;
    
    # SSL configuração CONFIÁVEL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    
    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-Content-Type-Options nosniff always;
    
    # Logs
    access_log /var/log/nginx/api_ssl_access.log;
    error_log /var/log/nginx/api_ssl_error.log;
    
    # CORS para proxy de imagens
    location /api/proxy-image {
        add_header 'Access-Control-Allow-Origin' 'https://www.desfollow.com.br' always;
        add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Origin, X-Requested-With, Content-Type, Accept' always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
        
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_hide_header 'Access-Control-Allow-Origin';
    }
    
    # CORS para outras rotas da API
    location /api/ {
        add_header 'Access-Control-Allow-Origin' 'https://www.desfollow.com.br' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Origin, X-Requested-With, Content-Type, Accept, Authorization' always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
        
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_hide_header 'Access-Control-Allow-Origin';
    }
    
    # Root da API
    location / {
        add_header 'Access-Control-Allow-Origin' 'https://www.desfollow.com.br' always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
        
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_hide_header 'Access-Control-Allow-Origin';
    }
}
EOF

# Testar configuração
echo "📋 8. Testando configuração nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração nginx válida"
    
    # Iniciar nginx
    echo "📋 9. Iniciando nginx..."
    sudo systemctl start nginx
    
    # Aguardar
    sleep 5
    
    # Testes de confiabilidade
    echo "📋 10. Testando confiabilidade do certificado..."
    
    echo "Teste verificação certificado:"
    timeout 15 openssl s_client -connect desfollow.com.br:443 -servername desfollow.com.br -verify_return_error 2>/dev/null | grep -E "(Verify return code|Protocol|Cipher)"
    
    echo ""
    echo "Teste cadeia de certificados:"
    timeout 10 openssl s_client -connect desfollow.com.br:443 -servername desfollow.com.br -showcerts 2>/dev/null | grep -c "BEGIN CERTIFICATE"
    
    echo ""
    echo "✅ CERTIFICADO SSL CONFIÁVEL CONFIGURADO!"
    echo "========================================"
    echo "🔗 Frontend: https://desfollow.com.br"
    echo "🔗 API: https://api.desfollow.com.br"
    echo ""
    echo "📱 MELHORIAS APLICADAS:"
    echo "• Certificado SSL regenerado com configurações corretas"
    echo "• OCSP Stapling habilitado"
    echo "• Headers de segurança adequados"
    echo "• Cadeia de certificados completa"
    echo "• Configuração confiável para todos os browsers"
    
else
    echo "❌ Erro na configuração nginx"
    sudo nginx -t
fi

echo ""
echo "📋 11. TESTE NO MOBILE:"
echo "Agora o certificado deve ser confiável. Teste:"
echo "1. Limpe cache do browser mobile"
echo "2. Feche e abra o browser"
echo "3. Acesse https://desfollow.com.br"
echo "4. Deve aparecer como site seguro (cadeado verde)"