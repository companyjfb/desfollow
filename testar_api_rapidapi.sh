#!/bin/bash

echo "🔍 Testando API RapidAPI..."
echo "=========================="

echo "📋 Verificando variáveis de ambiente..."
echo "RAPIDAPI_HOST: ${RAPIDAPI_HOST:-'instagram-premium-api-2023.p.rapidapi.com'}"
echo "RAPIDAPI_KEY: ${RAPIDAPI_KEY:-'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'}"

echo ""
echo "🔍 Testando API com curl..."
curl -X GET "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/web_profile_info?username=jordanbitencourt" \
  -H "x-rapidapi-host: instagram-premium-api-2023.p.rapidapi.com" \
  -H "x-rapidapi-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" \
  -H "x-access-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01"

echo ""
echo "📋 Verificando logs do backend..."
journalctl -u desfollow --no-pager -n 20

echo ""
echo "🔍 Para corrigir:"
echo "1. Verificar se a API key está correta"
echo "2. Verificar se o plano da API está ativo"
echo "3. Verificar se há rate limiting"
echo "4. Considerar usar dados reais em vez de simulados" 