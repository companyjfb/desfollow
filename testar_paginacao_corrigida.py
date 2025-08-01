#!/usr/bin/env python3
"""
Script de teste para verificar a paginação corrigida do scan.
Testa se a lógica de paginação está funcionando corretamente:
1. Busca todos os followers até terminar
2. Busca todos os following até terminar
3. Analisa os ghosts
"""

import asyncio
import sys
import os

# Adicionar o diretório backend ao path
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))

from app.ig import get_ghosts_with_profile, get_followers_with_new_api, get_following_with_new_api
from app.database import get_db

async def test_paginacao_completa(username: str):
    """
    Testa a paginação completa: followers -> following -> análise
    """
    print(f"🧪 === TESTE DE PAGINAÇÃO COMPLETA ===")
    print(f"👤 Usuário: {username}")
    print(f"📊 Testando lógica: followers -> following -> análise")
    
    try:
        # Testar função completa
        result = await get_ghosts_with_profile(username)
        
        print(f"\n✅ RESULTADO FINAL:")
        print(f"   - Seguidores capturados: {result.get('followers_count', 0)}")
        print(f"   - Seguindo capturados: {result.get('following_count', 0)}")
        print(f"   - Ghosts totais: {result.get('ghosts_count', 0)}")
        print(f"   - Ghosts reais: {result.get('real_ghosts_count', 0)}")
        print(f"   - Ghosts famosos: {result.get('famous_ghosts_count', 0)}")
        
        if result.get('error'):
            print(f"❌ ERRO: {result.get('error')}")
            return False
            
        return True
        
    except Exception as e:
        print(f"❌ ERRO no teste: {str(e)}")
        return False

async def test_paginacao_followers(username: str):
    """
    Testa apenas a paginação de followers
    """
    print(f"🧪 === TESTE DE PAGINAÇÃO FOLLOWERS ===")
    print(f"👤 Usuário: {username}")
    
    try:
        # Obter user_id primeiro
        from app.ig import get_user_data_from_rapidapi
        user_id, profile_info = get_user_data_from_rapidapi(username)
        
        if not user_id:
            print(f"❌ Não foi possível obter user_id para {username}")
            return False
            
        print(f"✅ User ID: {user_id}")
        print(f"📊 Profile: {profile_info.get('followers_count', 0)} seguidores")
        
        # Testar paginação de followers
        followers = await get_followers_with_new_api(user_id)
        
        print(f"\n✅ RESULTADO FOLLOWERS:")
        print(f"   - Seguidores capturados: {len(followers)}")
        print(f"   - Esperado: {profile_info.get('followers_count', 0)}")
        
        return True
        
    except Exception as e:
        print(f"❌ ERRO no teste followers: {str(e)}")
        return False

async def test_paginacao_following(username: str):
    """
    Testa apenas a paginação de following
    """
    print(f"🧪 === TESTE DE PAGINAÇÃO FOLLOWING ===")
    print(f"👤 Usuário: {username}")
    
    try:
        # Obter user_id primeiro
        from app.ig import get_user_data_from_rapidapi
        user_id, profile_info = get_user_data_from_rapidapi(username)
        
        if not user_id:
            print(f"❌ Não foi possível obter user_id para {username}")
            return False
            
        print(f"✅ User ID: {user_id}")
        print(f"📊 Profile: {profile_info.get('following_count', 0)} seguindo")
        
        # Testar paginação de following
        following = await get_following_with_new_api(user_id)
        
        print(f"\n✅ RESULTADO FOLLOWING:")
        print(f"   - Seguindo capturados: {len(following)}")
        print(f"   - Esperado: {profile_info.get('following_count', 0)}")
        
        return True
        
    except Exception as e:
        print(f"❌ ERRO no teste following: {str(e)}")
        return False

async def main():
    """
    Função principal para executar os testes
    """
    if len(sys.argv) < 2:
        print("❌ Uso: python testar_paginacao_corrigida.py <username> [teste]")
        print("   Testes disponíveis: completo, followers, following")
        print("   Exemplo: python testar_paginacao_corrigida.py johndoe completo")
        return
    
    username = sys.argv[1]
    teste = sys.argv[2] if len(sys.argv) > 2 else "completo"
    
    print(f"🚀 Iniciando teste de paginação para: @{username}")
    print(f"🧪 Tipo de teste: {teste}")
    
    success = False
    
    if teste == "completo":
        success = await test_paginacao_completa(username)
    elif teste == "followers":
        success = await test_paginacao_followers(username)
    elif teste == "following":
        success = await test_paginacao_following(username)
    else:
        print(f"❌ Teste '{teste}' não reconhecido")
        return
    
    if success:
        print(f"\n✅ TESTE CONCLUÍDO COM SUCESSO!")
    else:
        print(f"\n❌ TESTE FALHOU!")

if __name__ == "__main__":
    asyncio.run(main()) 