#!/bin/bash

echo "🔍 VERIFICAÇÃO SSL PÓS-CORREÇÃO - DESFOLLOW"
echo "==========================================="

# Verificar configuração nginx ativa
echo "📋 1. Verificando configuração nginx ativa..."
echo "Sites habilitados:"
ls -la /etc/nginx/sites-enabled/

echo ""
echo "Configuração ativa:"
cat /etc/nginx/sites-enabled/desfollow | head -30

echo ""
echo "📋 2. Verificando certificados disponíveis..."
echo "Certificados Let's Encrypt:"
ls -la /etc/letsencrypt/live/

echo ""
echo "Certificado desfollow.com.br:"
if [ -f /etc/letsencrypt/live/desfollow.com.br/fullchain.pem ]; then
    echo "✅ Certificado encontrado"
    openssl x509 -in /etc/letsencrypt/live/desfollow.com.br/fullchain.pem -text -noout | grep -E "(Subject|Issuer|Not After|DNS)"
else
    echo "❌ Certificado não encontrado"
fi

echo ""
echo "📋 3. Testando conectividade SSL..."

# Teste interno
echo "Teste interno (curl):"
curl -I https://desfollow.com.br --connect-timeout 10 --max-time 30 -k

echo ""
echo "Teste SSL direto:"
timeout 10 openssl s_client -connect desfollow.com.br:443 -servername desfollow.com.br 2>/dev/null | grep -E "(Verify return code|Protocol|Cipher|subject|issuer)"

echo ""
echo "📋 4. Verificando logs nginx..."
echo "Últimos erros nginx:"
tail -10 /var/log/nginx/error.log

echo ""
echo "Últimos acessos frontend:"
tail -5 /var/log/nginx/frontend_ssl_access.log 2>/dev/null || echo "Log não encontrado"

echo ""
echo "📋 5. Verificando portas abertas..."
netstat -tlnp | grep ":443\|:80"

echo ""
echo "📋 6. Verificando status nginx..."
systemctl status nginx --no-pager -l

echo ""
echo "📋 7. Verificando DNS..."
nslookup desfollow.com.br 8.8.8.8

echo ""
echo "📋 8. Testando com diferentes user agents..."
echo "Teste padrão:"
curl -sI https://desfollow.com.br 2>&1 | head -5

echo ""
echo "Teste mobile Safari:"
curl -sI https://desfollow.com.br -H "User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1" 2>&1 | head -5

echo ""
echo "📋 DIAGNÓSTICO CONCLUÍDO!"