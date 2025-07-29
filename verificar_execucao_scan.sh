#!/bin/bash
echo "🔍 Verificando execução do scan..."
echo "=================================="
echo ""

echo "📋 1. Verificando logs detalhados do backend..."
echo "📊 Execute em outro terminal: journalctl -u desfollow -f"
echo ""

echo "📋 2. Verificando se o código de scan está sendo executado..."
cd ~/desfollow
source venv/bin/activate

python3 -c "
import sys
sys.path.append('backend')

try:
    from app.routes import run_scan_with_database
    print('✅ Função run_scan_with_database importada')
    
    # Verificar se a função existe
    import inspect
    source = inspect.getsource(run_scan_with_database)
    print(f'📊 Função tem {len(source)} caracteres')
    
    # Verificar se tem logs de debug
    if 'print(' in source:
        print('✅ Função tem logs de debug')
    else:
        print('❌ Função não tem logs de debug')
        
    # Verificar se chama get_followers_optimized
    if 'get_followers_optimized' in source:
        print('✅ Função chama get_followers_optimized')
    else:
        print('❌ Função NÃO chama get_followers_optimized')
        
    # Verificar se chama get_following_optimized
    if 'get_following_optimized' in source:
        print('✅ Função chama get_following_optimized')
    else:
        print('❌ Função NÃO chama get_following_optimized')
        
except Exception as e:
    print(f'❌ Erro ao verificar função: {e}')
"
echo ""

echo "📋 3. Verificando se o background task está sendo executado..."
echo "📊 Últimos logs de background:"
journalctl -u desfollow --no-pager -n 50 | grep -E "(run_scan|background|task)" | tail -10
echo ""

echo "📋 4. Testando scan e monitorando logs em tempo real..."
echo "📊 Iniciando scan para 'instagram':"
SCAN_RESPONSE=$(curl -s -X POST https://api.desfollow.com.br/api/scan \
  -H "Content-Type: application/json" \
  -d '{"username": "instagram"}')

echo "$SCAN_RESPONSE"
echo ""

# Extrair job_id
JOB_ID=$(echo "$SCAN_RESPONSE" | grep -o '"job_id":"[^"]*"' | cut -d'"' -f4)

if [ -n "$JOB_ID" ]; then
    echo "✅ Job ID: $JOB_ID"
    echo ""
    
    echo "📋 5. Monitorando logs em tempo real..."
    echo "📊 Aguardando 5 segundos para começar..."
    sleep 5
    
    for i in {1..6}; do
        echo "📊 Verificação $i/6 (aguardando 10s)..."
        
        # Verificar status
        STATUS=$(curl -s "https://api.desfollow.com.br/api/scan/$JOB_ID")
        echo "📊 Status: $STATUS"
        
        # Verificar logs específicos
        echo "📊 Logs de scan:"
        journalctl -u desfollow --no-pager -n 20 | grep -E "(scan|instagram|followers|following|user_id)" | tail -5
        echo ""
        
        sleep 10
        
        # Verificar se terminou
        if echo "$STATUS" | grep -q '"status":"done"'; then
            echo "✅ Scan concluído!"
            break
        elif echo "$STATUS" | grep -q '"status":"error"'; then
            echo "❌ Scan falhou!"
            break
        fi
    done
else
    echo "❌ Não foi possível extrair Job ID"
fi

echo ""
echo "📋 6. Verificando se há erros específicos..."
echo "📊 Logs de erro:"
journalctl -u desfollow --no-pager -n 100 | grep -i error | tail -10
echo ""

echo "📋 7. Verificando se o código está sendo executado..."
echo "📊 Logs de execução:"
journalctl -u desfollow --no-pager -n 100 | grep -E "(📱|📄|📡|📊|✅|❌)" | tail -10
echo ""

echo "✅ Verificação concluída!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Se não houver logs, o código não está executando"
echo "   2. Se houver logs mas não progredir, verificar timeout"
echo "   3. Se houver erro específico, corrigir" 