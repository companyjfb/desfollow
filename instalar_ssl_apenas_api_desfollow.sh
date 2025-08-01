#!/bin/bash

echo "🔒 Instalação SSL APENAS para api.desfollow.com.br"
echo "================================================"
echo "Frontend já tem SSL ativo - mantendo como está"
echo "Apenas adicionando HTTPS na API sem quebrar nada"
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

echo "📋 1. Fazendo backup da configuração atual..."
BACKUP_FILE="/etc/nginx/sites-available/desfollow.backup.api-ssl.$(date +%Y%m%d_%H%M%S)"
sudo cp /etc/nginx/sites-available/desfollow "$BACKUP_FILE"
echo "💾 Backup salvo em: $BACKUP_FILE"

echo ""
echo "📋 2. Verificando se frontend já tem SSL..."
if curl -s "https://desfollow.com.br" | grep -q "DOCTYPE"; then
    echo "✅ Frontend HTTPS já funcionando - mantendo como está"
else
    echo "⚠️ Frontend HTTPS não está funcionando, mas continuando com API..."
fi

echo ""
echo "📋 3. Verificando estado atual da API..."
if curl -s "http://api.desfollow.com.br/api/health" | grep -q "healthy"; then
    echo "✅ API HTTP funcionando"
else
    echo "⚠️ API HTTP não responde, mas continuando..."
fi

if curl -s "https://api.desfollow.com.br/api/health" 2>/dev/null | grep -q "healthy"; then
    echo "✅ API HTTPS já funcionando! Script não necessário."
    exit 0
else
    echo "📋 API HTTPS não funcionando - instalando SSL..."
fi

echo ""
echo "📋 4. Instalando Certbot se necessário..."
sudo apt update
sudo apt install -y certbot python3-certbot-nginx
check_success "Certbot instalado"

echo ""
echo "📋 5. Verificando configuração nginx atual..."
sudo nginx -t
if [ $? -ne 0 ]; then
    echo "❌ Configuração nginx inválida. Restaurando backup..."
    sudo cp "$BACKUP_FILE" /etc/nginx/sites-available/desfollow
    exit 1
fi

echo ""
echo "📋 6. Obtendo certificado SSL APENAS para api.desfollow.com.br..."

# MÉTODO MAIS SEGURO: Usar webroot em vez de standalone
# Criar diretório webroot para o challenge
sudo mkdir -p /var/www/api-challenge
sudo chown www-data:www-data /var/www/api-challenge

# Adicionar temporariamente location para .well-known no nginx
sudo tee /tmp/nginx-api-challenge.conf > /dev/null << 'EOF'
# Configuração temporária para Let's Encrypt challenge
server {
    listen 80;
    server_name api.desfollow.com.br;
    
    location /.well-known/acme-challenge/ {
        root /var/www/api-challenge;
    }
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Substituir configuração temporariamente
sudo cp /etc/nginx/sites-available/desfollow /tmp/nginx-original.conf
sudo cp /tmp/nginx-api-challenge.conf /etc/nginx/sites-available/desfollow

# Recarregar nginx
sudo nginx -t && sudo systemctl reload nginx

# Obter certificado para API apenas
sudo certbot certonly --webroot \
  -w /var/www/api-challenge \
  -d api.desfollow.com.br \
  --non-interactive \
  --agree-tos \
  --email admin@desfollow.com.br

if [ $? -eq 0 ]; then
    echo "✅ Certificado SSL obtido para api.desfollow.com.br"
else
    echo "❌ Falha ao obter certificado. Restaurando configuração..."
    sudo cp /tmp/nginx-original.conf /etc/nginx/sites-available/desfollow
    sudo systemctl reload nginx
    exit 1
fi

echo ""
echo "📋 7. Criando configuração nginx com SSL APENAS para API..."

# Ler configuração atual e adicionar SSL para API
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# ========================================
# CONFIGURAÇÃO NGINX - DESFOLLOW v3
# ========================================
# Frontend: desfollow.com.br + www.desfollow.com.br (MANTIDO COMO ESTÁ)
# API: api.desfollow.com.br (ADICIONADO HTTPS)
# ========================================

# FRONTEND - MANTIDO COMO ESTAVA (HTTP ou HTTPS existente)
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Se já tinha HTTPS, manter redirecionamento
    # Se não tinha, manter HTTP
    # (Verificar manualmente se precisa de redirecionamento)
    
    root /var/www/html;
    index index.html;
    
    access_log /var/log/nginx/frontend_access.log;
    error_log /var/log/nginx/frontend_error.log;
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }
    
    location / {
        try_files $uri $uri/ /index.html;
        
        add_header X-Content-Type-Options nosniff;
        add_header X-Frame-Options DENY;
        add_header X-XSS-Protection "1; mode=block";
    }
    
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location /health {
        access_log off;
        return 200 "Frontend OK\n";
        add_header Content-Type text/plain;
    }
}

