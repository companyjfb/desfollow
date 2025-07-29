#!/bin/bash

echo "🔍 Testando paginação das APIs do Instagram..."
echo "=============================================="

USER_ID="1485141852"

echo "🔍 Testando followers API com diferentes abordagens..."

echo ""
echo "📋 Teste 1: Followers sem max_id (primeira página)..."
FOLLOWERS_PAGE1=$(curl -s -X GET "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/followers?user_id=$USER_ID" \
  -H "x-rapidapi-host: instagram-premium-api-2023.p.rapidapi.com" \
  -H "x-rapidapi-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" \
  -H "x-access-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01")

echo "📊 Followers página 1: $FOLLOWERS_PAGE1"

echo ""
echo "📋 Teste 2: Following sem max_id (primeira página)..."
FOLLOWING_PAGE1=$(curl -s -X GET "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/following?user_id=$USER_ID" \
  -H "x-rapidapi-host: instagram-premium-api-2023.p.rapidapi.com" \
  -H "x-rapidapi-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" \
  -H "x-access-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01")

echo "📊 Following página 1: $FOLLOWING_PAGE1"

echo ""
echo "📋 Teste 3: Verificando se há next_max_id..."
if echo "$FOLLOWERS_PAGE1" | grep -q "next_max_id"; then
    echo "✅ Followers tem next_max_id"
    NEXT_MAX_ID=$(echo "$FOLLOWERS_PAGE1" | grep -o '"next_max_id":"[^"]*"' | cut -d'"' -f4)
    echo "🔑 Next max_id: $NEXT_MAX_ID"
    
    echo ""
    echo "📋 Teste 4: Followers segunda página..."
    FOLLOWERS_PAGE2=$(curl -s -X GET "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/followers?user_id=$USER_ID&max_id=$NEXT_MAX_ID" \
      -H "x-rapidapi-host: instagram-premium-api-2023.p.rapidapi.com" \
      -H "x-rapidapi-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" \
      -H "x-access-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01")
    
    echo "📊 Followers página 2: $FOLLOWERS_PAGE2"
else
    echo "❌ Followers não tem next_max_id"
fi

if echo "$FOLLOWING_PAGE1" | grep -q "next_max_id"; then
    echo "✅ Following tem next_max_id"
    NEXT_MAX_ID_FOLLOWING=$(echo "$FOLLOWING_PAGE1" | grep -o '"next_max_id":"[^"]*"' | cut -d'"' -f4)
    echo "🔑 Next max_id following: $NEXT_MAX_ID_FOLLOWING"
    
    echo ""
    echo "📋 Teste 5: Following segunda página..."
    FOLLOWING_PAGE2=$(curl -s -X GET "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/following?user_id=$USER_ID&max_id=$NEXT_MAX_ID_FOLLOWING" \
      -H "x-rapidapi-host: instagram-premium-api-2023.p.rapidapi.com" \
      -H "x-rapidapi-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" \
      -H "x-access-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01")
    
    echo "📊 Following página 2: $FOLLOWING_PAGE2"
else
    echo "❌ Following não tem next_max_id"
fi

echo ""
echo "📋 Teste 6: Verificando se as APIs retornam erro..."
if echo "$FOLLOWERS_PAGE1" | grep -q "error"; then
    echo "❌ Followers API retornou erro"
    echo "📄 Erro: $FOLLOWERS_PAGE1"
else
    echo "✅ Followers API funcionando"
fi

if echo "$FOLLOWING_PAGE1" | grep -q "error"; then
    echo "❌ Following API retornou erro"
    echo "📄 Erro: $FOLLOWING_PAGE1"
else
    echo "✅ Following API funcionando"
fi

echo ""
echo "📋 Teste 7: Verificando se as APIs retornam rate limit..."
if echo "$FOLLOWERS_PAGE1" | grep -q "rate"; then
    echo "❌ Followers API rate limit"
else
    echo "✅ Followers API sem rate limit"
fi

if echo "$FOLLOWING_PAGE1" | grep -q "rate"; then
    echo "❌ Following API rate limit"
else
    echo "✅ Following API sem rate limit"
fi

echo ""
echo "🎯 Resumo do teste de paginação..." 