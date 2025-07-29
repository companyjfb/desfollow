import requests
import os
import asyncio
from typing import List, Dict, Any
import re

# Palavras-chave expandidas para detectar perfis famosos/influencers
FAMOUS_KEYWORDS = [
    # Categorias de conteúdo
    "video", "videos", "vídeo", "vídeos",
    "automation", "automação", "automated",
    "risada", "laugh", "funny", "humor",
    "oficial", "official", "original",
    
    # Redes sociais e plataformas
    "tiktok", "youtube", "youtu.be", "yt",
    "instagram", "insta", "ig",
    "twitter", "tweet", "x.com",
    "facebook", "fb", "meta",
    "linkedin", "snapchat", "twitch",
    
    # Tipos de conteúdo
    "content", "conteúdo", "creator", "criador",
    "influencer", "influenciador", "blogger",
    "vlogger", "streamer", "gamer",
    "podcast", "live", "ao vivo",
    
    # Profissões e nichos
    "marketing", "digital", "business",
    "entrepreneur", "empreendedor", "startup",
    "fitness", "health", "saúde", "workout",
    "fashion", "moda", "style", "estilo",
    "beauty", "beleza", "makeup", "maquiagem",
    "cooking", "chef", "food", "comida",
    "travel", "viagem", "turismo",
    "music", "música", "singer", "cantor",
    "artist", "artista", "design", "designer",
    "photography", "fotografia", "photographer",
    "model", "modelo", "actor", "ator",
    
    # Marcas e empresas
    "brand", "marca", "company", "empresa",
    "store", "loja", "shop", "compras",
    "agency", "agência", "consulting",
    
    # Indicadores de fama
    "verified", "verificado", "blue tick",
    "celebrity", "celebridade", "famous",
    "viral", "trending", "tendência",
    "award", "prêmio", "winner", "vencedor",
    
    # Outros indicadores
    "official", "oficial", "original",
    "premium", "vip", "exclusive",
    "pro", "professional", "profissional",
    "expert", "especialista", "specialist"
]

