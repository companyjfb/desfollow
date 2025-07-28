#!/usr/bin/env python3
"""
Script para debugar a resposta da API do Instagram.
"""

import requests
import json

# Configuração da RapidAPI
RAPIDAPI_KEY = "dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01"
RAPIDAPI_HOST = "instagram-premium-api-2023.p.rapidapi.com"

def debug_api_response():
    """
    Debuga a resposta da API para entender a estrutura dos dados.
    """
    print("🔍 Debugando resposta da API...")
    
    # Headers para a API
    headers = {
        'x-rapidapi-host': RAPIDAPI_HOST,
        'x-rapidapi-key': RAPIDAPI_KEY,
        'x-access-key': RAPIDAPI_KEY
    }
    
    # Testa com o user_id que sabemos que funciona
    user_id = "1485141852"
    
    # Endpoint de seguidores
    followers_url = f"https://{RAPIDAPI_HOST}/v1/user/followers/chunk"
    
    print(f"🔄 Testando endpoint: {followers_url}")
    print(f"📋 Parâmetros: user_id={user_id}")
    
    try:
        # Primeira requisição sem max_id
        response = requests.get(followers_url, headers=headers, params={'user_id': user_id})
        
        print(f"📊 Status Code: {response.status_code}")
        print(f"📊 Headers: {dict(response.headers)}")
        
        if response.status_code == 200:
            data = response.json()
            
            print(f"\n📋 ESTRUTURA DA RESPOSTA:")
            print(f"Tipo: {type(data)}")
            print(f"Tamanho: {len(str(data))} caracteres")
            
            if isinstance(data, list):
                print(f"✅ É uma lista com {len(data)} itens")
                if len(data) > 0:
                    print(f"📋 Primeiro item: {json.dumps(data[0], indent=2)}")
            elif isinstance(data, dict):
                print(f"✅ É um dicionário com chaves: {list(data.keys())}")
                print(f"📋 Conteúdo: {json.dumps(data, indent=2)}")
            else:
                print(f"❓ Tipo inesperado: {type(data)}")
                print(f"📋 Conteúdo: {data}")
            
            # Testa com max_id=2
            print(f"\n🔄 Testando com max_id=2...")
            response2 = requests.get(followers_url, headers=headers, params={'user_id': user_id, 'max_id': 2})
            
            if response2.status_code == 200:
                data2 = response2.json()
                print(f"📊 Status Code (max_id=2): {response2.status_code}")
                print(f"📋 Tipo (max_id=2): {type(data2)}")
                
                if isinstance(data2, list):
                    print(f"✅ Lista com {len(data2)} itens")
                elif isinstance(data2, dict):
                    print(f"✅ Dicionário com chaves: {list(data2.keys())}")
                    print(f"📋 Conteúdo: {json.dumps(data2, indent=2)}")
            else:
                print(f"❌ Erro com max_id=2: {response2.status_code}")
                print(f"📋 Response: {response2.text[:200]}...")
                
        else:
            print(f"❌ Erro na requisição: {response.status_code}")
            print(f"📋 Response: {response.text[:200]}...")
            
    except Exception as e:
        print(f"❌ Erro durante o debug: {e}")

if __name__ == "__main__":
    debug_api_response() 