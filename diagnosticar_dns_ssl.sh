#!/bin/bash

echo "🔍 DIAGNÓSTICO COMPLETO DNS E SSL"
echo "================================="
echo

echo "📋 1. Verificando conectividade externa..."
echo "• Testando conectividade geral:"
curl -s http://google.com > /dev/null && echo "✅ Internet OK" || echo "❌ Sem internet"

echo
echo "📋 2. Verificando DNS dos domínios..."
echo "• desfollow.com.br:"
dig +short desfollow.com.br A
nslookup desfollow.com.br | grep "Address:"

echo "• www.desfollow.com.br:"  
dig +short www.desfollow.com.br A
nslookup www.desfollow.com.br | grep "Address:"

echo "• api.desfollow.com.br:"
dig +short api.desfollow.com.br A  
nslookup api.desfollow.com.br | grep "Address:"

echo
echo "📋 3. Verificando IP do servidor atual..."
echo "• IP público do servidor:"
curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com

echo
echo "📋 4. Testando acessibilidade HTTP dos domínios..."
echo "• Testando desfollow.com.br:"
curl -s -o /dev/null -w "Status: %{http_code} | Tempo: %{time_total}s" http://desfollow.com.br
echo

echo "• Testando www.desfollow.com.br:"
curl -s -o /dev/null -w "Status: %{http_code} | Tempo: %{time_total}s" http://www.desfollow.com.br  
echo

echo "• Testando api.desfollow.com.br:"
curl -s -o /dev/null -w "Status: %{http_code} | Tempo: %{time_total}s" http://api.desfollow.com.br
echo

echo
echo "📋 5. Verificando portas abertas..."
echo "• Porta 80:"
netstat -tlnp | grep :80 || echo "Porta 80 livre"

echo "• Porta 443:"  
netstat -tlnp | grep :443 || echo "Porta 443 livre"

echo
echo "📋 6. Verificando firewall..."
ufw status || echo "UFW não configurado"

echo
echo "📋 7. Verificando certificados existentes..."
ls -la /etc/letsencrypt/live/ 2>/dev/null || echo "Nenhum certificado encontrado"

if [ -d "/etc/letsencrypt/live/desfollow.com.br" ]; then
    echo "📋 Detalhes do certificado existente:"
    certbot certificates
fi

echo
echo "📋 8. Verificando logs do LetsEncrypt..."
echo "• Últimas 10 linhas do log:"
tail -10 /var/log/letsencrypt/letsencrypt.log 2>/dev/null || echo "Log não encontrado"

echo
echo "📋 9. Verificando configuração Nginx..."
echo "• Sites habilitados:"
ls -la /etc/nginx/sites-enabled/

echo "• Testando configuração:"
nginx -t

echo
echo "📋 10. Verificando processo Nginx..."
ps aux | grep nginx | head -5

echo
echo "🎯 RESUMO DO DIAGNÓSTICO:"
echo "========================"

# Verificar se todos os domínios apontam para o IP correto
SERVER_IP=$(curl -s ifconfig.me)
DNS_DESFOLLOW=$(dig +short desfollow.com.br A)
DNS_WWW=$(dig +short www.desfollow.com.br A)  
DNS_API=$(dig +short api.desfollow.com.br A)

echo "IP do servidor: $SERVER_IP"
echo "DNS desfollow.com.br: $DNS_DESFOLLOW"
echo "DNS www.desfollow.com.br: $DNS_WWW"
echo "DNS api.desfollow.com.br: $DNS_API"

if [ "$SERVER_IP" = "$DNS_DESFOLLOW" ] && [ "$SERVER_IP" = "$DNS_WWW" ] && [ "$SERVER_IP" = "$DNS_API" ]; then
    echo "✅ Todos os DNS estão corretos!"
    echo "✅ Pode prosseguir com a instalação SSL"
else
    echo "❌ PROBLEMA: DNS não apontam para o servidor correto!"
    echo "⚠️ Corrija o DNS antes de instalar SSL"
fi