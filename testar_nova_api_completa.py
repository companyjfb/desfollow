#!/usr/bin/env python3
"""
Script para testar a nova API instagram-scraper-20251 antes de aplicar no app.
Testa followers, following e verifica se está funcionando corretamente.
"""

import requests
import json

def testar_nova_api(username="jordanbitencourt"):
    """
    Testa a nova API completamente antes de aplicar no app principal.
    """
    print(f"🔍 TESTANDO NOVA API PARA: @{username}")
    print("=" * 60)
    
    headers = {
        'x-rapidapi-host': 'instagram-scraper-20251.p.rapidapi.com',
        'x-rapidapi-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'
    }
    
    # Primeiro obter user_id da API antiga
    print("📋 1. Obtendo user_id da API antiga...")
    old_headers = {
        'x-rapidapi-host': 'instagram-premium-api-2023.p.rapidapi.com',
        'x-rapidapi-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01',
        'x-access-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'
    }
    
    try:
        response = requests.get(
            'https://instagram-premium-api-2023.p.rapidapi.com/v1/user/web_profile_info',
            params={'username': username},
            headers=old_headers
        )
        
        if response.status_code != 200:
            print(f"❌ Erro ao obter user_id: {response.status_code}")
            print(f"Response: {response.text}")
            return
            
        data = response.json()
        print(f"📋 Resposta da API: {json.dumps(data, indent=2)[:500]}...")
        
        user_id = None
        if 'user' in data:
            user_id = data['user'].get('id')
        
        if not user_id:
            print(f"❌ User ID não encontrado na resposta")
            return
            
        print(f"✅ User ID obtido: {user_id}")
        
    except Exception as e:
        print(f"❌ Erro ao obter user_id: {e}")
        return
    
    # Testar followers com nova API
    print(f"\n📋 2. Testando FOLLOWERS com nova API...")
    testar_endpoint_followers(user_id, headers)
    
    # Testar following com nova API
    print(f"\n📋 3. Testando FOLLOWING com nova API...")
    testar_endpoint_following(user_id, headers)

def testar_endpoint_followers(user_id, headers):
    """Testa endpoint de followers"""
    print(f"🚀 Testando followers para user_id: {user_id}")
    
    url = "https://instagram-scraper-20251.p.rapidapi.com/userfollowers/"
    params = {'username_or_id': user_id}
    
    try:
        response = requests.get(url, params=params, headers=headers)
        print(f"📊 Status: {response.status_code}")
        
        if response.status_code != 200:
            print(f"❌ ERRO FOLLOWERS: {response.status_code}")
            print(f"📄 Response: {response.text}")
            return
        
        data = response.json()
        print(f"✅ FOLLOWERS SUCCESS!")
        print(f"📊 Count: {data.get('count', 0)}")
        print(f"📊 Items: {len(data.get('items', []))}")
        print(f"📊 Pagination token: {'Sim' if data.get('pagination_token') else 'Não'}")
        
        # Mostrar primeiros 3 usuários
        items = data.get('items', [])
        if items:
            print(f"👥 Primeiros 3 seguidores:")
            for i, user in enumerate(items[:3]):
                print(f"  {i+1}. @{user.get('username')} - {user.get('full_name', 'N/A')}")
        
        return data
        
    except Exception as e:
        print(f"❌ ERRO FOLLOWERS: {e}")
        return None

def testar_endpoint_following(user_id, headers):
    """Testa endpoint de following"""
    print(f"🚀 Testando following para user_id: {user_id}")
    
    url = "https://instagram-scraper-20251.p.rapidapi.com/userfollowing/"
    params = {'username_or_id': user_id}
    
    try:
        response = requests.get(url, params=params, headers=headers)
        print(f"📊 Status: {response.status_code}")
        
        if response.status_code != 200:
            print(f"❌ ERRO FOLLOWING: {response.status_code}")
            print(f"📄 Response: {response.text}")
            return
        
        data = response.json()
        print(f"✅ FOLLOWING SUCCESS!")
        print(f"📊 Count: {data.get('count', 0)}")
        print(f"📊 Items: {len(data.get('items', []))}")
        print(f"📊 Pagination token: {'Sim' if data.get('pagination_token') else 'Não'}")
        
        # Mostrar primeiros 3 usuários
        items = data.get('items', [])
        if items:
            print(f"👥 Primeiros 3 seguindo:")
            for i, user in enumerate(items[:3]):
                print(f"  {i+1}. @{user.get('username')} - {user.get('full_name', 'N/A')}")
        
        return data
        
    except Exception as e:
        print(f"❌ ERRO FOLLOWING: {e}")
        return None

if __name__ == "__main__":
    testar_nova_api()