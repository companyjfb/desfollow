#!/bin/bash
echo "🔧 Corrigindo endpoints da API..."
echo "================================="
echo ""

echo "📋 1. Testando endpoints corretos (com /api)..."
echo "📊 Testando /api/health:"
curl -s https://api.desfollow.com.br/api/health
echo ""
echo ""

echo "📊 Testando /api/scan (POST):"
curl -s -X POST https://api.desfollow.com.br/api/scan \
  -H "Content-Type: application/json" \
  -d '{"username": "instagram"}' \
  -w "\nStatus: %{http_code}\n"
echo ""
echo ""

echo "📋 2. Verificando se o frontend está usando os endpoints corretos..."
cd ~/desfollow
if [ -f "src/utils/ghosts.ts" ]; then
    echo "📊 Configuração atual do ghosts.ts:"
    grep -A 5 -B 5 "api.desfollow.com.br" src/utils/ghosts.ts
else
    echo "❌ Arquivo ghosts.ts não encontrado"
fi
echo ""

echo "📋 3. Verificando se o frontend está usando /api..."
if [ -f "src/utils/ghosts.ts" ]; then
    if grep -q "/api" src/utils/ghosts.ts; then
        echo "✅ Frontend está usando /api"
    else
        echo "❌ Frontend NÃO está usando /api"
        echo "📋 Precisamos corrigir o frontend"
    fi
else
    echo "❌ Não foi possível verificar"
fi
echo ""

echo "📋 4. Testando scan completo com endpoint correto..."
SCAN_RESPONSE=$(curl -s -X POST https://api.desfollow.com.br/api/scan \
  -H "Content-Type: application/json" \
  -d '{"username": "instagram"}')

echo "📊 Resposta do scan:"
echo "$SCAN_RESPONSE"
echo ""

# Extrair job_id
JOB_ID=$(echo "$SCAN_RESPONSE" | grep -o '"job_id":"[^"]*"' | cut -d'"' -f4)

if [ -n "$JOB_ID" ]; then
    echo "✅ Job ID extraído: $JOB_ID"
    echo ""
    
    echo "📋 5. Aguardando 10 segundos para processamento..."
    sleep 10
    echo ""
    
    echo "📋 6. Verificando status do job..."
    STATUS_RESPONSE=$(curl -s "https://api.desfollow.com.br/api/scan/$JOB_ID")
    echo "📊 Status do job:"
    echo "$STATUS_RESPONSE"
    echo ""
    
    echo "📋 7. Aguardando mais 20 segundos..."
    sleep 20
    echo ""
    
    echo "📋 8. Verificando resultado final..."
    FINAL_STATUS=$(curl -s "https://api.desfollow.com.br/api/scan/$JOB_ID")
    echo "📊 Resultado final:"
    echo "$FINAL_STATUS"
    echo ""
    
    # Verificar se há dados
    if echo "$FINAL_STATUS" | grep -q '"count":[1-9]'; then
        echo "✅ Scan funcionando! Dados encontrados!"
    elif echo "$FINAL_STATUS" | grep -q '"status":"done"'; then
        echo "✅ Scan concluído!"
    elif echo "$FINAL_STATUS" | grep -q '"status":"error"'; then
        echo "❌ Scan falhou com erro"
    else
        echo "⏳ Scan ainda processando..."
    fi
    
else
    echo "❌ Não foi possível extrair Job ID"
    echo "📊 Resposta completa:"
    echo "$SCAN_RESPONSE"
fi

echo ""
echo "📋 9. Verificando se o frontend precisa ser atualizado..."
if [ -f "src/utils/ghosts.ts" ]; then
    echo "📊 Verificando se o frontend está usando /api:"
    grep -n "api.desfollow.com.br" src/utils/ghosts.ts
    echo ""
    echo "📋 Se o frontend não estiver usando /api, precisamos atualizar"
fi

echo ""
echo "✅ Correção concluída!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Se o scan funcionar, atualizar frontend para usar /api"
echo "   2. Se não funcionar, verificar logs do backend"
echo "   3. Testar no navegador real" 