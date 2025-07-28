#!/bin/bash

echo "🔍 Verificando DNS e conectividade final..."
echo "=========================================="

# Verificar IP do servidor
echo "📊 IP do servidor atual:"
SERVER_IP=$(curl -s ifconfig.me)
echo $SERVER_IP

# Verificar DNS dos domínios
echo ""
echo "🔍 Verificando DNS de desfollow.com.br:"
nslookup desfollow.com.br

echo ""
echo "🔍 Verificando DNS de api.desfollow.com.br:"
nslookup api.desfollow.com.br

echo ""
echo "🌐 Testando conectividade:"
echo "desfollow.com.br:"
curl -I http://desfollow.com.br --connect-timeout 10 2>/dev/null || echo "❌ Não acessível"

echo ""
echo "api.desfollow.com.br:"
curl -I http://api.desfollow.com.br --connect-timeout 10 2>/dev/null || echo "❌ Não acessível"

echo ""
echo "🔍 Testando localmente:"
echo "Frontend local:"
curl -I http://localhost 2>/dev/null || echo "❌ Não acessível"

echo ""
echo "API local:"
curl -I http://localhost:8000/api/health 2>/dev/null || echo "❌ Não acessível"

echo ""
echo "📋 Status dos serviços:"
systemctl status nginx --no-pager
echo ""
systemctl status desfollow --no-pager

echo ""
echo "🔍 Verificando arquivos do frontend:"
ls -la /var/www/desfollow/

echo ""
echo "✅ Verificação concluída!"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "1. Se desfollow.com.br não aponta para $SERVER_IP, configure o DNS"
echo "2. Se aponta, teste em http://desfollow.com.br"
echo "3. Se não funcionar, teste em http://$SERVER_IP" 