#!/bin/bash

echo "🧹 LIMPEZA COMPLETA DO NGINX - DESFOLLOW"
echo "========================================"
echo

# 1. Parar o Nginx
echo "📋 1. Parando Nginx..."
sudo systemctl stop nginx
echo "✅ Nginx parado"

# 2. Remover TODAS as configurações do desfollow
echo
echo "📋 2. Removendo TODAS as configurações antigas..."
sudo rm -f /etc/nginx/sites-enabled/desfollow*
sudo rm -f /etc/nginx/sites-available/desfollow*
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-available/default
echo "✅ Configurações antigas removidas"

# 3. Limpar configuração global se existir
echo
echo "📋 3. Verificando configuração global..."
if grep -q "limit_req_zone.*api" /etc/nginx/nginx.conf; then
    echo "ℹ️ Encontrado limit_req_zone no nginx.conf - removendo..."
    sudo sed -i '/limit_req_zone.*api/d' /etc/nginx/nginx.conf
    echo "✅ limit_req_zone removido do nginx.conf"
else
    echo "ℹ️ Nenhum limit_req_zone encontrado no nginx.conf"
fi

# 4. Aplicar configuração limpa
echo
echo "📋 4. Aplicando configuração completamente limpa..."
sudo cp nginx_desfollow_simples_sem_rate_limit.conf /etc/nginx/sites-available/desfollow
sudo ln -sf /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/desfollow
echo "✅ Configuração aplicada"

# 5. Testar configuração
echo
echo "📋 5. Testando configuração do Nginx..."
if sudo nginx -t; then
    echo "✅ Configuração válida!"
    
    # 6. Iniciar Nginx
    echo
    echo "📋 6. Iniciando Nginx..."
    sudo systemctl start nginx
    sudo systemctl enable nginx
    echo "✅ Nginx iniciado!"
    
    echo
    echo "🎉 NGINX CONFIGURADO COM SUCESSO!"
    echo "================================="
    echo "Frontend: https://www.desfollow.com.br"
    echo "Frontend: https://desfollow.com.br"
    echo "API: https://api.desfollow.com.br"
    echo
    echo "✅ Todas as configurações antigas removidas"
    echo "✅ Configuração limpa aplicada"
    echo "✅ Nginx funcionando corretamente"
    
else
    echo "❌ Ainda há erro na configuração!"
    echo "📋 Detalhes do erro:"
    sudo nginx -t
    echo
    echo "📋 Tentando iniciar mesmo assim..."
    sudo systemctl start nginx
fi

echo
echo "📋 Status final dos serviços:"
sudo systemctl status nginx --no-pager -l