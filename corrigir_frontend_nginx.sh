#!/bin/bash

echo "🔧 Corrigindo Frontend - Nginx..."
echo "================================"
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

echo "📋 1. Diagnóstico atual..."
echo "🔍 Verificando configuração do Nginx:"

# Verificar configuração atual
if nginx -t > /dev/null 2>&1; then
    echo "✅ Sintaxe do Nginx está OK"
else
    echo "❌ Problemas na configuração do Nginx"
    nginx -t
fi

echo ""
echo "🔍 Verificando se frontend existe em /var/www/desfollow:"
if [ -f "/var/www/desfollow/index.html" ]; then
    echo "✅ Frontend existe em /var/www/desfollow/"
    ls -la /var/www/desfollow/ | head -5
else
    echo "❌ Frontend NÃO existe em /var/www/desfollow/"
fi

echo ""
echo "🔍 Verificando resposta atual dos domínios:"
echo "📊 desfollow.com.br:"
curl -s http://desfollow.com.br/ | head -3
echo ""
echo "📊 www.desfollow.com.br:"
curl -s http://www.desfollow.com.br/ | head -3

echo ""
echo "📋 2. Atualizando código e fazendo build..."
cd /root/desfollow
git pull origin main
check_success "Código atualizado"

# Verificar se npm está disponível
if ! command -v npm &> /dev/null; then
    echo "❌ npm não encontrado! Instalando Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    apt-get install -y nodejs
    check_success "Node.js instalado"
fi

# Instalar dependências e fazer build
echo "📦 Instalando dependências..."
npm install
check_success "Dependências instaladas"

echo "🏗️ Fazendo build do frontend..."
npm run build
check_success "Build concluído"

echo ""
echo "📋 3. Copiando frontend para local correto..."

# Criar diretório se não existir
mkdir -p /var/www/desfollow

# Limpar diretório anterior e copiar novo
rm -rf /var/www/desfollow/*
cp -r dist/* /var/www/desfollow/
check_success "Arquivos copiados"

# Definir permissões
chown -R www-data:www-data /var/www/desfollow
chmod -R 755 /var/www/desfollow
check_success "Permissões definidas"

echo ""
echo "📋 4. Criando configuração corrigida do Nginx..."

# Fazer backup da configuração atual
cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null

# Criar nova configuração que separa claramente frontend e API
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Configuração Nginx para Desfollow - Frontend e API Separados

# Frontend (desfollow.com.br e www.desfollow.com.br)
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

    # Logs específicos do frontend
    access_log /var/log/nginx/desfollow_frontend_access.log;
    error_log /var/log/nginx/desfollow_frontend_error.log;
}

# API (api.desfollow.com.br) - mantém separado
server {
    listen 80;
    server_name api.desfollow.com.br;

    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

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
    access_log /var/log/nginx/desfollow_api_access.log;
    error_log /var/log/nginx/desfollow_api_error.log;
}
EOF

check_success "Configuração criada"

echo ""
echo "📋 5. Aplicando nova configuração..."

# Verificar sintaxe
nginx -t
check_success "Sintaxe do Nginx verificada"

# Recarregar Nginx
systemctl reload nginx
check_success "Nginx recarregado"

echo ""
echo "📋 6. Verificando resultado..."

# Aguardar um pouco para aplicar mudanças
sleep 3

echo "🔍 Testando domínios após correção:"
echo ""
echo "📊 http://desfollow.com.br/ (deve mostrar frontend):"
FRONTEND_RESPONSE=$(curl -s http://desfollow.com.br/ | head -1)
echo "$FRONTEND_RESPONSE"

if echo "$FRONTEND_RESPONSE" | grep -q "DOCTYPE\|html"; then
    echo "✅ Frontend carregando corretamente!"
else
    echo "⚠️ Ainda retornando API"
fi

echo ""
echo "📊 http://api.desfollow.com.br/ (deve mostrar API):"
API_RESPONSE=$(curl -s http://api.desfollow.com.br/ | head -1)
echo "$API_RESPONSE"

if echo "$API_RESPONSE" | grep -q "Desfollow API"; then
    echo "✅ API funcionando corretamente!"
else
    echo "⚠️ API pode ter problemas"
fi

echo ""
echo "📋 7. Verificação de arquivos do frontend..."
echo "📁 Arquivos em /var/www/desfollow/:"
ls -la /var/www/desfollow/ | head -5

echo ""
echo "✅ CORREÇÃO CONCLUÍDA!"
echo ""
echo "📊 Resultado esperado:"
echo "   - http://desfollow.com.br/ → Frontend React"
echo "   - http://www.desfollow.com.br/ → Frontend React"  
echo "   - http://api.desfollow.com.br/ → API JSON"
echo ""
echo "🔍 Para verificar:"
echo "   curl -s http://desfollow.com.br/ | head -5"
echo "   curl -s http://api.desfollow.com.br/ | head -5" 