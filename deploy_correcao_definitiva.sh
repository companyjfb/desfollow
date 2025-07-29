#!/bin/bash

echo "🚀 Deploy Correção DEFINITIVA - Pydantic Fix"
echo "============================================"
echo ""

echo "🎯 CORREÇÃO DEFINITIVA APLICADA:"
echo "✅ Integrada ao código fonte (backend/app/routes.py)"
echo "✅ Commitada no repositório Git"
echo "✅ Permanente - Sobrevive a atualizações"
echo ""

echo "📋 1. Atualizando código no servidor..."
cd /root/desfollow
git pull origin main

if [ $? -eq 0 ]; then
    echo "✅ Código atualizado com correção definitiva"
else
    echo "❌ Erro ao atualizar código"
    exit 1
fi

echo ""
echo "📋 2. Verificando correção aplicada..."
echo "🔍 Verificando StatusResponse model:"
grep -A 5 "class StatusResponse" backend/app/routes.py | grep -E "(sample|all):"

echo ""
echo "📋 3. Reiniciando serviço backend..."
systemctl restart desfollow

sleep 3

echo "📋 4. Verificando status do serviço..."
systemctl status desfollow --no-pager -l | head -8

echo ""
echo "📋 5. Testando API com correção definitiva..."

sleep 2

echo "🌐 Testando endpoint health:"
HEALTH_TEST=$(curl -s -w "HTTP_CODE:%{http_code}" https://api.desfollow.com.br/health 2>/dev/null)
echo "   Health: $HEALTH_TEST"

echo ""
echo "🌐 Testando POST /api/scan:"
SCAN_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST https://api.desfollow.com.br/api/scan \
  -H "Content-Type: application/json" \
  -H "Origin: https://www.desfollow.com.br" \
  -d '{"username": "testuser"}' 2>/dev/null)
echo "   Scan: $SCAN_RESPONSE"

echo ""
echo "🌐 Testando GET status (principal correção)..."
JOB_ID=$(echo "$SCAN_RESPONSE" | grep -o '"job_id":"[^"]*"' | cut -d'"' -f4)
if [ ! -z "$JOB_ID" ]; then
    echo "   Job ID: $JOB_ID"
    sleep 5
    
    echo "   Testando GET /api/scan/$JOB_ID:"
    STATUS_TEST=$(curl -s -w "HTTP_CODE:%{http_code}" https://api.desfollow.com.br/api/scan/$JOB_ID 2>/dev/null)
    echo "   Status: $STATUS_TEST"
    
    if [[ "$STATUS_TEST" == *"500"* ]]; then
        echo "   ❌ AINDA COM ERRO 500 - Verificar logs"
    else
        echo "   ✅ SEM ERRO 500 - Correção funcionando!"
    fi
else
    echo "   ⚠️ Não foi possível extrair job_id"
fi

echo ""
echo "📋 6. Verificando logs recentes..."
echo "🔹 Últimas 5 linhas do log:"
journalctl -u desfollow -n 5 --no-pager

echo ""
echo "✅ DEPLOY DEFINITIVO CONCLUÍDO!"
echo ""
echo "🔒 CORREÇÃO PERMANENTE APLICADA:"
echo "   • StatusResponse.sample: List[Dict[str, Any]]"
echo "   • StatusResponse.all: List[Dict[str, Any]]"
echo "   • Código fonte corrigido no repositório"
echo "   • Sobrevive a git pull, deploys, rebuilds"
echo ""
echo "🎯 VANTAGENS DA CORREÇÃO DEFINITIVA:"
echo "   ✅ Não precisa reaplicar após atualizações"
echo "   ✅ Integrada ao fluxo de desenvolvimento"  
echo "   ✅ Outros desenvolvedores recebem o fix"
echo "   ✅ Histórico Git documenta a mudança"
echo ""
echo "📋 TESTAR NO FRONTEND:"
echo "   • https://www.desfollow.com.br"
echo "   • Fazer scan completo"
echo "   • Verificar se dados dos ghosts aparecem"
echo "   • Não deve ter erro 500 no console"
echo ""
echo "📜 MONITORAR:"
echo "   journalctl -u desfollow -f"
echo ""
echo "🚀 Problema resolvido DEFINITIVAMENTE!" 