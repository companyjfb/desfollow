import asyncio
import httpx
import requests
from typing import Set, Tuple
import time
import random
import re

# Configuração da RapidAPI
RAPIDAPI_KEY = "dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01"
RAPIDAPI_HOST = "instagram-premium-api-2023.p.rapidapi.com"

async def get_user_id_from_rapidapi(username: str) -> str:
    """
    Obtém o user_id real do Instagram usando RapidAPI web_profile_info.
    """
    try:
        print(f"🔍 Obtendo user_id via RapidAPI para: {username}")
        
        clean_username = username.replace('@', '')
        
        # Headers para a API
        headers = {
            'x-rapidapi-host': RAPIDAPI_HOST,
            'x-rapidapi-key': RAPIDAPI_KEY,
            'x-access-key': RAPIDAPI_KEY
        }
        
        # Endpoint para obter informações do perfil
        profile_url = f"https://{RAPIDAPI_HOST}/v1/user/web_profile_info"
        profile_params = {'username': clean_username}
        
        print(f"🔄 Obtendo informações do perfil: {clean_username}")
        profile_response = requests.get(profile_url, headers=headers, params=profile_params)
        
        if profile_response.status_code == 200:
            profile_data = profile_response.json()
            
            # Extrai o user_id da resposta
            if 'user' in profile_data and 'id' in profile_data['user']:
                user_id = profile_data['user']['id']
                print(f"✅ User ID obtido via RapidAPI: {user_id}")
                return user_id
            else:
                print("⚠️ User ID não encontrado na resposta")
                return None
        else:
            print(f"❌ Erro ao obter perfil: {profile_response.status_code}")
            print(f"Response: {profile_response.text[:100]}...")
            return None
            
    except Exception as e:
        print(f"❌ Erro ao obter user_id via RapidAPI: {e}")
        return None

