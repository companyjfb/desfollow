#!/bin/bash

echo "🔍 DIAGNÓSTICO SSL PARA MOBILE - DESFOLLOW"
echo "=========================================="

# Verificar configuração nginx ativa
echo "📋 1. Verificando configuração nginx ativa..."
echo "Configuração em sites-enabled:"
ls -la /etc/nginx/sites-enabled/

echo ""
echo "Configuração ativa do desfollow:"
if [ -f /etc/nginx/sites-enabled/desfollow ]; then
    echo "✅ Arquivo de configuração encontrado"
    echo "Conteúdo (primeiras 50 linhas):"
    head -50 /etc/nginx/sites-enabled/desfollow
else
    echo "❌ Arquivo de configuração não encontrado"
fi

echo ""
echo "📋 2. Verificando certificados SSL..."
echo "Certificados em /etc/letsencrypt/live/:"
ls -la /etc/letsencrypt/live/

echo ""
echo "Verificando certificado principal:"
if [ -f /etc/letsencrypt/live/desfollow.com.br/fullchain.pem ]; then
    echo "✅ Certificado principal encontrado"
    openssl x509 -in /etc/letsencrypt/live/desfollow.com.br/fullchain.pem -text -noout | grep -E "(Subject|Issuer|Not After|DNS)"
else
    echo "❌ Certificado principal não encontrado"
fi

echo ""
echo "📋 3. Testando SSL com ferramentas..."

# Teste básico de conectividade
echo "Teste de conectividade HTTPS:"
curl -I https://desfollow.com.br --connect-timeout 10 --max-time 30 || echo "❌ Falha na conectividade HTTPS"

echo ""
echo "Teste SSL Labs (simulação):"
echo "Execute: https://www.ssllabs.com/ssltest/analyze.html?d=desfollow.com.br"

echo ""
echo "📋 4. Verificando compatibilidade móvel..."

# Testar protocolos SSL
echo "Testando TLS 1.2:"
openssl s_client -connect desfollow.com.br:443 -tls1_2 -servername desfollow.com.br < /dev/null 2>/dev/null | grep -E "(Verify return code|Protocol|Cipher)"

echo ""
echo "Testando TLS 1.3:"
openssl s_client -connect desfollow.com.br:443 -tls1_3 -servername desfollow.com.br < /dev/null 2>/dev/null | grep -E "(Verify return code|Protocol|Cipher)"

echo ""
echo "📋 5. Verificando cadeia de certificados..."
echo "Verificando cadeia completa:"
openssl s_client -connect desfollow.com.br:443 -servername desfollow.com.br -showcerts < /dev/null 2>/dev/null | grep -E "(subject|issuer)"

echo ""
echo "📋 6. Verificando logs nginx..."
echo "Últimos erros SSL:"
tail -20 /var/log/nginx/error.log | grep -i ssl

echo ""
echo "Últimos acessos frontend:"
tail -10 /var/log/nginx/frontend_access.log 2>/dev/null || echo "Log não encontrado"

echo ""
echo "📋 7. Status do nginx..."
systemctl status nginx --no-pager

echo ""
echo "🔧 SUGESTÕES PARA CORREÇÃO:"
echo "1. Verificar se o certificado inclui toda a cadeia (fullchain.pem)"
echo "2. Verificar compatibilidade dos ciphers com Safari mobile"
echo "3. Verificar se o OCSP stapling está configurado"
echo "4. Verificar se não há mixed content (HTTP em página HTTPS)"

echo ""
echo "📋 DIAGNÓSTICO CONCLUÍDO!"