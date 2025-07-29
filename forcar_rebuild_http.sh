#!/bin/bash

echo "🔧 Forçando rebuild completo com requisições HTTP..."
echo "================================================"

echo "📋 Limpando cache e arquivos antigos..."
rm -rf node_modules/.cache
rm -rf dist/
rm -rf .vite/

echo "📋 Fazendo pull das correções..."
git pull

echo "🔧 Reinstalando dependências..."
npm install

echo "🔧 Rebuildando frontend..."
npm run build

echo "📁 Copiando arquivos para Nginx..."
cp -r dist/* /var/www/desfollow/

echo "🔄 Recarregando Nginx..."
systemctl reload nginx

echo ""
echo "✅ Frontend rebuildado com requisições HTTP!"
echo ""
echo "📋 Verificando se funcionou..."
echo "   - Acesse: http://www.desfollow.com.br"
echo "   - Abra o console do browser (F12)"
echo "   - Verifique se as requisições são para HTTP"
echo "   - Teste: curl http://api.desfollow.com.br/api/health"
echo ""
echo "🔍 Para verificar no browser:"
echo "   - Pressione F12"
echo "   - Vá na aba Network"
echo "   - Faça um scan"
echo "   - Verifique se as requisições são para http://api.desfollow.com.br" 