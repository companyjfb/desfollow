#!/bin/bash

echo "🔥 CORREÇÃO DEFINITIVA DO FRONTEND"
echo "=================================="
echo ""

cd /root/desfollow

# 1. Verificar qual configuração nginx está ativa
echo "📋 1. Verificando configuração nginx ativa..."
if [ -f "/etc/nginx/sites-enabled/desfollow" ]; then
    NGINX_ROOT=$(grep -m1 "root /var/www" /etc/nginx/sites-enabled/desfollow | awk '{print $2}' | tr -d ';')
    echo "✅ Nginx configurado para: $NGINX_ROOT"
else
    echo "❌ Configuração nginx não encontrada!"
    exit 1
fi

# 2. Atualizar código
echo ""
echo "📋 2. Atualizando código..."
git pull origin main

# 3. Limpar tudo
echo ""
echo "📋 3. Limpando caches e builds antigos..."
rm -rf node_modules/.cache
rm -rf dist
npm cache clean --force

# 4. Instalar dependências
echo ""
echo "📋 4. Instalando dependências..."
npm install

# 5. Build
echo ""
echo "📋 5. Fazendo build..."
npm run build

if [ ! -d "dist" ]; then
    echo "❌ Build falhou - dist não encontrado"
    exit 1
fi

# 6. Remover todos os frontends antigos
echo ""
echo "📋 6. Removendo TODOS os frontends antigos..."
rm -rf /var/www/html/desfollow/*
rm -rf /var/www/desfollow/*
rm -rf /var/www/html/www/*

# 7. Criar diretórios se não existirem
echo ""
echo "📋 7. Criando diretórios necessários..."
mkdir -p "$NGINX_ROOT"
mkdir -p /var/www/html/desfollow
mkdir -p /var/www/desfollow

# 8. Copiar para TODOS os locais possíveis
echo ""
echo "📋 8. Copiando frontend para TODOS os locais..."
cp -r dist/* "$NGINX_ROOT/"
cp -r dist/* /var/www/html/desfollow/
cp -r dist/* /var/www/desfollow/

# 9. Corrigir permissões em TODOS
echo ""
echo "📋 9. Corrigindo permissões..."
chown -R www-data:www-data "$NGINX_ROOT"
chmod -R 755 "$NGINX_ROOT"
chown -R www-data:www-data /var/www/html/desfollow
chmod -R 755 /var/www/html/desfollow
chown -R www-data:www-data /var/www/desfollow
chmod -R 755 /var/www/desfollow

# 10. Verificar que arquivos foram copiados
echo ""
echo "📋 10. Verificando arquivos copiados..."
echo "🔍 Arquivos em $NGINX_ROOT:"
ls -la "$NGINX_ROOT" | head -5

echo ""
echo "🔍 Verificando index.html principal:"
if [ -f "$NGINX_ROOT/index.html" ]; then
    echo "✅ index.html encontrado em $NGINX_ROOT"
    echo "📄 Últimas linhas do index.html:"
    tail -3 "$NGINX_ROOT/index.html"
else
    echo "❌ index.html NÃO encontrado em $NGINX_ROOT"
    exit 1
fi

# 11. Força restart completo do nginx
echo ""
echo "📋 11. Reiniciando nginx COMPLETAMENTE..."
systemctl stop nginx
sleep 2
systemctl start nginx
systemctl status nginx --no-pager

# 12. Verificar se nginx está servindo corretamente
echo ""
echo "📋 12. Testando nginx..."
curl -s -I http://localhost/ | head -1

# 13. Verificar timestamp dos arquivos
echo ""
echo "📋 13. Verificando timestamp dos arquivos..."
echo "📅 Arquivos JS mais recentes:"
find "$NGINX_ROOT" -name "*.js" -type f -exec ls -la {} \; | head -2

echo ""
echo "✅ CORREÇÃO DEFINITIVA COMPLETA!"
echo "==============================="
echo ""
echo "🎯 PRÓXIMOS PASSOS:"
echo "1. Acesse: https://www.desfollow.com.br"
echo "2. Pressione Ctrl+Shift+R (hard refresh)"
echo "3. Ou abra uma aba anônima"
echo "4. Verifique o console (F12)"
echo ""
echo "🔍 VERIFICAR LOGS SE AINDA NÃO FUNCIONAR:"
echo "tail -f /var/log/nginx/frontend_access.log"
echo "tail -f /var/log/nginx/frontend_error.log"
echo ""
echo "📍 Frontend servido de: $NGINX_ROOT"