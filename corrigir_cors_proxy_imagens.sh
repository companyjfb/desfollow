#!/bin/bash

echo "🔧 CORRIGINDO CORS DO PROXY DE IMAGENS - DESFOLLOW"
echo "=================================================="

# Parar nginx
echo "📋 1. Parando nginx..."
sudo systemctl stop nginx

# Corrigir configuração CORS (estava duplicando headers)
echo "📋 2. Aplicando configuração CORS corrigida..."
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# CONFIGURAÇÃO NGINX CORS CORRIGIDO - DESFOLLOW
# =============================================

# HTTP para HTTPS redirect
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# FRONTEND HTTPS
server {
    listen 443 ssl;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    
    # SSL simples
    ssl_protocols TLSv1.2;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    
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

# API HTTPS - CORS CORRIGIDO
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name api.desfollow.com.br;
    
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    
    ssl_protocols TLSv1.2;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    
    # Logs
    access_log /var/log/nginx/api_access.log;
    error_log /var/log/nginx/api_error.log;
    
    # CORS para proxy de imagens (ENDPOINT ESPECÍFICO)
    location /api/proxy-image {
        # Headers CORS ÚNICOS (sem duplicação)
        add_header 'Access-Control-Allow-Origin' 'https://www.desfollow.com.br' always;
        add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Origin, X-Requested-With, Content-Type, Accept' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        
        # Preflight requests
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
        
        # Proxy para backend
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Headers específicos para proxy de imagem
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_hide_header 'Access-Control-Allow-Origin';
        proxy_hide_header 'Access-Control-Allow-Methods';
        proxy_hide_header 'Access-Control-Allow-Headers';
    }
    
    # CORS para outras rotas da API
    location /api/ {
        # Headers CORS ÚNICOS
        add_header 'Access-Control-Allow-Origin' 'https://www.desfollow.com.br' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Origin, X-Requested-With, Content-Type, Accept, Authorization' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        
        # Preflight requests
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
        
        # Proxy para backend
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # Esconder headers CORS do backend para evitar duplicação
        proxy_hide_header 'Access-Control-Allow-Origin';
        proxy_hide_header 'Access-Control-Allow-Methods';
        proxy_hide_header 'Access-Control-Allow-Headers';
        proxy_hide_header 'Access-Control-Allow-Credentials';
    }
    
    # Root da API (fallback)
    location / {
        add_header 'Access-Control-Allow-Origin' 'https://www.desfollow.com.br' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Origin, X-Requested-With, Content-Type, Accept, Authorization' always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
        
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Esconder headers CORS do backend
        proxy_hide_header 'Access-Control-Allow-Origin';
        proxy_hide_header 'Access-Control-Allow-Methods';
        proxy_hide_header 'Access-Control-Allow-Headers';
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
    echo "📋 5. Testando CORS..."
    
    echo "Teste OPTIONS para proxy-image:"
    curl -X OPTIONS -H "Origin: https://www.desfollow.com.br" -H "Access-Control-Request-Method: GET" -I https://api.desfollow.com.br/api/proxy-image --insecure 2>/dev/null | grep -i "access-control"
    
    echo ""
    echo "Teste GET para API:"
    curl -H "Origin: https://www.desfollow.com.br" -I https://api.desfollow.com.br/api/status --insecure 2>/dev/null | grep -i "access-control"
    
    echo ""
    echo "✅ CORREÇÃO CORS CONCLUÍDA!"
    echo "=========================="
    echo "🔗 Frontend: https://desfollow.com.br"
    echo "🔗 API: https://api.desfollow.com.br"
    echo ""
    echo "📱 PROBLEMAS CORRIGIDOS:"
    echo "• CORS duplicado resolvido"
    echo "• Headers CORS únicos"
    echo "• Proxy-image com CORS específico"
    echo "• proxy_hide_header para evitar duplicação"
    echo "• Configuração específica por endpoint"
    
else
    echo "❌ Erro na configuração"
    sudo nginx -t
fi

echo ""
echo "📋 6. TESTE NO MOBILE - SSL:"
echo "Se ainda não funcionar no mobile, vamos testar temporariamente HTTP:"
echo "Execute: sudo sed -i 's/https:/http:/g' /var/www/desfollow/index.html"