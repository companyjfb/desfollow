#!/bin/bash

echo "🔧 CORRIGINDO CONFIGURAÇÃO NGINX SSL"
echo "===================================="

# Corrigir configuração do Nginx
echo "📋 1. Corrigindo configuração do Nginx..."
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# Configuração para api.desfollow.com.br com SSL
server {
    listen 80;
    server_name api.desfollow.com.br;
    
    # Redirecionar HTTP para HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    
    # Configurações SSL seguras
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    
    # Handle preflight requests
    location / {
        # CORS headers para o frontend
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' 'https://desfollow.com.br';
            add_header 'Access-Control-Allow-Origin' 'https://www.desfollow.com.br';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE';
            add_header 'Access-Control-Allow-Headers' 'Origin, Content-Type, Accept, Authorization, X-Requested-With';
            add_header 'Access-Control-Allow-Credentials' 'true';
            add_header 'Content-Length' 0;
            add_header 'Content-Type' 'text/plain';
            return 204;
        }
        
        # CORS headers para todas as respostas
        add_header 'Access-Control-Allow-Origin' 'https://desfollow.com.br';
        add_header 'Access-Control-Allow-Origin' 'https://www.desfollow.com.br';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE';
        add_header 'Access-Control-Allow-Headers' 'Origin, Content-Type, Accept, Authorization, X-Requested-With';
        add_header 'Access-Control-Allow-Credentials' 'true';
        
        # Proxy para o backend Python
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $server_name;
        
        # Timeouts
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        proxy_buffering off;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

# Testar configuração do Nginx
echo "📋 2. Testando configuração do Nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração Nginx OK!"
    
    # Reiniciar Nginx
    echo "📋 3. Reiniciando Nginx..."
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    
    # Verificar se desfollow service está rodando
    echo "📋 4. Verificando serviço desfollow..."
    sudo systemctl status desfollow --no-pager
    
    # Se não estiver rodando, iniciar
    if ! sudo systemctl is-active --quiet desfollow; then
        echo "📋 5. Iniciando serviço desfollow..."
        sudo systemctl start desfollow
    fi
    
    # Aguardar serviços inicializarem
    sleep 5
    
    # Verificar status dos serviços
    echo "📋 6. Verificando status final..."
    echo "• Nginx:"
    sudo systemctl status nginx --no-pager -l | head -10
    echo "• Desfollow:"
    sudo systemctl status desfollow --no-pager -l | head -10
    
    # Testar HTTPS
    echo "📋 7. Testando HTTPS..."
    echo "• HTTP -> HTTPS redirect:"
    curl -I http://api.desfollow.com.br/health 2>/dev/null | head -3
    echo "• HTTPS response:"
    curl -I https://api.desfollow.com.br/health 2>/dev/null | head -5
    
    echo ""
    echo "✅ NGINX SSL CORRIGIDO COM SUCESSO!"
    echo "🌐 API disponível em: https://api.desfollow.com.br"
    
else
    echo "❌ Erro na configuração do Nginx!"
    sudo nginx -t
fi