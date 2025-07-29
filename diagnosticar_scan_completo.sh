#!/bin/bash

echo "🔍 Diagnóstico Completo do Sistema de Scan..."
echo "============================================"
echo ""

# Função para separar seções
section() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

section "1. VERIFICANDO SERVIÇOS"

echo "🔍 Status do backend (desfollow):"
if systemctl is-active --quiet desfollow; then
    echo "✅ Backend está rodando"
    echo "⏰ Tempo ativo: $(systemctl show desfollow --property=ActiveEnterTimestamp --value)"
else
    echo "❌ Backend NÃO está rodando!"
    echo "🔧 Iniciando backend..."
    systemctl start desfollow
    sleep 5
fi

echo ""
echo "🔍 Status do nginx:"
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx está rodando"
else
    echo "❌ Nginx não está rodando!"
    systemctl start nginx
fi

section "2. TESTANDO API RAPIDAPI"

echo "🔍 Testando obtenção de profile via RapidAPI..."

# Testar um username conhecido
TEST_USERNAME="instagram"

echo "📝 Testando com username: $TEST_USERNAME"

RAPIDAPI_RESPONSE=$(curl -s -w "%{http_code}" \
  -H "x-rapidapi-host: instagram-premium-api-2023.p.rapidapi.com" \
  -H "x-rapidapi-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" \
  -H "x-access-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" \
  "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/web_profile_info?username=$TEST_USERNAME")

HTTP_CODE="${RAPIDAPI_RESPONSE: -3}"
RESPONSE_BODY="${RAPIDAPI_RESPONSE%???}"

echo "📊 Status Code: $HTTP_CODE"
echo "📋 Resposta:"
echo "$RESPONSE_BODY" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE_BODY"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ RapidAPI funcionando!"
else
    echo "❌ RapidAPI com problemas!"
fi

section "3. VERIFICANDO VARIÁVEIS DE AMBIENTE"

echo "🔍 Verificando variáveis de ambiente do backend..."
cd /root/desfollow

if [ -f "backend/.env" ]; then
    echo "✅ Arquivo .env existe"
    echo "📋 Variáveis configuradas:"
    grep -E "RAPIDAPI|DATABASE" backend/.env | sed 's/=.*/=***/' || echo "❌ Nenhuma variável encontrada"
else
    echo "❌ Arquivo backend/.env não encontrado!"
fi

section "4. LOGS DO BACKEND (ÚLTIMOS 50 LINHAS)"

echo "🔍 Logs mais recentes do backend:"
journalctl -u desfollow --no-pager -n 50 | tail -30

section "5. TESTANDO ENDPOINT DE SCAN"

echo "🔍 Testando endpoint /api/scan..."

# Fazer scan de teste
SCAN_RESPONSE=$(curl -s -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"instagram"}' \
  http://127.0.0.1:8000/api/scan)

HTTP_CODE="${SCAN_RESPONSE: -3}"
RESPONSE_BODY="${SCAN_RESPONSE%???}"

echo "📊 Status Code: $HTTP_CODE"
echo "📋 Resposta:"
echo "$RESPONSE_BODY" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE_BODY"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Endpoint /api/scan respondeu!"
    
    # Extrair job_id
    JOB_ID=$(echo "$RESPONSE_BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('job_id', 'N/A'))" 2>/dev/null)
    echo "🆔 Job ID: $JOB_ID"
    
    if [ "$JOB_ID" != "N/A" ]; then
        echo ""
        echo "⏳ Aguardando 10 segundos para o job processar..."
        sleep 10
        
        echo "🔍 Verificando status do job..."
        STATUS_RESPONSE=$(curl -s http://127.0.0.1:8000/api/scan/$JOB_ID)
        echo "📋 Status do job:"
        echo "$STATUS_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$STATUS_RESPONSE"
    fi
else
    echo "❌ Endpoint /api/scan com problemas!"
fi

section "6. VERIFICANDO CACHE DE JOBS"

echo "🔍 Verificando cache de jobs..."
if [ -f "/tmp/desfollow_jobs.json" ]; then
    echo "✅ Cache de jobs existe"
    echo "📋 Conteúdo:"
    cat /tmp/desfollow_jobs.json | python3 -m json.tool 2>/dev/null || echo "Cache inválido"
else
    echo "ℹ️ Nenhum cache de jobs encontrado"
fi

section "7. VERIFICANDO BANCO DE DADOS"

echo "🔍 Testando conexão com banco..."
python3 -c "
import os
import sys
sys.path.append('/root/desfollow')

try:
    from backend.app.database import get_db
    from backend.app.database import Scan
    from sqlalchemy.orm import Session
    
    # Testar conexão
    db_gen = get_db()
    db = next(db_gen)
    
    # Contar scans recentes
    from datetime import datetime, timedelta
    recent_scans = db.query(Scan).filter(
        Scan.created_at >= datetime.utcnow() - timedelta(hours=1)
    ).count()
    
    print(f'✅ Conexão com banco OK')
    print(f'📊 Scans na última hora: {recent_scans}')
    
    # Ver último scan
    last_scan = db.query(Scan).order_by(Scan.created_at.desc()).first()
    if last_scan:
        print(f'📋 Último scan: {last_scan.username} - {last_scan.status}')
    else:
        print('📋 Nenhum scan encontrado')
        
    db.close()
    
except Exception as e:
    print(f'❌ Erro no banco: {e}')
"

section "8. DIAGNÓSTICO FINAL"

echo "🔍 Resumo dos problemas encontrados:"

# Verificar principais pontos de falha
PROBLEMS=0

# 1. Backend rodando?
if ! systemctl is-active --quiet desfollow; then
    echo "❌ Backend não está rodando"
    PROBLEMS=$((PROBLEMS + 1))
fi

# 2. RapidAPI funcionando?
if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ RapidAPI com problemas (Status: $HTTP_CODE)"
    PROBLEMS=$((PROBLEMS + 1))
fi

# 3. Arquivo .env existe?
if [ ! -f "backend/.env" ]; then
    echo "❌ Arquivo .env não encontrado"
    PROBLEMS=$((PROBLEMS + 1))
fi

if [ $PROBLEMS -eq 0 ]; then
    echo "✅ Nenhum problema óbvio encontrado"
    echo ""
    echo "🔍 PRÓXIMOS PASSOS:"
    echo "   1. Verificar logs do backend em tempo real:"
    echo "      journalctl -u desfollow -f"
    echo ""
    echo "   2. Fazer scan manual e acompanhar logs:"
    echo "      curl -X POST -H 'Content-Type: application/json' -d '{\"username\":\"instagram\"}' http://127.0.0.1:8000/api/scan"
    echo ""
    echo "   3. Se o problema persistir, adicionar mais logs no código:"
    echo "      Editar backend/app/routes.py e adicionar prints detalhados"
else
    echo ""
    echo "🚨 PROBLEMAS ENCONTRADOS: $PROBLEMS"
    echo ""
    echo "🔧 SOLUÇÕES:"
    echo "   - Reiniciar backend: systemctl restart desfollow"
    echo "   - Verificar variáveis de ambiente"
    echo "   - Testar RapidAPI manualmente"
fi

echo ""
echo "✅ DIAGNÓSTICO CONCLUÍDO!" 