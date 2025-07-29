#!/bin/bash

echo "🔧 Instalando dependências do frontend..."
echo "========================================"

echo "📋 Verificando se npm está instalado..."
if ! command -v npm &> /dev/null; then
    echo "❌ npm não está instalado!"
    echo "🔧 Instalando Node.js e npm..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    apt-get install -y nodejs
    echo "✅ Node.js e npm instalados!"
else
    echo "✅ npm já está instalado!"
fi

echo ""
echo "📋 Fazendo pull das correções..."
cd ~/desfollow
git pull

echo "🔧 Instalando dependências do projeto..."
npm install

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