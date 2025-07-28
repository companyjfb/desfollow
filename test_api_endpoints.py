#!/usr/bin/env python3
"""
Script para testar endpoints da API Desfollow
"""

import requests
import json
import time

# Configurações
BASE_URL = "http://api.desfollow.com.br"
TEST_USERNAME = "instagram"  # Username de teste

def test_health_endpoint():
    """Testa o endpoint de health check"""
    print("🔍 Testando endpoint /health...")
    
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=10)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Erro: {e}")
        return False

def test_api_health_endpoint():
    """Testa o endpoint /api/health"""
    print("\n🔍 Testando endpoint /api/health...")
    
    try:
        response = requests.get(f"{BASE_URL}/api/health", timeout=10)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Erro: {e}")
        return False

def test_scan_endpoint():
    """Testa o endpoint de scan"""
    print(f"\n🔍 Testando endpoint /api/scan com username: {TEST_USERNAME}...")
    
    try:
        payload = {"username": TEST_USERNAME}
        response = requests.post(
            f"{BASE_URL}/api/scan", 
            json=payload, 
            timeout=30,
            headers={"Content-Type": "application/json"}
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            job_id = data.get("job_id")
            print(f"✅ Job ID: {job_id}")
            return job_id
        else:
            print("❌ Falha no scan")
            return None
            
    except Exception as e:
        print(f"❌ Erro: {e}")
        return None

def test_scan_status(job_id):
    """Testa o status de um scan"""
    if not job_id:
        return
    
    print(f"\n🔍 Testando status do job: {job_id}...")
    
    try:
        response = requests.get(f"{BASE_URL}/api/scan/{job_id}", timeout=10)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            status = data.get("status")
            print(f"✅ Status do job: {status}")
            return status
        else:
            print("❌ Falha ao obter status")
            return None
            
    except Exception as e:
        print(f"❌ Erro: {e}")
        return None

def test_rapidapi_connection():
    """Testa conexão com RapidAPI"""
    print("\n🔍 Testando conexão com RapidAPI...")
    
    try:
        headers = {
            'x-rapidapi-host': 'instagram-premium-api-2023.p.rapidapi.com',
            'x-rapidapi-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01',
            'x-access-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'
        }
        
        url = "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/web_profile_info"
        params = {'username': TEST_USERNAME}
        
        response = requests.get(url, headers=headers, params=params, timeout=30)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print("✅ RapidAPI funcionando")
            return True
        else:
            print(f"❌ RapidAPI erro: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro RapidAPI: {e}")
        return False

def main():
    """Executa todos os testes"""
    print("🚀 Iniciando testes da API Desfollow...")
    print("=" * 50)
    
    # Teste 1: Health endpoints
    health_ok = test_health_endpoint()
    api_health_ok = test_api_health_endpoint()
    
    # Teste 2: RapidAPI
    rapidapi_ok = test_rapidapi_connection()
    
    # Teste 3: Scan endpoint
    job_id = test_scan_endpoint()
    
    # Teste 4: Status do scan
    if job_id:
        print(f"\n⏳ Aguardando 5 segundos para verificar status...")
        time.sleep(5)
        status = test_scan_status(job_id)
    
    print("\n" + "=" * 50)
    print("📊 RESUMO DOS TESTES:")
    print(f"✅ /health: {'OK' if health_ok else 'ERRO'}")
    print(f"✅ /api/health: {'OK' if api_health_ok else 'ERRO'}")
    print(f"✅ RapidAPI: {'OK' if rapidapi_ok else 'ERRO'}")
    print(f"✅ /api/scan: {'OK' if job_id else 'ERRO'}")
    
    if not rapidapi_ok:
        print("\n🚨 PROBLEMA IDENTIFICADO:")
        print("A RapidAPI não está respondendo. Verifique:")
        print("1. Se a API key está correta")
        print("2. Se há créditos disponíveis")
        print("3. Se a API está funcionando")
    
    if not job_id:
        print("\n🚨 PROBLEMA IDENTIFICADO:")
        print("O endpoint /api/scan não está funcionando. Verifique:")
        print("1. Se o backend está rodando")
        print("2. Se há erros nos logs")
        print("3. Se a configuração está correta")

if __name__ == "__main__":
    main() 