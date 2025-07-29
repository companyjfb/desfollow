#!/bin/bash

echo "🔧 Corrigindo configurações do Nginx para IP correto..."
echo "======================================================"

echo "📋 Verificando configuração atual..."
nginx -t

echo ""
echo "🔧 Aplicando configuração corrigida..."

# Fazer backup da configuração atual
cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.$(date +%Y%m%d_%H%M%S)

# Criar configuração corrigida
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Configuração Nginx para Desfollow - IP Corrigido
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

# Configuração para HTTPS - API (api.desfollow.com.br)
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

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

# Configuração para HTTPS - Frontend (www.desfollow.com.br)
server {
    listen 443 ssl http2;
    server_name www.desfollow.com.br desfollow.com.br;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/www.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/www.desfollow.com.br/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

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

# Redirecionamento HTTP para HTTPS
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

server {
    listen 80;
    server_name www.desfollow.com.br desfollow.com.br;
    return 301 https://$server_name$request_uri;
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
        <p>API: <a href="https://api.desfollow.com.br">api.desfollow.com.br</a></p>
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
        echo "✅ Configuração corrigida com sucesso!"
        echo ""
        echo "📋 Resumo:"
        echo "   - Servidor: 195.35.17.75"
        echo "   - Frontend: https://www.desfollow.com.br"
        echo "   - API: https://api.desfollow.com.br"
        echo "   - Logs: /var/log/nginx/desfollow_*_access.log"
        
    else
        echo "❌ Erro ao recarregar Nginx!"
        echo "🔧 Restaurando configuração anterior..."
        cp /etc/nginx/sites-available/desfollow.backup.* /etc/nginx/sites-available/desfollow
        systemctl reload nginx
        echo "✅ Configuração anterior restaurada!"
    fi
    
else
    echo "❌ Erro na sintaxe da configuração!"
    echo "🔧 Restaurando configuração anterior..."
    cp /etc/nginx/sites-available/desfollow.backup.* /etc/nginx/sites-available/desfollow
    echo "✅ Configuração anterior restaurada!"
fi 