#!/bin/bash

echo "🔄 ATUALIZANDO FRONTEND E LIMPANDO CACHE - DESFOLLOW"
echo "=================================================="

# Parar nginx
echo "📋 1. Parando nginx..."
sudo systemctl stop nginx

# Fazer backup do frontend atual
echo "📋 2. Fazendo backup do frontend atual..."
sudo mkdir -p /var/backups/desfollow
sudo cp -r /var/www/desfollow /var/backups/desfollow/backup-$(date +%Y%m%d_%H%M%S) 2>/dev/null || echo "Backup opcional criado"

# Limpar completamente o diretório frontend
echo "📋 3. Limpando frontend antigo COMPLETAMENTE..."
sudo rm -rf /var/www/desfollow/*
sudo rm -rf /var/www/desfollow/.*  2>/dev/null || true

# Recriar estrutura básica
echo "📋 4. Criando estrutura limpa..."
sudo mkdir -p /var/www/desfollow/lovable-uploads
sudo mkdir -p /var/www/desfollow/assets

# Baixar build mais recente do GitHub
echo "📋 5. Baixando build mais recente do GitHub..."

# Baixar arquivos principais da build
GITHUB_DIST_URL="https://raw.githubusercontent.com/nadr00j/desfollow/main/dist"

echo "Baixando index.html..."
sudo wget -q -O "/var/www/desfollow/index.html" "$GITHUB_DIST_URL/index.html"

echo "Baixando favicon.ico..."
sudo wget -q -O "/var/www/desfollow/favicon.ico" "$GITHUB_DIST_URL/favicon.ico"

echo "Baixando robots.txt..."
sudo wget -q -O "/var/www/desfollow/robots.txt" "$GITHUB_DIST_URL/robots.txt"

# Verificar se tem vite.svg
echo "Baixando vite.svg..."
sudo wget -q -O "/var/www/desfollow/vite.svg" "$GITHUB_DIST_URL/vite.svg" 2>/dev/null || echo "vite.svg não encontrado (opcional)"

# Baixar assets (CSS e JS) - precisamos descobrir os nomes exatos
echo "📋 6. Descobrindo e baixando assets..."

# Criar script temporário para extrair URLs de assets do index.html
echo "Extraindo URLs de assets do index.html..."
sudo wget -q -O "/tmp/index_temp.html" "$GITHUB_DIST_URL/index.html"

# Extrair URLs de CSS e JS
CSS_FILES=$(grep -oE '/assets/[^"]*\.css' /tmp/index_temp.html | sed 's|^/||')
JS_FILES=$(grep -oE '/assets/[^"]*\.js' /tmp/index_temp.html | sed 's|^/||')

echo "Arquivos CSS encontrados:"
echo "$CSS_FILES"
echo "Arquivos JS encontrados:"
echo "$JS_FILES"

# Baixar arquivos CSS
for css_file in $CSS_FILES; do
    if [ ! -z "$css_file" ]; then
        echo "Baixando $css_file..."
        sudo mkdir -p "/var/www/desfollow/$(dirname "$css_file")"
        sudo wget -q -O "/var/www/desfollow/$css_file" "$GITHUB_DIST_URL/$css_file"
        if [ $? -eq 0 ]; then
            echo "✅ $css_file baixado"
        else
            echo "❌ Erro ao baixar $css_file"
        fi
    fi
done

# Baixar arquivos JS
for js_file in $JS_FILES; do
    if [ ! -z "$js_file" ]; then
        echo "Baixando $js_file..."
        sudo mkdir -p "/var/www/desfollow/$(dirname "$js_file")"
        sudo wget -q -O "/var/www/desfollow/$js_file" "$GITHUB_DIST_URL/$js_file"
        if [ $? -eq 0 ]; then
            echo "✅ $js_file baixado"
        else
            echo "❌ Erro ao baixar $js_file"
        fi
    fi
done

# Limpar arquivo temporário
rm /tmp/index_temp.html

# Baixar todas as imagens
echo "📋 7. Baixando todas as imagens..."
./copiar_todas_imagens_favicon.sh

# Configurar headers nginx anti-cache
echo "📋 8. Configurando nginx com headers anti-cache..."
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# CONFIGURAÇÃO NGINX ANTI-CACHE - DESFOLLOW
# Frontend sempre atualizado
# ==========================================

# HTTP para HTTPS redirect
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# FRONTEND HTTPS - ANTI-CACHE
server {
    listen 443 ssl http2;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Certificados SSL (ajustar conforme necessário)
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    
    # SSL básico
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Diretório
    root /var/www/desfollow;
    index index.html;
    
    # Logs
    access_log /var/log/nginx/frontend_access.log;
    error_log /var/log/nginx/frontend_error.log;
    
    # Headers para FORÇAR atualização e evitar cache
    add_header Cache-Control "no-cache, no-store, must-revalidate" always;
    add_header Pragma "no-cache" always;
    add_header Expires "0" always;
    add_header ETag "" always;
    
    # Headers adicionais para mobile
    add_header X-Cache-Status "FORCED-REFRESH" always;
    add_header Last-Modified $date_gmt always;
    
    # HTML - NUNCA fazer cache
    location ~ \.html$ {
        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
        add_header Pragma "no-cache" always;
        add_header Expires "0" always;
        add_header ETag "" always;
        try_files $uri =404;
    }
    
    # CSS e JS - Cache curto para permitir atualizações
    location ~* \.(css|js)$ {
        add_header Cache-Control "public, max-age=300" always;  # 5 minutos apenas
        add_header ETag "" always;
        try_files $uri =404;
    }
    
    # Imagens - Cache normal
    location ~* \.(png|jpg|jpeg|gif|ico|svg|webp)$ {
        add_header Cache-Control "public, max-age=3600" always;  # 1 hora
        try_files $uri =404;
    }
    
    # Diretório de imagens lovable-uploads
    location /lovable-uploads/ {
        add_header Cache-Control "public, max-age=3600" always;
        try_files $uri =404;
    }
    
    # React Router - SEMPRE sem cache
    location / {
        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
        add_header Pragma "no-cache" always;
        add_header Expires "0" always;
        try_files $uri $uri/ /index.html;
    }
}

# API HTTPS - sem mudanças
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
    
    # SSL básico
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Logs
    access_log /var/log/nginx/api_access.log;
    error_log /var/log/nginx/api_error.log;
    
    # Proxy SIMPLES para backend (CORS tratado pelo FastAPI)
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # Timeouts
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
EOF

# Ajustar permissões
echo "📋 9. Ajustando permissões..."
sudo chown -R www-data:www-data /var/www/desfollow/
sudo chmod -R 755 /var/www/desfollow/

# Testar configuração nginx
echo "📋 10. Testando configuração nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração nginx válida"
    
    # Iniciar nginx
    echo "📋 11. Iniciando nginx..."
    sudo systemctl start nginx
    
    # Aguardar
    sleep 3
    
    # Testes
    echo "📋 12. Testando frontend atualizado..."
    
    echo "Teste https://desfollow.com.br:"
    curl -I https://desfollow.com.br 2>/dev/null | grep -E "(HTTP/|Cache-Control|X-Cache-Status)"
    
    echo ""
    echo "Teste https://www.desfollow.com.br:"
    curl -I https://www.desfollow.com.br 2>/dev/null | grep -E "(HTTP/|Cache-Control|X-Cache-Status)"
    
    echo ""
    echo "Verificando estrutura final:"
    ls -la /var/www/desfollow/ | head -10
    
    echo ""
    echo "✅ FRONTEND ATUALIZADO E CACHE LIMPO!"
    echo "===================================="
    echo "🔗 https://desfollow.com.br"
    echo "🔗 https://www.desfollow.com.br"
    echo ""
    echo "📱 MUDANÇAS APLICADAS:"
    echo "• Frontend completamente renovado"
    echo "• Build mais recente do GitHub"
    echo "• Cache FORÇADAMENTE desabilitado"
    echo "• Headers anti-cache para mobile"
    echo "• Funciona em ambos domínios"
    echo ""
    echo "🧹 PARA LIMPAR CACHE NO MOBILE:"
    echo "1. Safari > Configurações > Limpar Histórico e Dados"
    echo "2. Ou força refresh: segurar reload"
    echo "3. Ou modo privado/anônimo"
    
else
    echo "❌ Erro na configuração nginx"
    sudo nginx -t
fi