#!/bin/bash

echo "🔍 DIAGNÓSTICO DETALHADO ACESSO MÓVEL - DESFOLLOW"
echo "================================================"

# Verificar se o script anterior foi executado
echo "📋 1. Verificando se a correção foi aplicada..."
if grep -q "CONFIGURAÇÃO NGINX SSL MÓVEL FINAL" /etc/nginx/sites-available/desfollow 2>/dev/null; then
    echo "✅ Configuração final aplicada"
else
    echo "❌ Configuração final NÃO aplicada - execute ./corrigir_ssl_final_mobile.sh primeiro"
fi

echo ""
echo "📋 2. Testando conectividade básica..."

# Teste de ping
echo "Teste de ping:"
ping -c 3 desfollow.com.br

echo ""
echo "📋 3. Testando resolução DNS..."
echo "DNS via Google:"
nslookup desfollow.com.br 8.8.8.8

echo ""
echo "DNS via Cloudflare:"
nslookup desfollow.com.br 1.1.1.1

echo ""
echo "📋 4. Testando portas específicas..."
echo "Porta 443 (HTTPS):"
timeout 10 telnet desfollow.com.br 443 < /dev/null 2>&1 | head -5

echo ""
echo "Porta 80 (HTTP):"
timeout 10 telnet desfollow.com.br 80 < /dev/null 2>&1 | head -5

echo ""
echo "📋 5. Testando SSL com diferentes métodos..."

echo "Teste SSL básico:"
timeout 15 openssl s_client -connect desfollow.com.br:443 -servername desfollow.com.br < /dev/null 2>/dev/null | grep -E "(Verify return code|Protocol|Cipher|subject|issuer)"

echo ""
echo "Teste SSL com SNI explícito:"
timeout 15 openssl s_client -connect desfollow.com.br:443 -servername desfollow.com.br -verify_hostname desfollow.com.br < /dev/null 2>/dev/null | grep -E "(Verify return code|Protocol|Cipher)"

echo ""
echo "📋 6. Testando com curl simulando diferentes dispositivos..."

echo "Curl padrão:"
curl -v --connect-timeout 10 --max-time 20 https://desfollow.com.br 2>&1 | head -10

echo ""
echo "Curl com User-Agent iPhone:"
curl -v --connect-timeout 10 --max-time 20 -H "User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1" https://desfollow.com.br 2>&1 | head -10

echo ""
echo "📋 7. Verificando certificado detalhadamente..."
echo "Informações do certificado:"
openssl x509 -in /etc/letsencrypt/live/desfollow.com.br/fullchain.pem -text -noout | grep -A 10 -B 2 "Subject Alternative Name"

echo ""
echo "Verificando cadeia de certificados:"
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt /etc/letsencrypt/live/desfollow.com.br/fullchain.pem

echo ""
echo "📋 8. Verificando logs em tempo real..."
echo "Últimos 20 erros nginx:"
tail -20 /var/log/nginx/error.log

echo ""
echo "Últimos 10 acessos frontend:"
tail -10 /var/log/nginx/frontend_ssl_access.log 2>/dev/null || echo "Log não encontrado"

echo ""
echo "📋 9. Testando com wget (outro método)..."
wget --spider --server-response --timeout=10 https://desfollow.com.br 2>&1 | head -10

echo ""
echo "📋 10. Verificando firewall..."
echo "Status do UFW:"
ufw status

echo ""
echo "Regras iptables (portas 80/443):"
iptables -L INPUT -n | grep -E ":80|:443"

echo ""
echo "📋 11. Verificando se há conflitos de IP..."
echo "IPs configurados no servidor:"
ip addr show | grep "inet " | grep -v "127.0.0.1"

echo ""
echo "📋 12. Testando diferentes versões TLS..."
echo "TLS 1.2:"
timeout 10 openssl s_client -connect desfollow.com.br:443 -tls1_2 < /dev/null 2>/dev/null | grep -E "(Protocol|Cipher|Verify return code)"

echo ""
echo "TLS 1.3:"
timeout 10 openssl s_client -connect desfollow.com.br:443 -tls1_3 < /dev/null 2>/dev/null | grep -E "(Protocol|Cipher|Verify return code)"

echo ""
echo "📋 DIAGNÓSTICO COMPLETO CONCLUÍDO!"
echo "================================="
echo "🔍 PRÓXIMOS PASSOS:"
echo "1. Se houver erros de DNS, verificar propagação"
echo "2. Se houver timeout, verificar firewall/iptables"
echo "3. Se SSL falhar, verificar certificado"
echo "4. Se curl funcionar mas mobile não, problema pode ser no dispositivo/rede"