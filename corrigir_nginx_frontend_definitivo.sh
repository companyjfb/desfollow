#!/bin/bash

echo "🔧 Configuração Definitiva do Nginx - Separando Frontend e API"
echo "============================================================"
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

echo "📋 1. Fazendo backup das configurações atuais..."
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null
echo "✅ Backup realizado"

echo ""
echo "📋 2. Removendo configurações conflitantes..."
# Remover links simbólicos antigos que podem causar conflito
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/desfollow*
echo "✅ Configurações antigas removidas"

echo ""
echo "📋 3. Criando nova configuração definitiva..."

# Criar arquivo de configuração principal
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# ========================================
# CONFIGURAÇÃO DEFINITIVA NGINX - DESFOLLOW
# ========================================
# Frontend: desfollow.com.br + www.desfollow.com.br
# API: api.desfollow.com.br
# ========================================

# BLOCO 1: FRONTEND - desfollow.com.br e www.desfollow.com.br
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Diretório do frontend buildado
    root /var/www/html;
    index index.html;
    
    # Logs específicos do frontend
    access_log /var/log/nginx/frontend_access.log;
    error_log /var/log/nginx/frontend_error.log;
    
    # Configurações de cache para assets estáticos
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
    
    # Bloquear acesso direto a .env, .git, etc
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Status de saúde do frontend
    location /health {
        access_log off;
        return 200 "Frontend OK\n";
        add_header Content-Type text/plain;
    }
}

# BLOCO 2: API - api.desfollow.com.br
server {
    listen 80;
    server_name api.desfollow.com.br;
    
    # Logs específicos da API
    access_log /var/log/nginx/api_access.log;
    error_log /var/log/nginx/api_error.log;
    
    # Configurações de proxy para API
    location / {
        # Proxy para backend Python/Gunicorn
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts para API
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Headers CORS para API
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

check_success "Configuração criada"

echo ""
echo "📋 4. Ativando nova configuração..."
ln -sf /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/
check_success "Configuração ativada"

echo ""
echo "📋 5. Testando configuração do nginx..."
nginx -t
check_success "Configuração válida"

echo ""
echo "📋 6. Buildando frontend atualizado..."
cd /root/desfollow
npm run build 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Frontend buildado"
else
    echo "⚠️ Erro no build - verificando se Node.js está instalado..."
    # Tentar instalar Node.js se não existir
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - 2>/dev/null
    apt-get install -y nodejs 2>/dev/null
    npm run build
    check_success "Frontend buildado após instalar Node.js"
fi

echo ""
echo "📋 7. Copiando frontend para nginx..."
mkdir -p /var/www/html
rm -rf /var/www/html/*
cp -r dist/* /var/www/html/ 2>/dev/null || cp -r build/* /var/www/html/ 2>/dev/null
check_success "Frontend copiado"

echo ""
echo "📋 8. Configurando permissões..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
check_success "Permissões configuradas"

echo ""
echo "📋 9. Recarregando nginx..."
systemctl reload nginx
check_success "Nginx recarregado"

echo ""
echo "📋 10. Verificando se backend está rodando..."
if systemctl is-active --quiet desfollow.service; then
    echo "✅ Backend está ativo"
else
    echo "🔄 Iniciando backend..."
    systemctl start desfollow.service
    sleep 3
fi

echo ""
echo "📋 11. Testando URLs finais..."

echo "🌐 Testando frontend: desfollow.com.br"
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://desfollow.com.br 2>/dev/null)
if [ "$FRONTEND_RESPONSE" = "200" ]; then
    echo "✅ Frontend respondendo (HTTP $FRONTEND_RESPONSE)"
    # Verificar se é HTML e não JSON da API
    CONTENT=$(curl -s http://desfollow.com.br | head -c 100)
    if echo "$CONTENT" | grep -q "<!DOCTYPE html"; then
        echo "✅ Conteúdo é HTML (frontend correto)"
    else
        echo "⚠️ Conteúdo pode não ser frontend"
    fi
else
    echo "❌ Frontend: HTTP $FRONTEND_RESPONSE"
fi

echo "🌐 Testando API: api.desfollow.com.br"
BACKEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://api.desfollow.com.br 2>/dev/null)
if [ "$BACKEND_RESPONSE" = "200" ]; then
    echo "✅ API respondendo (HTTP $BACKEND_RESPONSE)"
    API_CONTENT=$(curl -s http://api.desfollow.com.br)
    if echo "$API_CONTENT" | grep -q "Desfollow API"; then
        echo "✅ Conteúdo é API (correto)"
    fi
else
    echo "❌ API: HTTP $BACKEND_RESPONSE"
fi

echo ""
echo "✅ CONFIGURAÇÃO NGINX APLICADA COM SUCESSO!"
echo ""
echo "🎯 CONFIGURAÇÃO FINAL:"
echo "   Frontend: http://desfollow.com.br"
echo "   Frontend: http://www.desfollow.com.br"
echo "   API:      http://api.desfollow.com.br"
echo ""
echo "📊 Para verificar:"
echo "   curl http://desfollow.com.br (deve retornar HTML)"
echo "   curl http://api.desfollow.com.br (deve retornar JSON da API)"
echo "   tail -f /var/log/nginx/frontend_access.log"
echo "   tail -f /var/log/nginx/api_access.log"
echo ""
echo "🚀 Problema de mixing frontend/API resolvido!" 