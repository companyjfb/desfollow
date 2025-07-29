#!/bin/bash
echo "🔧 Forçando execução do scan..."
echo "==============================="
echo ""

echo "📋 1. Verificando se o background task está sendo executado..."
echo "📊 Execute em outro terminal: journalctl -u desfollow -f"
echo ""

echo "📋 2. Testando função diretamente..."
cd ~/desfollow
source venv/bin/activate

python3 -c "
import asyncio
import sys
sys.path.append('backend')

try:
    from app.ig import get_ghosts_with_profile
    from app.database import get_db
    from sqlalchemy.orm import Session
    
    print('✅ Função importada')
    
    # Testar função diretamente
    async def test_scan():
        print('🧪 Testando scan diretamente...')
        
        # Simular dados de perfil
        profile_info = {
            'username': 'instagram',
            'followers_count': 1000,
            'following_count': 500
        }
        
        print('📱 Chamando get_ghosts_with_profile...')
        result = await get_ghosts_with_profile('instagram', profile_info)
        print(f'📊 Resultado: {result}')
        
    # Executar teste
    asyncio.run(test_scan())
    
except Exception as e:
    print(f'❌ Erro ao testar função: {e}')
    import traceback
    traceback.print_exc()
"
echo ""

echo "📋 3. Verificando se há erros de import..."
python3 -c "
import sys
sys.path.append('backend')

try:
    print('📊 Testando imports...')
    from app.ig import get_followers_optimized, get_following_optimized
    print('✅ Funções de paginação importadas')
    
    from app.ig import get_user_id_from_rapidapi
    print('✅ Função de user_id importada')
    
    print('✅ Todos os imports funcionando')
    
except Exception as e:
    print(f'❌ Erro nos imports: {e}')
"
echo ""

echo "📋 4. Iniciando scan e monitorando logs..."
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
    echo "📊 Aguardando 3 segundos para começar..."
    sleep 3
    
    for i in {1..10}; do
        echo "📊 Verificação $i/10 (aguardando 8s)..."
        
        # Verificar status
        STATUS=$(curl -s "https://api.desfollow.com.br/api/scan/$JOB_ID")
        echo "📊 Status: $STATUS"
        
        # Verificar logs específicos
        echo "📊 Logs de execução:"
        journalctl -u desfollow --no-pager -n 30 | grep -E "(🚀|📱|📄|📡|📊|✅|❌|🔍|🎯)" | tail -5
        echo ""
        
        sleep 8
        
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

echo "📋 7. Verificando se o background task está sendo executado..."
echo "📊 Logs de background:"
journalctl -u desfollow --no-pager -n 100 | grep -E "(background|task|run_scan)" | tail -10
echo ""

echo "✅ Verificação concluída!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Se função testar OK, problema é no background task"
echo "   2. Se função falhar, corrigir código"
echo "   3. Se logs mostrarem erro específico, corrigir" 