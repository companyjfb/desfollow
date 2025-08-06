#!/bin/bash

echo "🔍 DIAGNOSTICANDO CONFIGURAÇÃO NGINX"
echo "===================================="
echo ""

# 1. Verificar arquivos de configuração nginx
echo "📋 1. Verificando arquivos nginx..."
echo ""
echo "🔍 Sites disponíveis:"
ls -la /etc/nginx/sites-available/ 2>/dev/null || echo "❌ Diretório sites-available não existe"
echo ""
echo "🔍 Sites habilitados:"
ls -la /etc/nginx/sites-enabled/ 2>/dev/null || echo "❌ Diretório sites-enabled não existe"
echo ""

# 2. Verificar configuração principal nginx
echo "📋 2. Verificando configuração principal..."
if [ -f "/etc/nginx/nginx.conf" ]; then
    echo "✅ nginx.conf encontrado"
    grep -n "include.*sites" /etc/nginx/nginx.conf || echo "❌ Include sites não encontrado"
else
    echo "❌ nginx.conf não encontrado"
fi
echo ""

# 3. Verificar configurações de desfollow
echo "📋 3. Procurando configurações de desfollow..."
find /etc/nginx -name "*desfollow*" -type f 2>/dev/null
echo ""

# 4. Verificar qual configuração está sendo usada
echo "📋 4. Verificando configurações ativas..."
nginx -T 2>/dev/null | grep -A 5 -B 5 "desfollow\|www\.desfollow" || echo "❌ Nenhuma configuração desfollow encontrada"
echo ""

# 5. Verificar diretórios de frontend
echo "📋 5. Verificando diretórios de frontend..."
echo "🔍 /var/www/html/desfollow:"
ls -la /var/www/html/desfollow/ 2>/dev/null || echo "❌ Não existe"
echo ""
echo "🔍 /var/www/desfollow:"
ls -la /var/www/desfollow/ 2>/dev/null || echo "❌ Não existe"
echo ""
echo "🔍 /var/www/html:"
ls -la /var/www/html/ 2>/dev/null || echo "❌ Não existe"
echo ""

# 6. Verificar processo nginx
echo "📋 6. Verificando processo nginx..."
systemctl status nginx --no-pager
echo ""

# 7. Testar configuração nginx
echo "📋 7. Testando configuração nginx..."
nginx -t
echo ""

echo "✅ DIAGNÓSTICO COMPLETO!"
echo "========================"