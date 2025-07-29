#!/bin/bash
echo "🧪 Testando scan completo..."
echo "============================"
echo ""

echo "📋 1. Verificando status da API..."
curl -s https://api.desfollow.com.br/health
echo ""
echo ""

echo "📋 2. Iniciando scan de teste..."
SCAN_RESPONSE=$(curl -s -X POST https://api.desfollow.com.br/scan \
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
    
    echo "📋 3. Aguardando 10 segundos para processamento..."
    sleep 10
    echo ""
    
    echo "📋 4. Verificando status do job..."
    STATUS_RESPONSE=$(curl -s "https://api.desfollow.com.br/scan/$JOB_ID")
    echo "📊 Status do job:"
    echo "$STATUS_RESPONSE"
    echo ""
    
    echo "📋 5. Aguardando mais 20 segundos..."
    sleep 20
    echo ""
    
    echo "📋 6. Verificando resultado final..."
    FINAL_STATUS=$(curl -s "https://api.desfollow.com.br/scan/$JOB_ID")
    echo "📊 Resultado final:"
    echo "$FINAL_STATUS"
    echo ""
    
    # Verificar se há dados
    if echo "$FINAL_STATUS" | grep -q '"count":[1-9]'; then
        echo "✅ Scan funcionando! Dados encontrados!"
    elif echo "$FINAL_STATUS" | grep -q '"status":"done"'; then
        echo "✅ Scan concluído! Verificando dados..."
        echo "$FINAL_STATUS" | grep -o '"count":[0-9]*'
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
echo "📋 7. Verificando jobs ativos..."
curl -s https://api.desfollow.com.br/health
echo ""
echo ""

echo "✅ Teste concluído!"
echo ""
echo "📋 Para testar manualmente:"
echo "   curl -s -X POST https://api.desfollow.com.br/scan -H 'Content-Type: application/json' -d '{\"username\": \"seu_usuario\"}'" 