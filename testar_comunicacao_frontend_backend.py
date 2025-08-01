#!/usr/bin/env python3
"""
🔍 Teste de Comunicação Frontend-Backend Desfollow
Verifica se os dados estão fluindo corretamente entre frontend e backend
"""

import requests
import json
import time
from typing import Dict, Any

# URLs de teste
BACKEND_BASE_URL = "https://api.desfollow.com.br"
API_BASE_URL = "https://api.desfollow.com.br/api"
FRONTEND_BASE_URL = "https://desfollow.com.br"

# Username de teste
TEST_USERNAME = "jordanbitencourt"

def test_backend_health():
    """Testa se o backend está respondendo"""
    print("\n🏥 1. TESTANDO SAÚDE DO BACKEND")
    print("=" * 50)
    
    try:
        response = requests.get(f"{BACKEND_BASE_URL}/health")
        print(f"📊 Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Backend está saudável: {data}")
            return True
        else:
            print(f"❌ Backend não está saudável: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erro ao conectar com backend: {e}")
        return False

def test_scan_start():
    """Testa início de scan"""
    print("\n🚀 2. TESTANDO INÍCIO DE SCAN")
    print("=" * 50)
    
    try:
        payload = {"username": TEST_USERNAME}
        response = requests.post(f"{API_BASE_URL}/scan", json=payload)
        
        print(f"📊 Status Code: {response.status_code}")
        print(f"📄 Response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            job_id = data.get("job_id")
            print(f"✅ Scan iniciado com sucesso!")
            print(f"🆔 Job ID: {job_id}")
            return job_id
        else:
            print(f"❌ Erro ao iniciar scan: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Erro ao iniciar scan: {e}")
        return None

def test_scan_status(job_id: str):
    """Testa consulta de status"""
    print(f"\n📊 3. TESTANDO STATUS DO SCAN")
    print("=" * 50)
    
    max_attempts = 10
    for attempt in range(1, max_attempts + 1):
        try:
            response = requests.get(f"{API_BASE_URL}/scan/{job_id}")
            
            print(f"🔄 Tentativa {attempt}/{max_attempts}")
            print(f"📊 Status Code: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                status = data.get("status")
                print(f"📈 Status: {status}")
                
                # Verificar se temos dados do perfil
                profile_info = data.get("profile_info")
                if profile_info:
                    print(f"👤 Perfil encontrado: {profile_info.get('followers_count', 0)} seguidores")
                
                # Verificar contadores
                followers_count = data.get("followers_count", 0)
                following_count = data.get("following_count", 0)
                print(f"📊 Dados capturados: {followers_count} seguidores, {following_count} seguindo")
                
                if status == "done":
                    print(f"✅ Scan concluído!")
                    print(f"👻 Ghosts encontrados: {data.get('count', 0)}")
                    print(f"🔍 Real ghosts: {data.get('real_ghosts_count', 0)}")
                    print(f"⭐ Famous ghosts: {data.get('famous_ghosts_count', 0)}")
                    return data
                elif status == "error":
                    error = data.get("error", "Erro desconhecido")
                    print(f"❌ Scan falhou: {error}")
                    return None
                else:
                    print(f"⏳ Aguardando... (status: {status})")
            else:
                print(f"❌ Erro na consulta: {response.text}")
            
            time.sleep(2)
            
        except Exception as e:
            print(f"❌ Erro na tentativa {attempt}: {e}")
            time.sleep(2)
    
    print(f"⏰ Timeout após {max_attempts} tentativas")
    return None

def test_history_api():
    """Testa API de histórico"""
    print(f"\n📋 4. TESTANDO API DE HISTÓRICO")
    print("=" * 50)
    
    try:
        response = requests.get(f"{API_BASE_URL}/user/{TEST_USERNAME}/history")
        
        print(f"📊 Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Histórico obtido com sucesso!")
            print(f"📊 Número de scans no histórico: {len(data)}")
            
            if data:
                latest = data[0]
                print(f"🕐 Último scan: {latest.get('created_at')}")
                print(f"📈 Status: {latest.get('status')}")
                print(f"👻 Ghosts: {latest.get('ghosts_count', 0)}")
            
            return data
        else:
            print(f"📭 Nenhum histórico encontrado: {response.text}")
            return []
    except Exception as e:
        print(f"❌ Erro ao consultar histórico: {e}")
        return None

def test_cors():
    """Testa configuração CORS"""
    print(f"\n🌐 5. TESTANDO CONFIGURAÇÃO CORS")
    print("=" * 50)
    
    try:
        # Simular requisição CORS do frontend
        headers = {
            "Origin": FRONTEND_BASE_URL,
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "Content-Type"
        }
        
        response = requests.options(f"{API_BASE_URL}/scan", headers=headers)
        print(f"📊 Preflight Status: {response.status_code}")
        print(f"🔒 CORS Headers: {dict(response.headers)}")
        
        if response.status_code in [200, 204]:
            print(f"✅ CORS configurado corretamente!")
            return True
        else:
            print(f"❌ Problema na configuração CORS")
            return False
            
    except Exception as e:
        print(f"❌ Erro no teste CORS: {e}")
        return False

def main():
    """Executa todos os testes"""
    print("🧪 TESTE COMPLETO DE COMUNICAÇÃO FRONTEND-BACKEND")
    print("=" * 60)
    print(f"🖥️  Backend URL: {BACKEND_BASE_URL}")
    print(f"🎯 API Base URL: {API_BASE_URL}")
    print(f"🌐 Frontend URL: {FRONTEND_BASE_URL}")
    print(f"👤 Username de teste: {TEST_USERNAME}")
    
    # 1. Testar saúde do backend
    if not test_backend_health():
        print("\n❌ Backend não está respondendo. Parando testes.")
        return
    
    # 2. Testar CORS
    test_cors()
    
    # 3. Testar início de scan
    job_id = test_scan_start()
    if not job_id:
        print("\n❌ Não foi possível iniciar scan. Parando testes.")
        return
    
    # 4. Testar status do scan
    scan_result = test_scan_status(job_id)
    
    # 5. Testar histórico
    test_history_api()
    
    # Resumo final
    print("\n🎯 RESUMO DOS TESTES")
    print("=" * 50)
    
    if scan_result and scan_result.get("status") == "done":
        print("✅ Comunicação frontend-backend funcionando!")
        print("✅ Dados sendo transmitidos corretamente!")
        
        # Verificar se há dados reais
        followers_count = scan_result.get("followers_count", 0)
        following_count = scan_result.get("following_count", 0)
        
        if followers_count > 0 or following_count > 0:
            print("✅ APIs do Instagram retornando dados!")
        else:
            print("⚠️  APIs do Instagram retornando 0 dados - verificar configuração")
            
    else:
        print("❌ Problemas na comunicação detectados")
    
    print("\n" + "=" * 60)

if __name__ == "__main__":
    main()