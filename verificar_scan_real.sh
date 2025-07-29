#!/bin/bash
echo "🔍 Verificando scan real no app..."
echo "==================================="
echo ""

echo "📋 1. Verificando logs do backend em tempo real..."
echo "📊 Para ver logs: journalctl -u desfollow -f"
echo "📊 Execute isso em outro terminal e depois teste o scan"
echo ""

echo "📋 2. Testando scan real via frontend..."
echo "📊 Acesse: https://desfollow.com.br"
echo "📊 Digite um username real do Instagram"
echo "📊 Clique em 'Analisar'"
echo "📊 Verifique o console do navegador (F12)"
echo ""

echo "📋 3. Verificando se o RapidAPI está funcionando..."
cd ~/desfollow
source venv/bin/activate

python3 -c "
import os
import requests
from dotenv import load_dotenv

load_dotenv()
RAPIDAPI_KEY = os.getenv('RAPIDAPI_KEY')

if not RAPIDAPI_KEY:
    print('❌ RAPIDAPI_KEY não encontrada')
    exit(1)

print(f'✅ RAPIDAPI_KEY encontrada: {RAPIDAPI_KEY[:10]}...')

# Testar API do Instagram
url = 'https://instagram-bulk-profile-scrapper.p.rapidapi.com/clients/api/ig/media_by_username'
headers = {
    'X-RapidAPI-Key': RAPIDAPI_KEY,
    'X-RapidAPI-Host': 'instagram-bulk-profile-scrapper.p.rapidapi.com'
}
params = {'ig': 'instagram'}

try:
    response = requests.get(url, headers=headers, params=params)
    print(f'📊 Status: {response.status_code}')
    if response.status_code == 200:
        data = response.json()
        print(f'✅ API funcionando! Dados: {len(str(data))} caracteres')
    else:
        print(f'❌ API falhou: {response.text}')
except Exception as e:
    print(f'❌ Erro ao testar API: {e}')
"
echo ""

echo "📋 4. Verificando se o banco está funcionando..."
python3 -c "
import os
import psycopg2
from dotenv import load_dotenv

try:
    load_dotenv()
    DATABASE_URL = os.getenv('DATABASE_URL')
    conn = psycopg2.connect(DATABASE_URL)
    cursor = conn.cursor()
    
    cursor.execute('SELECT COUNT(*) FROM scans')
    count = cursor.fetchone()[0]
    print(f'✅ Banco funcionando! {count} scans no total')
    
    cursor.execute('SELECT COUNT(*) FROM scans WHERE status = \"running\"')
    running = cursor.fetchone()[0]
    print(f'📊 Scans rodando: {running}')
    
    cursor.execute('SELECT COUNT(*) FROM scans WHERE status = \"done\"')
    done = cursor.fetchone()[0]
    print(f'📊 Scans concluídos: {done}')
    
    conn.close()
    
except Exception as e:
    print(f'❌ Erro no banco: {e}')
"
echo ""

echo "📋 5. Verificando se o backend está processando corretamente..."
echo "📊 Últimos logs do backend:"
journalctl -u desfollow --no-pager -n 20 | grep -E "(scan|instagram|rapidapi|error)"
echo ""

echo "📋 6. Testando scan manual via API..."
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
    
    echo "📋 7. Monitorando progresso..."
    for i in {1..6}; do
        echo "📊 Verificação $i/6 (aguardando 10s)..."
        sleep 10
        
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
echo "📋 8. Verificando se há erros específicos..."
echo "📊 Logs de erro do backend:"
journalctl -u desfollow --no-pager -n 50 | grep -i error
echo ""

echo "✅ Verificação concluída!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Se RapidAPI falhar, verificar chave"
echo "   2. Se banco falhar, verificar conexão"
echo "   3. Se backend falhar, verificar logs"
echo "   4. Testar no navegador real" 