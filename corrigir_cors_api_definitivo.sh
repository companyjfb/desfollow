#!/bin/bash

echo "🔧 CORRIGINDO CORS DA API DEFINITIVAMENTE - DESFOLLOW"
echo "===================================================="

# Parar nginx
echo "📋 1. Parando nginx..."
sudo systemctl stop nginx

# Criar configuração nginx focada APENAS no CORS
echo "📋 2. Aplicando configuração nginx CORS DEFINITIVA..."
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# CONFIGURAÇÃO NGINX CORS DEFINITIVA - DESFOLLOW
# Usando SSL da Hostinger
# ===============================================

# HTTP para HTTPS redirect
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# FRONTEND HTTPS - SSL da Hostinger
server {
    listen 443 ssl http2;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Certificados SSL da Hostinger (devem estar no caminho correto)
    ssl_certificate /etc/ssl/certs/desfollow.com.br.crt;
    ssl_certificate_key /etc/ssl/private/desfollow.com.br.key;
    
    # SSL básico
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Diretório
    root /var/www/desfollow;
    index index.html;
    
    # Logs
    access_log /var/log/nginx/frontend_access.log;
    error_log /var/log/nginx/frontend_error.log;
    
    # Servir arquivos
    location / {
        try_files $uri $uri/ /index.html;
    }
}

# API HTTPS - CORS TOTAL
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL da API (Hostinger)
    ssl_certificate /etc/ssl/certs/api.desfollow.com.br.crt;
    ssl_certificate_key /etc/ssl/private/api.desfollow.com.br.key;
    
    # SSL básico
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Logs
    access_log /var/log/nginx/api_access.log;
    error_log /var/log/nginx/api_error.log;
    
    # CORS GLOBAL para toda a API
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Origin, X-Requested-With, Content-Type, Accept, Authorization, Cache-Control, Pragma' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    add_header 'Access-Control-Max-Age' '86400' always;
    
    # Handle ALL preflight requests
    location / {
        # Preflight request
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'Origin, X-Requested-With, Content-Type, Accept, Authorization, Cache-Control, Pragma' always;
            add_header 'Access-Control-Allow-Credentials' 'true' always;
            add_header 'Access-Control-Max-Age' '86400' always;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
        
        # Proxy para backend Python
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
        
        # IMPORTANTE: Esconder headers CORS do backend para evitar duplicação
        proxy_hide_header 'Access-Control-Allow-Origin';
        proxy_hide_header 'Access-Control-Allow-Methods';
        proxy_hide_header 'Access-Control-Allow-Headers';
        proxy_hide_header 'Access-Control-Allow-Credentials';
    }
}
EOF

# Verificar se os certificados da Hostinger existem
echo "📋 3. Verificando certificados SSL da Hostinger..."
if [ -f "/etc/ssl/certs/desfollow.com.br.crt" ]; then
    echo "✅ Certificado frontend encontrado"
else
    echo "⚠️ Certificado frontend não encontrado em /etc/ssl/certs/desfollow.com.br.crt"
    echo "Verificando outros locais possíveis..."
    
    # Verificar locais alternativos
    find /etc -name "*desfollow*" -type f 2>/dev/null | head -5
    find /etc -name "*.crt" -type f 2>/dev/null | grep -i desfollow | head -3
    
    # Se não encontrar, usar configuração sem SSL específico
    echo "Usando configuração genérica..."
    sudo sed -i 's|ssl_certificate.*|ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;|' /etc/nginx/sites-available/desfollow
    sudo sed -i 's|ssl_certificate_key.*|ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;|' /etc/nginx/sites-available/desfollow
fi

if [ -f "/etc/ssl/certs/api.desfollow.com.br.crt" ]; then
    echo "✅ Certificado API encontrado"
else
    echo "⚠️ Certificado API não encontrado, usando Let's Encrypt..."
    sudo sed -i 's|ssl_certificate /etc/ssl/certs/api.desfollow.com.br.crt;|ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;|' /etc/nginx/sites-available/desfollow
    sudo sed -i 's|ssl_certificate_key /etc/ssl/private/api.desfollow.com.br.key;|ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;|' /etc/nginx/sites-available/desfollow
fi

# Testar configuração
echo "📋 4. Testando configuração nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração nginx válida"
    
    # Iniciar nginx
    echo "📋 5. Iniciando nginx..."
    sudo systemctl start nginx
    
    # Aguardar
    sleep 3
    
    # Testes específicos de CORS
    echo "📋 6. Testando CORS..."
    
    echo "Teste OPTIONS (preflight) para /api/scan:"
    curl -X OPTIONS \
         -H "Origin: https://www.desfollow.com.br" \
         -H "Access-Control-Request-Method: POST" \
         -H "Access-Control-Request-Headers: Content-Type" \
         -v \
         https://api.desfollow.com.br/api/scan 2>&1 | grep -i "access-control\|< HTTP"
    
    echo ""
    echo "Teste GET simples:"
    curl -H "Origin: https://www.desfollow.com.br" \
         -v \
         https://api.desfollow.com.br/api/status 2>&1 | grep -i "access-control\|< HTTP"
    
    echo ""
    echo "✅ CORREÇÃO CORS DEFINITIVA APLICADA!"
    echo "===================================="
    echo "🔗 Frontend: https://desfollow.com.br"
    echo "🔗 API: https://api.desfollow.com.br"
    echo ""
    echo "📱 CORS CONFIGURADO:"
    echo "• Access-Control-Allow-Origin: * (permite qualquer origem)"
    echo "• Métodos: GET, POST, PUT, DELETE, OPTIONS"
    echo "• Headers: todos os necessários"
    echo "• Preflight requests tratados corretamente"
    echo "• Headers do backend escondidos (evita duplicação)"
    
else
    echo "❌ Erro na configuração nginx"
    sudo nginx -t
fi

echo ""
echo "📋 7. Se ainda houver problema CORS:"
echo "1. Verifique se o backend Python também tem CORS configurado"
echo "2. Teste no browser dev tools se os headers estão aparecendo"
echo "3. Limpe cache do browser e teste novamente"