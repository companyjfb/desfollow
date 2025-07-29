#!/bin/bash
echo "🧪 Testando scan completo (com banco funcionando)..."
echo "=================================================="
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
    
    echo "📋 3. Aguardando 15 segundos para processamento..."
    sleep 15
    echo ""
    
    echo "📋 4. Verificando status do job..."
    STATUS_RESPONSE=$(curl -s "https://api.desfollow.com.br/scan/$JOB_ID")
    echo "📊 Status do job:"
    echo "$STATUS_RESPONSE"
    echo ""
    
    echo "📋 5. Aguardando mais 30 segundos..."
    sleep 30
    echo ""
    
    echo "📋 6. Verificando resultado final..."
    FINAL_STATUS=$(curl -s "https://api.desfollow.com.br/scan/$JOB_ID")
    echo "📊 Resultado final:"
    echo "$FINAL_STATUS"
    echo ""
    
    # Verificar se há dados
    if echo "$FINAL_STATUS" | grep -q '"count":[1-9]'; then
        echo "✅ Scan funcionando! Dados encontrados!"
        echo "📊 Contagem de ghosts:"
        echo "$FINAL_STATUS" | grep -o '"count":[0-9]*'
    elif echo "$FINAL_STATUS" | grep -q '"status":"done"'; then
        echo "✅ Scan concluído! Verificando dados..."
        echo "📊 Contagem de ghosts:"
        echo "$FINAL_STATUS" | grep -o '"count":[0-9]*'
        echo "📊 Status:"
        echo "$FINAL_STATUS" | grep -o '"status":"[^"]*"'
    elif echo "$FINAL_STATUS" | grep -q '"status":"error"'; then
        echo "❌ Scan falhou com erro"
        echo "📊 Erro:"
        echo "$FINAL_STATUS" | grep -o '"error":"[^"]*"'
    else
        echo "⏳ Scan ainda processando..."
        echo "📊 Status atual:"
        echo "$FINAL_STATUS" | grep -o '"status":"[^"]*"'
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

echo "📋 8. Verificando scans no banco..."
cd ~/desfollow
source venv/bin/activate

python3 -c "
import os
import psycopg2
from dotenv import load_dotenv

try:
    load_dotenv()
    DATABASE_URL = os.getenv('DATABASE_URL')
    conn = psycopg2.connect(DATABASE_URL)
    cursor = conn.cursor()
    
    cursor.execute('SELECT COUNT(*) FROM scans WHERE status = \"done\"')
    done_count = cursor.fetchone()[0]
    print(f'📊 Scans concluídos no banco: {done_count}')
    
    cursor.execute('SELECT COUNT(*) FROM scans WHERE status = \"error\"')
    error_count = cursor.fetchone()[0]
    print(f'📊 Scans com erro no banco: {error_count}')
    
    cursor.execute('SELECT COUNT(*) FROM scans WHERE status IN (\"running\", \"queued\")')
    active_count = cursor.fetchone()[0]
    print(f'📊 Scans ativos no banco: {active_count}')
    
    conn.close()
    
except Exception as e:
    print(f'❌ Erro ao verificar banco: {e}')
"
echo ""

echo "✅ Teste concluído!"
echo ""
echo "📋 Para testar manualmente:"
echo "   curl -s -X POST https://api.desfollow.com.br/scan -H 'Content-Type: application/json' -d '{\"username\": \"seu_usuario\"}'" 