#!/bin/bash

echo "🔧 APLICANDO CONFIGURAÇÃO NGINX DEFINITIVA"
echo "=========================================="
echo "✅ Frontend: www.desfollow.com.br e desfollow.com.br"
echo "✅ API: api.desfollow.com.br"
echo ""

cd /root/desfollow

# 1. Fazer backup da configuração atual
echo "📋 1. Fazendo backup da configuração atual..."
if [ -f "/etc/nginx/sites-available/desfollow" ]; then
    cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup criado"
else
    echo "ℹ️ Nenhuma configuração anterior encontrada"
fi

# 2. Adicionar limit_req_zone se necessário
echo ""
echo "📋 2. Verificando limit_req_zone no nginx.conf..."
if ! grep -q "limit_req_zone" /etc/nginx/nginx.conf; then
    echo "📋 Adicionando limit_req_zone ao nginx.conf..."
    sed -i '/http {/a\\n    # Rate limiting zones\n    limit_req_zone $binary_remote_addr zone=api:10m rate=30r/m;\n    limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;' /etc/nginx/nginx.conf
    echo "✅ limit_req_zone adicionado"
else
    echo "✅ limit_req_zone já existe"
fi

# 3. Copiar nova configuração
echo ""
echo "📋 3. Aplicando nova configuração Nginx..."
cp nginx_desfollow_definitivo.conf /etc/nginx/sites-available/desfollow
echo "✅ Configuração copiada"

# 4. Habilitar site
echo ""
echo "📋 4. Habilitando site..."
ln -sf /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/
echo "✅ Site habilitado"

# 5. Remover configuração padrão se existir
echo ""
echo "📋 5. Removendo configuração padrão..."
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    rm /etc/nginx/sites-enabled/default
    echo "✅ Configuração padrão removida"
else
    echo "ℹ️ Configuração padrão não encontrada"
fi

# 6. Verificar se diretório do frontend existe
echo ""
echo "📋 6. Verificando diretório do frontend..."
if [ ! -d "/var/www/html/desfollow" ]; then
    echo "📋 Criando diretório do frontend..."
    mkdir -p /var/www/html/desfollow
    echo "✅ Diretório criado"
    
    # Se não existir frontend, criar um index.html temporário
    if [ ! -f "/var/www/html/desfollow/index.html" ]; then
        echo "📋 Frontend não encontrado. Você precisa buildar e mover o frontend!"
        echo "📋 Execute: npm run build e depois mova os arquivos para /var/www/html/desfollow"
    fi
else
    echo "✅ Diretório do frontend existe"
fi

# 7. Testar configuração
echo ""
echo "📋 7. Testando configuração Nginx..."
nginx_test=$(nginx -t 2>&1)
if [[ $? -eq 0 ]]; then
    echo "✅ Configuração Nginx válida"
    
    # 8. Recarregar Nginx
    echo ""
    echo "📋 8. Recarregando Nginx..."
    systemctl reload nginx
    echo "✅ Nginx recarregado"
    
    # 9. Verificar status
    echo ""
    echo "📋 9. Verificando status..."
    if systemctl is-active --quiet nginx; then
        echo "✅ Nginx está rodando"
    else
        echo "❌ Problema com Nginx"
        systemctl status nginx --no-pager -l
    fi
    
else
    echo "❌ Erro na configuração Nginx:"
    echo "$nginx_test"
    echo ""
    echo "📋 Restaurando backup..."
    if [ -f "/etc/nginx/sites-available/desfollow.backup.$(date +%Y%m%d_%H%M%S)" ]; then
        cp /etc/nginx/sites-available/desfollow.backup.* /etc/nginx/sites-available/desfollow
        systemctl reload nginx
        echo "✅ Backup restaurado"
    fi
    exit 1
fi

echo ""
echo "✅ CONFIGURAÇÃO NGINX APLICADA COM SUCESSO!"
echo "============================================"
echo ""
echo "🌐 RESULTADO ESPERADO:"
echo "   • www.desfollow.com.br → FRONTEND React"
echo "   • desfollow.com.br → FRONTEND React" 
echo "   • api.desfollow.com.br → API FastAPI"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "   1. Verificar se frontend está buildado em /var/www/html/desfollow"
echo "   2. Testar: curl -H 'Host: www.desfollow.com.br' http://localhost"
echo "   3. Testar: curl -H 'Host: api.desfollow.com.br' https://localhost"
echo "   4. Verificar logs: tail -f /var/log/nginx/frontend_access.log" 