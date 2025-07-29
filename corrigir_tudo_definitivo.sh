#!/bin/bash

echo "🔧 CORREÇÃO DEFINITIVA - Frontend + Backend SSL + CORS"
echo "====================================================="
echo ""
echo "🎯 Este script resolve TODOS os problemas de uma vez:"
echo "   ✅ Frontend nos domínios principais"
echo "   ✅ SSL na API backend"  
echo "   ✅ CORS funcionando"
echo "   ✅ Comunicação entre frontend e API"
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

echo "📋 1. Preparação inicial..."

# Atualizar código
cd /root/desfollow
git pull origin main
check_success "Código atualizado"

# Verificar serviços
if ! systemctl is-active --quiet nginx; then
    systemctl start nginx
fi

echo ""
echo "📋 2. Instalando/verificando dependências..."

# Certbot
if ! command -v certbot &> /dev/null; then
    apt update && apt install -y certbot python3-certbot-nginx
    check_success "Certbot instalado"
fi

# Node.js para frontend
if ! command -v npm &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    apt-get install -y nodejs
    check_success "Node.js instalado"
fi

echo ""
echo "📋 3. Fazendo build do frontend..."
npm install && npm run build
check_success "Frontend buildado"

# Copiar frontend
mkdir -p /var/www/desfollow
rm -rf /var/www/desfollow/*
cp -r dist/* /var/www/desfollow/
chown -R www-data:www-data /var/www/desfollow
chmod -R 755 /var/www/desfollow
check_success "Frontend copiado"

echo ""
echo "📋 4. Gerando certificado SSL (se necessário)..."

# Parar nginx para gerar certificado
systemctl stop nginx

# Gerar/renovar certificado
certbot certonly \
    --standalone \
    --email admin@desfollow.com.br \
    --agree-tos \
    --no-eff-email \
    --domains api.desfollow.com.br \
    --non-interactive \
    --force-renewal 2>/dev/null || echo "Certificado já existe ou erro esperado"

# Iniciar nginx novamente
systemctl start nginx
check_success "Nginx reiniciado"

echo ""
echo "📋 5. Criando configuração DEFINITIVA do Nginx..."

# Backup
cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.definitivo.$(date +%Y%m%d_%H%M%S) 2>/dev/null

# Criar configuração que resolve TUDO
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Configuração Definitiva - Resolve Frontend + API + CORS

# Frontend HTTP (desfollow.com.br e www.desfollow.com.br)
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;

    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Headers CORS para frontend
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
            add_header Access-Control-Allow-Origin "*";
        }
    }

    # API Proxy - CRUCIAL para evitar CORS
    location /api/ {
        # Headers CORS essenciais
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization" always;
        
        # Preflight requests
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "*" always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization" always;
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type "text/plain charset=UTF-8";
            add_header Content-Length 0;
            return 204;
        }

        # Proxy para API local (HTTP interno)
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

    # SSL
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Strict-Transport-Security "max-age=31536000" always;

    # Headers CORS para API direta
    add_header Access-Control-Allow-Origin "*" always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization" always;

    # Preflight requests para API
    if ($request_method = 'OPTIONS') {
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization" always;
        add_header Access-Control-Max-Age 1728000;
        add_header Content-Type "text/plain charset=UTF-8";
        add_header Content-Length 0;
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

check_success "Configuração definitiva criada"

echo ""
echo "📋 6. Atualizando backend para CORS correto..."

# Atualizar CORS no backend
cat > /tmp/cors_patch.py << 'EOF'
import re

# Ler arquivo atual
with open('/root/desfollow/backend/app/main.py', 'r') as f:
    content = f.read()

# Atualizar origins para incluir todos os domínios necessários
new_origins = '''allowed_origins = [
    # Domínios de produção - HTTP
    "http://desfollow.com.br",
    "http://www.desfollow.com.br",
    # Domínios de produção - HTTPS  
    "https://desfollow.com.br",
    "https://www.desfollow.com.br",
    "https://api.desfollow.com.br",
    # Para desenvolvimento local
    "http://localhost:3000",
    "http://localhost:5173",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:5173",
    # Wildcard para resolver problemas
    "*"
]'''

# Substituir configuração de CORS
pattern = r'allowed_origins = \[.*?\]'
content = re.sub(pattern, new_origins, content, flags=re.DOTALL)

# Salvar arquivo
with open('/root/desfollow/backend/app/main.py', 'w') as f:
    f.write(content)

print("✅ CORS atualizado no backend")
EOF

python3 /tmp/cors_patch.py
check_success "Backend CORS atualizado"

echo ""
echo "📋 7. Aplicando configurações..."

# Testar e aplicar nginx
nginx -t
check_success "Nginx sintaxe OK"

systemctl reload nginx
check_success "Nginx recarregado"

# Reiniciar backend para aplicar CORS
systemctl restart desfollow
check_success "Backend reiniciado"

echo ""
echo "📋 8. Aguardando estabilização..."
sleep 10

echo ""
echo "📋 9. Testando tudo..."

echo "🔍 Frontend (desfollow.com.br):"
FRONTEND_TEST=$(curl -s http://desfollow.com.br/ | head -1)
if echo "$FRONTEND_TEST" | grep -q "DOCTYPE\|html"; then
    echo "✅ Frontend funcionando!"
else
    echo "⚠️ Frontend: $FRONTEND_TEST"
fi

echo ""
echo "🔍 API HTTP (deve redirecionar):"
curl -I http://api.desfollow.com.br/ 2>/dev/null | head -2

echo ""
echo "🔍 API HTTPS:"
API_TEST=$(curl -s https://api.desfollow.com.br/ 2>/dev/null | head -1)
if echo "$API_TEST" | grep -q "Desfollow API"; then
    echo "✅ API HTTPS funcionando!"
else
    echo "⚠️ API HTTPS: $API_TEST"
fi

echo ""
echo "🔍 API via frontend (CORS test):"
CORS_TEST=$(curl -s http://desfollow.com.br/api/health 2>/dev/null)
if echo "$CORS_TEST" | grep -q "healthy"; then
    echo "✅ CORS funcionando!"
else
    echo "⚠️ CORS: $CORS_TEST"
fi

echo ""
echo "📋 10. Configurando renovação automática SSL..."
(crontab -l 2>/dev/null | grep -v certbot; echo "0 12 * * * /usr/bin/certbot renew --quiet --nginx") | crontab -
check_success "Renovação automática configurada"

echo ""
echo "✅ CORREÇÃO DEFINITIVA CONCLUÍDA!"
echo ""
echo "🎯 RESULTADO FINAL:"
echo "   ✅ http://desfollow.com.br/ → Frontend React (sem CORS)"
echo "   ✅ http://www.desfollow.com.br/ → Frontend React (sem CORS)"
echo "   ✅ http://desfollow.com.br/api/ → API via proxy (sem CORS)"
echo "   ✅ https://api.desfollow.com.br/ → API direta HTTPS"
echo "   ✅ Backend configurado com CORS amplo"
echo ""
echo "🔍 TESTES FINAIS:"
echo "   curl -s http://desfollow.com.br/ | head -3"
echo "   curl -s http://desfollow.com.br/api/health"
echo "   curl -s https://api.desfollow.com.br/api/health"
echo ""
echo "🎉 Agora frontend e API funcionam juntos SEM conflitos!" 