async def get_all_instagram_data_with_pagination(user_id: str, headers: dict) -> Tuple[list, list]:
    """
    Obtém todos os dados possíveis do Instagram usando paginação com endpoints /chunk.
    Sempre tenta 2 páginas para cada tipo, mesmo com erros.
    Mostra apenas usuários NOVOS encontrados em cada página.
    """
    all_followers = []
    all_following = []
    
    # Conjuntos para rastrear usuários já encontrados em cada campo
    found_followers_usernames = set()
    found_following_usernames = set()
    
    print(f"🔄 Obtendo TODOS os seguidores para user_id: {user_id}...")
    
    # Endpoints /chunk
    followers_url = f"https://{RAPIDAPI_HOST}/v1/user/followers/chunk"
    following_url = f"https://{RAPIDAPI_HOST}/v1/user/following/chunk"
    
    # Paginação para seguidores - SEMPRE 2 páginas
    print("📄 Paginação de seguidores com /chunk...")
    
    # Primeira requisição sem max_id
    try:
        followers_response = requests.get(followers_url, headers=headers, params={'user_id': user_id})
        if followers_response.status_code == 200:
            followers_data = followers_response.json()
            
            # Processa a resposta que pode ser uma lista aninhada
            current_page_followers = []
            if isinstance(followers_data, list):
                # Verifica se é uma lista aninhada (primeiro item é uma lista)
                if len(followers_data) > 0 and isinstance(followers_data[0], list):
                    # É uma lista aninhada, extrai os usuários da lista interna
                    for nested_list in followers_data:
                        if isinstance(nested_list, list):
                            current_page_followers.extend(nested_list)
                else:
                    # É uma lista direta de usuários
                    current_page_followers = followers_data
            elif isinstance(followers_data, dict):
                data = followers_data.get('data', [])
                if data:
                    current_page_followers = data
            
            # Filtra apenas usuários NOVOS (não encontrados anteriormente)
            new_followers = []
            for follower in current_page_followers:
                if isinstance(follower, dict) and 'username' in follower:
                    username = follower['username']
                    if username not in found_followers_usernames:
                        found_followers_usernames.add(username)
                        new_followers.append(follower)
            
            all_followers.extend(new_followers)
            print(f"✅ Página 1 (sem max_id): {len(new_followers)} seguidores NOVOS encontrados")
        else:
            print(f"⚠️ Página 1 falhou: {followers_response.status_code} - continuando...")
    except Exception as e:
        print(f"⚠️ Erro na página 1: {e} - continuando...")
    
    # Páginas subsequentes usando max_id incremental (2) - SEMPRE 2 páginas
    max_pages = 2  # Sempre 2 páginas
    
    for page in range(2, max_pages + 1):
        try:
            max_id = page  # Usa o número da página como max_id
            followers_response = requests.get(followers_url, headers=headers, params={'user_id': user_id, 'max_id': max_id})
            
            if followers_response.status_code == 200:
                followers_data = followers_response.json()
                
                # Extrai dados da resposta
                current_page_followers = []
                if isinstance(followers_data, list):
                    # Verifica se é uma lista aninhada
                    if len(followers_data) > 0 and isinstance(followers_data[0], list):
                        # É uma lista aninhada, extrai os usuários da lista interna
                        for nested_list in followers_data:
                            if isinstance(nested_list, list):
                                current_page_followers.extend(nested_list)
                    else:
                        current_page_followers = followers_data
                elif isinstance(followers_data, dict):
                    current_page_followers = followers_data.get('data', [])
                
                # Filtra apenas usuários NOVOS (não encontrados anteriormente)
                new_followers = []
                for follower in current_page_followers:
                    if isinstance(follower, dict) and 'username' in follower:
                        username = follower['username']
                        if username not in found_followers_usernames:
                            found_followers_usernames.add(username)
                            new_followers.append(follower)
                
                all_followers.extend(new_followers)
                print(f"✅ Página {page} (max_id={max_id}): {len(new_followers)} seguidores NOVOS encontrados")
                    
            else:
                print(f"⚠️ Página {page} falhou: {followers_response.status_code} - continuando...")
                
        except Exception as e:
            print(f"⚠️ Erro na página {page}: {e} - continuando...")
    
    # Paginação para seguindo - SEMPRE 2 páginas
    print(f"🔄 Obtendo TODOS os seguindo para user_id: {user_id}...")
    print("📄 Paginação de seguindo com /chunk...")
    
    # Primeira requisição sem max_id
    try:
        following_response = requests.get(following_url, headers=headers, params={'user_id': user_id})
        if following_response.status_code == 200:
            following_data = following_response.json()
            
            # Processa a resposta que pode ser uma lista aninhada
            current_page_following = []
            if isinstance(following_data, list):
                # Verifica se é uma lista aninhada (primeiro item é uma lista)
                if len(following_data) > 0 and isinstance(following_data[0], list):
                    # É uma lista aninhada, extrai os usuários da lista interna
                    for nested_list in following_data:
                        if isinstance(nested_list, list):
                            current_page_following.extend(nested_list)
                else:
                    # É uma lista direta de usuários
                    current_page_following = following_data
            elif isinstance(following_data, dict):
                data = following_data.get('data', [])
                if data:
                    current_page_following = data
            
            # Filtra apenas usuários NOVOS (não encontrados anteriormente)
            new_following = []
            for following in current_page_following:
                if isinstance(following, dict) and 'username' in following:
                    username = following['username']
                    if username not in found_following_usernames:
                        found_following_usernames.add(username)
                        new_following.append(following)
            
            all_following.extend(new_following)
            print(f"✅ Página 1 (sem max_id): {len(new_following)} seguindo NOVOS encontrados")
        else:
            print(f"⚠️ Página 1 falhou: {following_response.status_code} - continuando...")
    except Exception as e:
        print(f"⚠️ Erro na página 1: {e} - continuando...")
    
    # Páginas subsequentes usando max_id incremental (2) - SEMPRE 2 páginas
    for page in range(2, max_pages + 1):
        try:
            max_id = page  # Usa o número da página como max_id
            following_response = requests.get(following_url, headers=headers, params={'user_id': user_id, 'max_id': max_id})
            
            if following_response.status_code == 200:
                following_data = following_response.json()
                
                # Extrai dados da resposta
                current_page_following = []
                if isinstance(following_data, list):
                    # Verifica se é uma lista aninhada
                    if len(following_data) > 0 and isinstance(following_data[0], list):
                        # É uma lista aninhada, extrai os usuários da lista interna
                        for nested_list in following_data:
                            if isinstance(nested_list, list):
                                current_page_following.extend(nested_list)
                    else:
                        current_page_following = following_data
                elif isinstance(following_data, dict):
                    current_page_following = following_data.get('data', [])
                
                # Filtra apenas usuários NOVOS (não encontrados anteriormente)
                new_following = []
                for following in current_page_following:
                    if isinstance(following, dict) and 'username' in following:
                        username = following['username']
                        if username not in found_following_usernames:
                            found_following_usernames.add(username)
                            new_following.append(following)
                
                all_following.extend(new_following)
                print(f"✅ Página {page} (max_id={max_id}): {len(new_following)} seguindo NOVOS encontrados")
                    
            else:
                print(f"⚠️ Página {page} falhou: {following_response.status_code} - continuando...")
                
        except Exception as e:
            print(f"⚠️ Erro na página {page}: {e} - continuando...")
    
    # Remove duplicatas (por segurança, embora já tenhamos filtrado)
    unique_followers = {}
    for follower in all_followers:
        if isinstance(follower, dict) and 'username' in follower:
            username = follower['username']
            if username not in unique_followers:
                unique_followers[username] = follower
    
    unique_following = {}
    for following in all_following:
        if isinstance(following, dict) and 'username' in following:
            username = following['username']
            if username not in unique_following:
                unique_following[username] = following
    
    all_followers = list(unique_followers.values())
    all_following = list(unique_following.values())
    
    print(f"🎯 Seguidores únicos encontrados: {len(all_followers)}")
    print(f"🎯 Seguindo únicos encontrados: {len(all_following)}")
    print(f"📊 Resultado final - Seguidores únicos: {len(all_followers)}, Seguindo únicos: {len(all_following)}")
    
    return all_following, all_followers

