#!/bin/bash

# Script para corrigir problema de CORS no Desfollow (Versão 3)
# Versão simplificada - apenas HTTP por enquanto

echo "🔧 Corrigindo problema de CORS no Desfollow (v3)..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERRO] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[AVISO] $1${NC}"
}

# Verifica se está rodando como root
if [ "$EUID" -ne 0 ]; then
    error "Execute este script como root (sudo)"
    exit 1
fi

log "📋 Verificando configuração atual..."

# Backup da configuração atual
if [ -f "/etc/nginx/sites-available/desfollow" ]; then
    log "💾 Fazendo backup da configuração atual..."
    cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.$(date +%Y%m%d_%H%M%S)
fi

log "🌐 Aplicando nova configuração do Nginx..."

# Aplica a configuração simplificada (apenas HTTP)
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Configuração simplificada do Nginx para Desfollow
# Frontend: desfollow.com.br
# Backend: api.desfollow.com.br

# Configuração para o frontend (desfollow.com.br)
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;

    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Configuração para servir arquivos estáticos do frontend
    root /var/www/desfollow;
    index index.html;

    # Configuração para SPA (Single Page Application)
    location / {
        try_files $uri $uri/ /index.html;
        
        # Headers para cache de arquivos estáticos
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Configuração para API (proxy para o backend)
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Headers CORS específicos para o frontend
        add_header Access-Control-Allow-Origin "https://desfollow.com.br" always;
        add_header Access-Control-Allow-Origin "https://www.desfollow.com.br" always;
        add_header Access-Control-Allow-Origin "http://desfollow.com.br" always;
        add_header Access-Control-Allow-Origin "http://www.desfollow.com.br" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With" always;
        add_header Access-Control-Allow-Credentials "true" always;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Configuração específica para autenticação
    location /api/auth/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Headers CORS específicos para o frontend
        add_header Access-Control-Allow-Origin "https://desfollow.com.br" always;
        add_header Access-Control-Allow-Origin "https://www.desfollow.com.br" always;
        add_header Access-Control-Allow-Origin "http://desfollow.com.br" always;
        add_header Access-Control-Allow-Origin "http://www.desfollow.com.br" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With" always;
        add_header Access-Control-Allow-Credentials "true" always;
    }

    # Logs
    access_log /var/log/nginx/desfollow_frontend_access.log;
    error_log /var/log/nginx/desfollow_frontend_error.log;
}

# Configuração para o backend (api.desfollow.com.br)
server {
    listen 80;
    server_name api.desfollow.com.br;

    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Configuração da API
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Headers CORS para o backend
        add_header Access-Control-Allow-Origin "https://desfollow.com.br" always;
        add_header Access-Control-Allow-Origin "https://www.desfollow.com.br" always;
        add_header Access-Control-Allow-Origin "http://desfollow.com.br" always;
        add_header Access-Control-Allow-Origin "http://www.desfollow.com.br" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With" always;
        add_header Access-Control-Allow-Credentials "true" always;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Configuração específica para autenticação
    location /api/auth/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Headers CORS para o backend
        add_header Access-Control-Allow-Origin "https://desfollow.com.br" always;
        add_header Access-Control-Allow-Origin "https://www.desfollow.com.br" always;
        add_header Access-Control-Allow-Origin "http://desfollow.com.br" always;
        add_header Access-Control-Allow-Origin "http://www.desfollow.com.br" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With" always;
        add_header Access-Control-Allow-Credentials "true" always;
    }

    # Configuração para health check
    location /health {
        access_log off;
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
    }

    # Logs
    access_log /var/log/nginx/desfollow_api_access.log;
    error_log /var/log/nginx/desfollow_api_error.log;
}
EOF

log "🔗 Habilitando configuração do Nginx..."
ln -sf /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

log "🧪 Testando configuração do Nginx..."
nginx -t

if [ $? -eq 0 ]; then
    log "✅ Configuração do Nginx válida"
else
    error "❌ Erro na configuração do Nginx"
    log "📋 Restaurando backup..."
    backup_files=$(ls /etc/nginx/sites-available/desfollow.backup.* 2>/dev/null | head -1)
    if [ -n "$backup_files" ]; then
        cp "$backup_files" /etc/nginx/sites-available/desfollow
        nginx -t
    fi
    exit 1
fi

log "🚀 Reiniciando Nginx..."
systemctl restart nginx

if [ $? -eq 0 ]; then
    log "✅ Nginx reiniciado com sucesso"
else
    error "❌ Erro ao reiniciar Nginx"
    exit 1
fi

log "📊 Verificando status dos serviços..."

# Verificar se o Nginx está rodando
if systemctl is-active --quiet nginx; then
    log "✅ Nginx está rodando"
else
    error "❌ Nginx não está rodando"
    systemctl status nginx
fi

# Verificar se o backend está rodando
if systemctl is-active --quiet desfollow; then
    log "✅ Backend está rodando"
else
    warning "⚠️ Backend não está rodando. Iniciando..."
    systemctl start desfollow
fi

log "🔍 Testando conectividade..."

# Testar se a API está respondendo
if curl -s http://localhost:8000/ > /dev/null; then
    log "✅ Backend está respondendo localmente"
else
    warning "⚠️ Backend não está respondendo localmente"
fi

# Testar se o Nginx está respondendo
if curl -s http://localhost/ > /dev/null; then
    log "✅ Nginx está respondendo"
else
    warning "⚠️ Nginx não está respondendo"
fi

log "✅ Configuração de CORS aplicada com sucesso!"
echo ""
echo "📋 Resumo das mudanças:"
echo "1. ✅ Configuração simplificada do Nginx aplicada"
echo "2. ✅ Headers CORS configurados para desfollow.com.br"
echo "3. ✅ Proxy reverso configurado para API"
echo "4. ✅ Headers de segurança configurados"
echo ""
echo "🌐 URLs configuradas:"
echo "- Frontend: http://desfollow.com.br"
echo "- Backend: http://api.desfollow.com.br"
echo ""
echo "🔧 Próximos passos:"
echo "1. Teste a aplicação no navegador"
echo "2. Verifique se o erro de CORS foi resolvido"
echo "3. Configure SSL posteriormente se necessário"
echo "4. Monitore os logs: tail -f /var/log/nginx/desfollow_*_error.log" 