#!/bin/bash
echo "🔍 Verificando scan detalhadamente..."
echo "===================================="
echo ""

echo "📋 1. Verificando logs do backend em tempo real..."
echo "📊 Execute em outro terminal: journalctl -u desfollow -f"
echo ""

echo "📋 2. Testando API do Instagram diretamente..."
python3 -c "
import requests
import os
from dotenv import load_dotenv

load_dotenv()

# Testar API de perfil
print('📊 Testando API de perfil...')
url = 'https://instagram-premium-api-2023.p.rapidapi.com/v1/user/web_profile_info'
headers = {
    'x-rapidapi-host': 'instagram-premium-api-2023.p.rapidapi.com',
    'x-rapidapi-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01',
    'x-access-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'
}
params = {'username': 'instagram'}

try:
    response = requests.get(url, headers=headers, params=params)
    print(f'📊 Status: {response.status_code}')
    if response.status_code == 200:
        data = response.json()
        print(f'✅ API funcionando!')
        if 'user' in data:
            user = data['user']
            print(f'📊 User ID: {user.get(\"id\")}')
            print(f'📊 Followers: {user.get(\"edge_followed_by\", {}).get(\"count\")}')
            print(f'📊 Following: {user.get(\"edge_follow\", {}).get(\"count\")}')
        else:
            print(f'❌ Campo user não encontrado')
    else:
        print(f'❌ API falhou: {response.text}')
except Exception as e:
    print(f'❌ Erro: {e}')
"
echo ""

echo "📋 3. Testando API de seguidores..."
python3 -c "
import requests

# Testar API de seguidores
print('📊 Testando API de seguidores...')
url = 'https://instagram-premium-api-2023.p.rapidapi.com/v1/user/followers'
headers = {
    'x-rapidapi-host': 'instagram-premium-api-2023.p.rapidapi.com',
    'x-rapidapi-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01',
    'x-access-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'
}
params = {'user_id': '1485141852'}

try:
    response = requests.get(url, headers=headers, params=params)
    print(f'📊 Status: {response.status_code}')
    if response.status_code == 200:
        data = response.json()
        print(f'✅ API funcionando!')
        users = data.get('users', [])
        print(f'📊 Seguidores retornados: {len(users)}')
        if users:
            print(f'📊 Primeiro usuário: {users[0].get(\"username\")}')
    else:
        print(f'❌ API falhou: {response.text}')
except Exception as e:
    print(f'❌ Erro: {e}')
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
    
    echo "📋 5. Monitorando progresso detalhado..."
    for i in {1..8}; do
        echo "📊 Verificação $i/8 (aguardando 10s)..."
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
echo "📋 6. Verificando logs específicos do scan..."
echo "📊 Logs de scan:"
journalctl -u desfollow --no-pager -n 50 | grep -E "(scan|instagram|user_id|followers|following|error)" | tail -20
echo ""

echo "📋 7. Verificando se há erros específicos..."
echo "📊 Logs de erro:"
journalctl -u desfollow --no-pager -n 100 | grep -i error | tail -10
echo ""

echo "✅ Verificação concluída!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Se API funcionar mas scan não, verificar código"
echo "   2. Se logs mostrarem erro específico, corrigir"
echo "   3. Se scan ficar travado, verificar timeout" 