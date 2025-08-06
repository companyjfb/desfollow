#!/bin/bash

echo "🔒 INSTALANDO SSL LETSENCRYPT - DESFOLLOW"
echo "=========================================="
echo

# 1. Instalar certbot se não estiver instalado
echo "📋 1. Verificando/Instalando Certbot..."
if ! command -v certbot &> /dev/null; then
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
    echo "✅ Certbot instalado"
else
    echo "✅ Certbot já está instalado"
fi

# 2. Parar nginx temporariamente
echo
echo "📋 2. Parando Nginx temporariamente..."
sudo systemctl stop nginx
echo "✅ Nginx parado"

# 3. Gerar certificados para todos os domínios
echo
echo "📋 3. Gerando certificados SSL..."
sudo certbot certonly --standalone \
    -d desfollow.com.br \
    -d www.desfollow.com.br \
    -d api.desfollow.com.br \
    --agree-tos \
    --non-interactive \
    --email admin@desfollow.com.br

if [ $? -eq 0 ]; then
    echo "✅ Certificados SSL gerados com sucesso!"
    
    # 4. Aplicar configuração com SSL
    echo
    echo "📋 4. Aplicando configuração com SSL..."
    sudo cp nginx_desfollow_simples_sem_rate_limit.conf /etc/nginx/sites-available/desfollow
    echo "✅ Configuração SSL aplicada"
    
    # 5. Testar e iniciar
    echo
    echo "📋 5. Testando configuração SSL..."
    if sudo nginx -t; then
        echo "✅ Configuração SSL válida!"
        
        echo
        echo "📋 6. Iniciando Nginx com SSL..."
        sudo systemctl start nginx
        echo "✅ Nginx com SSL iniciado!"
        
        echo
        echo "🎉 SSL CONFIGURADO COM SUCESSO!"
        echo "==============================="
        echo "Frontend: https://www.desfollow.com.br"
        echo "Frontend: https://desfollow.com.br"
        echo "API: https://api.desfollow.com.br"
        echo
        echo "✅ Certificados SSL válidos"
        echo "✅ HTTPS obrigatório"
        echo "✅ Configuração final aplicada"
        
    else
        echo "❌ Erro na configuração SSL!"
        echo "📋 Voltando para HTTP temporário..."
        sudo cp nginx_desfollow_sem_ssl_temporario.conf /etc/nginx/sites-available/desfollow
        sudo systemctl start nginx
    fi
    
else
    echo "❌ Erro ao gerar certificados SSL!"
    echo "📋 Mantendo configuração HTTP..."
    sudo systemctl start nginx
fi

echo
echo "📋 Status final:"
sudo systemctl status nginx --no-pager -l