async def get_instagram_data_rapidapi(username: str) -> Tuple[Set[str], Set[str], dict]:
    """
    Obtém dados reais do Instagram usando RapidAPI Premium API.
    Retorna: (following_users, followers_users, profile_info)
    """
    try:
        print(f"🚀 RapidAPI: Tentando obter dados para {username}")
        
        # Remove @ se presente
        clean_username = username.replace('@', '')
        
        # Primeiro, obtém o user_id real via RapidAPI
        user_id = await get_user_id_from_rapidapi(clean_username)
        
        if not user_id:
            print("❌ Não foi possível obter user_id via RapidAPI")
            return set(), set(), {}
        
        # Headers para a API
        headers = {
            'x-rapidapi-host': RAPIDAPI_HOST,
            'x-rapidapi-key': RAPIDAPI_KEY,
            'x-access-key': RAPIDAPI_KEY
        }
        
        # Obtém informações completas do perfil
        profile_info = {}
        profile_url = f"https://{RAPIDAPI_HOST}/v1/user/web_profile_info"
        profile_params = {'username': clean_username}
        
        print(f"🔄 Obtendo informações completas do perfil...")
        profile_response = requests.get(profile_url, headers=headers, params=profile_params)
        
        if profile_response.status_code == 200:
            profile_data = profile_response.json()
            if 'user' in profile_data:
                user_data = profile_data['user']
                profile_info = {
                    'username': user_data.get('username', clean_username),
                    'full_name': user_data.get('full_name', ''),
                    'profile_pic_url': user_data.get('profile_pic_url', ''),
                    'profile_pic_url_hd': user_data.get('profile_pic_url_hd', ''),
                    'biography': user_data.get('biography', ''),
                    'is_private': user_data.get('is_private', False),
                    'is_verified': user_data.get('is_verified', False),
                    'followers_count': user_data.get('edge_followed_by', {}).get('count', 0),
                    'following_count': user_data.get('edge_follow', {}).get('count', 0),
                    'posts_count': user_data.get('edge_owner_to_timeline_media', {}).get('count', 0)
                }
                print(f"✅ Informações do perfil obtidas")
        
        # Obtém todos os dados com paginação
        following_data, followers_data = await get_all_instagram_data_with_pagination(user_id, headers)
        
        # Extrai usernames e dados completos dos seguidores
        followers_users = set()
        followers_details = []
        for user in followers_data:
            if isinstance(user, dict) and 'username' in user:
                followers_users.add(user['username'])
                followers_details.append({
                    'username': user['username'],
                    'full_name': user.get('full_name', ''),
                    'profile_pic_url': user.get('profile_pic_url', ''),
                    'is_private': user.get('is_private', False),
                    'is_verified': user.get('is_verified', False)
                })
        
        # Extrai usernames e dados completos dos seguindo
        following_users = set()
        following_details = []
        for user in following_data:
            if isinstance(user, dict) and 'username' in user:
                following_users.add(user['username'])
                following_details.append({
                    'username': user['username'],
                    'full_name': user.get('full_name', ''),
                    'profile_pic_url': user.get('profile_pic_url', ''),
                    'is_private': user.get('is_private', False),
                    'is_verified': user.get('is_verified', False)
                })
        
        print(f"✅ RapidAPI: {len(following_users)} seguindo, {len(followers_users)} seguidores")
        
        # Adiciona os detalhes aos dados do perfil
        profile_info['following_details'] = following_details
        profile_info['followers_details'] = followers_details
        
        return following_users, followers_users, profile_info
            
    except Exception as e:
        print(f"❌ Erro na RapidAPI: {e}")
        return set(), set(), {}

