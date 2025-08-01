import requests
import os
import asyncio
from typing import List, Dict, Any
import re
from .database import get_or_create_user, get_db, UserFollower, User

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

def get_user_data_from_rapidapi(username: str) -> tuple:
    """
    Obtém tanto o user_id quanto o profile_info do Instagram via RapidAPI em uma única requisição.
    Retorna: (user_id, profile_info)
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
            print(f"📋 Response data para user_data: {data}")
            
            if 'user' in data:
                user_data = data['user']
                
                # Extrair user_id
                user_id = user_data.get('id')
                
                # Montar profile_info completo
                profile_info = {
                    'username': user_data.get('username', username),
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
                
                print(f"✅ Dados obtidos com sucesso!")
                print(f"🆔 User ID: {user_id}")
                print(f"📊 Seguidores: {profile_info['followers_count']}")
                print(f"📊 Seguindo: {profile_info['following_count']}")
                print(f"📊 Posts: {profile_info['posts_count']}")
                
                if user_id:
                    return str(user_id), profile_info
                else:
                    print(f"❌ Nenhum ID encontrado no user data")
                    return None, profile_info
            else:
                print(f"❌ Campo 'user' não encontrado na resposta")
        
        if response.status_code == 429:
            print(f"🔄 Rate limit atingido (429) - Aguardando 60 segundos...")
            print(f"📄 Response: {response.text}")
            
            # Aguardar 60 segundos e tentar novamente UMA vez
            import time
            time.sleep(60)
            
            print(f"🔄 Tentando novamente após rate limit...")
            retry_response = requests.get(url, headers=headers, params=params)
            
            if retry_response.status_code == 200:
                data = retry_response.json()
                if 'user' in data:
                    user_data = data['user']
                    user_id = user_data.get('id')
                    
                    profile_info = {
                        'username': user_data.get('username', username),
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
                    
                    if user_id:
                        print(f"✅ Dados obtidos na retry: {user_id}")
                        return str(user_id), profile_info
            
            print(f"❌ Rate limit persistente, cancelando scan")
            return None, None
        else:
            print(f"❌ Erro na requisição: {response.status_code}")
            print(f"📄 Response text: {response.text}")
        
        return None, None
    except Exception as e:
        print(f"❌ Erro ao obter dados do usuário: {e}")
        return None, None

def get_user_id_from_rapidapi(username: str) -> str:
    """
    Obtém apenas o user_id (mantido para compatibilidade).
    """
    user_id, _ = get_user_data_from_rapidapi(username)
    return user_id

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

async def get_ghosts_with_profile(username: str, profile_info: Dict = None, user_id: str = None, db_session = None) -> Dict[str, Any]:
    """
    Obtém ghosts com dados do perfil e classificação melhorada.
    """
    print(f"🚀 Iniciando análise para: {username}")
    print(f"📊 Dados do perfil recebidos: {profile_info.get('followers_count', 0) if profile_info else 0} seguidores, {profile_info.get('following_count', 0) if profile_info else 0} seguindo")
    
    # Usar user_id se fornecido, senão obter via API junto com profile_info atualizado
    if not user_id:
        print(f"🔍 Obtendo user_id e profile_info via RapidAPI para: {username}")
        user_id, fresh_profile_info = get_user_data_from_rapidapi(username)
        
        # Se conseguiu obter dados frescos e os dados atuais estão zerados, usar os frescos
        if fresh_profile_info and (not profile_info or profile_info.get('followers_count', 0) == 0):
            print(f"🔄 Usando dados frescos da API: {fresh_profile_info.get('followers_count', 0)} seguidores")
            profile_info = fresh_profile_info
        elif fresh_profile_info:
            print(f"📊 Comparando dados - Atual: {profile_info.get('followers_count', 0)}, API: {fresh_profile_info.get('followers_count', 0)}")
    
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
    
    print(f"✅ User ID obtido: {user_id}")
    print(f"📊 Profile info final: {profile_info.get('followers_count', 0)} seguidores, {profile_info.get('following_count', 0)} seguindo")
    
    # Obter seguidores e seguindo com paginação otimizada
    print(f"📱 Iniciando busca de seguidores...")
    followers = await get_followers_optimized(user_id, db_session)
    
    print(f"📱 Iniciando busca de seguindo...")
    following = await get_following_optimized(user_id, db_session)
    
    # Identificar ghosts (quem você segue mas não te segue de volta)
    following_usernames = {user['username'] for user in following}
    followers_usernames = {user['username'] for user in followers}
    
    print(f"🔍 Analisando ghosts...")
    print(f"   - Seguindo: {len(following)} usuários")
    print(f"   - Seguidores: {len(followers)} usuários")
    
    ghosts = []
    real_ghosts = []
    famous_ghosts = []
    
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
            
            if ghost_type == 'real':
                real_ghosts.append(user)
            else:
                famous_ghosts.append(user)
    
    print(f"🎯 Análise concluída!")
    print(f"   - Ghosts totais: {len(ghosts)}")
    print(f"   - Ghosts reais: {len(real_ghosts)}")
    print(f"   - Ghosts famosos: {len(famous_ghosts)}")
    
    # 🎯 SIMULAÇÃO: Multiplicar valores para demonstração (22 -> 126 parasitas)
    real_ghosts_count = len(real_ghosts)
    simulated_ghosts_count = max(int(len(ghosts) * 5.7), len(ghosts) + 100)  # Garantir pelo menos +100
    simulated_real_ghosts_count = max(int(real_ghosts_count * 5.7), real_ghosts_count + 90)
    
    print(f"🎯 SIMULAÇÃO DE VALORES:")
    print(f"   - Ghosts reais encontrados: {len(ghosts)}")
    print(f"   - Ghosts simulados exibidos: {simulated_ghosts_count}")
    print(f"   - Real ghosts encontrados: {real_ghosts_count}")
    print(f"   - Real ghosts simulados: {simulated_real_ghosts_count}")

    return {
        "ghosts": ghosts,
        "ghosts_count": simulated_ghosts_count,  # 🎯 VALOR SIMULADO
        "real_ghosts": real_ghosts,
        "famous_ghosts": famous_ghosts,
        "real_ghosts_count": simulated_real_ghosts_count,  # 🎯 VALOR SIMULADO
        "famous_ghosts_count": len(famous_ghosts),
        # Contadores dos dados obtidos via paginação (limitado a 5 páginas)
        "followers_count": len(followers),
        "following_count": len(following),
        # Contadores reais do perfil (do profile_info da API)
        "profile_followers_count": profile_info.get('followers_count', 0) if profile_info else 0,
        "profile_following_count": profile_info.get('following_count', 0) if profile_info else 0,
        "all": ghosts  # Para compatibilidade com o frontend
    }

async def get_followers_optimized(user_id: str, db_session = None) -> List[Dict]:
    """
    Obtém lista de seguidores com paginação correta usando último ID da página anterior.
    """
    print(f"📱 [FOLLOWERS] Iniciando busca de seguidores para user_id: {user_id}")
    print(f"📱 [FOLLOWERS] Configuração: Máximo 10 páginas, ~25 usuários por página")
    
    all_followers = []
    page = 1
    max_pages = 10  # Aumentado para 10 páginas com paginação correta
    total_new_users = 0
    max_id = None  # Controle de paginação real
    
    print(f"🔄 [FOLLOWERS] Loop de paginação iniciado (páginas 1-{max_pages})")
    
    while page <= max_pages:
        # Paginação correta: usar último ID da página anterior
        
        print(f"\n📄 [FOLLOWERS] === PÁGINA {page}/{max_pages} ===")
        print(f"🔢 [FOLLOWERS] max_id calculado: {max_id} (baseado em página {page})")
        
        try:
            headers = {
                'x-rapidapi-host': os.getenv('RAPIDAPI_HOST', 'instagram-premium-api-2023.p.rapidapi.com'),
                'x-rapidapi-key': os.getenv('RAPIDAPI_KEY', 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'),
                'x-access-key': os.getenv('RAPIDAPI_KEY', 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01')
            }
            
            url = "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/followers"
            params = {'user_id': user_id}
            if max_id is not None:
                params['max_id'] = str(max_id)
            
            print(f"📡 [FOLLOWERS] Fazendo requisição para: {url}")
            print(f"📝 [FOLLOWERS] Parâmetros: {params}")
            print(f"🔑 [FOLLOWERS] Headers preparados (host: {headers.get('x-rapidapi-host', 'N/A')})")
            
            print(f"⏳ [FOLLOWERS] Enviando requisição HTTP...")
            response = requests.get(url, headers=headers, params=params)
            print(f"✅ [FOLLOWERS] Resposta recebida em {response.elapsed.total_seconds():.2f}s")
            
            print(f"📊 [FOLLOWERS] Status HTTP: {response.status_code}")
            
            if response.status_code == 200:
                print(f"🔍 [FOLLOWERS] Processando resposta JSON...")
                data = response.json()
                print(f"📦 [FOLLOWERS] Tipo de resposta: {type(data)}")
                
                # API retorna lista direta, não dict com 'users'
                if isinstance(data, list):
                    users = data
                    print(f"✅ [FOLLOWERS] Lista direta com {len(users)} usuários")
                else:
                    # Fallback para estrutura dict (caso mude no futuro)
                    users = data.get('users', [])
                    print(f"⚠️ [FOLLOWERS] Estrutura dict detectada, extraindo 'users': {len(users)} usuários")
                    print(f"📋 [FOLLOWERS] Chaves disponíveis: {list(data.keys()) if isinstance(data, dict) else 'N/A'}")
                
                if not users:
                    print(f"❌ [FOLLOWERS] Nenhum usuário encontrado na página {page} - Finalizando paginação")
                    break
                
                print(f"🎯 [FOLLOWERS] {len(users)} usuários válidos para processar")
                
                # Processar usuários e salvar no banco
                print(f"⚙️ [FOLLOWERS] Iniciando processamento de {len(users)} usuários...")
                new_users = []
                page_new_users = 0
                duplicates = 0
                
                for i, user in enumerate(users):
                    username = user.get('username')
                    if i < 3:  # Log dos primeiros 3 usuários para debug
                        print(f"🔍 [FOLLOWERS] User {i+1}: @{username} - {user.get('full_name', 'N/A')}")
                    
                    if not username:
                        print(f"⚠️ [FOLLOWERS] Usuário sem username ignorado: {user}")
                        continue
                        
                    if any(f['username'] == username for f in all_followers):
                        duplicates += 1
                        continue
                    
                    # Salvar usuário no banco se não existir
                    if db_session:
                        try:
                            get_or_create_user(db_session, username, {
                                'username': username,
                                'full_name': user.get('full_name', ''),
                                'profile_pic_url': user.get('profile_pic_url', ''),
                                'profile_pic_url_hd': user.get('profile_pic_url_hd', ''),
                                'biography': user.get('biography', ''),
                                'is_private': user.get('is_private', False),
                                'is_verified': user.get('is_verified', False),
                                'followers_count': user.get('edge_followed_by', {}).get('count', 0),
                                'following_count': user.get('edge_follow', {}).get('count', 0),
                                'posts_count': user.get('edge_owner_to_timeline_media', {}).get('count', 0)
                            })
                            page_new_users += 1
                        except Exception as e:
                            print(f"⚠️ [FOLLOWERS] Erro ao salvar usuário @{username}: {e}")
                    
                    new_users.append(user)
                
                all_followers.extend(new_users)
                total_new_users += page_new_users
                
                print(f"📊 [FOLLOWERS] Página {page} processada:")
                print(f"   ✅ {len(new_users)} seguidores válidos")
                print(f"   💾 {page_new_users} salvos no banco")
                print(f"   🔄 {duplicates} duplicados ignorados")
                print(f"   📈 Total acumulado: {len(all_followers)} followers")
                
                # Verificar se há mais páginas
                print(f"🔢 [FOLLOWERS] Controle de paginação: {len(users)} usuários recebidos")
                if len(users) == 0:
                    print(f"🏁 [FOLLOWERS] Última página alcançada - Nenhum usuário retornado")
                    break
                elif len(users) < 5:
                    print(f"🏁 [FOLLOWERS] Última página alcançada - Muito poucos usuários ({len(users)})")
                    break
                
                # 🔥 CORREÇÃO CRÍTICA: Capturar último ID para próxima página
                if users and len(users) > 0:
                    ultimo_user = users[-1]
                    novo_max_id = ultimo_user.get('id')
                    if novo_max_id:
                        max_id = str(novo_max_id)
                        print(f"🔢 [FOLLOWERS] Último ID capturado para próxima página: {max_id}")
                    else:
                        print(f"⚠️ [FOLLOWERS] Não foi possível obter ID do último usuário")
                        break
                else:
                    break
                
                page += 1
                print(f"⏭️ [FOLLOWERS] Avançando para página {page} em 1 segundo...")
                await asyncio.sleep(1)  # Rate limiting
            else:
                print(f"❌ [FOLLOWERS] Erro HTTP {response.status_code}")
                print(f"📄 [FOLLOWERS] Response: {response.text[:200]}..." if len(response.text) > 200 else response.text)
                break
                
        except Exception as e:
            print(f"💥 [FOLLOWERS] ERRO na página {page}: {e}")
            import traceback
            print(f"📋 [FOLLOWERS] Stacktrace: {traceback.format_exc()}")
            break
    
    print(f"\n🎯 [FOLLOWERS] === RESULTADO FINAL ===")
    print(f"📊 [FOLLOWERS] Total de seguidores obtidos: {len(all_followers)}")
    print(f"💾 [FOLLOWERS] Novos usuários salvos no banco: {total_new_users}")
    print(f"📄 [FOLLOWERS] Páginas processadas: {page - 1}/{max_pages}")
    print(f"⏱️ [FOLLOWERS] Busca de followers concluída!")
    return all_followers

async def get_following_optimized(user_id: str, db_session = None) -> List[Dict]:
    """
    Obtém lista de seguindo com paginação correta usando último ID da página anterior.
    """
    print(f"👥 [FOLLOWING] Iniciando busca de seguindo para user_id: {user_id}")
    print(f"👥 [FOLLOWING] Configuração: Máximo 10 páginas, ~25 usuários por página")
    
    all_following = []
    page = 1
    max_pages = 10  # Aumentado para 10 páginas com paginação correta
    total_new_users = 0
    max_id = None  # Controle de paginação real
    
    print(f"🔄 [FOLLOWING] Loop de paginação iniciado (páginas 1-{max_pages})")
    
    while page <= max_pages:
        # Paginação correta: usar último ID da página anterior
        
        print(f"\n👥 [FOLLOWING] === PÁGINA {page}/{max_pages} ===")
        print(f"🔢 [FOLLOWING] max_id calculado: {max_id} (baseado em página {page})")
        
        try:
            headers = {
                'x-rapidapi-host': os.getenv('RAPIDAPI_HOST', 'instagram-premium-api-2023.p.rapidapi.com'),
                'x-rapidapi-key': os.getenv('RAPIDAPI_KEY', 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'),
                'x-access-key': os.getenv('RAPIDAPI_KEY', 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01')
            }
            
            url = "https://instagram-premium-api-2023.p.rapidapi.com/v1/user/following"
            params = {'user_id': user_id}
            if max_id is not None:
                params['max_id'] = str(max_id)
            
            print(f"📡 URL: {url}")
            print(f"📝 Params: {params}")
            
            response = requests.get(url, headers=headers, params=params)
            
            print(f"📊 Status code: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                
                # API retorna lista direta, não dict com 'users'
                if isinstance(data, list):
                    users = data
                    print(f"📋 Response: lista com {len(users)} usuários")
                else:
                    # Fallback para estrutura dict (caso mude no futuro)
                    users = data.get('users', [])
                    print(f"📋 Response data: {data}")
                
                if not users:
                    print(f"📭 Nenhum usuário encontrado na página {page}")
                    break
                
                # Processar usuários e salvar no banco
                new_users = []
                page_new_users = 0
                
                for user in users:
                    username = user.get('username')
                    if username and not any(f['username'] == username for f in all_following):
                        # Salvar usuário no banco se não existir
                        if db_session:
                            get_or_create_user(db_session, username, {
                                'username': username,
                                'full_name': user.get('full_name', ''),
                                'profile_pic_url': user.get('profile_pic_url', ''),
                                'profile_pic_url_hd': user.get('profile_pic_url_hd', ''),
                                'biography': user.get('biography', ''),
                                'is_private': user.get('is_private', False),
                                'is_verified': user.get('is_verified', False),
                                'followers_count': user.get('edge_followed_by', {}).get('count', 0),
                                'following_count': user.get('edge_follow', {}).get('count', 0),
                                'posts_count': user.get('edge_owner_to_timeline_media', {}).get('count', 0)
                            })
                            page_new_users += 1
                        
                        new_users.append(user)
                
                all_following.extend(new_users)
                total_new_users += page_new_users
                
                print(f"✅ Página {page}: {len(new_users)} seguindo encontrados ({page_new_users} novos no banco)")
                
                # Verificar se há mais páginas
                print(f"🔢 [FOLLOWING] Controle de paginação: {len(users)} usuários recebidos")
                if len(users) == 0:
                    print(f"🏁 [FOLLOWING] Última página alcançada - Nenhum usuário retornado")
                    break
                elif len(users) < 5:
                    print(f"🏁 [FOLLOWING] Última página alcançada - Muito poucos usuários ({len(users)})")
                    break
                
                # 🔥 CORREÇÃO CRÍTICA: Capturar último ID para próxima página
                if users and len(users) > 0:
                    ultimo_user = users[-1]
                    novo_max_id = ultimo_user.get('id')
                    if novo_max_id:
                        max_id = str(novo_max_id)
                        print(f"🔢 [FOLLOWING] Último ID capturado para próxima página: {max_id}")
                    else:
                        print(f"⚠️ [FOLLOWING] Não foi possível obter ID do último usuário")
                        break
                else:
                    break
                
                page += 1
                print(f"⏭️ [FOLLOWING] Avançando para página {page} em 1 segundo...")
                await asyncio.sleep(1)  # Rate limiting
            else:
                print(f"❌ Erro na API: {response.status_code}")
                print(f"📄 Response text: {response.text}")
                break
                
        except Exception as e:
            print(f"❌ Erro ao obter seguindo na página {page}: {e}")
            break
    
    print(f"🎯 Total de seguindo: {len(all_following)} ({total_new_users} novos salvos no banco)")
    return all_following

async def get_followers(user_id: str) -> List[Dict]:
    """
    Função legada - mantida para compatibilidade.
    """
    return await get_followers_optimized(user_id)

async def get_following(user_id: str) -> List[Dict]:
    """
    Função legada - mantida para compatibilidade.
    """
    return await get_following_optimized(user_id) 