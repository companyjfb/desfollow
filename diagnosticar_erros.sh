#!/bin/bash
echo "🔍 Diagnosticando erros..."
echo "=========================="
echo ""

echo "📋 Status dos serviços..."
echo "1. Nginx:"
systemctl status nginx --no-pager -l
echo ""

echo "2. Backend:"
systemctl status desfollow --no-pager -l
echo ""

echo "3. SSL:"
if [ -f "/etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem" ]; then
    echo "✅ Certificado SSL existe"
    openssl x509 -in /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem -text -noout | grep -E "(Subject|Not After)"
else
    echo "❌ Certificado SSL não encontrado"
fi
echo ""

echo "4. Testando conectividade..."
echo "📊 HTTP -> HTTPS redirecionamento:"
curl -I http://api.desfollow.com.br 2>/dev/null | head -3
echo ""

echo "📊 HTTPS direto:"
curl -I https://api.desfollow.com.br 2>/dev/null | head -3
echo ""

echo "5. Testando API endpoints..."
echo "📊 Health check:"
curl -s https://api.desfollow.com.br/health 2>/dev/null || echo "❌ Health check falhou"
echo ""

echo "📊 CORS test:"
curl -X OPTIONS "https://api.desfollow.com.br/api/scan" \
  -H "Origin: https://desfollow.com.br" \
  -H "Access-Control-Request-Method: POST" \
  -v 2>&1 | grep -E "(Access-Control|HTTP/)" || echo "❌ CORS test falhou"
echo ""

echo "6. Logs recentes do backend..."
echo "📋 Últimas 20 linhas:"
journalctl -u desfollow --no-pager -n 20
echo ""

echo "7. Logs recentes do Nginx..."
echo "📋 Últimas 10 linhas:"
journalctl -u nginx --no-pager -n 10
echo ""

echo "8. Configuração do Nginx..."
echo "📋 Teste de sintaxe:"
nginx -t
echo ""

echo "9. Verificando arquivos..."
echo "📋 Frontend existe:"
ls -la /var/www/desfollow/ 2>/dev/null || echo "❌ Frontend não encontrado"
echo ""

echo "10. Testando scan completo..."
echo "📊 Fazendo scan de teste:"
SCAN_RESPONSE=$(curl -X POST "https://api.desfollow.com.br/api/scan" \
  -H "Content-Type: application/json" \
  -H "Origin: https://desfollow.com.br" \
  -d '{"username": "instagram"}' \
  -s 2>/dev/null)

if [ ! -z "$SCAN_RESPONSE" ]; then
    echo "✅ Scan funcionou: $SCAN_RESPONSE"
else
    echo "❌ Scan falhou"
fi
echo ""

echo "✅ Diagnóstico concluído!"
echo ""
echo "📋 Próximos passos baseados nos erros encontrados:"
echo "1. Se SSL não existe: execute instalar_ssl_api_completo.sh"
echo "2. Se CORS falha: execute corrigir_cors_simples.sh"
echo "3. Se backend não inicia: execute atualizar_backend_api.sh"
echo "4. Se frontend não carrega: execute atualizar_frontend_completo.sh" 