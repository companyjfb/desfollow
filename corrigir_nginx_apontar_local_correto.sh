#!/bin/bash

echo "🎯 CORRIGINDO NGINX PARA APONTAR LOCAL CORRETO"
echo "=============================================="
echo ""

cd /root/desfollow

# 1. Verificar arquivos nos dois locais
echo "📋 1. Verificando arquivos nos dois locais..."
echo "🔍 /var/www/desfollow (ATUAL DO NGINX):"
ls -la /var/www/desfollow/index.html 2>/dev/null || echo "❌ Não existe"

echo ""
echo "🔍 /var/www/html/desfollow (MAIS RECENTE):"
ls -la /var/www/html/desfollow/index.html 2>/dev/null || echo "❌ Não existe"

# 2. Atualizar código e fazer novo build
echo ""
echo "📋 2. Atualizando código e fazendo novo build..."
git pull origin main
rm -rf dist
npm run build

if [ ! -d "dist" ]; then
    echo "❌ Erro no build"
    exit 1
fi
echo "✅ Novo build criado"

# 3. Copiar novo frontend para o local que o nginx está usando
echo ""
echo "📋 3. Copiando novo frontend para /var/www/desfollow..."
rm -rf /var/www/desfollow/*
cp -r dist/* /var/www/desfollow/

# 4. Também copiar para o outro local como backup
echo ""
echo "📋 4. Atualizando backup em /var/www/html/desfollow..."
rm -rf /var/www/html/desfollow/*
cp -r dist/* /var/www/html/desfollow/

# 5. Corrigir permissões
echo ""
echo "📋 5. Corrigindo permissões..."
chown -R www-data:www-data /var/www/desfollow
chmod -R 755 /var/www/desfollow
chown -R www-data:www-data /var/www/html/desfollow
chmod -R 755 /var/www/html/desfollow

# 6. Verificar que arquivos foram atualizados
echo ""
echo "📋 6. Verificando arquivos atualizados..."
echo "📅 Timestamp do index.html em /var/www/desfollow:"
ls -la /var/www/desfollow/index.html

echo ""
echo "📅 Timestamp do index.html em /var/www/html/desfollow:"
ls -la /var/www/html/desfollow/index.html

# 7. Verificar conteúdo do index.html
echo ""
echo "📋 7. Verificando conteúdo do index.html..."
echo "🔍 Primeiras linhas do arquivo principal:"
head -3 /var/www/desfollow/index.html

# 8. Recarregar nginx
echo ""
echo "📋 8. Recarregando nginx..."
systemctl reload nginx

# 9. Teste final
echo ""
echo "📋 9. Testando acesso..."
curl -s -I http://localhost/ | head -1

echo ""
echo "✅ CORREÇÃO COMPLETA!"
echo "===================="
echo ""
echo "🎯 AGORA TESTE:"
echo "1. https://www.desfollow.com.br"
echo "2. Ctrl+Shift+R (hard refresh)"
echo "3. Ou aba anônima"
echo ""
echo "📍 Nginx configurado para: /var/www/desfollow"
echo "📍 Frontend atualizado em: /var/www/desfollow"
echo "📍 Backup mantido em: /var/www/html/desfollow"
echo ""
echo "🔍 Se ainda não funcionar, verifique cache do navegador"
echo "🔍 Ou execute: systemctl restart nginx"