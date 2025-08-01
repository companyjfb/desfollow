#!/usr/bin/env python3
"""
Script simples para testar se a API antiga está funcionando para obter user_id.
"""

import requests
import json

def testar_api_antiga(username="jordanbitencourt"):
    """Testa se consegue obter user_id e profile_info da API antiga"""
    print(f"🔍 TESTANDO API ANTIGA PARA: @{username}")
    print("=" * 50)
    
    headers = {
        'x-rapidapi-host': 'instagram-premium-api-2023.p.rapidapi.com',
        'x-rapidapi-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01',
        'x-access-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'
    }
    
    url = "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/web_profile_info"
    params = {'username': username}
    
    try:
        response = requests.get(url, headers=headers, params=params)
        print(f"📊 Status: {response.status_code}")
        
        if response.status_code != 200:
            print(f"❌ ERRO: {response.status_code}")
            print(f"Response: {response.text}")
            return False
        
        data = response.json()
        
        if 'user' in data:
            user_data = data['user']
            user_id = user_data.get('id')
            followers = user_data.get('edge_followed_by', {}).get('count', 0)
            following = user_data.get('edge_follow', {}).get('count', 0)
            
            print(f"✅ SUCCESS!")
            print(f"🆔 User ID: {user_id}")
            print(f"📊 Seguidores: {followers}")
            print(f"📊 Seguindo: {following}")
            print(f"📊 Nome: {user_data.get('full_name', 'N/A')}")
            
            return True
        else:
            print(f"❌ Campo 'user' não encontrado")
            print(f"📄 Response: {json.dumps(data, indent=2)[:500]}...")
            return False
            
    except Exception as e:
        print(f"❌ ERRO: {e}")
        return False

if __name__ == "__main__":
    # Testar com alguns usernames diferentes
    usernames = ["jordanbitencourt", "instagram", "zuck"]
    
    for username in usernames:
        print(f"\n{'='*60}")
        success = testar_api_antiga(username)
        if success:
            print(f"✅ @{username}: API funcionando!")
        else:
            print(f"❌ @{username}: API com problemas!")
        print("=" * 60)