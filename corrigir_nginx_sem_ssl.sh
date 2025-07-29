#!/bin/bash

echo "🔧 Aplicando configuração Nginx sem SSL (temporário)..."
echo "====================================================="

echo "📋 Verificando configuração atual..."
nginx -t 2>/dev/null || echo "⚠️ Configuração atual com problemas"

echo ""
echo "🔧 Aplicando configuração sem SSL..."

# Fazer backup da configuração atual
cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || echo "⚠️ Não foi possível fazer backup"

# Criar configuração sem SSL
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Configuração Nginx para Desfollow - SEM SSL (Temporário)
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
    echo "🔧 Verificando se o diretório do frontend existe..."
    if [ ! -d "/var/www/desfollow" ]; then
        echo "❌ Diretório /var/www/desfollow não existe!"
        echo "🔧 Criando diretório..."
        mkdir -p /var/www/desfollow
        chown www-data:www-data /var/www/desfollow
        echo "✅ Diretório criado!"
    else
        echo "✅ Diretório /var/www/desfollow existe!"
    fi
    
    echo ""
    echo "🔧 Verificando se os arquivos do frontend estão no lugar..."
    if [ ! -f "/var/www/desfollow/index.html" ]; then
        echo "❌ Arquivo index.html não encontrado em /var/www/desfollow!"
        echo "🔧 Copiando arquivos do frontend..."
        
        # Verificar se existe build do frontend
        if [ -d "dist" ]; then
            cp -r dist/* /var/www/desfollow/
            chown -R www-data:www-data /var/www/desfollow
            echo "✅ Arquivos do frontend copiados!"
        else
            echo "⚠️ Diretório 'dist' não encontrado. Criando index.html básico..."
            cat > /var/www/desfollow/index.html << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Desfollow - Encontre quem não retribui seus follows</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .container { max-width: 600px; margin: 0 auto; }
        h1 { color: #333; }
        p { color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚧 Em Manutenção</h1>
        <p>O Desfollow está sendo configurado. Volte em alguns minutos!</p>
        <p>API: <a href="http://api.desfollow.com.br">api.desfollow.com.br</a></p>
    </div>
</body>
</html>
EOF
            chown www-data:www-data /var/www/desfollow/index.html
            echo "✅ index.html básico criado!"
        fi
    else
        echo "✅ Arquivo index.html encontrado!"
    fi
    
    echo ""
    echo "🔧 Recarregando Nginx..."
    systemctl reload nginx
    
    if [ $? -eq 0 ]; then
        echo "✅ Nginx recarregado com sucesso!"
        
        echo ""
        echo "🔍 Testando configuração..."
        echo "📱 Frontend (www.desfollow.com.br):"
        curl -I http://www.desfollow.com.br 2>/dev/null | head -5
        
        echo ""
        echo "🔧 API (api.desfollow.com.br):"
        curl -I http://api.desfollow.com.br 2>/dev/null | head -5
        
        echo ""
        echo "✅ Configuração aplicada com sucesso!"
        echo ""
        echo "📋 Resumo:"
        echo "   - Servidor: 195.35.17.75"
        echo "   - Frontend: http://www.desfollow.com.br (SEM SSL)"
        echo "   - API: http://api.desfollow.com.br (SEM SSL)"
        echo "   - Logs: /var/log/nginx/desfollow_*_access.log"
        echo ""
        echo "⚠️ IMPORTANTE: Esta é uma configuração temporária sem SSL!"
        echo "   Para adicionar SSL, execute: certbot --nginx -d desfollow.com.br -d www.desfollow.com.br -d api.desfollow.com.br"
        
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