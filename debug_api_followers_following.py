#!/usr/bin/env python3
"""
Debug da API RapidAPI - Followers e Following
=============================================

Script para descobrir exatamente o formato de resposta da API
para endpoints de followers e following
"""

import requests
import json
import os

def test_followers_api(user_id):
    """Testa endpoint de followers"""
    print(f"🔍 Testando API de FOLLOWERS para user_id: {user_id}")
    print("=" * 60)
    
    headers = {
        'x-rapidapi-host': 'instagram-premium-api-2023.p.rapidapi.com',
        'x-rapidapi-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01',
        'x-access-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'
    }
    
    url = "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/followers"
    params = {'user_id': user_id}
    
    print(f"📡 URL: {url}")
    print(f"📝 Params: {params}")
    print(f"🔑 Headers: {headers}")
    print()
    
    try:
        response = requests.get(url, headers=headers, params=params)
        
        print(f"📊 Status Code: {response.status_code}")
        print(f"📄 Headers: {dict(response.headers)}")
        print()
        
        if response.status_code == 200:
            try:
                data = response.json()
                print(f"📋 TIPO DE RESPOSTA: {type(data)}")
                print(f"📋 RESPOSTA RAW:")
                print(json.dumps(data, indent=2)[:1000] + "..." if len(str(data)) > 1000 else json.dumps(data, indent=2))
                print()
                
                # Analisar estrutura
                if isinstance(data, dict):
                    print("✅ Resposta é um DICIONÁRIO")
                    print(f"🔑 Chaves disponíveis: {list(data.keys())}")
                    
                    if 'users' in data:
                        users = data['users']
                        print(f"👥 Campo 'users' encontrado, tipo: {type(users)}")
                        if isinstance(users, list) and users:
                            print(f"👤 Primeiro usuário: {json.dumps(users[0], indent=2)[:500]}...")
                            print(f"🔑 Chaves do primeiro usuário: {list(users[0].keys()) if isinstance(users[0], dict) else 'N/A'}")
                    else:
                        print("❌ Campo 'users' NÃO encontrado")
                        
                elif isinstance(data, list):
                    print("⚠️ Resposta é uma LISTA direta")
                    if data:
                        print(f"👤 Primeiro item: {json.dumps(data[0], indent=2)[:500]}...")
                        print(f"🔑 Chaves do primeiro item: {list(data[0].keys()) if isinstance(data[0], dict) else 'N/A'}")
                else:
                    print(f"❓ Resposta é tipo desconhecido: {type(data)}")
                
            except json.JSONDecodeError as e:
                print(f"❌ Erro ao decodificar JSON: {e}")
                print(f"📄 Response text: {response.text[:500]}...")
        else:
            print(f"❌ Erro na API: {response.status_code}")
            print(f"📄 Response text: {response.text[:500]}...")
            
    except Exception as e:
        print(f"❌ Erro na requisição: {e}")

def test_following_api(user_id):
    """Testa endpoint de following"""
    print(f"\n🔍 Testando API de FOLLOWING para user_id: {user_id}")
    print("=" * 60)
    
    headers = {
        'x-rapidapi-host': 'instagram-premium-api-2023.p.rapidapi.com',
        'x-rapidapi-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01',
        'x-access-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'
    }
    
    url = "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/following"
    params = {'user_id': user_id}
    
    print(f"📡 URL: {url}")
    print(f"📝 Params: {params}")
    print()
    
    try:
        response = requests.get(url, headers=headers, params=params)
        
        print(f"📊 Status Code: {response.status_code}")
        print()
        
        if response.status_code == 200:
            try:
                data = response.json()
                print(f"📋 TIPO DE RESPOSTA: {type(data)}")
                print(f"📋 RESPOSTA RAW:")
                print(json.dumps(data, indent=2)[:1000] + "..." if len(str(data)) > 1000 else json.dumps(data, indent=2))
                print()
                
                # Analisar estrutura
                if isinstance(data, dict):
                    print("✅ Resposta é um DICIONÁRIO")
                    print(f"🔑 Chaves disponíveis: {list(data.keys())}")
                    
                    if 'users' in data:
                        users = data['users']
                        print(f"👥 Campo 'users' encontrado, tipo: {type(users)}")
                        if isinstance(users, list) and users:
                            print(f"👤 Primeiro usuário: {json.dumps(users[0], indent=2)[:500]}...")
                            print(f"🔑 Chaves do primeiro usuário: {list(users[0].keys()) if isinstance(users[0], dict) else 'N/A'}")
                    else:
                        print("❌ Campo 'users' NÃO encontrado")
                        
                elif isinstance(data, list):
                    print("⚠️ Resposta é uma LISTA direta")
                    if data:
                        print(f"👤 Primeiro item: {json.dumps(data[0], indent=2)[:500]}...")
                        print(f"🔑 Chaves do primeiro item: {list(data[0].keys()) if isinstance(data[0], dict) else 'N/A'}")
                else:
                    print(f"❓ Resposta é tipo desconhecido: {type(data)}")
                
            except json.JSONDecodeError as e:
                print(f"❌ Erro ao decodificar JSON: {e}")
                print(f"📄 Response text: {response.text[:500]}...")
        else:
            print(f"❌ Erro na API: {response.status_code}")
            print(f"📄 Response text: {response.text[:500]}...")
            
    except Exception as e:
        print(f"❌ Erro na requisição: {e}")

if __name__ == "__main__":
    # Usar o user_id do Instagram que sabemos que funciona
    USER_ID = "25025320"  # Instagram oficial
    
    print("🧪 DEBUG DA API RAPIDAPI - FOLLOWERS E FOLLOWING")
    print("=" * 60)
    print()
    
    # Testar ambos endpoints
    test_followers_api(USER_ID)
    test_following_api(USER_ID)
    
    print("\n" + "=" * 60)
    print("📊 RESUMO DO DEBUG")
    print("=" * 60)
    print()
    print("🎯 PRÓXIMOS PASSOS:")
    print("   1. Verificar o formato exato da resposta")
    print("   2. Ajustar código para lidar com estrutura correta")
    print("   3. Verificar se 'users' está no nível correto")
    print("   4. Corrigir lógica de max_id baseado na estrutura real")
    print() 