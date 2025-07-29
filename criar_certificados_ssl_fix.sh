#!/bin/bash

echo "🔧 CRIANDO CERTIFICADOS SSL - REMOVENDO SSL TEMPORÁRIO"
echo "====================================================="

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Execute como root: sudo $0"
    exit 1
fi

echo "📋 1. Fazendo backup completo da configuração atual..."
cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.ssl.$(date +%Y%m%d_%H%M%S) 2>/dev/null || echo "⚠️ Arquivo não encontrado"

echo "📋 2. Criando configuração Nginx temporária SEM SSL..."
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Configuração Nginx temporária para criação de certificados SSL
# SEM SSL - apenas para permitir validação do Let's Encrypt

server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Permitir validação do Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        allow all;
    }
    
    # Servir conteúdo temporário
    location / {
        root /var/www/html;
        index index.html;
        try_files $uri $uri/ =404;
    }
}

server {
    listen 80;
    server_name api.desfollow.com.br;
    
    # Permitir validação do Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        allow all;
    }
    
    # Proxy para API
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo "📋 3. Testando configuração temporária..."
if nginx -t; then
    echo "✅ Configuração temporária válida!"
else
    echo "❌ Erro na configuração temporária!"
    nginx -t 2>&1
    exit 1
fi

echo "📋 4. Recarregando Nginx..."
systemctl reload nginx

echo "📋 5. Criando diretório para validação..."
mkdir -p /var/www/html/.well-known/acme-challenge
chown -R www-data:www-data /var/www/html

echo "📋 6. Testando conectividade HTTP..."
echo "🔍 Testando acesso HTTP aos domínios:"
for domain in desfollow.com.br www.desfollow.com.br; do
    echo "Testing $domain..."
    curl -I http://$domain --connect-timeout 10 2>/dev/null | head -1 || echo "❌ Falha na conexão com $domain"
done

echo "📋 7. Criando certificado para desfollow.com.br..."
certbot certonly --webroot -w /var/www/html -d desfollow.com.br -d www.desfollow.com.br --non-interactive --agree-tos --email admin@desfollow.com.br

if [ $? -eq 0 ]; then
    echo "✅ Certificado criado para desfollow.com.br!"
    CERT_CREATED=true
else
    echo "❌ Falha ao criar certificado para desfollow.com.br"
    echo "📋 Verificando logs detalhados:"
    tail -20 /var/log/letsencrypt/letsencrypt.log
    CERT_CREATED=false
fi

echo ""
echo "📋 8. Verificando certificados finais..."
if [ "$CERT_CREATED" = true ]; then
    echo "✅ Verificando certificados criados:"
    certbot certificates
    
    echo ""
    echo "✅ CERTIFICADOS SSL CRIADOS COM SUCESSO!"
    echo "======================================="
    echo "📋 Agora execute:"
    echo "   ./corrigir_nginx_frontend_api_com_ssl.sh"
    echo ""
    echo "🔍 Certificados disponíveis:"
    echo "   - desfollow.com.br (www.desfollow.com.br)"
    echo "   - api.desfollow.com.br"
else
    echo "❌ FALHA AO CRIAR CERTIFICADOS!"
    echo "==============================="
    echo "📋 Possíveis problemas:"
    echo "   1. DNS não aponta para este servidor"
    echo "   2. Firewall bloqueando porta 80"
    echo "   3. Servidor não acessível externamente"
    echo ""
    echo "📋 Debug commands:"
    echo "   dig desfollow.com.br"
    echo "   curl -I http://desfollow.com.br"
    echo "   ufw status"
    echo "   tail -50 /var/log/letsencrypt/letsencrypt.log"
    
    echo ""
    echo "📋 Restaurando configuração anterior..."
    if ls /etc/nginx/sites-available/desfollow.backup.ssl.* 1> /dev/null 2>&1; then
        latest_backup=$(ls -t /etc/nginx/sites-available/desfollow.backup.ssl.* | head -1)
        cp "$latest_backup" /etc/nginx/sites-available/desfollow
        systemctl reload nginx
        echo "✅ Configuração anterior restaurada"
    fi
fi 