#!/bin/bash

echo "🔍 Testando API completa..."
echo "==========================="

echo "📋 Verificando variáveis de ambiente..."
echo "RAPIDAPI_HOST: $(grep RAPIDAPI_HOST ~/desfollow/backend/.env | cut -d'=' -f2)"
echo "RAPIDAPI_KEY: $(grep RAPIDAPI_KEY ~/desfollow/backend/.env | cut -d'=' -f2 | cut -c1-10)..."

echo ""
echo "🔍 Testando endpoint de health..."
curl -s https://api.desfollow.com.br/api/health | jq .

echo ""
echo "🔍 Testando RapidAPI diretamente..."
curl -s -X GET "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/web_profile_info?username=jordanbitencourt" \
  -H "x-rapidapi-host: instagram-premium-api-2023.p.rapidapi.com" \
  -H "x-rapidapi-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" \
  -H "x-access-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" | jq .

echo ""
echo "🔍 Testando user_id via RapidAPI..."
USER_DATA=$(curl -s -X GET "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/web_profile_info?username=jordanbitencourt" \
  -H "x-rapidapi-host: instagram-premium-api-2023.p.rapidapi.com" \
  -H "x-rapidapi-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" \
  -H "x-access-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01")

echo "📊 User data: $USER_DATA"
USER_ID=$(echo $USER_DATA | jq -r '.user.id // .user.pk // null')
echo "🔑 User ID: $USER_ID"

if [ "$USER_ID" != "null" ] && [ "$USER_ID" != "" ]; then
    echo "✅ User ID encontrado: $USER_ID"
    
    echo ""
    echo "🔍 Testando followers API..."
    curl -s -X GET "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/followers?user_id=$USER_ID" \
      -H "x-rapidapi-host: instagram-premium-api-2023.p.rapidapi.com" \
      -H "x-rapidapi-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" \
      -H "x-access-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" | jq '.users | length'
    
    echo ""
    echo "🔍 Testando following API..."
    curl -s -X GET "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/following?user_id=$USER_ID" \
      -H "x-rapidapi-host: instagram-premium-api-2023.p.rapidapi.com" \
      -H "x-rapidapi-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" \
      -H "x-access-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" | jq '.users | length'
else
    echo "❌ User ID não encontrado!"
fi

echo ""
echo "📋 Verificando logs do backend..."
journalctl -u desfollow --no-pager -n 10

echo ""
echo "🔍 Testando scan via API..."
SCAN_RESPONSE=$(curl -s -X POST "https://api.desfollow.com.br/api/scan" \
  -H "Content-Type: application/json" \
  -d '{"username": "jordanbitencourt"}')

echo "📊 Scan response: $SCAN_RESPONSE"
JOB_ID=$(echo $SCAN_RESPONSE | jq -r '.job_id')

if [ "$JOB_ID" != "null" ] && [ "$JOB_ID" != "" ]; then
    echo "✅ Job ID: $JOB_ID"
    
    echo ""
    echo "⏳ Aguardando 5 segundos..."
    sleep 5
    
    echo ""
    echo "🔍 Verificando status do scan..."
    curl -s "https://api.desfollow.com.br/api/scan/$JOB_ID" | jq .
else
    echo "❌ Job ID não encontrado!"
fi 