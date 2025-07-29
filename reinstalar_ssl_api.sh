#!/bin/bash

echo "🔐 Reinstalando SSL para api.desfollow.com.br..."
echo "==============================================="
echo ""

# Função para verificar sucesso
check_success() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ Erro: $1"
        exit 1
    fi
}

echo "📋 1. Verificando estado atual..."

# Verificar se certbot está instalado
if ! command -v certbot &> /dev/null; then
    echo "❌ Certbot não encontrado! Instalando..."
    apt update
    apt install -y certbot python3-certbot-nginx
    check_success "Certbot instalado"
else
    echo "✅ Certbot já está instalado"
fi

# Verificar certificados existentes
echo "🔍 Certificados atuais:"
certbot certificates | grep -A 5 "api.desfollow.com.br" || echo "   Nenhum certificado encontrado para api.desfollow.com.br"

echo ""
echo "📋 2. Verificando configuração do Nginx..."

# Verificar se nginx está rodando
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx está rodando"
else
    echo "❌ Nginx não está rodando! Iniciando..."
    systemctl start nginx
    check_success "Nginx iniciado"
fi

# Verificar configuração do nginx
nginx -t
check_success "Configuração do Nginx válida"

echo ""
echo "📋 3. Verificando DNS e conectividade..."

# Verificar se o domínio resolve para este servidor
API_IP=$(dig +short api.desfollow.com.br)
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip)

echo "🌐 DNS api.desfollow.com.br aponta para: $API_IP"
echo "🖥️ IP do servidor atual: $SERVER_IP"

if [ "$API_IP" = "$SERVER_IP" ]; then
    echo "✅ DNS está correto"
else
    echo "⚠️ DNS pode não estar apontando para este servidor"
    echo "   Continuando mesmo assim..."
fi

echo ""
echo "📋 4. Parando serviços temporariamente..."

# Parar nginx temporariamente para certificação
systemctl stop nginx
check_success "Nginx parado temporariamente"

echo ""
echo "📋 5. Removendo certificados antigos (se existirem)..."

# Remover certificados antigos se existirem
certbot delete --cert-name api.desfollow.com.br --non-interactive 2>/dev/null || echo "   Nenhum certificado anterior encontrado"

echo ""
echo "📋 6. Gerando novo certificado SSL..."

# Gerar novo certificado usando standalone (sem nginx rodando)
certbot certonly \
    --standalone \
    --email admin@desfollow.com.br \
    --agree-tos \
    --no-eff-email \
    --domains api.desfollow.com.br \
    --non-interactive \
    --force-renewal

check_success "Certificado SSL gerado"

echo ""
echo "📋 7. Iniciando Nginx novamente..."
systemctl start nginx
check_success "Nginx iniciado"

echo ""
echo "📋 8. Atualizando configuração do Nginx com SSL..."

# Fazer backup da configuração atual
cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.ssl.$(date +%Y%m%d_%H%M%S)

# Criar configuração completa com SSL
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Configuração Nginx para Desfollow - Frontend e API com SSL

# Frontend HTTP (desfollow.com.br e www.desfollow.com.br)
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;

    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http://api.desfollow.com.br https://api.desfollow.com.br http: https: data: blob: 'unsafe-inline'" always;

    # Configuração do frontend React
    root /var/www/desfollow;
    index index.html;

    # Configuração para Single Page Application (SPA)
    location / {
        try_files $uri $uri/ /index.html;
        
        # Cache para arquivos estáticos
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Proxy para API no mesmo domínio (para evitar CORS)
    location /api/ {
        proxy_pass https://api.desfollow.com.br/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Logs específicos do frontend
    access_log /var/log/nginx/desfollow_frontend_access.log;
    error_log /var/log/nginx/desfollow_frontend_error.log;
}

# API HTTP (api.desfollow.com.br) - Redirecionamento para HTTPS
server {
    listen 80;
    server_name api.desfollow.com.br;
    
    # Redirecionar tudo para HTTPS
    return 301 https://$server_name$request_uri;
}

# API HTTPS (api.desfollow.com.br) - Principal
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;

    # Configuração SSL
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

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

    # Logs específicos da API
    access_log /var/log/nginx/desfollow_api_ssl_access.log;
    error_log /var/log/nginx/desfollow_api_ssl_error.log;
}
EOF

check_success "Configuração SSL criada"

echo ""
echo "📋 9. Aplicando nova configuração..."

# Verificar sintaxe
nginx -t
check_success "Sintaxe do Nginx verificada"

# Recarregar Nginx
systemctl reload nginx
check_success "Nginx recarregado com SSL"

echo ""
echo "📋 10. Configurando renovação automática..."

# Configurar renovação automática
crontab -l 2>/dev/null | grep -v "certbot renew" | crontab -
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet --nginx") | crontab -
check_success "Renovação automática configurada"

echo ""
echo "📋 11. Testando certificado SSL..."

# Aguardar um pouco
sleep 5

echo "🔐 Testando HTTPS da API:"
SSL_TEST=$(curl -s -I https://api.desfollow.com.br/ 2>/dev/null | head -1)
echo "$SSL_TEST"

if echo "$SSL_TEST" | grep -q "200\|301\|302"; then
    echo "✅ HTTPS funcionando!"
else
    echo "⚠️ Problemas com HTTPS"
fi

echo ""
echo "📋 12. Verificação final dos certificados..."
certbot certificates | grep -A 5 "api.desfollow.com.br"

echo ""
echo "✅ REINSTALAÇÃO DO SSL CONCLUÍDA!"
echo ""
echo "📊 URLs atualizadas:"
echo "   - http://desfollow.com.br/ → Frontend (HTTP)"
echo "   - http://www.desfollow.com.br/ → Frontend (HTTP)"
echo "   - http://api.desfollow.com.br/ → Redireciona para HTTPS"
echo "   - https://api.desfollow.com.br/ → API (HTTPS)"
echo ""
echo "🔍 Para testar:"
echo "   curl -s https://api.desfollow.com.br/api/health | python3 -m json.tool"
echo "   curl -I https://api.desfollow.com.br/"
echo ""
echo "📅 Renovação automática: configurada para 12:00 diariamente" 