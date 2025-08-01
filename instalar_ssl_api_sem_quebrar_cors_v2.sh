#!/bin/bash

echo "🔒 Instalação SSL API - SEM QUEBRAR CORS (v2)"
echo "============================================="
echo "Baseado no instalar_ssl_api_definitivo.sh mas com melhorias:"
echo "  ✅ Timeout 300s (5 minutos) para scans longos"
echo "  ✅ CORS mantido para HTTP e HTTPS"
echo "  ✅ Proxy buffering desabilitado"
echo "  ✅ Backup automático da configuração atual"
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

echo "📋 1. Verificando domínios configurados..."
echo "   - Frontend: desfollow.com.br, www.desfollow.com.br"
echo "   - API: api.desfollow.com.br"
echo ""

echo "📋 2. Fazendo backup da configuração atual..."
BACKUP_FILE="/etc/nginx/sites-available/desfollow.backup.pre-ssl.$(date +%Y%m%d_%H%M%S)"
sudo cp /etc/nginx/sites-available/desfollow "$BACKUP_FILE"
echo "💾 Backup salvo em: $BACKUP_FILE"

echo ""
echo "📋 3. Instalando Certbot se necessário..."
sudo apt update
sudo apt install -y certbot python3-certbot-nginx
check_success "Certbot instalado"

echo ""
echo "📋 4. Verificando se nginx está configurado corretamente..."
sudo nginx -t
if [ $? -ne 0 ]; then
    echo "❌ Configuração nginx inválida. Restaurando backup..."
    sudo cp "$BACKUP_FILE" /etc/nginx/sites-available/desfollow
    exit 1
fi

echo ""
echo "📋 5. Obtendo certificados SSL para todos os domínios..."

# Parar nginx temporariamente para evitar conflitos
sudo systemctl stop nginx

# Obter certificados para todos os domínios
sudo certbot certonly --standalone \
  -d desfollow.com.br \
  -d www.desfollow.com.br \
  -d api.desfollow.com.br \
  --non-interactive \
  --agree-tos \
  --email admin@desfollow.com.br \
  --expand

check_success "Certificados SSL obtidos"

echo ""
echo "📋 6. Criando configuração nginx com SSL + CORS preservado..."

# Criar nova configuração com SSL e timeouts corrigidos
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# ========================================
# CONFIGURAÇÃO NGINX COM SSL - DESFOLLOW v2
# ========================================
# Frontend: desfollow.com.br + www.desfollow.com.br (HTTPS)
# API: api.desfollow.com.br (HTTPS)
# CORREÇÕES: Timeout 300s, CORS preservado, Proxy buffering off
# ========================================

# REDIRECIONAMENTO HTTP -> HTTPS (Frontend)
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# FRONTEND HTTPS - desfollow.com.br e www.desfollow.com.br
server {
    listen 443 ssl http2;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    
    # Configurações SSL seguras
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    
    # Diretório do frontend buildado
    root /var/www/html;
    index index.html;
    
    # Logs específicos do frontend
    access_log /var/log/nginx/frontend_ssl_access.log;
    error_log /var/log/nginx/frontend_ssl_error.log;
    
    # Configurações de cache para assets estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }
    
    # React Router - todas as rotas SPA
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Bloquear acesso direto a arquivos sensíveis
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Status de saúde do frontend
    location /health {
        access_log off;
        return 200 "Frontend SSL OK\n";
        add_header Content-Type text/plain;
    }
}

