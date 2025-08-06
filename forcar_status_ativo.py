#!/usr/bin/env python3

import requests
import json

def forcar_status_ativo():
    """Força o status para ativo diretamente no banco"""
    print("🔧 FORÇANDO STATUS ATIVO NO BANCO")
    print("=================================")
    
    username = "jordanbitencourt" 
    url = f"https://api.desfollow.com.br/api/subscription/force-active/{username}"
    
    try:
        response = requests.post(url, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Status forçado com sucesso:")
            print(json.dumps(data, indent=2))
        else:
            print(f"❌ Erro ao forçar status: {response.status_code}")
            print(f"Resposta: {response.text}")
            
    except Exception as e:
        print(f"❌ Erro: {e}")

def verificar_depois():
    """Verifica o status após forçar"""
    print("\n🔍 VERIFICANDO APÓS FORÇAR")
    print("=========================")
    
    username = "jordanbitencourt"
    url = f"https://api.desfollow.com.br/api/subscription/check/{username}?verify_with_api=false"
    
    try:
        response = requests.get(url, timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            print(f"📊 Status atual: {data.get('subscription_status')}")
            print(f"✅ Ativa: {data.get('has_active_subscription')}")
            print(f"📅 Dias restantes: {data.get('days_remaining')}")
        else:
            print(f"❌ Erro: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Erro: {e}")

if __name__ == "__main__":
    forcar_status_ativo()
    verificar_depois()