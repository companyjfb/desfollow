#!/usr/bin/env python3
"""
Debug detalhado para entender onde os dados estão sendo perdidos.
"""

import sys
import os

# Adiciona o diretório backend ao path
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))

from app.ig import get_all_instagram_data_with_pagination
import requests

# Configuração da RapidAPI
RAPIDAPI_KEY = "dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01"
RAPIDAPI_HOST = "instagram-premium-api-2023.p.rapidapi.com"

async def debug_detailed():
    """
    Debug detalhado da função de paginação.
    """
    print("🔍 Debug detalhado da paginação...")
    
    # Headers para a API
    headers = {
        'x-rapidapi-host': RAPIDAPI_HOST,
        'x-rapidapi-key': RAPIDAPI_KEY,
        'x-access-key': RAPIDAPI_KEY
    }
    
    # Testa com o user_id que sabemos que funciona
    user_id = "1485141852"
    
    print(f"🔄 Testando com user_id: {user_id}")
    
    try:
        # Chama a função de paginação
        following_data, followers_data = await get_all_instagram_data_with_pagination(user_id, headers)
        
        print(f"\n📊 RESULTADOS DA PAGINAÇÃO:")
        print(f"Following data type: {type(following_data)}")
        print(f"Following data length: {len(following_data)}")
        print(f"Followers data type: {type(followers_data)}")
        print(f"Followers data length: {len(followers_data)}")
        
        if following_data:
            print(f"\n📋 Primeiro item following: {following_data[0] if len(following_data) > 0 else 'N/A'}")
        if followers_data:
            print(f"📋 Primeiro item followers: {followers_data[0] if len(followers_data) > 0 else 'N/A'}")
        
        # Testa manualmente a API
        print(f"\n🔄 Teste manual da API...")
        followers_url = f"https://{RAPIDAPI_HOST}/v1/user/followers/chunk"
        
        response = requests.get(followers_url, headers=headers, params={'user_id': user_id})
        if response.status_code == 200:
            data = response.json()
            print(f"✅ API manual retornou: {len(data)} itens")
            print(f"📋 Tipo do primeiro item: {type(data[0]) if len(data) > 0 else 'N/A'}")
            
            if len(data) > 0:
                first_item = data[0]
                print(f"📋 Primeiro item: {first_item}")
                
                # Verifica se é uma lista aninhada
                if isinstance(first_item, list):
                    print(f"✅ É uma lista aninhada com {len(first_item)} itens")
                    if len(first_item) > 0:
                        actual_user = first_item[0]
                        print(f"📋 Primeiro usuário real: {actual_user}")
                        if 'username' in actual_user:
                            print(f"✅ Username encontrado: {actual_user['username']}")
                        else:
                            print(f"❌ Username não encontrado. Chaves disponíveis: {list(actual_user.keys())}")
                else:
                    # É um dicionário direto
                    if 'username' in first_item:
                        print(f"✅ Username encontrado: {first_item['username']}")
                    else:
                        print(f"❌ Username não encontrado. Chaves disponíveis: {list(first_item.keys())}")
        
    except Exception as e:
        print(f"❌ Erro durante o debug: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    import asyncio
    asyncio.run(debug_detailed()) 