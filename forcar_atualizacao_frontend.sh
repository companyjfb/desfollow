#!/bin/bash

echo "🔥 FORÇANDO ATUALIZAÇÃO COMPLETA DO FRONTEND"
echo "=========================================="
echo ""

cd /root/desfollow

# 1. Puxar código mais recente
echo "📋 1. Puxando código mais recente..."
git pull origin main
if [ $? -ne 0 ]; then
    echo "❌ Erro ao puxar código do Git"
    exit 1
fi
echo "✅ Código atualizado"

# 2. Limpar caches Node/npm
echo ""
echo "📋 2. Limpando caches Node/npm..."
npm cache clean --force
rm -rf node_modules/.cache
rm -rf dist
echo "✅ Caches limpos"

# 3. Reinstalar dependências
echo ""
echo "📋 3. Reinstalando dependências..."
rm -rf node_modules
npm install
if [ $? -ne 0 ]; then
    echo "❌ Erro ao instalar dependências"
    exit 1
fi
echo "✅ Dependências reinstaladas"

# 4. Build FORÇADO
echo ""
echo "📋 4. Build FORÇADO com cache limpo..."
npm run build
if [ $? -ne 0 ]; then
    echo "❌ Erro ao buildar projeto"
    exit 1
fi
echo "✅ Build completado"

# 5. REMOVER completamente frontend antigo
echo ""
echo "📋 5. REMOVENDO frontend antigo COMPLETAMENTE..."
rm -rf /var/www/html/desfollow/*
rm -rf /var/www/html/www/*
echo "✅ Frontend antigo removido"

# 6. Copiar novo frontend com timestamp
echo ""
echo "📋 6. Copiando novo frontend..."
cp -r dist/* /var/www/html/desfollow/
cp -r dist/* /var/www/html/www/
echo "✅ Novo frontend copiado"

# 7. Forçar permissões
echo ""
echo "📋 7. Definindo permissões..."
chown -R www-data:www-data /var/www/html/desfollow
chmod -R 755 /var/www/html/desfollow
chown -R www-data:www-data /var/www/html/www  
chmod -R 755 /var/www/html/www
echo "✅ Permissões aplicadas"

# 8. Reiniciar Nginx para limpar cache
echo ""
echo "📋 8. Reiniciando Nginx para limpar cache..."
systemctl reload nginx
systemctl restart nginx
echo "✅ Nginx reiniciado"

# 9. Verificar arquivos JS atuais
echo ""
echo "📋 9. Verificando arquivos JS gerados..."
ls -la /var/www/html/desfollow/assets/*.js | head -3
echo ""

# 10. Testar acesso
echo ""
echo "📋 10. Testando acesso..."
curl -s -H "Host: www.desfollow.com.br" http://localhost/ | grep -o 'index-[^"]*\.js' | head -1
echo ""

echo "✅ ATUALIZAÇÃO FORÇADA COMPLETA!"
echo "==============================="
echo ""
echo "🔄 CACHE DO NAVEGADOR:"
echo "   • Pressione Ctrl+F5 no navegador"
echo "   • Ou F12 → Network → Disable Cache"
echo "   • Ou modo anônimo/incognito"
echo ""
echo "🧪 VERIFICAR LOGS:"
echo "   console.log('🔍 DEBUG - Is Paid User:', isPaidUser);"
echo "   NÃO DEVE APARECER: 'Is Special User'"
echo ""
echo "📱 TESTAR:"
echo "   https://www.desfollow.com.br"
echo "   F12 → Console → Verificar logs"