def filter_real_ghosts(ghosts_details: list, profile_info: dict) -> dict:
    """
    Filtra os ghosts para identificar perfis reais vs famosos/verificados.
    Retorna apenas perfis que parecem ser pessoas reais.
    """
    if not ghosts_details:
        return {
            "real_ghosts": [],
            "famous_ghosts": [],
            "real_ghosts_count": 0,
            "famous_ghosts_count": 0
        }
    
    real_ghosts = []
    famous_ghosts = []
    
    for user in ghosts_details:
        # Critérios para identificar perfis famosos/verificados
        is_famous = False
        
        # 1. Perfil verificado
        if user.get('is_verified', False):
            is_famous = True
        
        # 2. Nomes que parecem ser marcas/empresas
        full_name = user.get('full_name', '').lower()
        username = user.get('username', '').lower()
        
        # Palavras-chave que indicam perfis comerciais/famosos
        famous_keywords = [
            'official', 'oficial', 'brand', 'marca', 'company', 'empresa',
            'store', 'loja', 'shop', 'compras', 'news', 'noticias',
            'tv', 'radio', 'media', 'press', 'imprensa', 'magazine',
            'channel', 'canal', 'show', 'programa', 'music', 'musica',
            'artist', 'artista', 'actor', 'atriz', 'celebrity', 'celebridade',
            'influencer', 'blogger', 'youtuber', 'tiktoker', 'streamer',
            'gaming', 'games', 'esports', 'sports', 'esporte', 'fitness',
            'gym', 'academia', 'nutrition', 'nutricao', 'beauty', 'beleza',
            'fashion', 'moda', 'lifestyle', 'vida', 'travel', 'viagem',
            'food', 'comida', 'restaurant', 'restaurante', 'hotel',
            'car', 'carro', 'auto', 'motor', 'tech', 'tecnologia',
            'app', 'software', 'digital', 'online', 'web', 'site'
        ]
        
        # Verifica se o nome ou username contém palavras-chave famosas
        for keyword in famous_keywords:
            if keyword in full_name or keyword in username:
                is_famous = True
                break
        
        # 3. Usernames que parecem ser comerciais (muitos números, caracteres especiais)
        if len(username) > 20 or username.count('_') > 2 or username.count('.') > 1:
            is_famous = True
        
        # 4. Nomes muito curtos ou muito longos (geralmente não são pessoas reais)
        if len(full_name) < 3 or len(full_name) > 50:
            is_famous = True
        
        # 5. Usernames que começam com números (geralmente não são pessoas reais)
        if username and username[0].isdigit():
            is_famous = True
        
        # 6. Usernames que são apenas números
        if username.isdigit():
            is_famous = True
        
        # 7. Nomes que parecem ser nomes de produtos/serviços
        product_indicators = ['pro', 'plus', 'premium', 'gold', 'silver', 'platinum', 'vip']
        for indicator in product_indicators:
            if indicator in username:
                is_famous = True
                break
        
        # Classifica o usuário
        if is_famous:
            famous_ghosts.append(user)
        else:
            real_ghosts.append(user)
    
    return {
        "real_ghosts": real_ghosts,
        "famous_ghosts": famous_ghosts,
        "real_ghosts_count": len(real_ghosts),
        "famous_ghosts_count": len(famous_ghosts)
    }

