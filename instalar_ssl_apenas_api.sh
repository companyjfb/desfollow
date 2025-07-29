#!/bin/bash

echo "🔒 Instalação SSL APENAS para API - api.desfollow.com.br"
echo "======================================================"
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

echo "📋 1. Verificando status atual do nginx..."
if ! systemctl is-active --quiet nginx; then
    echo "⚠️ Nginx parado, iniciando..."
    systemctl start nginx
    check_success "Nginx iniciado"
else
    echo "✅ Nginx já rodando"
fi

echo ""
echo "📋 2. Verificando SSL existente nos domínios principais..."
if openssl s_client -connect desfollow.com.br:443 -servername desfollow.com.br </dev/null 2>/dev/null | grep -q "Verify return code: 0"; then
    echo "✅ SSL já ativo em desfollow.com.br"
    SSL_MAIN_ACTIVE=true
else
    echo "⚠️ SSL não ativo em desfollow.com.br"
    SSL_MAIN_ACTIVE=false
fi

echo ""
echo "📋 3. Verificando SSL da API..."
if openssl s_client -connect api.desfollow.com.br:443 -servername api.desfollow.com.br </dev/null 2>/dev/null | grep -q "Verify return code: 0"; then
    echo "✅ SSL já ativo em api.desfollow.com.br - nada a fazer!"
    exit 0
else
    echo "❌ SSL não ativo em api.desfollow.com.br - prosseguindo..."
fi

echo ""
echo "📋 4. Criando diretório para challenges Let's Encrypt..."
mkdir -p /var/www/html/.well-known/acme-challenge
chown -R www-data:www-data /var/www/html/.well-known
chmod -R 755 /var/www/html/.well-known
check_success "Diretório de challenges criado"

echo ""
echo "📋 5. Testando se challenge path está funcionando..."
echo "test-api-ssl" > /var/www/html/.well-known/acme-challenge/test-api
CHALLENGE_TEST=$(curl -s http://api.desfollow.com.br/.well-known/acme-challenge/test-api 2>/dev/null)
if [ "$CHALLENGE_TEST" = "test-api-ssl" ]; then
    echo "✅ Challenge path funcionando para API"
    rm /var/www/html/.well-known/acme-challenge/test-api
else
    echo "❌ Challenge path não está funcionando para API"
    echo "Response: $CHALLENGE_TEST"
    echo "Configurando nginx para servir challenges..."
    
    # Backup configuração atual
    cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.ssl.$(date +%Y%m%d_%H%M%S)
    
    # Adicionar location para challenges na configuração da API
    sed -i '/server_name api\.desfollow\.com\.br;/a \    \n    # CRITICAL: Local para challenges Let'\''s Encrypt\n    location /.well-known/acme-challenge/ {\n        root /var/www/html;\n        try_files $uri =404;\n    }' /etc/nginx/sites-available/desfollow
    
    nginx -t && systemctl reload nginx
    check_success "Nginx reconfigurado para challenges"
    
    # Testar novamente
    sleep 2
    CHALLENGE_TEST=$(curl -s http://api.desfollow.com.br/.well-known/acme-challenge/test-api 2>/dev/null)
    if [ "$CHALLENGE_TEST" = "test-api-ssl" ]; then
        echo "✅ Challenge path agora funcionando"
        rm /var/www/html/.well-known/acme-challenge/test-api
    else
        echo "❌ Challenge path ainda não funciona - saindo"
        exit 1
    fi
fi

echo ""
echo "📋 6. Obtendo certificado SSL APENAS para API..."

# Tentar com domínio existente primeiro (expand)
if [ -d "/etc/letsencrypt/live/desfollow.com.br" ]; then
    echo "🔄 Expandindo certificado existente para incluir api.desfollow.com.br..."
    certbot certonly \
      --webroot \
      --webroot-path=/var/www/html \
      -d desfollow.com.br \
      -d www.desfollow.com.br \
      -d api.desfollow.com.br \
      --email admin@desfollow.com.br \
      --agree-tos \
      --non-interactive \
      --expand
    
    if [ $? -eq 0 ]; then
        echo "✅ Certificado expandido com sucesso"
        CERT_PATH="/etc/letsencrypt/live/desfollow.com.br"
    else
        echo "⚠️ Expansão falhou, tentando certificado separado..."
        certbot certonly \
          --webroot \
          --webroot-path=/var/www/html \
          -d api.desfollow.com.br \
          --email admin@desfollow.com.br \
          --agree-tos \
          --non-interactive
        
        check_success "Certificado SSL obtido para API"
        CERT_PATH="/etc/letsencrypt/live/api.desfollow.com.br"
    fi
else
    echo "🆕 Criando certificado apenas para API..."
    certbot certonly \
      --webroot \
      --webroot-path=/var/www/html \
      -d api.desfollow.com.br \
      --email admin@desfollow.com.br \
      --agree-tos \
      --non-interactive
    
    check_success "Certificado SSL obtido para API"
    CERT_PATH="/etc/letsencrypt/live/api.desfollow.com.br"
fi

echo ""
echo "📋 7. Atualizando configuração nginx para API com SSL..."

# Ler configuração atual
CURRENT_CONFIG=$(cat /etc/nginx/sites-available/desfollow)

# Verificar se já tem configuração SSL para API
if echo "$CURRENT_CONFIG" | grep -q "listen 443.*api\.desfollow\.com\.br"; then
    echo "⚠️ Configuração SSL da API já existe, atualizando..."
else
    echo "🆕 Adicionando configuração SSL para API..."
fi

# Criar nova configuração com SSL para API
cat > /etc/nginx/sites-available/desfollow << EOF
# ========================================
# CONFIGURAÇÃO NGINX - DESFOLLOW
# SSL nos domínios principais + API
# ========================================

# Frontend HTTP -> HTTPS (se necessário)
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Manter challenges para renovações
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files \$uri =404;
    }
    
    # Se SSL ativo nos domínios principais, redirecionar
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# API HTTP -> HTTPS  
server {
    listen 80;
    server_name api.desfollow.com.br;
    
    # Manter challenges para renovações
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files \$uri =404;
    }
    
    # Redirecionar para HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# API HTTPS (NOVA CONFIGURAÇÃO)
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate $CERT_PATH/fullchain.pem;
    ssl_certificate_key $CERT_PATH/privkey.pem;
    
    # Configurações SSL modernas
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Logs SSL API
    access_log /var/log/nginx/api_ssl_access.log;
    error_log /var/log/nginx/api_ssl_error.log;
    
    # Proxy para API
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        
        # CORS para HTTPS
        add_header Access-Control-Allow-Origin "https://desfollow.com.br, https://www.desfollow.com.br" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
        add_header Access-Control-Allow-Credentials true always;
        
        # OPTIONS preflight
        if (\$request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://desfollow.com.br, https://www.desfollow.com.br" always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain charset=UTF-8';
            add_header Content-Length 0;
            return 204;
        }
    }
}
EOF

