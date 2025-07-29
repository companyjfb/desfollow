#!/bin/bash

echo "🔧 Atualizando frontend com requisições HTTP..."
echo "=============================================="

echo "📋 Fazendo pull das correções..."
cd ~/desfollow
git pull

echo "🔧 Rebuildando frontend..."
npm run build

echo "📁 Copiando arquivos para Nginx..."
cp -r dist/* /var/www/desfollow/

echo "🔄 Recarregando Nginx..."
systemctl reload nginx

echo ""
echo "✅ Frontend atualizado!"
echo ""
echo "📋 Verificando se funcionou..."
echo "   - Acesse: http://www.desfollow.com.br"
echo "   - Verifique no console do browser se as requisições são HTTP"
echo "   - Teste: curl http://api.desfollow.com.br/api/health" 