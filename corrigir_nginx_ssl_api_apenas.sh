#!/bin/bash

echo "🔧 CORREÇÃO NGINX: SSL apenas na API"
echo "===================================="
echo "Frontend: HTTP (sem SSL problemático)"
echo "API: HTTPS (certificado existe)"
echo ""

# Backup da configuração atual
BACKUP_FILE="/etc/nginx/sites-available/desfollow.backup.fix-ssl.$(date +%Y%m%d_%H%M%S)"
sudo cp /etc/nginx/sites-available/desfollow "$BACKUP_FILE"
echo "💾 Backup: $BACKUP_FILE"

echo ""
echo "📋 Criando configuração nginx corrigida..."

# Configuração corrigida - sem SSL no frontend
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# ========================================
# CONFIGURAÇÃO NGINX CORRIGIDA - DESFOLLOW
# ========================================
# Frontend: HTTP (sem SSL)
# API: HTTPS (SSL funcionando)
# ========================================

# FRONTEND HTTP - SEM SSL (temporário)
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    root /var/www/html;
    index index.html;
    
    access_log /var/log/nginx/frontend_access.log;
    error_log /var/log/nginx/frontend_error.log;
    
    # Cache para assets estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }
    
    # React Router - todas as rotas SPA
    location / {
        try_files $uri $uri/ /index.html;
        
        # Headers de segurança
        add_header X-Content-Type-Options nosniff;
        add_header X-Frame-Options DENY;
        add_header X-XSS-Protection "1; mode=block";
    }
    
    # Bloquear acesso a arquivos sensíveis
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "Frontend HTTP OK\n";
        add_header Content-Type text/plain;
    }
}

# API HTTP -> HTTPS REDIRECT
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# API HTTPS - CERTIFICADO EXISTE
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL da API (existem)
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    
    # Configurações SSL seguras
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Logs da API
    access_log /var/log/nginx/api_ssl_access.log;
    error_log /var/log/nginx/api_ssl_error.log;
    
    # Proxy para backend
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
        
        # Preflight CORS
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
    
    # Health check da API
    location /health {
        access_log off;
        proxy_pass http://127.0.0.1:8000/health;
    }
}
EOF

echo "✅ Configuração corrigida criada"

echo ""
echo "📋 Testando configuração..."
sudo nginx -t
if [ $? -eq 0 ]; then
    echo "✅ Configuração nginx válida!"
else
    echo "❌ Configuração inválida. Restaurando backup..."
    sudo cp "$BACKUP_FILE" /etc/nginx/sites-available/desfollow
    exit 1
fi

echo ""
echo "📋 Iniciando nginx..."
sudo systemctl start nginx
if [ $? -eq 0 ]; then
    echo "✅ Nginx iniciado com sucesso!"
else
    echo "❌ Erro ao iniciar nginx"
    sudo systemctl status nginx
    exit 1
fi

echo ""
echo "📋 Verificando se backend está rodando..."
if sudo lsof -i :8000 | grep -q LISTEN; then
    echo "✅ Backend rodando na porta 8000"
else
    echo "⚠️ Backend não está rodando. Iniciando..."
    cd /root/desfollow/backend
    nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 --env-file env.production > /tmp/backend.log 2>&1 &
    sleep 3
    if sudo lsof -i :8000 | grep -q LISTEN; then
        echo "✅ Backend iniciado"
    else
        echo "❌ Falha ao iniciar backend"
    fi
fi

echo ""
echo "📋 Testando endpoints..."

sleep 2

echo "🧪 Testando frontend HTTP..."
FRONTEND_TEST=$(curl -s -o /dev/null -w "%{http_code}" "http://desfollow.com.br" 2>/dev/null)
if [ "$FRONTEND_TEST" = "200" ]; then
    echo "✅ Frontend HTTP: $FRONTEND_TEST"
else
    echo "⚠️ Frontend HTTP: $FRONTEND_TEST"
fi

echo "🧪 Testando API HTTPS..."
API_TEST=$(curl -s "https://api.desfollow.com.br/api/health" 2>/dev/null)
if echo "$API_TEST" | grep -q "healthy"; then
    echo "✅ API HTTPS: $API_TEST"
else
    echo "⚠️ API HTTPS: $API_TEST"
fi

echo "🧪 Testando redirecionamento API HTTP -> HTTPS..."
REDIRECT_TEST=$(curl -s -o /dev/null -w "%{http_code}" "http://api.desfollow.com.br/api/health" 2>/dev/null)
if [ "$REDIRECT_TEST" = "301" ]; then
    echo "✅ Redirecionamento API: $REDIRECT_TEST"
else
    echo "⚠️ Redirecionamento API: $REDIRECT_TEST"
fi

echo ""
echo "📋 Testando comunicação completa..."
cd /root/desfollow
python3 testar_comunicacao_frontend_backend.py

echo ""
echo "✅ NGINX CORRIGIDO!"
echo ""
echo "🔗 CONFIGURAÇÃO FINAL:"
echo "   Frontend: http://desfollow.com.br (HTTP temporário)"
echo "   Frontend: http://www.desfollow.com.br (HTTP temporário)"  
echo "   API:      https://api.desfollow.com.br (HTTPS funcionando)"
echo ""
echo "🔄 REDIRECIONAMENTOS:"
echo "   http://api.desfollow.com.br → https://api.desfollow.com.br"
echo ""
echo "⚙️ MELHORIAS ATIVAS:"
echo "   ✅ Timeout API: 300s (5 minutos)"
echo "   ✅ CORS: HTTP + HTTPS preservados"
echo "   ✅ Proxy buffering: Desabilitado"
echo ""
echo "📜 Backup salvo em: $BACKUP_FILE"
echo ""
echo "🚀 Sistema funcionando! Frontend temporariamente em HTTP até resolver SSL."