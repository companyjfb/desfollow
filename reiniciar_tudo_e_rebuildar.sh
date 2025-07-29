#!/bin/bash

echo "🔄 Reiniciando tudo e rebuildando frontend..."
echo "============================================="

echo "📋 Parando serviços..."
systemctl stop desfollow
systemctl stop desfollow-limpeza

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

echo "🔄 Reiniciando todos os serviços..."
systemctl start desfollow
systemctl start desfollow-limpeza
systemctl reload nginx

echo ""
echo "✅ Tudo reiniciado e rebuildado!"
echo ""
echo "📋 Verificando status dos serviços..."
systemctl status desfollow --no-pager
echo ""
systemctl status desfollow-limpeza --no-pager
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