async def get_ghosts(username: str) -> dict:
    """
    Função principal que obtém dados do Instagram usando apenas RapidAPI.
    """
    print(f"🚀 Iniciando análise para: {username}")
    
    # Remove @ se presente
    clean_username = username.replace('@', '')
    
    # Obtém dados via RapidAPI
    following_users, followers_users, profile_info = await get_instagram_data_rapidapi(clean_username)
    
    # Se não conseguiu obter dados, retorna erro
    if not following_users and not followers_users:
        return {
            "error": "Não foi possível obter dados do Instagram. Verifique se o username está correto e tente novamente.",
            "username": clean_username,
            "following_count": 0,
            "followers_count": 0,
            "ghosts_count": 0,
            "ghosts": [],
            "ghosts_details": [],
            "real_ghosts": [],
            "famous_ghosts": [],
            "real_ghosts_count": 0,
            "famous_ghosts_count": 0,
            "following": [],
            "followers": [],
            "profile_info": {}
        }
    
    # Calcula ghosts (pessoas que não seguem de volta)
    ghosts = following_users - followers_users
    
    print(f"👻 Encontrados {len(ghosts)} ghosts")
    print(f"📊 Total: {len(following_users)} seguindo, {len(followers_users)} seguidores")
    
    # Obtém detalhes dos ghosts
    ghosts_details = []
    if 'following_details' in profile_info:
        for user in profile_info['following_details']:
            if user['username'] in ghosts:
                ghosts_details.append(user)
    
    # Filtra ghosts para identificar perfis reais vs famosos
    filtered_ghosts = filter_real_ghosts(ghosts_details, profile_info)
    
    print(f"🔍 Filtros aplicados:")
    print(f"   - Perfis reais: {filtered_ghosts['real_ghosts_count']}")
    print(f"   - Perfis famosos/verificados: {filtered_ghosts['famous_ghosts_count']}")
    
    return {
        "username": clean_username,
        "following_count": len(following_users),
        "followers_count": len(followers_users),
        "ghosts_count": len(ghosts),
        "ghosts": list(ghosts),  # Todos os ghosts
        "ghosts_details": ghosts_details,  # Detalhes completos dos ghosts
        "real_ghosts": filtered_ghosts["real_ghosts"],  # Apenas perfis reais
        "famous_ghosts": filtered_ghosts["famous_ghosts"],  # Perfis famosos/verificados
        "real_ghosts_count": filtered_ghosts["real_ghosts_count"],
        "famous_ghosts_count": filtered_ghosts["famous_ghosts_count"],
        "following": list(following_users),  # Todos os seguindo
        "followers": list(followers_users),  # Todos os seguidores
        "profile_info": profile_info
    }

