#!/bin/bash

echo "🔧 CORREÇÃO SSL SIMPLES PARA MOBILE - DESFOLLOW"
echo "==============================================="

# Parar nginx
echo "📋 1. Parando nginx..."
sudo systemctl stop nginx

# Criar configuração SSL extremamente simples e compatível
echo "📋 2. Aplicando configuração SSL SIMPLES e compatível..."
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# CONFIGURAÇÃO NGINX SSL SIMPLES - DESFOLLOW
# Máxima compatibilidade com dispositivos móveis
# =============================================

# HTTP para HTTPS redirect
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# FRONTEND HTTPS - Configuração SIMPLES
server {
    listen 443 ssl;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    
    # SSL configuração BÁSICA e COMPATÍVEL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout 5m;
    
    # Headers básicos
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    
    # Configurações básicas
    root /var/www/html;
    index index.html;
    
    # Logs
    access_log /var/log/nginx/ssl_access.log;
    error_log /var/log/nginx/ssl_error.log;
    
    # Servir todos os arquivos estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|webp)$ {
        expires 1d;
        add_header Cache-Control "public";
        try_files $uri =404;
    }
    
    # Diretório de imagens
    location /lovable-uploads/ {
        expires 1d;
        add_header Cache-Control "public";
        try_files $uri /favicon.ico;
    }
    
    # React Router
    location / {
        try_files $uri $uri/ /index.html;
    }
}

# API - Configuração SIMPLES
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name api.desfollow.com.br;
    
    # Certificados SSL da API
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    
    # SSL configuração BÁSICA
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout 5m;
    
    # Headers básicos
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    
    # Logs
    access_log /var/log/nginx/api_ssl_access.log;
    error_log /var/log/nginx/api_ssl_error.log;
    
    # Proxy para backend
    location / {
        # CORS simples
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization';
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
        
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Testar configuração
echo "📋 3. Testando configuração..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração válida"
    
    # Iniciar nginx
    echo "📋 4. Iniciando nginx..."
    sudo systemctl start nginx
    
    # Aguardar
    sleep 3
    
    # Testes específicos
    echo "📋 5. Executando testes..."
    
    echo "Teste SSL básico:"
    echo | timeout 10 openssl s_client -connect desfollow.com.br:443 -servername desfollow.com.br 2>/dev/null | grep -E "(Protocol|Cipher|Verify return code)"
    
    echo ""
    echo "Teste conectividade simples:"
    timeout 10 nc -zv desfollow.com.br 443 2>&1
    
    echo ""
    echo "Teste HTTP (deve redirecionar):"
    curl -sI http://desfollow.com.br | head -3
    
    echo ""
    echo "Verificando se imagens existem:"
    ls -la /var/www/html/lovable-uploads/ | head -5
    
    echo ""
    echo "Teste imagem específica:"
    curl -sI https://desfollow.com.br/lovable-uploads/82f11f27-4149-4c8f-b121-63897652035d.png --insecure | head -3
    
    echo ""
    echo "✅ CONFIGURAÇÃO SSL SIMPLES APLICADA!"
    echo "====================================="
    echo "🔗 Frontend: https://desfollow.com.br"
    echo "🔗 API: https://api.desfollow.com.br"
    echo ""
    echo "📱 MUDANÇAS APLICADAS:"
    echo "• SSL configuração BÁSICA (máxima compatibilidade)"
    echo "• Ciphers HIGH (padrão seguro)"
    echo "• Removido HTTP/2 (pode causar problemas em alguns móveis)"
    echo "• Headers simplificados"
    echo "• CORS básico"
    echo "• Timeouts reduzidos"
    
else
    echo "❌ Erro na configuração"
    sudo nginx -t
fi

echo ""
echo "📋 6. Para testar no mobile:"
echo "1. Limpe o cache do Safari mobile"
echo "2. Tente em modo privado/anônimo"
echo "3. Teste em diferentes redes (WiFi/4G)"
echo "4. Se ainda não funcionar, pode ser problema de propagação DNS"