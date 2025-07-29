#!/bin/bash

echo "🔍 Verificando DNS do desfollow.com.br..."
echo "=========================================="

echo "📋 Verificando resolução atual:"
echo "desfollow.com.br:"
nslookup desfollow.com.br
echo ""
echo "www.desfollow.com.br:"
nslookup www.desfollow.com.br
echo ""
echo "api.desfollow.com.br:"
nslookup api.desfollow.com.br

echo ""
echo "🔍 Verificando IP do servidor atual:"
curl -s ifconfig.me
echo ""

echo ""
echo "🔍 Testando conectividade:"
echo "Testando desfollow.com.br:"
curl -I https://desfollow.com.br 2>/dev/null || echo "❌ Não acessível"
echo ""
echo "Testando www.desfollow.com.br:"
curl -I https://www.desfollow.com.br 2>/dev/null || echo "❌ Não acessível"
echo ""
echo "Testando api.desfollow.com.br:"
curl -I https://api.desfollow.com.br/api/health 2>/dev/null || echo "❌ Não acessível"

echo ""
echo "🔧 Verificando configuração do Nginx:"
nginx -t

echo ""
echo "📊 Status dos serviços:"
systemctl status nginx --no-pager
echo ""
systemctl status desfollow --no-pager

echo ""
echo "🔍 Verificando se o frontend está sendo servido:"
ls -la /var/www/html/

echo ""
echo "🔍 Testando localmente:"
echo "Frontend local:"
curl -I http://localhost/ 2>/dev/null || echo "❌ Frontend local não funciona"
echo ""
echo "API local:"
curl -I http://localhost:8000/api/health 2>/dev/null || echo "❌ API local não funciona"

echo ""
echo "✅ Verificação DNS concluída!"
echo ""
echo "💡 Se o DNS ainda aponta para o servidor antigo, você precisa:"
echo "1. Acessar o painel de controle do seu provedor de DNS"
echo "2. Alterar os registros A para apontar para o IP atual do VPS"
echo "3. Aguardar a propagação (pode levar até 24h)" 