#!/bin/bash
echo "🔧 Corrigindo API e problemas do banco..."
echo "========================================="
echo ""

echo "📋 1. Verificando configuração atual da API..."
cd ~/desfollow
grep -n "rapidapi" backend/app/ig.py
echo ""

echo "📋 2. Testando API correta..."
python3 -c "
import requests

# Testar API correta
url = 'https://instagram-premium-api-2023.p.rapidapi.com/v1/user/followers/chunk'
headers = {
    'x-access-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01',
    'x-rapidapi-host': 'instagram-premium-api-2023.p.rapidapi.com',
    'x-rapidapi-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'
}
params = {'user_id': '1485141852', 'max_id': '50'}

try:
    response = requests.get(url, headers=headers, params=params)
    print(f'📊 Status: {response.status_code}')
    if response.status_code == 200:
        data = response.json()
        print(f'✅ API correta funcionando!')
        print(f'📊 Dados: {len(str(data))} caracteres')
    else:
        print(f'❌ API falhou: {response.text}')
except Exception as e:
    print(f'❌ Erro ao testar API: {e}')
"
echo ""

echo "📋 3. Corrigindo problemas do banco..."
python3 -c "
import os
import psycopg2
from dotenv import load_dotenv

try:
    load_dotenv()
    DATABASE_URL = os.getenv('DATABASE_URL')
    conn = psycopg2.connect(DATABASE_URL)
    cursor = conn.cursor()
    
    # Testar com aspas simples
    cursor.execute('SELECT COUNT(*) FROM scans')
    count = cursor.fetchone()[0]
    print(f'✅ Banco funcionando! {count} scans no total')
    
    cursor.execute(\"\"\"SELECT COUNT(*) FROM scans WHERE status = 'running'\"\"\")
    running = cursor.fetchone()[0]
    print(f'📊 Scans rodando: {running}')
    
    cursor.execute(\"\"\"SELECT COUNT(*) FROM scans WHERE status = 'done'\"\"\")
    done = cursor.fetchone()[0]
    print(f'📊 Scans concluídos: {done}')
    
    cursor.execute(\"\"\"SELECT COUNT(*) FROM scans WHERE status = 'error'\"\"\")
    error = cursor.fetchone()[0]
    print(f'📊 Scans com erro: {error}')
    
    conn.close()
    
except Exception as e:
    print(f'❌ Erro no banco: {e}')
"
echo ""

echo "📋 4. Verificando se o backend está usando a API correta..."
grep -A 10 -B 5 "rapidapi" backend/app/ig.py
echo ""

echo "📋 5. Testando scan com API corrigida..."
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
    
    echo "📋 6. Monitorando progresso..."
    for i in {1..3}; do
        echo "📊 Verificação $i/3 (aguardando 15s)..."
        sleep 15
        
        STATUS=$(curl -s "https://api.desfollow.com.br/api/scan/$JOB_ID")
        echo "📊 Status: $STATUS"
        echo ""
        
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
echo "📋 7. Verificando logs do backend..."
echo "📊 Últimos logs:"
journalctl -u desfollow --no-pager -n 10 | grep -E "(scan|instagram|rapidapi|error)"
echo ""

echo "✅ Correção concluída!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Se API funcionar, testar no navegador"
echo "   2. Se banco funcionar, verificar dados"
echo "   3. Se scan funcionar, verificar ghosts" 