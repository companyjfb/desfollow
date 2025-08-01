#!/usr/bin/env python3
"""
Teste completo do fluxo de scaneamento do Desfollow:
1. Iniciar scan via API
2. Acompanhar progresso
3. Verificar resultado final
4. Testar todas as integrações (APIs, banco, frontend)
"""

import requests
import time
import json

def testar_fluxo_completo(username="jordanbitencourt"):
    """
    Testa o fluxo completo de scaneamento exatamente como o frontend faria.
    """
    print(f"🚀 TESTE COMPLETO DO FLUXO DESFOLLOW")
    print(f"👤 Username: @{username}")
    print("=" * 70)
    
    base_url = "https://api.desfollow.com.br"
    
    # 1. Iniciar scan
    print(f"\n📋 1. INICIANDO SCAN...")
    print("-" * 40)
    
    try:
        response = requests.post(f"{base_url}/api/scan", json={"username": username})
        print(f"📊 Status: {response.status_code}")
        
        if response.status_code != 200:
            print(f"❌ ERRO ao iniciar scan: {response.text}")
            return False
            
        scan_data = response.json()
        job_id = scan_data.get("job_id")
        
        if not job_id:
            print(f"❌ ERRO: job_id não retornado")
            print(f"📄 Response: {scan_data}")
            return False
            
        print(f"✅ Scan iniciado!")
        print(f"🆔 Job ID: {job_id}")
        
    except Exception as e:
        print(f"❌ ERRO ao iniciar scan: {e}")
        return False
    
    # 2. Acompanhar progresso
    print(f"\n📋 2. ACOMPANHANDO PROGRESSO...")
    print("-" * 40)
    
    max_attempts = 30  # 5 minutos máximo
    attempt = 1
    
    while attempt <= max_attempts:
        try:
            print(f"🔄 Tentativa {attempt}/{max_attempts}")
            
            response = requests.get(f"{base_url}/api/scan/{job_id}")
            print(f"📊 Status: {response.status_code}")
            
            if response.status_code != 200:
                print(f"❌ ERRO ao consultar status: {response.text}")
                time.sleep(10)
                attempt += 1
                continue
                
            status_data = response.json()
            status = status_data.get("status", "unknown")
            
            print(f"📈 Status atual: {status}")
            
            if status == "running":
                # Mostrar progresso se disponível
                profile_info = status_data.get("profile_info", {})
                followers_count = profile_info.get("followers_count", 0)
                following_count = profile_info.get("following_count", 0)
                
                print(f"👤 Perfil: {followers_count} seguidores, {following_count} seguindo")
                print(f"⏳ Aguardando conclusão...")
                
            elif status == "done":
                print(f"✅ SCAN CONCLUÍDO!")
                
                # Analisar resultado
                print(f"\n📋 3. ANALISANDO RESULTADO...")
                print("-" * 40)
                
                analisar_resultado(status_data)
                return True
                
            elif status == "error":
                error_msg = status_data.get("error_message", "Erro desconhecido")
                print(f"❌ SCAN FALHOU: {error_msg}")
                return False
                
            else:
                print(f"⚠️ Status desconhecido: {status}")
            
            time.sleep(10)  # Aguardar 10 segundos
            attempt += 1
            
        except Exception as e:
            print(f"❌ ERRO ao consultar status: {e}")
            time.sleep(10)
            attempt += 1
    
    print(f"⏰ TIMEOUT: Scan não concluído em {max_attempts * 10} segundos")
    return False

def analisar_resultado(data):
    """
    Analisa o resultado final do scan
    """
    print(f"📊 RESULTADO FINAL:")
    
    # Informações do perfil
    profile_info = data.get("profile_info", {})
    print(f"👤 Perfil:")
    print(f"   - Username: {profile_info.get('username', 'N/A')}")
    print(f"   - Nome: {profile_info.get('full_name', 'N/A')}")
    print(f"   - Seguidores (perfil): {profile_info.get('followers_count', 0)}")
    print(f"   - Seguindo (perfil): {profile_info.get('following_count', 0)}")
    print(f"   - Privado: {profile_info.get('is_private', False)}")
    print(f"   - Verificado: {profile_info.get('is_verified', False)}")
    
    # Dados do scan
    ghosts_data = data.get("ghosts_data", {})
    print(f"\n👻 DADOS DO SCAN:")
    print(f"   - Seguidores capturados: {ghosts_data.get('followers_count', 0)}")
    print(f"   - Seguindo capturados: {ghosts_data.get('following_count', 0)}")
    print(f"   - Ghosts encontrados: {ghosts_data.get('ghosts_count', 0)}")
    print(f"   - Real ghosts: {ghosts_data.get('real_ghosts_count', 0)}")
    print(f"   - Famous ghosts: {ghosts_data.get('famous_ghosts_count', 0)}")
    
    # Verificar se há erros
    error = ghosts_data.get("error")
    if error:
        print(f"⚠️ ERRO REPORTADO: {error}")
    
    # Verificar dados dos cards
    ghosts = ghosts_data.get("ghosts", [])
    real_ghosts = ghosts_data.get("real_ghosts", [])
    famous_ghosts = ghosts_data.get("famous_ghosts", [])
    
    print(f"\n📋 CARDS DE PERFIS:")
    print(f"   - Total ghosts (cards): {len(ghosts)}")
    print(f"   - Real ghosts (cards): {len(real_ghosts)}")
    print(f"   - Famous ghosts (cards): {len(famous_ghosts)}")
    
    # Mostrar alguns exemplos
    if ghosts:
        print(f"\n👥 PRIMEIROS 3 GHOSTS:")
        for i, ghost in enumerate(ghosts[:3]):
            username = ghost.get('username', 'N/A')
            full_name = ghost.get('full_name', 'N/A')
            ghost_type = ghost.get('ghost_type', 'N/A')
            print(f"   {i+1}. @{username} - {full_name} ({ghost_type})")
    
    # Verificar consistência
    print(f"\n🔍 VERIFICAÇÃO DE CONSISTÊNCIA:")
    
    followers_captured = ghosts_data.get('followers_count', 0)
    following_captured = ghosts_data.get('following_count', 0)
    
    if followers_captured == 0 and following_captured == 0:
        print(f"❌ PROBLEMA: Nenhum dado capturado das APIs")
    elif len(ghosts) == 0 and following_captured > 0:
        print(f"⚠️ SUSPEITO: {following_captured} seguindo mas 0 ghosts")
    else:
        print(f"✅ Dados parecem consistentes")
    
    # Estatísticas percentuais
    if following_captured > 0:
        ghost_rate = (len(ghosts) / following_captured) * 100
        print(f"📊 Taxa de ghosts real: {ghost_rate:.1f}%")
    
    print(f"\n" + "=" * 70)

if __name__ == "__main__":
    success = testar_fluxo_completo()
    
    print(f"\n🎯 RESULTADO FINAL:")
    if success:
        print(f"✅ Fluxo completo funcionando!")
    else:
        print(f"❌ Fluxo com problemas!")
    
    print("=" * 70)