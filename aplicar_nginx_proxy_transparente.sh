#!/bin/bash

echo "🔄 APLICANDO NGINX COM PROXY TRANSPARENTE PARA IMAGENS"
echo "====================================================="
echo

# 1. Fazer backup da configuração atual
echo "📋 1. Fazendo backup da configuração atual..."
if [ -f /etc/nginx/sites-enabled/desfollow ]; then
    sudo cp /etc/nginx/sites-enabled/desfollow /etc/nginx/sites-enabled/desfollow.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup criado"
else
    echo "ℹ️ Nenhuma configuração anterior encontrada"
fi

# 2. Aplicar nova configuração com proxy transparente
echo
echo "📋 2. Aplicando configuração com proxy transparente..."
sudo cp nginx_desfollow_com_proxy_transparente.conf /etc/nginx/sites-available/desfollow
sudo ln -sf /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/desfollow
echo "✅ Configuração aplicada"

# 3. Testar configuração
echo
echo "📋 3. Testando configuração do Nginx..."
if sudo nginx -t; then
    echo "✅ Configuração válida!"
    
    # 4. Recarregar Nginx
    echo
    echo "📋 4. Recarregando Nginx..."
    sudo systemctl reload nginx
    echo "✅ Nginx recarregado!"
    
    echo
    echo "🎉 PROXY TRANSPARENTE CONFIGURADO COM SUCESSO!"
    echo "=============================================="
    echo "Frontend: https://www.desfollow.com.br"
    echo "Frontend: https://desfollow.com.br"
    echo "API: https://api.desfollow.com.br"
    echo
    echo "✅ Proxy transparente para imagens Instagram ativo"
    echo "✅ URLs Instagram são automaticamente proxificadas"
    echo "✅ CORS resolvido na origem (sem bloqueios)"
    echo "✅ Cache de imagens por 1 hora"
    echo "✅ Fallback para proxy da API se necessário"
    echo
    echo "📋 Como funciona:"
    echo "• Imagens Instagram são redirecionadas para /instagram-proxy/"
    echo "• Nginx faz proxy transparente sem CORS"
    echo "• Frontend não vê diferença, funciona automaticamente"
    
else
    echo "❌ Erro na configuração!"
    echo "📋 Detalhes do erro:"
    sudo nginx -t
    echo
    echo "📋 Restaurando backup..."
    if [ -f /etc/nginx/sites-enabled/desfollow.backup.* ]; then
        sudo cp /etc/nginx/sites-enabled/desfollow.backup.* /etc/nginx/sites-enabled/desfollow
        sudo systemctl reload nginx
        echo "✅ Backup restaurado"
    fi
fi

echo
echo "📋 Status final dos serviços:"
sudo systemctl status nginx --no-pager -l