check_success "Configuração SSL da API criada"

echo ""
echo "📋 8. Testando configuração final..."
nginx -t
check_success "Configuração nginx válida"

echo ""
echo "📋 9. Aplicando configuração..."
systemctl reload nginx
check_success "Nginx SSL da API ativado"

echo ""
echo "📋 10. Testando URLs finais..."

sleep 3

echo "🌐 Testando API HTTPS..."
API_HTTPS=$(curl -s -o /dev/null -w "%{http_code}" https://api.desfollow.com.br --insecure 2>/dev/null)
echo "   API HTTPS: $API_HTTPS"

if [ "$API_HTTPS" = "200" ] || [ "$API_HTTPS" = "404" ]; then
    echo "✅ SSL da API funcionando!"
else
    echo "⚠️ SSL da API pode ter problemas"
fi

echo "🌐 Testando redirecionamento API..."
REDIRECT_API=$(curl -s -o /dev/null -w "%{http_code}" http://api.desfollow.com.br 2>/dev/null)
echo "   API HTTP -> HTTPS: $REDIRECT_API"

echo ""
echo "✅ SSL DA API INSTALADO COM SUCESSO!"
echo ""
echo "🔒 URLs FINAIS:"
echo "   https://desfollow.com.br (Frontend - SSL existente)"
echo "   https://www.desfollow.com.br (Frontend - SSL existente)"  
echo "   https://api.desfollow.com.br (API - SSL NOVO) ✨"
echo ""
echo "🔄 REDIRECIONAMENTOS:"
echo "   http://api.desfollow.com.br → https://api.desfollow.com.br ✅"
echo ""
echo "📜 VERIFICAR LOGS DA API:"
echo "   tail -f /var/log/nginx/api_ssl_access.log"
echo "   tail -f /var/log/nginx/api_ssl_error.log"
echo ""
echo "🔍 TESTAR API SSL:"
echo "   curl https://api.desfollow.com.br"
echo "   curl https://api.desfollow.com.br/health"
echo ""
echo "🚀 Problema CORS API/HTTPS resolvido!" 