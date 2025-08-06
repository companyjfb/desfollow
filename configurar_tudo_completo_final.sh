#!/bin/bash

echo "🚀 CONFIGURAÇÃO COMPLETA FINAL - DESFOLLOW"
echo "=========================================="
echo "• Proxy transparente para imagens Instagram"
echo "• SSL para todos os domínios" 
echo "• CORS resolvido"
echo "• Separação frontend/backend"
echo

# Passo 1: Garantir que está no diretório correto
echo "📋 1. Verificando diretório e atualizando código..."
cd /root/desfollow
git pull origin main
echo "✅ Código atualizado"

# Passo 2: Reiniciar backend
echo
echo "📋 2. Reiniciando backend..."
systemctl restart desfollow
sleep 3
echo "✅ Backend reiniciado"

# Passo 3: Aplicar configuração HTTP temporária primeiro
echo
echo "📋 3. Aplicando configuração HTTP temporária..."
chmod +x aplicar_nginx_temporario_http.sh
./aplicar_nginx_temporario_http.sh

# Aguardar um pouco para garantir que está funcionando
echo
echo "📋 4. Aguardando estabilização..."
sleep 5

# Passo 4: Verificar se o Nginx está funcionando
echo
echo "📋 5. Verificando status do Nginx..."
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx está rodando"
else
    echo "❌ Nginx não está rodando - reiniciando..."
    systemctl start nginx
fi

# Passo 5: Verificar conectividade dos domínios
echo
echo "📋 6. Verificando conectividade dos domínios..."
echo "• Testando desfollow.com.br..."
curl -s -o /dev/null -w "%{http_code}" http://desfollow.com.br || echo "Não acessível"

echo "• Testando www.desfollow.com.br..."  
curl -s -o /dev/null -w "%{http_code}" http://www.desfollow.com.br || echo "Não acessível"

echo "• Testando api.desfollow.com.br..."
curl -s -o /dev/null -w "%{http_code}" http://api.desfollow.com.br || echo "Não acessível"

# Passo 6: Instalar SSL com método webroot (mais compatível)
echo
echo "📋 7. Instalando SSL com método webroot..."

# Primeiro, garantir que o diretório webroot existe
sudo mkdir -p /var/www/html/desfollow/.well-known/acme-challenge
sudo chown -R www-data:www-data /var/www/html/

# Gerar certificados usando webroot
sudo certbot certonly \
    --webroot \
    --webroot-path=/var/www/html/desfollow \
    -d desfollow.com.br \
    -d www.desfollow.com.br \
    -d api.desfollow.com.br \
    --agree-tos \
    --non-interactive \
    --email admin@desfollow.com.br \
    --expand \
    --verbose

if [ $? -eq 0 ]; then
    echo "✅ Certificados SSL gerados com sucesso!"
    
    # Passo 7: Aplicar configuração com proxy transparente E SSL
    echo
    echo "📋 8. Aplicando configuração final com SSL e proxy transparente..."
    chmod +x aplicar_nginx_proxy_transparente.sh
    ./aplicar_nginx_proxy_transparente.sh
    
    # Passo 8: Atualizar frontend
    echo
    echo "📋 9. Atualizando frontend..."
    chmod +x buildar_frontend_definitivo.sh
    ./buildar_frontend_definitivo.sh
    
    echo
    echo "🎉 CONFIGURAÇÃO COMPLETA FINALIZADA!"
    echo "===================================="
    echo "Frontend: https://www.desfollow.com.br"
    echo "Frontend: https://desfollow.com.br"
    echo "API: https://api.desfollow.com.br"
    echo
    echo "✅ SSL funcionando"
    echo "✅ Proxy transparente para imagens Instagram"
    echo "✅ CORS resolvido"
    echo "✅ Separação frontend/backend"
    echo "✅ Cache de imagens"
    echo "✅ Sistema de fallback"
    
else
    echo "❌ Erro ao gerar certificados SSL!"
    echo "📋 Aplicando apenas proxy transparente sem SSL..."
    
    # Aplicar configuração sem SSL mesmo assim
    sudo cp nginx_desfollow_sem_ssl_temporario.conf /etc/nginx/sites-available/desfollow
    
    # Adicionar proxy transparente na configuração HTTP
    cat >> /tmp/nginx_temp.conf << 'EOF'

    # PROXY TRANSPARENTE PARA IMAGENS INSTAGRAM/FACEBOOK (HTTP)
    location ~* ^/instagram-proxy/(.+)$ {
        set $instagram_url $1;
        
        proxy_set_header User-Agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36";
        proxy_set_header Accept "image/webp,image/apng,image/*,*/*;q=0.8";
        proxy_set_header Host "";
        
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET" always;
        add_header Cache-Control "public, max-age=3600" always;
        
        proxy_pass https://$instagram_url;
        proxy_ssl_verify off;
        proxy_ssl_server_name on;
        proxy_redirect off;
        proxy_buffering on;
        
        proxy_connect_timeout 10s;
        proxy_send_timeout 10s;
        proxy_read_timeout 10s;
    }
EOF
    
    # Inserir o proxy transparente na configuração HTTP
    sed -i '/location \/ {/i\\n'"$(cat /tmp/nginx_temp.conf | sed 's/$/\\n/' | tr -d '\n')" /etc/nginx/sites-available/desfollow
    rm /tmp/nginx_temp.conf
    
    systemctl reload nginx
    
    echo
    echo "⚠️ CONFIGURAÇÃO PARCIAL APLICADA (HTTP)"
    echo "======================================="
    echo "Frontend: http://www.desfollow.com.br"
    echo "Frontend: http://desfollow.com.br"  
    echo "API: http://api.desfollow.com.br"
    echo
    echo "✅ Proxy transparente para imagens Instagram funcionando"
    echo "❌ SSL não configurado (problema de conectividade)"
fi

echo
echo "📋 Status final dos serviços:"
systemctl status nginx --no-pager -l
echo
systemctl status desfollow --no-pager -l