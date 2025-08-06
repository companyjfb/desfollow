#!/bin/bash

echo "🚀 APLICANDO CONFIGURAÇÃO NGINX SIMPLES CORRIGIDA"
echo "================================================="
echo

# 1. Fazer backup da configuração atual
echo "📋 1. Fazendo backup da configuração atual..."
if [ -f /etc/nginx/sites-enabled/desfollow ]; then
    sudo cp /etc/nginx/sites-enabled/desfollow /etc/nginx/sites-enabled/desfollow.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup criado"
else
    echo "ℹ️ Nenhuma configuração anterior encontrada"
fi

# 2. Remover todas as configurações antigas
echo
echo "📋 2. Removendo configurações antigas..."
sudo rm -f /etc/nginx/sites-enabled/desfollow
sudo rm -f /etc/nginx/sites-enabled/default
echo "✅ Configurações antigas removidas"

# 3. Aplicar nova configuração
echo
echo "📋 3. Aplicando nova configuração simples..."
sudo cp nginx_desfollow_simples_sem_rate_limit.conf /etc/nginx/sites-available/desfollow
sudo ln -sf /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/desfollow
echo "✅ Configuração aplicada"

# 4. Testar configuração
echo
echo "📋 4. Testando configuração do Nginx..."
if sudo nginx -t; then
    echo "✅ Configuração válida!"
    
    # 5. Recarregar Nginx
    echo
    echo "📋 5. Recarregando Nginx..."
    sudo systemctl reload nginx
    echo "✅ Nginx recarregado!"
    
    echo
    echo "🎉 CONFIGURAÇÃO APLICADA COM SUCESSO!"
    echo "======================================"
    echo "Frontend: https://www.desfollow.com.br"
    echo "Frontend: https://desfollow.com.br"
    echo "API: https://api.desfollow.com.br"
    echo
    echo "✅ Imagens do Instagram: Carregamento direto (sem proxy)"
    echo "✅ CORS: Configurado apenas para domínios corretos"
    echo "✅ SSL: Ativo em todos os domínios"
    echo "✅ Separação: Frontend/Backend por domínio"
    
else
    echo "❌ Erro na configuração!"
    echo "📋 Restaurando backup..."
    if [ -f /etc/nginx/sites-enabled/desfollow.backup.* ]; then
        sudo cp /etc/nginx/sites-enabled/desfollow.backup.* /etc/nginx/sites-enabled/desfollow
        sudo systemctl reload nginx
        echo "✅ Backup restaurado"
    fi
fi