def get_user_id_from_rapidapi(username: str) -> str:
    """
    Obtém o user_id do Instagram via RapidAPI.
    """
    try:
        headers = {
            'x-rapidapi-host': os.getenv('RAPIDAPI_HOST', 'instagram-premium-api-2023.p.rapidapi.com'),
            'x-rapidapi-key': os.getenv('RAPIDAPI_KEY', 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'),
            'x-access-key': os.getenv('RAPIDAPI_KEY', 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01')
        }
        
        url = "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/web_profile_info"
        params = {'username': username}
        
        response = requests.get(url, headers=headers, params=params)
        
        if response.status_code == 200:
            data = response.json()
            if 'user' in data and 'pk' in data['user']:
                return str(data['user']['pk'])
        
        return None
    except Exception as e:
        print(f"❌ Erro ao obter user_id: {e}")
        return None

def is_famous_profile(username: str, full_name: str = "", biography: str = "") -> bool:
    """
    Verifica se um perfil é famoso/influencer baseado em palavras-chave.
    """
    # Normalizar texto para busca
    search_text = f"{username} {full_name} {biography}".lower()
    
    # Verificar cada palavra-chave
    for keyword in FAMOUS_KEYWORDS:
        if keyword.lower() in search_text:
            return True
    
    # Verificar padrões específicos
    patterns = [
        r'@[a-zA-Z0-9_]+',  # Menciona outros usuários
        r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+',  # Links
        r'\d+[kKmM]',  # Números seguidos de k/m (seguidores)
        r'#\w+',  # Hashtags
    ]
    
    for pattern in patterns:
        if re.search(pattern, search_text):
            return True
    
    return False

def classify_ghost(username: str, full_name: str = "", biography: str = "") -> str:
    """
    Classifica um ghost como 'real' ou 'famous'.
    """
    if is_famous_profile(username, full_name, biography):
        return "famous"
    else:
        return "real"

async def get_ghosts_with_profile(username: str, profile_info: Dict = None, user_id: str = None) -> Dict[str, Any]:
    """
    Obtém ghosts com dados do perfil e classificação melhorada.
    """
    print(f"🚀 Iniciando análise para: {username} (com dados do perfil pré-obtidos)")
    
    # Usar user_id se fornecido, senão obter via API
    if not user_id:
        print(f"🔍 Obtendo user_id via RapidAPI para: {username}")
        user_id = get_user_id_from_rapidapi(username)
    
    if not user_id:
        return {
            "ghosts": [],
            "ghosts_count": 0,
            "real_ghosts": [],
            "famous_ghosts": [],
            "real_ghosts_count": 0,
            "famous_ghosts_count": 0,
            "error": "Não foi possível obter user_id"
        }
    
    print(f"✅ Usando user_id já obtido: {user_id}")
    
    # Obter seguidores e seguindo
    followers = await get_followers(user_id)
    following = await get_following(user_id)
    
    # Identificar ghosts (quem você segue mas não te segue de volta)
    following_usernames = {user['username'] for user in following}
    followers_usernames = {user['username'] for user in followers}
    
    ghosts = []
    for user in following:
        if user['username'] not in followers_usernames:
            # Classificar o ghost
            ghost_type = classify_ghost(
                user['username'], 
                user.get('full_name', ''), 
                user.get('biography', '')
            )
            
            user['ghost_type'] = ghost_type
            ghosts.append(user)
    
    # Separar ghosts por tipo
    real_ghosts = [g for g in ghosts if g['ghost_type'] == 'real']
    famous_ghosts = [g for g in ghosts if g['ghost_type'] == 'famous']
    
    return {
        "ghosts": ghosts,
        "ghosts_count": len(ghosts),
        "real_ghosts": real_ghosts,
        "famous_ghosts": famous_ghosts,
        "real_ghosts_count": len(real_ghosts),
        "famous_ghosts_count": len(famous_ghosts),
        "followers_count": len(followers),
        "following_count": len(following)
    }

async def get_followers(user_id: str) -> List[Dict]:
    """
    Obtém lista de seguidores com dados completos.
    """
    print(f"🔄 Obtendo TODOS os seguidores para user_id: {user_id}...")
    
    followers = []
    max_id = None
    page = 1
    
    while True:
        print(f"📄 Paginação de seguidores com /chunk...")
        
        try:
            headers = {
                'x-rapidapi-host': os.getenv('RAPIDAPI_HOST', 'instagram-premium-api-2023.p.rapidapi.com'),
                'x-rapidapi-key': os.getenv('RAPIDAPI_KEY', 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'),
                'x-access-key': os.getenv('RAPIDAPI_KEY', 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01')
            }
            
            url = "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/followers"
            params = {
                'user_id': user_id,
                'max_id': max_id
            }
            
            response = requests.get(url, headers=headers, params=params)
            
            if response.status_code == 200:
                data = response.json()
                users = data.get('users', [])
                
                if not users:
                    break
                
                # Adicionar apenas usuários novos
                new_users = []
                for user in users:
                    if not any(f['username'] == user['username'] for f in followers):
                        new_users.append(user)
                
                followers.extend(new_users)
                print(f"✅ Página {page} (max_id={max_id}): {len(new_users)} seguidores NOVOS encontrados")
                
                # Verificar se há mais páginas
                if 'next_max_id' in data and data['next_max_id']:
                    max_id = data['next_max_id']
                    page += 1
                    await asyncio.sleep(1)  # Rate limiting
                else:
                    break
            else:
                print(f"❌ Erro na API: {response.status_code}")
                break
                
        except Exception as e:
            print(f"❌ Erro ao obter seguidores: {e}")
            break
    
    print(f"🎯 Seguidores únicos encontrados: {len(followers)}")
    return followers

async def get_following(user_id: str) -> List[Dict]:
    """
    Obtém lista de seguindo com dados completos.
    """
    print(f"🔄 Obtendo TODOS os seguindo para user_id: {user_id}...")
    
    following = []
    max_id = None
    page = 1
    
    while True:
        print(f"📄 Paginação de seguindo com /chunk...")
        
        try:
            headers = {
                'x-rapidapi-host': os.getenv('RAPIDAPI_HOST', 'instagram-premium-api-2023.p.rapidapi.com'),
                'x-rapidapi-key': os.getenv('RAPIDAPI_KEY', 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'),
                'x-access-key': os.getenv('RAPIDAPI_KEY', 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01')
            }
            
            url = "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/following"
            params = {
                'user_id': user_id,
                'max_id': max_id
            }
            
            response = requests.get(url, headers=headers, params=params)
            
            if response.status_code == 200:
                data = response.json()
                users = data.get('users', [])
                
                if not users:
                    break
                
                # Adicionar apenas usuários novos
                new_users = []
                for user in users:
                    if not any(f['username'] == user['username'] for f in following):
                        new_users.append(user)
                
                following.extend(new_users)
                print(f"✅ Página {page} (max_id={max_id}): {len(new_users)} seguindo NOVOS encontrados")
                
                # Verificar se há mais páginas
                if 'next_max_id' in data and data['next_max_id']:
                    max_id = data['next_max_id']
                    page += 1
                    await asyncio.sleep(1)  # Rate limiting
                else:
                    break
            else:
                print(f"❌ Erro na API: {response.status_code}")
                break
                
        except Exception as e:
            print(f"❌ Erro ao obter seguindo: {e}")
            break
    
    print(f"🎯 Seguindo únicos encontrados: {len(following)}")
    return following 