#!/bin/bash

echo "🧪 Teste Completo do Sistema de Scan Pós-Correção..."
echo "===================================================="
echo ""

cd /root/desfollow

echo "🔍 1. TESTANDO SCAN COMPLETO..."

# Testar com um username real para ver todo o fluxo
TEST_USERNAME="instagram"

echo "📝 Iniciando scan para: $TEST_USERNAME"

SCAN_RESPONSE=$(curl -s -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$TEST_USERNAME\"}" \
  http://127.0.0.1:8000/api/scan)

HTTP_CODE="${SCAN_RESPONSE: -3}"
RESPONSE_BODY="${SCAN_RESPONSE%???}"

echo "📊 Status Code: $HTTP_CODE"
echo "📋 Resposta: $RESPONSE_BODY"

if [ "$HTTP_CODE" = "200" ]; then
    JOB_ID=$(echo "$RESPONSE_BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('job_id', 'N/A'))" 2>/dev/null)
    
    if [ "$JOB_ID" != "N/A" ]; then
        echo "✅ Job criado: $JOB_ID"
        echo ""
        
        # Monitorar o progresso do scan
        echo "📊 Monitorando progresso do scan..."
        
        for i in {1..6}; do
            echo "⏳ Verificação $i/6 (após ${i}0 segundos)..."
            sleep 10
            
            STATUS_RESPONSE=$(curl -s http://127.0.0.1:8000/api/scan/$JOB_ID)
            
            # Extrair informações chave
            STATUS=$(echo "$STATUS_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('status', 'unknown'))" 2>/dev/null)
            PROFILE_INFO=$(echo "$STATUS_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print('SIM' if data.get('profile_info') else 'NÃO')" 2>/dev/null)
            COUNT=$(echo "$STATUS_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('count', 0))" 2>/dev/null)
            ERROR=$(echo "$STATUS_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('error', 'N/A'))" 2>/dev/null)
            
            echo "   📋 Status: $STATUS"
            echo "   👤 Profile Info: $PROFILE_INFO"
            echo "   🔢 Count: $COUNT"
            if [ "$ERROR" != "N/A" ] && [ "$ERROR" != "None" ]; then
                echo "   ❌ Error: $ERROR"
            fi
            
            # Se concluído, mostrar resultado final
            if [ "$STATUS" = "done" ]; then
                echo ""
                echo "🎉 SCAN CONCLUÍDO!"
                echo "📋 Resultado final:"
                echo "$STATUS_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$STATUS_RESPONSE"
                break
            elif [ "$STATUS" = "error" ]; then
                echo ""
                echo "❌ SCAN COM ERRO!"
                echo "📋 Detalhes do erro:"
                echo "$STATUS_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$STATUS_RESPONSE"
                break
            fi
            
            echo ""
        done
        
        # Se ainda estiver rodando após 1 minuto, algo pode estar errado
        if [ "$STATUS" = "running" ]; then
            echo "⚠️ Scan ainda em execução após 1 minuto..."
            echo "🔍 Verificando logs para possíveis problemas..."
            
            echo ""
            echo "📋 Logs mais recentes:"
            journalctl -u desfollow --no-pager -n 15
        fi
        
    else
        echo "❌ Não foi possível extrair job_id"
    fi
else
    echo "❌ Erro na requisição: $HTTP_CODE"
fi

echo ""
echo "🔍 2. VERIFICANDO BANCO DE DADOS..."

echo "📊 Verificando se dados foram salvos no banco..."

python3 -c "
import sys
sys.path.append('/root/desfollow')

try:
    from backend.app.database import get_db, Scan
    from datetime import datetime, timedelta
    
    # Conectar ao banco
    db_gen = get_db()
    db = next(db_gen)
    
    # Buscar scans recentes (última hora)
    recent_scans = db.query(Scan).filter(
        Scan.created_at >= datetime.utcnow() - timedelta(hours=1)
    ).order_by(Scan.created_at.desc()).limit(5).all()
    
    print(f'📊 Scans na última hora: {len(recent_scans)}')
    
    for scan in recent_scans:
        print(f'📋 {scan.username} - {scan.status} - Ghosts: {scan.ghosts_count or 0}')
        if scan.profile_info:
            followers = scan.profile_info.get('followers_count', 0)
            following = scan.profile_info.get('following_count', 0)
            print(f'   👥 {followers} seguidores, {following} seguindo')
        if scan.error_message:
            print(f'   ❌ Erro: {scan.error_message}')
        print()
    
    db.close()
    
except Exception as e:
    print(f'❌ Erro ao verificar banco: {e}')
"

echo ""
echo "🔍 3. VERIFICANDO CACHE DE JOBS..."

if [ -f "/tmp/desfollow_jobs.json" ]; then
    echo "📋 Cache atual de jobs:"
    cat /tmp/desfollow_jobs.json | python3 -m json.tool 2>/dev/null || echo "Cache inválido"
else
    echo "ℹ️ Nenhum cache de jobs encontrado"
fi

echo ""
echo "🔍 4. VERIFICANDO LOGS DE ERRO..."

echo "📋 Erros recentes nos logs:"
if journalctl -u desfollow --no-pager -n 50 | grep -i error | tail -5; then
    echo "(Mostrando últimos 5 erros)"
else
    echo "✅ Nenhum erro recente encontrado!"
fi

echo ""
echo "🔍 5. TESTE DE HEALTH CHECK..."

echo "📊 Verificando API health..."
HEALTH_RESPONSE=$(curl -s http://127.0.0.1:8000/api/health)
echo "📋 Health: $HEALTH_RESPONSE"

JOBS_ACTIVE=$(echo "$HEALTH_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('jobs_active', 0))" 2>/dev/null)
echo "🔢 Jobs ativos: $JOBS_ACTIVE"

echo ""
echo "✅ TESTE COMPLETO FINALIZADO!"
echo ""

echo "📊 RESUMO:"
echo "=========="

# Verificar status geral
ERRORS_FOUND=0

# 1. Verificar se há jobs ativos em excesso
if [ "$JOBS_ACTIVE" -gt 5 ]; then
    echo "⚠️ Muitos jobs ativos: $JOBS_ACTIVE (limite recomendado: 5)"
    ERRORS_FOUND=$((ERRORS_FOUND + 1))
else
    echo "✅ Jobs ativos dentro do limite: $JOBS_ACTIVE"
fi

# 2. Verificar se há erros recentes
if journalctl -u desfollow --no-pager -n 20 | grep -q -i "error\|exception\|traceback"; then
    echo "⚠️ Erros encontrados nos logs recentes"
    ERRORS_FOUND=$((ERRORS_FOUND + 1))
else
    echo "✅ Nenhum erro crítico nos logs recentes"
fi

# 3. Verificar se backend está rodando
if systemctl is-active --quiet desfollow; then
    echo "✅ Backend está ativo"
else
    echo "❌ Backend não está rodando"
    ERRORS_FOUND=$((ERRORS_FOUND + 1))
fi

echo ""
if [ $ERRORS_FOUND -eq 0 ]; then
    echo "🎉 SISTEMA FUNCIONANDO CORRETAMENTE!"
    echo ""
    echo "🎯 PRÓXIMOS PASSOS:"
    echo "   1. Testar no frontend: https://www.desfollow.com.br"
    echo "   2. Fazer alguns scans de teste"
    echo "   3. Monitorar performance"
else
    echo "⚠️ PROBLEMAS ENCONTRADOS: $ERRORS_FOUND"
    echo ""
    echo "🔧 INVESTIGAR:"
    echo "   1. Verificar logs em tempo real: journalctl -u desfollow -f"
    echo "   2. Testar endpoints manualmente"
    echo "   3. Verificar se limpeza automática está funcionando"
fi 