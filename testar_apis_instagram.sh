#!/bin/bash

echo "🔍 Testando APIs do Instagram..."
echo "================================"

USER_ID="1485141852"

echo "🔍 Testando followers API..."
FOLLOWERS_RESPONSE=$(curl -s -X GET "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/followers?user_id=$USER_ID" \
  -H "x-rapidapi-host: instagram-premium-api-2023.p.rapidapi.com" \
  -H "x-rapidapi-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" \
  -H "x-access-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01")

echo "📊 Followers response: $FOLLOWERS_RESPONSE"

echo ""
echo "🔍 Testando following API..."
FOLLOWING_RESPONSE=$(curl -s -X GET "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/following?user_id=$USER_ID" \
  -H "x-rapidapi-host: instagram-premium-api-2023.p.rapidapi.com" \
  -H "x-rapidapi-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" \
  -H "x-access-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01")

echo "📊 Following response: $FOLLOWING_RESPONSE"

echo ""
echo "🔍 Verificando se as APIs retornam erro..."
if echo "$FOLLOWERS_RESPONSE" | grep -q "error"; then
    echo "❌ Followers API retornou erro"
else
    echo "✅ Followers API funcionando"
fi

if echo "$FOLLOWING_RESPONSE" | grep -q "error"; then
    echo "❌ Following API retornou erro"
else
    echo "✅ Following API funcionando"
fi

echo ""
echo "🔍 Testando com diferentes endpoints..."
echo "📋 Tentando endpoint alternativo para followers..."
curl -s -X GET "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/followers" \
  -H "x-rapidapi-host: instagram-premium-api-2023.p.rapidapi.com" \
  -H "x-rapidapi-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" \
  -H "x-access-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" \
  -d "user_id=$USER_ID"

echo ""
echo "📋 Tentando endpoint alternativo para following..."
curl -s -X GET "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/following" \
  -H "x-rapidapi-host: instagram-premium-api-2023.p.rapidapi.com" \
  -H "x-rapidapi-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" \
  -H "x-access-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" \
  -d "user_id=$USER_ID" 