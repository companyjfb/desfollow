#!/usr/bin/env python3
"""
Teste Específico da Paginação da API do Instagram
==================================================

Este script testa especificamente a paginação das APIs do Instagram
para verificar se está funcionando corretamente.
"""

import os
import requests
import json
import time
from dotenv import load_dotenv

# Configurar logging
import logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Configuração das APIs
API_2_HOST = 'instagram-scraper-20251.p.rapidapi.com'
API_2_BASE_URL = f'https://{API_2_HOST}'
RAPIDAPI_KEY = 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'

def test_paginacao_followers(user_id: str, max_pages: int = 5):
    """Testa paginação de seguidores"""
    logger.info(f"🧪 Testando paginação de FOLLOWERS para user_id: {user_id}")
    
    all_followers = []
    pagination_token = None
    page = 1
    
    headers = {
        'x-rapidapi-host': API_2_HOST,
        'x-rapidapi-key': RAPIDAPI_KEY
    }
    
    while page <= max_pages:
        logger.info(f"📄 === PÁGINA {page} FOLLOWERS ===")
        
        try:
            url = f"{API_2_BASE_URL}/userfollowers/"
            params = {
                'username_or_id': user_id,
                'count': 50
            }
            
            if pagination_token:
                params['pagination_token'] = pagination_token
                logger.info(f"🔗 Usando pagination_token: {pagination_token[:50]}...")
            
            logger.info(f"📡 URL: {url}")
            logger.info(f"📝 Params: {params}")
            
            response = requests.get(url, params=params, headers=headers)
            logger.info(f"📊 Status code: {response.status_code}")
            
            if response.status_code != 200:
                logger.error(f"❌ ERRO na API: {response.status_code}")
                logger.error(f"📄 Response: {response.text[:500]}")
                break
                
            data = response.json()
            
            # Log da estrutura da resposta
            logger.info(f"📊 Estrutura da resposta:")
            logger.info(f"   - Keys: {list(data.keys())}")
            
            api_data = data.get('data', {})
            items = api_data.get('items', [])
            count = api_data.get('count', 0)
            
            pagination_token = data.get('pagination_token')
            
            logger.info(f"   - data.count: {count}")
            logger.info(f"   - data.items: {len(items)} items")
            logger.info(f"   - pagination_token: {pagination_token}")
            
            if not items:
                logger.info(f"🏁 Fim da paginação - Nenhum item na página {page}")
                break
                
            logger.info(f"✅ {len(items)} seguidores recebidos na página {page}")
            
            # Processar usuários
            page_new_users = 0
            for i, user in enumerate(items):
                username = user.get('username')
                if i < 3:  # Log dos primeiros 3
                    logger.info(f"🔍 User {i+1}: @{username} - {user.get('full_name', 'N/A')}")
                
                if not username:
                    continue
                    
                # Evitar duplicatas
                if any(f['username'] == username for f in all_followers):
                    continue
                
                user_data = {
                    'id': user.get('id'),
                    'username': username,
                    'full_name': user.get('full_name', ''),
                    'profile_pic_url': user.get('profile_pic_url', ''),
                    'is_private': user.get('is_private', False),
                    'is_verified': user.get('is_verified', False)
                }
                all_followers.append(user_data)
                page_new_users += 1
            
            logger.info(f"📊 Página {page}: {page_new_users} novos usuários")
            logger.info(f"📊 Total acumulado: {len(all_followers)} usuários")
            
            # Verificar se há mais páginas
            if not pagination_token:
                logger.info(f"🏁 Fim da paginação - Sem pagination_token")
                break
                
            page += 1
            time.sleep(1)  # Pequeno delay entre requisições
            
        except Exception as e:
            logger.error(f"❌ ERRO na página {page}: {str(e)}")
            break
    
    logger.info(f"✅ TESTE FOLLOWERS CONCLUÍDO!")
    logger.info(f"📊 Total de seguidores capturados: {len(all_followers)}")
    logger.info(f"📊 Páginas processadas: {page - 1}")
    
    return all_followers