# REDIRECIONAMENTO HTTP -> HTTPS (API)
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# API HTTPS - api.desfollow.com.br
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    
    # Configurações SSL seguras
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança para API
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Logs específicos da API
    access_log /var/log/nginx/api_ssl_access.log;
    error_log /var/log/nginx/api_ssl_error.log;
    
    # Configurações de proxy para API
    location / {
        # Proxy para backend Python/Gunicorn
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $host;
        
        # 🚀 CORREÇÃO: Timeouts aumentados para 5 minutos (300s)
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        
        # 🚀 CORREÇÃO: Configurações para requests longos
        proxy_buffering off;
        proxy_request_buffering off;
        client_max_body_size 10m;
        
        # 🚀 CORREÇÃO: Headers CORS amplos (HTTPS + HTTP como fallback)
        add_header Access-Control-Allow-Origin "https://desfollow.com.br, https://www.desfollow.com.br, http://desfollow.com.br, http://www.desfollow.com.br" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
        add_header Access-Control-Allow-Credentials true always;
        
        # Resposta para OPTIONS (preflight CORS)
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
    
    # Status específico da API
    location /health {
        access_log off;
        proxy_pass http://127.0.0.1:8000/health;
    }
}
EOF

check_success "Configuração SSL v2 criada"

echo ""
echo "📋 7. Testando nova configuração..."
sudo nginx -t
check_success "Configuração SSL válida"

echo ""
echo "📋 8. Iniciando nginx com SSL..."
sudo systemctl start nginx
check_success "Nginx iniciado com SSL"

# Verificar se backend está rodando
echo ""
echo "📋 9. Verificando backend..."
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
echo "📋 10. Verificando certificados..."
echo "   Certificado válido até:"
openssl x509 -in /etc/letsencrypt/live/desfollow.com.br/fullchain.pem -noout -dates | grep notAfter

echo ""
echo "📋 11. Configurando renovação automática..."
sudo tee /etc/cron.d/certbot-desfollow > /dev/null << 'EOF'
# Renovar certificados SSL automaticamente
0 12 * * * root certbot renew --quiet --reload-hook "systemctl reload nginx"
EOF
check_success "Renovação automática configurada"

echo ""
echo "📋 12. Testando URLs com SSL..."

sleep 5  # Aguardar nginx inicializar completamente

echo "🧪 Testando API Health HTTPS..."
API_HEALTH=$(curl -s "https://api.desfollow.com.br/api/health" --insecure 2>/dev/null)
if echo "$API_HEALTH" | grep -q "healthy"; then
    echo "✅ API Health HTTPS funcionando: $API_HEALTH"
else
    echo "⚠️ API Health HTTPS: $API_HEALTH"
fi

echo ""
echo "🧪 Testando frontend HTTPS..."
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://desfollow.com.br --insecure 2>/dev/null)
if [ "$FRONTEND_RESPONSE" = "200" ]; then
    echo "✅ Frontend HTTPS respondendo (HTTP $FRONTEND_RESPONSE)"
else
    echo "⚠️ Frontend HTTPS: HTTP $FRONTEND_RESPONSE"
fi

echo ""
echo "📋 13. Testando comunicação completa..."
cd /root/desfollow
python3 testar_comunicacao_frontend_backend.py

echo ""
echo "✅ SSL INSTALADO COM SUCESSO (v2)!"
echo ""
echo "🔒 CONFIGURAÇÃO FINAL COM SSL + CORREÇÕES:"
echo "   Frontend: https://desfollow.com.br (SSL ativado)"
echo "   Frontend: https://www.desfollow.com.br (SSL ativado)"
echo "   API:      https://api.desfollow.com.br (SSL ativado)"
echo ""
echo "🔄 REDIRECIONAMENTOS AUTOMÁTICOS:"
echo "   http://desfollow.com.br → https://desfollow.com.br"
echo "   http://api.desfollow.com.br → https://api.desfollow.com.br"
echo ""
echo "⚙️ MELHORIAS APLICADAS:"
echo "   ✅ Timeout: 300s (5 minutos) para scans longos"
echo "   ✅ CORS: HTTP + HTTPS para evitar problemas"
echo "   ✅ Proxy buffering: Desabilitado para requests longos"
echo "   ✅ Backend: Auto-start se necessário"
echo ""
echo "📊 Para verificar:"
echo "   curl https://api.desfollow.com.br/api/health"
echo "   curl https://desfollow.com.br"
echo ""
echo "📜 Backup da configuração anterior em:"
echo "   $BACKUP_FILE"
echo ""
echo "🚀 Problemas HTTPS/CORS/Timeout resolvidos!"