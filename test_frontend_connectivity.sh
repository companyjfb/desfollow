#!/bin/bash

echo "🔍 Testando conectividade do frontend com a API..."
echo "================================================"

# Testar se o frontend está acessível
echo "📱 Testando frontend (desfollow.com.br):"
curl -I https://desfollow.com.br --connect-timeout 10

echo ""
echo "🔌 Testando API (api.desfollow.com.br):"
curl -I https://api.desfollow.com.br --connect-timeout 10

echo ""
echo "🔍 Testando endpoint específico da API:"
curl -I https://api.desfollow.com.br/api/health --connect-timeout 10

echo ""
echo "📊 Testando POST para /api/scan:"
curl -X POST https://api.desfollow.com.br/api/scan \
  -H "Content-Type: application/json" \
  -d '{"username":"instagram"}' \
  --connect-timeout 30 \
  --max-time 60

echo ""
echo "🔍 Verificando logs do Nginx:"
tail -20 /var/log/nginx/access.log

echo ""
echo "🔍 Verificando logs de erro do Nginx:"
tail -20 /var/log/nginx/error.log

echo ""
echo "🔍 Verificando se o backend está respondendo localmente:"
curl -I http://localhost:8000/api/health --connect-timeout 5

echo ""
echo "🔍 Verificando se há processos do backend rodando:"
ps aux | grep gunicorn

echo ""
echo "🔍 Verificando uso de memória e CPU:"
top -bn1 | head -10

echo ""
echo "✅ Teste de conectividade concluído!" 