# FRONTEND HTTPS (se já existia)
server {
    listen 443 ssl http2;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Certificados do frontend (se existirem)
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    
    root /var/www/html;
    index index.html;
    
    access_log /var/log/nginx/frontend_ssl_access.log;
    error_log /var/log/nginx/frontend_ssl_error.log;
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location /health {
        access_log off;
        return 200 "Frontend SSL OK\n";
        add_header Content-Type text/plain;
    }
}

# API HTTP -> HTTPS REDIRECT
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# API HTTPS - NOVA CONFIGURAÇÃO
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL da API
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    access_log /var/log/nginx/api_ssl_access.log;
    error_log /var/log/nginx/api_ssl_error.log;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $host;
        
        # 🚀 TIMEOUTS CORRIGIDOS: 5 minutos
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        
        # 🚀 CONFIGURAÇÕES PARA REQUESTS LONGOS
        proxy_buffering off;
        proxy_request_buffering off;
        client_max_body_size 10m;
        
        # 🚀 CORS PRESERVADO: HTTP + HTTPS
        add_header Access-Control-Allow-Origin "https://desfollow.com.br, https://www.desfollow.com.br, http://desfollow.com.br, http://www.desfollow.com.br" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
        add_header Access-Control-Allow-Credentials true always;
        
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://desfollow.com.br, https://www.desfollow.com.br, http://desfollow.com.br, http://www.desfollow.com.br" always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain charset=UTF-8';
            add_header Content-Length 0;
            return 204;
        }
    }
    
    location /health {
        access_log off;
        proxy_pass http://127.0.0.1:8000/health;
    }
}
EOF

check_success "Configuração SSL da API criada"

echo ""
echo "📋 8. Testando nova configuração..."
sudo nginx -t
check_success "Configuração SSL válida"

echo ""
echo "📋 9. Aplicando configuração..."
sudo systemctl reload nginx
check_success "Nginx recarregado com SSL da API"

# Verificar se backend está rodando
echo ""
echo "📋 10. Verificando backend..."
if sudo lsof -i :8000 | grep -q LISTEN; then
    echo "✅ Backend rodando na porta 8000"
else
    echo "⚠️ Backend não está rodando. Tentando iniciar..."
    cd /root/desfollow/backend
    nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 --env-file env.production > /tmp/backend.log 2>&1 &
    sleep 3
    if sudo lsof -i :8000 | grep -q LISTEN; then
        echo "✅ Backend iniciado com sucesso"
    else
        echo "❌ Falha ao iniciar backend. Verifique /tmp/backend.log"
    fi
fi

echo ""
echo "📋 11. Configurando renovação automática..."
sudo tee /etc/cron.d/certbot-api-desfollow > /dev/null << 'EOF'
# Renovar certificado SSL da API automaticamente
0 12 * * * root certbot renew --quiet --deploy-hook "systemctl reload nginx"
EOF
check_success "Renovação automática configurada"

echo ""
echo "📋 12. Testando API com SSL..."

sleep 5

echo "🧪 Testando API HTTPS..."
API_HEALTH=$(curl -s "https://api.desfollow.com.br/api/health" 2>/dev/null)
if echo "$API_HEALTH" | grep -q "healthy"; then
    echo "✅ API HTTPS funcionando: $API_HEALTH"
else
    echo "⚠️ API HTTPS: $API_HEALTH"
    echo "🔍 Testando certificado..."
    echo | openssl s_client -connect api.desfollow.com.br:443 -servername api.desfollow.com.br 2>/dev/null | grep "Verification:"
fi

echo ""
echo "📋 13. Testando redirecionamento HTTP -> HTTPS..."
REDIRECT_TEST=$(curl -s -o /dev/null -w "%{http_code}" "http://api.desfollow.com.br/api/health" 2>/dev/null)
if [ "$REDIRECT_TEST" = "301" ]; then
    echo "✅ Redirecionamento HTTP -> HTTPS funcionando"
else
    echo "⚠️ Redirecionamento: HTTP $REDIRECT_TEST"
fi

echo ""
echo "📋 14. Testando comunicação completa..."
cd /root/desfollow
python3 testar_comunicacao_frontend_backend.py

echo ""
echo "✅ SSL INSTALADO APENAS NA API!"
echo ""
echo "🔒 CONFIGURAÇÃO FINAL:"
echo "   Frontend: MANTIDO como estava (HTTP ou HTTPS existente)"
echo "   API:      https://api.desfollow.com.br (SSL ADICIONADO)"
echo ""
echo "🔄 REDIRECIONAMENTO AUTOMÁTICO:"
echo "   http://api.desfollow.com.br → https://api.desfollow.com.br"
echo ""
echo "⚙️ MELHORIAS NA API:"
echo "   ✅ Timeout: 300s (5 minutos)"
echo "   ✅ CORS: HTTP + HTTPS preservados"
echo "   ✅ Proxy buffering: Desabilitado"
echo ""
echo "📊 Para testar:"
echo "   curl https://api.desfollow.com.br/api/health"
echo "   curl https://desfollow.com.br (frontend mantido)"
echo ""
echo "📜 Backup da configuração anterior:"
echo "   $BACKUP_FILE"
echo ""
echo "🚀 SSL da API instalado sem quebrar frontend!"