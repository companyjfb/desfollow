#!/bin/bash

echo "🚀 BUILDANDO E MOVENDO FRONTEND PARA NGINX"
echo "=========================================="

cd /root/desfollow

echo "📋 1. Verificando dependências do frontend..."
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependências..."
    npm install
fi

echo "📋 2. Fazendo build do frontend..."
npm run build

echo "📋 3. Verificando se build foi criado..."
if [ ! -d "dist" ]; then
    echo "❌ Build falhou - diretório 'dist' não encontrado"
    exit 1
fi

echo "📋 4. Criando diretório de destino..."
mkdir -p /var/www/html/desfollow

echo "📋 5. Removendo frontend antigo..."
rm -rf /var/www/html/desfollow/*

echo "📋 6. Copiando arquivos do build..."
cp -r dist/* /var/www/html/desfollow/

echo "📋 7. Ajustando permissões..."
chown -R www-data:www-data /var/www/html/desfollow
chmod -R 755 /var/www/html/desfollow

echo "📋 8. Verificando arquivos copiados..."
echo "📁 Arquivos em /var/www/html/desfollow:"
ls -la /var/www/html/desfollow/

echo "📋 9. Testando frontend..."
if [ -f "/var/www/html/desfollow/index.html" ]; then
    echo "✅ index.html encontrado!"
    echo "📄 Primeiras linhas do index.html:"
    head -5 /var/www/html/desfollow/index.html
else
    echo "❌ index.html não encontrado!"
    exit 1
fi

echo ""
echo "✅ FRONTEND BUILDADO E MOVIDO COM SUCESSO!"
echo "========================================="
echo "🌐 Acesse: https://www.desfollow.com.br"
echo "📋 Logs: tail -f /var/log/nginx/frontend_error.log" 