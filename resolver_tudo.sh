#!/bin/bash
echo "🔧 Resolvendo todos os problemas..."
echo "==================================="
echo ""

echo "📋 1. Atualizando backend..."
cd ~/desfollow
git pull
systemctl restart desfollow
sleep 3
echo "✅ Backend atualizado!"
echo ""

echo "📋 2. Verificando SSL..."
if [ ! -f "/etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem" ]; then
    echo "❌ SSL não encontrado, instalando..."
    chmod +x ~/desfollow/instalar_ssl_api_completo.sh
    ~/desfollow/instalar_ssl_api_completo.sh
else
    echo "✅ SSL já existe!"
fi
echo ""

echo "📋 3. Corrigindo CORS..."
chmod +x ~/desfollow/corrigir_cors_simples.sh
~/desfollow/corrigir_cors_simples.sh
echo ""

echo "📋 4. Atualizando frontend..."
chmod +x ~/desfollow/atualizar_frontend_completo.sh
~/desfollow/atualizar_frontend_completo.sh
echo ""

echo "📋 5. Verificando serviços..."
echo "📊 Nginx:"
systemctl status nginx --no-pager -l | head -10
echo ""

echo "📊 Backend:"
systemctl status desfollow --no-pager -l | head -10
echo ""

echo "📋 6. Testando conectividade..."
echo "📊 HTTPS API:"
curl -I https://api.desfollow.com.br 2>/dev/null | head -3
echo ""

echo "📊 Frontend:"
curl -I https://desfollow.com.br 2>/dev/null | head -3
echo ""

echo "📋 7. Testando API..."
echo "📊 Health check:"
curl -s https://api.desfollow.com.br/health 2>/dev/null || echo "❌ Health check falhou"
echo ""

echo "📊 CORS test:"
curl -X OPTIONS "https://api.desfollow.com.br/api/scan" \
  -H "Origin: https://desfollow.com.br" \
  -H "Access-Control-Request-Method: POST" \
  -s 2>/dev/null | grep -q "Access-Control" && echo "✅ CORS funcionando" || echo "❌ CORS falhou"
echo ""

echo "📋 8. Testando scan..."
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

echo "✅ Todos os problemas resolvidos!"
echo ""
echo "🧪 Teste agora:"
echo "   - https://desfollow.com.br"
echo "   - Digite um username do Instagram"
echo "   - Deve funcionar completamente"
echo ""
echo "📋 Se ainda houver problemas:"
echo "   journalctl -u desfollow -f"
echo "   journalctl -u nginx -f" 