def test_paginacao_following(user_id: str, max_pages: int = 5):
    """Testa paginação de seguindo"""
    logger.info(f"🧪 Testando paginação de FOLLOWING para user_id: {user_id}")
    
    all_following = []
    pagination_token = None
    page = 1
    
    headers = {
        'x-rapidapi-host': API_2_HOST,
        'x-rapidapi-key': RAPIDAPI_KEY
    }
    
    while page <= max_pages:
        logger.info(f"📄 === PÁGINA {page} FOLLOWING ===")
        
        try:
            url = f"{API_2_BASE_URL}/userfollowing/"
            params = {
                'username_or_id': user_id,
                'count': 50
            }
            
            if pagination_token:
                params['pagination_token'] = pagination_token
                logger.info(f"🔗 Usando pagination_token: {pagination_token[:50]}...")
            
            logger.info(f"📡 URL: {url}")
            logger.info(f"📝 Params: {params}")
            
            response = requests.get(url, params=params, headers=headers)
            logger.info(f"📊 Status code: {response.status_code}")
            
            if response.status_code != 200:
                logger.error(f"❌ ERRO na API: {response.status_code}")
                logger.error(f"📄 Response: {response.text[:500]}")
                break
                
            data = response.json()
            
            # Log da estrutura da resposta
            logger.info(f"📊 Estrutura da resposta:")
            logger.info(f"   - Keys: {list(data.keys())}")
            
            api_data = data.get('data', {})
            items = api_data.get('items', [])
            count = api_data.get('count', 0)
            
            pagination_token = data.get('pagination_token')
            
            logger.info(f"   - data.count: {count}")
            logger.info(f"   - data.items: {len(items)} items")
            logger.info(f"   - pagination_token: {pagination_token}")
            
            if not items:
                logger.info(f"🏁 Fim da paginação - Nenhum item na página {page}")
                break
                
            logger.info(f"✅ {len(items)} seguindo recebidos na página {page}")
            
            # Processar usuários
            page_new_users = 0
            for i, user in enumerate(items):
                username = user.get('username')
                if i < 3:  # Log dos primeiros 3
                    logger.info(f"🔍 User {i+1}: @{username} - {user.get('full_name', 'N/A')}")
                
                if not username:
                    continue
                    
                # Evitar duplicatas
                if any(f['username'] == username for f in all_following):
                    continue
                
                user_data = {
                    'id': user.get('id'),
                    'username': username,
                    'full_name': user.get('full_name', ''),
                    'profile_pic_url': user.get('profile_pic_url', ''),
                    'is_private': user.get('is_private', False),
                    'is_verified': user.get('is_verified', False)
                }
                all_following.append(user_data)
                page_new_users += 1
            
            logger.info(f"📊 Página {page}: {page_new_users} novos usuários")
            logger.info(f"📊 Total acumulado: {len(all_following)} usuários")
            
            # Verificar se há mais páginas
            if not pagination_token:
                logger.info(f"🏁 Fim da paginação - Sem pagination_token")
                break
                
            page += 1
            time.sleep(1)  # Pequeno delay entre requisições
            
        except Exception as e:
            logger.error(f"❌ ERRO na página {page}: {str(e)}")
            break
    
    logger.info(f"✅ TESTE FOLLOWING CONCLUÍDO!")
    logger.info(f"📊 Total de seguindo capturados: {len(all_following)}")
    logger.info(f"📊 Páginas processadas: {page - 1}")
    
    return all_following

def get_user_id_from_username(username: str):
    """Obtém user_id a partir do username"""
    try:
        headers = {
            'x-rapidapi-host': 'instagram-premium-api-2023.p.rapidapi.com',
            'x-rapidapi-key': RAPIDAPI_KEY,
            'x-access-key': RAPIDAPI_KEY
        }
        
        url = "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/web_profile_info"
        params = {'username': username}
        
        response = requests.get(url, headers=headers, params=params)
        
        if response.status_code == 200:
            data = response.json()
            if 'user' in data:
                user_id = data['user'].get('id')
                logger.info(f"✅ User ID obtido para @{username}: {user_id}")
                return user_id
        else:
            logger.error(f"❌ Erro ao obter user_id: {response.status_code}")
            
    except Exception as e:
        logger.error(f"❌ Erro ao obter user_id: {e}")
    
    return None

def main():
    """Função principal"""
    logger.info("🚀 Iniciando teste de paginação da API do Instagram...")
    
    # Username para testar (pode ser alterado)
    test_username = "instagram"  # Perfil público para teste
    
    logger.info(f"🧪 Testando com username: @{test_username}")
    
    # Obter user_id
    user_id = get_user_id_from_username(test_username)
    
    if not user_id:
        logger.error("❌ Não foi possível obter user_id. Teste abortado.")
        return
    
    # Testar paginação de seguidores
    logger.info("=" * 50)
    followers = test_paginacao_followers(user_id, max_pages=3)
    
    # Testar paginação de seguindo
    logger.info("=" * 50)
    following = test_paginacao_following(user_id, max_pages=3)
    
    # Resumo final
    logger.info("=" * 50)
    logger.info("📊 RESUMO FINAL:")
    logger.info(f"   - Seguidores capturados: {len(followers)}")
    logger.info(f"   - Seguindo capturados: {len(following)}")
    logger.info(f"   - Total de usuários: {len(followers) + len(following)}")
    
    # Salvar resultados em arquivo
    results = {
        'user_id': user_id,
        'username': test_username,
        'followers_count': len(followers),
        'following_count': len(following),
        'followers_sample': followers[:5] if followers else [],
        'following_sample': following[:5] if following else []
    }
    
    with open('teste_paginacao_resultado.json', 'w') as f:
        json.dump(results, f, indent=2)
    
    logger.info("💾 Resultados salvos em 'teste_paginacao_resultado.json'")

if __name__ == "__main__":
    main() 