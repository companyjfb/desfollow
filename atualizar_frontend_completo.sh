#!/bin/bash

echo "🌐 Atualizando frontend completo..."
echo "==================================="

echo "📥 Fazendo pull das últimas mudanças..."
cd ~/desfollow
git pull

echo ""
echo "🔧 Verificando se npm está instalado..."
if ! command -v npm &> /dev/null; then
    echo "❌ npm não encontrado! Instalando Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    apt-get install -y nodejs
    echo "✅ Node.js instalado!"
else
    echo "✅ npm já está instalado!"
fi

echo ""
echo "📦 Instalando dependências..."
npm install

echo ""
echo "🏗️ Fazendo build do frontend..."
npm run build

echo ""
echo "📁 Copiando arquivos para o servidor web..."
rm -rf /var/www/desfollow/*
cp -r dist/* /var/www/desfollow/

echo ""
echo "🔧 Definindo permissões..."
chown -R www-data:www-data /var/www/desfollow
chmod -R 755 /var/www/desfollow

echo ""
echo "🔄 Recarregando Nginx..."
systemctl reload nginx

echo ""
echo "📋 Verificando status do Nginx..."
systemctl status nginx --no-pager -l

echo ""
echo "✅ Frontend atualizado!"
echo ""
echo "🧪 Teste agora:"
echo "   - https://desfollow.com.br"
echo "   - https://www.desfollow.com.br"
echo "   - Ambos devem mostrar a mesma versão"
echo ""
echo "📋 Para verificar se está funcionando:"
echo "   curl -I https://desfollow.com.br"
echo "   curl -I https://www.desfollow.com.br" 