async def get_ghosts_with_profile(username: str, profile_info: dict, user_id: str) -> dict:
    """
    Função que obtém dados do Instagram usando RapidAPI, mas com dados do perfil pré-obtidos.
    Evita duplicação de chamadas à API.
    """
    print(f"🚀 Iniciando análise para: {username} (com dados do perfil pré-obtidos)")
    
    # Remove @ se presente
    clean_username = username.replace('@', '')
    
    try:
        # Headers para a API
        headers = {
            'x-rapidapi-host': RAPIDAPI_HOST,
            'x-rapidapi-key': RAPIDAPI_KEY,
            'x-access-key': RAPIDAPI_KEY
        }
        
        # Usa o user_id já obtido (não chama a API novamente)
        if not user_id:
            print("❌ User ID não fornecido")
            return {
                "error": "User ID não fornecido.",
                "username": clean_username,
                "following_count": 0,
                "followers_count": 0,
                "ghosts_count": 0,
                "ghosts": [],
                "ghosts_details": [],
                "real_ghosts": [],
                "famous_ghosts": [],
                "real_ghosts_count": 0,
                "famous_ghosts_count": 0,
                "following": [],
                "followers": [],
                "profile_info": profile_info  # Mantém os dados do perfil já obtidos
            }
        
        print(f"✅ Usando user_id já obtido: {user_id}")
        
        # Obtém todos os dados com paginação (sem obter dados do perfil novamente)
        following_data, followers_data = await get_all_instagram_data_with_pagination(user_id, headers)
        
        # Extrai usernames e dados completos dos seguidores
        followers_users = set()
        followers_details = []
        for user in followers_data:
            if isinstance(user, dict) and 'username' in user:
                followers_users.add(user['username'])
                followers_details.append({
                    'username': user['username'],
                    'full_name': user.get('full_name', ''),
                    'profile_pic_url': user.get('profile_pic_url', ''),
                    'is_private': user.get('is_private', False),
                    'is_verified': user.get('is_verified', False)
                })
        
        # Extrai usernames e dados completos dos seguindo
        following_users = set()
        following_details = []
        for user in following_data:
            if isinstance(user, dict) and 'username' in user:
                following_users.add(user['username'])
                following_details.append({
                    'username': user['username'],
                    'full_name': user.get('full_name', ''),
                    'profile_pic_url': user.get('profile_pic_url', ''),
                    'is_private': user.get('is_private', False),
                    'is_verified': user.get('is_verified', False)
                })
        
        print(f"✅ RapidAPI: {len(following_users)} seguindo, {len(followers_users)} seguidores")
        
        # Adiciona os detalhes aos dados do perfil (sem sobrescrever dados já obtidos)
        profile_info['following_details'] = following_details
        profile_info['followers_details'] = followers_details
        
        # Calcula ghosts (pessoas que não seguem de volta)
        ghosts = following_users - followers_users
        
        print(f"👻 Encontrados {len(ghosts)} ghosts")
        print(f"📊 Total: {len(following_users)} seguindo, {len(followers_users)} seguidores")
        
        # Obtém detalhes dos ghosts
        ghosts_details = []
        for user in following_details:
            if user['username'] in ghosts:
                ghosts_details.append(user)
        
        # Filtra ghosts para identificar perfis reais vs famosos
        filtered_ghosts = filter_real_ghosts(ghosts_details, profile_info)
        
        print(f"🔍 Filtros aplicados:")
        print(f"   - Perfis reais: {filtered_ghosts['real_ghosts_count']}")
        print(f"   - Perfis famosos/verificados: {filtered_ghosts['famous_ghosts_count']}")
        
        return {
            "username": clean_username,
            "following_count": len(following_users),
            "followers_count": len(followers_users),
            "ghosts_count": len(ghosts),
            "ghosts": list(ghosts),  # Todos os ghosts
            "ghosts_details": ghosts_details,  # Detalhes completos dos ghosts
            "real_ghosts": filtered_ghosts["real_ghosts"],  # Apenas perfis reais
            "famous_ghosts": filtered_ghosts["famous_ghosts"],  # Perfis famosos/verificados
            "real_ghosts_count": filtered_ghosts["real_ghosts_count"],
            "famous_ghosts_count": filtered_ghosts["famous_ghosts_count"],
            "following": list(following_users),  # Todos os seguindo
            "followers": list(followers_users),  # Todos os seguidores
            "profile_info": profile_info  # Usa os dados do perfil pré-obtidos
        }
        
    except Exception as e:
        print(f"❌ Erro na análise: {e}")
        return {
            "error": f"Erro durante a análise: {str(e)}",
            "username": clean_username,
            "following_count": 0,
            "followers_count": 0,
            "ghosts_count": 0,
            "ghosts": [],
            "ghosts_details": [],
            "real_ghosts": [],
            "famous_ghosts": [],
            "real_ghosts_count": 0,
            "famous_ghosts_count": 0,
            "following": [],
            "followers": [],
            "profile_info": profile_info  # Mantém os dados do perfil mesmo com erro
        } 