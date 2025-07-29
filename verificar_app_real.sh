#!/bin/bash
echo "🌐 Verificando se o app real está funcionando..."
echo "================================================"
echo ""

echo "📋 1. Verificando frontend..."
echo "📊 Desfollow.com.br:"
curl -s -I https://desfollow.com.br | head -5
echo ""

echo "📊 www.desfollow.com.br:"
curl -s -I https://www.desfollow.com.br | head -5
echo ""

echo "📋 2. Testando API diretamente..."
echo "📊 Health check:"
curl -s https://api.desfollow.com.br/health
echo ""
echo ""

echo "📊 Scan endpoint (teste direto):"
curl -s -X POST https://api.desfollow.com.br/scan \
  -H "Content-Type: application/json" \
  -d '{"username": "instagram"}' \
  -w "\nStatus: %{http_code}\n"
echo ""
echo ""

echo "📋 3. Verificando se o frontend está fazendo requisições corretas..."
echo "📊 Verificando console do navegador (simulado):"
echo "   - Abra https://desfollow.com.br"
echo "   - Abra DevTools (F12)"
echo "   - Vá na aba Console"
echo "   - Digite um username e clique em scan"
echo "   - Verifique se há erros no console"
echo ""

echo "📋 4. Verificando se o frontend está usando HTTPS..."
echo "📊 Verificando configuração do frontend:"
cd ~/desfollow
if [ -f "src/utils/ghosts.ts" ]; then
    echo "📊 Configuração atual do ghosts.ts:"
    grep -n "api.desfollow.com.br" src/utils/ghosts.ts || echo "❌ Não encontrou configuração da API"
else
    echo "❌ Arquivo ghosts.ts não encontrado"
fi
echo ""

echo "📋 5. Verificando build do frontend..."
echo "📊 Verificando se o build está atualizado:"
ls -la dist/ 2>/dev/null | head -5 || echo "❌ Pasta dist não encontrada"
echo ""

echo "📋 6. Testando scan via frontend (simulado)..."
echo "📊 Para testar via frontend:"
echo "   1. Acesse https://desfollow.com.br"
echo "   2. Digite um username do Instagram"
echo "   3. Clique em 'Analisar'"
echo "   4. Verifique se aparece 'Processando...'"
echo "   5. Aguarde e verifique se mostra resultados"
echo ""

echo "📋 7. Verificando logs do backend durante scan..."
echo "📊 Para ver logs em tempo real:"
echo "   journalctl -u desfollow -f"
echo ""

echo "📋 8. Verificando se há problemas de CORS..."
echo "📊 Testando CORS:"
curl -s -H "Origin: https://desfollow.com.br" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -X OPTIONS https://api.desfollow.com.br/scan
echo ""
echo ""

echo "✅ Verificação concluída!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Acesse https://desfollow.com.br"
echo "   2. Teste o scan com um username real"
echo "   3. Verifique se funciona no navegador"
echo "   4. Se não funcionar, verifique console do navegador" 