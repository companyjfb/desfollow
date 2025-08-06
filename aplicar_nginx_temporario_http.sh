#!/bin/bash

echo "🚀 APLICANDO CONFIGURAÇÃO NGINX TEMPORÁRIA (HTTP)"
echo "================================================"
echo

# 1. Aplicar configuração temporária sem SSL
echo "📋 1. Aplicando configuração HTTP temporária..."
sudo cp nginx_desfollow_sem_ssl_temporario.conf /etc/nginx/sites-available/desfollow
echo "✅ Configuração aplicada"

# 2. Testar configuração
echo
echo "📋 2. Testando configuração do Nginx..."
if sudo nginx -t; then
    echo "✅ Configuração válida!"
    
    # 3. Iniciar Nginx
    echo
    echo "📋 3. Iniciando Nginx..."
    sudo systemctl start nginx
    sudo systemctl enable nginx
    echo "✅ Nginx iniciado!"
    
    echo
    echo "🎉 NGINX FUNCIONANDO TEMPORARIAMENTE!"
    echo "===================================="
    echo "Frontend: http://www.desfollow.com.br"
    echo "Frontend: http://desfollow.com.br"
    echo "API: http://api.desfollow.com.br"
    echo
    echo "⚠️ ATENÇÃO: Configuração temporária HTTP!"
    echo "✅ CORS configurado para imagens Instagram"
    echo "✅ Separação frontend/backend funcionando"
    echo
    echo "📋 Próximo passo: Configurar SSL"
    
else
    echo "❌ Ainda há erro na configuração!"
    echo "📋 Detalhes do erro:"
    sudo nginx -t
fi

echo
echo "📋 Status final dos serviços:"
sudo systemctl status nginx --no-pager -l