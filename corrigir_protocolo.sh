#!/bin/bash

echo "🔧 Corrigindo problema de protocolo HTTP/HTTPS..."
echo "================================================"

echo "📋 Verificando configuração atual..."
nginx -t

echo ""
echo "🔧 Aplicando correções..."

# Fazer backup da configuração atual
cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || echo "⚠️ Não foi possível fazer backup"

# Criar configuração corrigida
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Configuração Nginx para Desfollow - Protocolo Corrigido
# Servidor: 195.35.17.75

# Configuração para API (api.desfollow.com.br)
server {
    listen 80;
    server_name api.desfollow.com.br;

    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Configuração da API
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

    # Configuração específica para autenticação
    location /api/auth/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
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

# Configuração para Frontend (www.desfollow.com.br)
server {
    listen 80;
    server_name www.desfollow.com.br desfollow.com.br;

    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Configuração do frontend
    root /var/www/desfollow;
    index index.html;

    # Configuração para arquivos estáticos
    location / {
        try_files $uri $uri/ /index.html;
        
        # Cache para arquivos estáticos
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Configuração para API (proxy para api.desfollow.com.br)
    location /api/ {
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

    # Logs
    access_log /var/log/nginx/desfollow_frontend_access.log;
    error_log /var/log/nginx/desfollow_frontend_error.log;
}
EOF

echo "✅ Configuração aplicada!"

echo ""
echo "🔍 Verificando sintaxe da nova configuração..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Sintaxe da configuração está correta!"
    
    echo ""
    echo "🔧 Recarregando Nginx..."
    systemctl reload nginx
    
    if [ $? -eq 0 ]; then
        echo "✅ Nginx recarregado com sucesso!"
        
        echo ""
        echo "🔧 Reiniciando backend..."
        systemctl restart desfollow
        
        echo ""
        echo "⏳ Aguardando 5 segundos..."
        sleep 5
        
        echo ""
        echo "🔍 Testando configuração..."
        echo "📱 Frontend (www.desfollow.com.br):"
        curl -I http://www.desfollow.com.br 2>/dev/null | head -5
        
        echo ""
        echo "🔧 API (api.desfollow.com.br):"
        curl -I http://api.desfollow.com.br 2>/dev/null | head -5
        
        echo ""
        echo "🔍 Testando endpoint de scan:"
        curl -X POST http://api.desfollow.com.br/api/scan \
          -H "Content-Type: application/json" \
          -H "Origin: http://www.desfollow.com.br" \
          -d '{"username":"test"}' \
          -v 2>&1 | head -10
        
        echo ""
        echo "✅ Configuração corrigida com sucesso!"
        echo ""
        echo "📋 Resumo:"
        echo "   - Servidor: 195.35.17.75"
        echo "   - Frontend: http://www.desfollow.com.br"
        echo "   - API: http://api.desfollow.com.br"
        echo "   - Protocolo: HTTP (compatível com HTTPS futuro)"
        echo ""
        echo "💡 Agora o frontend deve funcionar corretamente!"
        echo "💡 As requisições serão feitas para HTTP, não HTTPS"
        
    else
        echo "❌ Erro ao recarregar Nginx!"
        echo "🔧 Verificando status..."
        systemctl status nginx --no-pager
    fi
    
else
    echo "❌ Erro na sintaxe da configuração!"
    echo "🔧 Verificando logs..."
    nginx -t 2>&1
fi 