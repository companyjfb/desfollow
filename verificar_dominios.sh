#!/bin/bash

echo "🔍 Verificando configuração dos domínios..."
echo "=========================================="

# Verificar IP do servidor
echo "📊 IP do servidor atual:"
curl -s ifconfig.me
echo ""

# Verificar DNS dos domínios
echo "🔍 Verificando DNS de desfollow.com.br:"
nslookup desfollow.com.br
echo ""

echo "🔍 Verificando DNS de api.desfollow.com.br:"
nslookup api.desfollow.com.br
echo ""

echo "🔍 Verificando DNS de www.desfollow.com.br:"
nslookup www.desfollow.com.br
echo ""

# Verificar se os domínios estão acessíveis
echo "🌐 Testando acesso HTTP:"
echo "desfollow.com.br:"
curl -I http://desfollow.com.br --connect-timeout 10 2>/dev/null || echo "❌ Não acessível"
echo ""

echo "api.desfollow.com.br:"
curl -I http://api.desfollow.com.br --connect-timeout 10 2>/dev/null || echo "❌ Não acessível"
echo ""

echo "www.desfollow.com.br:"
curl -I http://www.desfollow.com.br --connect-timeout 10 2>/dev/null || echo "❌ Não acessível"
echo ""

# Verificar configuração do Nginx
echo "🔧 Verificando configuração do Nginx:"
nginx -t
echo ""

echo "📋 Domínios configurados no Nginx:"
grep -r "server_name" /etc/nginx/sites-enabled/
echo ""

echo "📊 Status do Nginx:"
systemctl status nginx --no-pager
echo ""

echo "✅ Verificação concluída!" 