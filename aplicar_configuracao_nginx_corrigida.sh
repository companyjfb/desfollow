#!/bin/bash

echo "🚀 APLICANDO CONFIGURAÇÃO NGINX CORRIGIDA"
echo "======================================="
echo ""

cd /root/desfollow

# 1. Fazer backup da configuração atual
echo "📋 1. Fazendo backup da configuração atual..."
if [ -f "/etc/nginx/sites-enabled/desfollow" ]; then
    cp /etc/nginx/sites-enabled/desfollow /etc/nginx/sites-enabled/desfollow.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup criado"
else
    echo "ℹ️ Nenhuma configuração anterior encontrada"
fi

# 2. Copiar nova configuração
echo ""
echo "📋 2. Aplicando nova configuração..."
cp nginx_desfollow_corrigido_final.conf /etc/nginx/sites-available/desfollow
ln -sf /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/desfollow
echo "✅ Configuração aplicada"

# 3. Remover configuração padrão se existir
echo ""
echo "📋 3. Removendo configuração padrão..."
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    rm /etc/nginx/sites-enabled/default
    echo "✅ Configuração padrão removida"
else
    echo "ℹ️ Configuração padrão já estava removida"
fi

# 4. Testar configuração
echo ""
echo "📋 4. Testando configuração do Nginx..."
nginx -t
if [ $? -eq 0 ]; then
    echo "✅ Configuração válida"
else
    echo "❌ Erro na configuração!"
    echo "📋 Restaurando backup..."
    if [ -f "/etc/nginx/sites-enabled/desfollow.backup.*" ]; then
        latest_backup=$(ls -t /etc/nginx/sites-enabled/desfollow.backup.* | head -1)
        cp "$latest_backup" /etc/nginx/sites-enabled/desfollow
        nginx -t
    fi
    exit 1
fi

# 5. Recarregar Nginx
echo ""
echo "📋 5. Recarregando Nginx..."
systemctl reload nginx
if [ $? -eq 0 ]; then
    echo "✅ Nginx recarregado com sucesso"
else
    echo "❌ Erro ao recarregar Nginx"
    systemctl status nginx
    exit 1
fi

# 6. Verificar status dos serviços
echo ""
echo "📋 6. Verificando status dos serviços..."
echo "🔍 Nginx:"
systemctl is-active nginx
echo "🔍 Desfollow Backend:"
systemctl is-active desfollow

# 7. Testar domínios
echo ""
echo "📋 7. Testando domínios..."
echo "🌐 Frontend (desfollow.com.br):"
curl -s -o /dev/null -w "%{http_code}" -H "Host: desfollow.com.br" http://localhost/
echo ""
echo "🌐 Frontend (www.desfollow.com.br):"
curl -s -o /dev/null -w "%{http_code}" -H "Host: www.desfollow.com.br" http://localhost/
echo ""
echo "🌐 API (api.desfollow.com.br):"
curl -s -o /dev/null -w "%{http_code}" -H "Host: api.desfollow.com.br" http://localhost/api/health

echo ""
echo "✅ CONFIGURAÇÃO NGINX APLICADA!"
echo "==============================="
echo ""
echo "🌐 DOMÍNIOS CONFIGURADOS:"
echo "   • Frontend: https://desfollow.com.br"
echo "   • Frontend: https://www.desfollow.com.br"
echo "   • API: https://api.desfollow.com.br"
echo ""
echo "🔧 MELHORIAS APLICADAS:"
echo "   • CORS corrigido para imagens do Instagram"
echo "   • Separação completa entre frontend e backend"
echo "   • SSL configurado para todos os domínios"
echo "   • Rate limiting na API"
echo "   • Proxy para imagens do Instagram"
echo "   • Headers de segurança"
echo ""
echo "📋 LOGS:"
echo "   • Frontend: tail -f /var/log/nginx/frontend_https_access.log"
echo "   • API: tail -f /var/log/nginx/api_access.log"