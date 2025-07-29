#!/bin/bash

echo "🔧 CRIANDO CERTIFICADOS SSL - CONFIGURAÇÃO MÍNIMA"
echo "==============================================="

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Execute como root: sudo $0"
    exit 1
fi

echo "📋 1. Parando todos os redirecionamentos..."
# Fazer backup completo
cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.pre-ssl.$(date +%Y%m%d_%H%M%S) 2>/dev/null || echo "⚠️ Arquivo não encontrado"

echo "📋 2. Removendo TODA configuração SSL e redirecionamentos..."
# Desativar site atual
rm -f /etc/nginx/sites-enabled/desfollow

echo "📋 3. Criando configuração MÍNIMA sem redirecionamentos..."
cat > /etc/nginx/sites-available/desfollow-temp << 'EOF'
# Configuração MÍNIMA para criar certificados SSL
# SEM redirecionamentos, SEM SSL

server {
    listen 80;
    server_name desfollow.com.br;
    
    root /var/www/html;
    index index.html;
    
    # Let's Encrypt validation
    location /.well-known/acme-challenge/ {
        try_files $uri =404;
    }
    
    location / {
        return 200 'OK - desfollow.com.br';
        add_header Content-Type text/plain;
    }
}

server {
    listen 80;
    server_name www.desfollow.com.br;
    
    root /var/www/html;
    index index.html;
    
    # Let's Encrypt validation
    location /.well-known/acme-challenge/ {
        try_files $uri =404;
    }
    
    location / {
        return 200 'OK - www.desfollow.com.br';
        add_header Content-Type text/plain;
    }
}

server {
    listen 80;
    server_name api.desfollow.com.br;
    
    # Let's Encrypt validation
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files $uri =404;
    }
    
    # API continua funcionando
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo "📋 4. Ativando configuração mínima..."
ln -sf /etc/nginx/sites-available/desfollow-temp /etc/nginx/sites-enabled/

echo "📋 5. Testando configuração mínima..."
if nginx -t; then
    echo "✅ Configuração mínima válida!"
else
    echo "❌ Erro na configuração mínima!"
    nginx -t 2>&1
    exit 1
fi

echo "📋 6. Recarregando Nginx..."
systemctl reload nginx

echo "📋 7. Criando diretórios e testando acesso..."
mkdir -p /var/www/html/.well-known/acme-challenge
echo "test" > /var/www/html/.well-known/acme-challenge/test
chown -R www-data:www-data /var/www/html

echo "📋 8. Testando acesso HTTP direto (sem redirecionamentos)..."
sleep 2  # Aguardar Nginx carregar
for domain in desfollow.com.br www.desfollow.com.br; do
    echo "🔍 Testando $domain..."
    response=$(curl -s -w "HTTP_CODE:%{http_code}" http://$domain/test 2>/dev/null)
    echo "   Resposta: $response"
    
    # Testar diretório de validação
    validation_response=$(curl -s -w "HTTP_CODE:%{http_code}" http://$domain/.well-known/acme-challenge/test 2>/dev/null)
    echo "   Validação: $validation_response"
done

echo ""
echo "📋 9. Aguardando 5 segundos antes de criar certificados..."
sleep 5

echo "📋 10. Criando certificado com método standalone..."
# Parar nginx temporariamente
systemctl stop nginx

echo "🔧 Usando método standalone (sem nginx)..."
certbot certonly --standalone -d desfollow.com.br -d www.desfollow.com.br --non-interactive --agree-tos --email admin@desfollow.com.br

CERT_RESULT=$?

# Reiniciar nginx
systemctl start nginx

echo ""
echo "📋 11. Verificando resultado..."
if [ $CERT_RESULT -eq 0 ]; then
    echo "✅ CERTIFICADO CRIADO COM SUCESSO!"
    echo "==============================="
    
    echo "📋 Verificando certificados..."
    certbot certificates
    
    echo ""
    echo "📋 Agora restaurando configuração e ativando SSL..."
    # Restaurar configuração original e aplicar SSL
    rm -f /etc/nginx/sites-enabled/desfollow-temp
    if ls /etc/nginx/sites-available/desfollow.backup.pre-ssl.* 1> /dev/null 2>&1; then
        latest_backup=$(ls -t /etc/nginx/sites-available/desfollow.backup.pre-ssl.* | head -1)
        cp "$latest_backup" /etc/nginx/sites-available/desfollow
    fi
    
    echo "✅ PRÓXIMO PASSO:"
    echo "   ./corrigir_nginx_frontend_api_com_ssl.sh"
    
else
    echo "❌ FALHA AO CRIAR CERTIFICADO!"
    echo "============================"
    echo "📋 Verificando logs:"
    tail -20 /var/log/letsencrypt/letsencrypt.log
    
    echo ""
    echo "📋 Comandos de debug:"
    echo "   nslookup desfollow.com.br"
    echo "   curl -v http://desfollow.com.br"
    echo "   systemctl status nginx"
    
    # Restaurar configuração
    rm -f /etc/nginx/sites-enabled/desfollow-temp
    if ls /etc/nginx/sites-available/desfollow.backup.pre-ssl.* 1> /dev/null 2>&1; then
        latest_backup=$(ls -t /etc/nginx/sites-available/desfollow.backup.pre-ssl.* | head -1)
        cp "$latest_backup" /etc/nginx/sites-available/desfollow
        ln -sf /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/
    fi
    systemctl reload nginx
fi

# Cleanup
rm -f /var/www/html/.well-known/acme-challenge/test

echo ""
echo "📋 Configuração restaurada." 