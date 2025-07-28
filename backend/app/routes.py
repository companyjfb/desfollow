from fastapi import APIRouter, BackgroundTasks, HTTPException, Depends
from pydantic import BaseModel
from uuid import uuid4
from typing import Dict, Any
from .ig import get_ghosts, get_user_id_from_rapidapi, get_ghosts_with_profile
from .database import get_db, User, Scan
from .auth import get_current_active_user, get_current_premium_user
import requests
import time
import asyncio
from fastapi.responses import StreamingResponse
import io
import json
import os
from datetime import datetime

router = APIRouter()
MEM = {}  # cache em memória (trocar por Redis depois)


class ScanRequest(BaseModel):
    username: str


class ScanResponse(BaseModel):
    job_id: str


class StatusResponse(BaseModel):
    status: str
    count: int = None
    sample: list[str] = None
    all: list[str] = None
    ghosts_details: list[dict] = None
    real_ghosts: list[dict] = None
    famous_ghosts: list[dict] = None
    real_ghosts_count: int = None
    famous_ghosts_count: int = None
    profile_info: dict = None
    error: str = None


@router.post("/scan", response_model=ScanResponse)
async def scan(payload: ScanRequest, bg: BackgroundTasks):
    """
    Inicia um scan para encontrar usuários que não retribuem o follow.
    """
    username = payload.username.strip()
    
    print(f"🔍 Scan solicitado para: {username}")
    
    if not username:
        raise HTTPException(status_code=400, detail="Username é obrigatório")
    
    # Remove @ se presente
    username = username.lstrip("@")
    print(f"🧹 Username limpo: {username}")
    
    job_id = str(uuid4())
    MEM[job_id] = {"status": "queued"}
    
    print(f"📋 Job criado: {job_id}")
    
    # Adiciona tarefa em background
    bg.add_task(run_scan_separated, job_id, username)
    
    return ScanResponse(job_id=job_id)


async def run_scan(job_id: str, username: str):
    """
    Executa o scan em background.
    """
    try:
        print(f"🚀 Iniciando scan para job {job_id}: {username}")
        MEM[job_id] = {"status": "running"}
        
        # ETAPA 1: Obtém dados do perfil PRIMEIRO e salva IMEDIATAMENTE
        print(f"📱 ETAPA 1: Obtendo dados do perfil para: {username}")
        
        # Obtém o user_id e dados básicos do perfil
        print(f"🔍 Chamando get_user_id_from_rapidapi...")
        user_id = await get_user_id_from_rapidapi(username)
        print(f"🔑 User ID obtido: {user_id}")
        profile_info = None
        
        if user_id:
            # Obtém informações do perfil com retry para erros 429
            headers = {
                'x-rapidapi-host': os.getenv('RAPIDAPI_HOST', 'instagram-premium-api-2023.p.rapidapi.com'),
                'x-rapidapi-key': os.getenv('RAPIDAPI_KEY', 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'),
                'x-access-key': os.getenv('RAPIDAPI_KEY', 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01')
            }
            
            profile_url = f"https://instagram-premium-api-2023.p.rapidapi.com/v1/user/web_profile_info"
            profile_params = {'username': username}
            
            # Retry automático para erros 429
            max_retries = 3
            retry_delay = 5  # segundos
            
            for attempt in range(max_retries):
                try:
                    profile_response = requests.get(profile_url, headers=headers, params=profile_params)
                    
                    if profile_response.status_code == 200:
                        profile_data = profile_response.json()
                        if 'user' in profile_data:
                            user_data = profile_data['user']
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
                            
                            # SALVA OS DADOS DO PERFIL IMEDIATAMENTE - ETAPA 1 CONCLUÍDA
                            print(f"🚨 ETAPA 1 CONCLUÍDA: Salvando dados do perfil IMEDIATAMENTE!")
                            print(f"📊 Seguidores obtidos: {profile_info.get('followers_count', 0)}")
                            
                            MEM[job_id] = {
                                "status": "running",
                                "profile_info": profile_info
                            }
                            
                            print(f"✅ Dados do perfil SALVOS no cache!")
                            print(f"🎯 Frontend pode detectar dados AGORA!")
                            
                            # Pequeno delay para garantir que o frontend detecte os dados
                            await asyncio.sleep(0.1)
                            
                            break  # Sucesso, sai do loop
                            
                    elif profile_response.status_code == 429:
                        print(f"⚠️ Rate limit (429) na tentativa {attempt + 1}/{max_retries}. Aguardando {retry_delay}s...")
                        if attempt < max_retries - 1:  # Não aguarda na última tentativa
                            time.sleep(retry_delay)
                            retry_delay *= 2  # Backoff exponencial
                        else:
                            print(f"❌ Rate limit persistente após {max_retries} tentativas")
                    else:
                        print(f"❌ Erro ao obter perfil: {profile_response.status_code}")
                        print(f"Response: {profile_response.text}")
                        break
                        
                except Exception as e:
                    print(f"❌ Erro na tentativa {attempt + 1}: {e}")
                    if attempt < max_retries - 1:
                        time.sleep(retry_delay)
                    else:
                        print(f"❌ Erro persistente após {max_retries} tentativas")
        
        # ETAPA 2: Coleta os "fantasmas" (quem não retribui)
        print(f"📱 ETAPA 2: Coletando dados do Instagram para: {username}")
        
        # Passa os dados do perfil já obtidos para evitar duplicação
        if profile_info:
            print(f"📊 Usando dados do perfil já obtidos: {profile_info.get('followers_count', 0)} seguidores")
            print(f"🔍 Profile info completo: {profile_info}")
            print(f"🔑 User ID: {user_id}")
            # Modifica a função get_ghosts para aceitar dados do perfil pré-obtidos
            print(f"🚀 Chamando get_ghosts_with_profile...")
            ghosts = await get_ghosts_with_profile(username, profile_info, user_id)
            print(f"📊 Resultado de get_ghosts_with_profile: {ghosts}")
        else:
            print(f"⚠️ Nenhum dado do perfil obtido, usando função padrão")
            ghosts = await get_ghosts(username)
        
        print(f"✅ Scan concluído! Encontrados {len(ghosts)} usuários")
        print(f"📊 Dados retornados: {ghosts.keys()}")
        print(f"📸 Profile info no resultado: {ghosts.get('profile_info', {})}")
        
        # Atualiza com todos os dados finais
        current_data = MEM[job_id]
        print(f"📊 Dados atuais no cache: {current_data}")
        
        # Verifica se há dados do perfil no resultado
        if 'profile_info' in ghosts and ghosts['profile_info']:
            print(f"✅ Dados do perfil encontrados no resultado: {ghosts['profile_info'].get('followers_count', 0)} seguidores")
        else:
            print(f"⚠️ Dados do perfil não encontrados no resultado")
            # Mantém os dados do perfil já salvos
            if 'profile_info' in current_data and current_data['profile_info']:
                print(f"📊 Mantendo dados do perfil já salvos: {current_data['profile_info'].get('followers_count', 0)} seguidores")
                ghosts['profile_info'] = current_data['profile_info']
        
        current_data.update({
            "status": "done",
            "count": ghosts["ghosts_count"],
            "sample": ghosts["ghosts"][:5],  # Máximo 5 grátis
            "all": ghosts["ghosts"],
            "ghosts_details": ghosts["ghosts_details"],
            "real_ghosts": ghosts["real_ghosts"],
            "famous_ghosts": ghosts["famous_ghosts"],
            "real_ghosts_count": ghosts["real_ghosts_count"],
            "famous_ghosts_count": ghosts["famous_ghosts_count"],
            "profile_info": ghosts["profile_info"]  # Usa os dados do perfil (mantidos ou do resultado)
        })
        
        print(f"📊 Dados finais no cache: {current_data}")
        MEM[job_id] = current_data
        
    except Exception as e:
        print(f"❌ Erro no scan {job_id}: {e}")
        # Mantém os dados do perfil mesmo se houver erro no scan completo
        current_data = MEM.get(job_id, {})
        current_data.update({
            "status": "error",
            "error": str(e)
        })
        MEM[job_id] = current_data


async def run_scan_separated(job_id: str, username: str):
    """
    Executa o scan em duas etapas separadas para permitir detecção imediata dos dados do perfil.
    """
    try:
        print(f"🚀 Iniciando scan separado para job {job_id}: {username}")
        MEM[job_id] = {"status": "running"}
        
        # ETAPA 1: Obtém dados do perfil e salva IMEDIATAMENTE
        print(f"📱 ETAPA 1: Obtendo dados do perfil...")
        
        user_id = await get_user_id_from_rapidapi(username)
        if not user_id:
            raise Exception("Não foi possível obter o user_id")
        
        # Obtém dados do perfil
        headers = {
            'x-rapidapi-host': 'instagram-premium-api-2023.p.rapidapi.com',
            'x-rapidapi-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01',
            'x-access-key': 'dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'
        }
        
        profile_url = f"https://instagram-premium-api-2023.p.rapidapi.com/v1/user/web_profile_info"
        profile_params = {'username': username}
        
        profile_response = requests.get(profile_url, headers=headers, params=profile_params)
        if profile_response.status_code != 200:
            raise Exception(f"Erro ao obter perfil: {profile_response.status_code}")
        
        profile_data = profile_response.json()
        if 'user' not in profile_data:
            raise Exception("Dados do usuário não encontrados")
        
        user_data = profile_data['user']
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
        
        # SALVA OS DADOS DO PERFIL IMEDIATAMENTE - ETAPA 1 CONCLUÍDA
        print(f"🚨 ETAPA 1 CONCLUÍDA: Salvando dados do perfil IMEDIATAMENTE!")
        print(f"📊 Seguidores obtidos: {profile_info.get('followers_count', 0)}")
        
        MEM[job_id] = {
            "status": "running",
            "profile_info": profile_info
        }
        
        print(f"✅ Dados do perfil SALVOS no cache!")
        print(f"🎯 Frontend pode detectar dados AGORA!")
        
        # Pequeno delay para garantir que o frontend detecte os dados
        await asyncio.sleep(0.1)
        
        # ETAPA 2: Obtém ghosts (pode demorar)
        print(f"📱 ETAPA 2: Obtendo ghosts...")
        ghosts = await get_ghosts_with_profile(username, profile_info, user_id)
        
        # Atualiza com dados finais
        current_data = MEM[job_id]
        current_data.update({
            "status": "done",
            "count": ghosts["ghosts_count"],
            "sample": ghosts["ghosts"][:5],
            "all": ghosts["ghosts"],
            "ghosts_details": ghosts["ghosts_details"],
            "real_ghosts": ghosts["real_ghosts"],
            "famous_ghosts": ghosts["famous_ghosts"],
            "real_ghosts_count": ghosts["real_ghosts_count"],
            "famous_ghosts_count": ghosts["famous_ghosts_count"],
            "profile_info": profile_info  # Mantém os dados do perfil já salvos
        })
        
        MEM[job_id] = current_data
        print(f"✅ Scan separado concluído!")
        
    except Exception as e:
        print(f"❌ Erro no scan separado {job_id}: {e}")
        current_data = MEM.get(job_id, {})
        current_data.update({
            "status": "error",
            "error": str(e)
        })
        MEM[job_id] = current_data


@router.get("/scan/{job_id}", response_model=StatusResponse)
def status(job_id: str):
    """
    Verifica o status de um scan em andamento.
    """
    if job_id not in MEM:
        raise HTTPException(status_code=404, detail="Job não encontrado")
    
    job_data = MEM[job_id]
    
    if job_data["status"] == "error":
        return StatusResponse(
            status="error",
            error=job_data.get("error", "Erro desconhecido")
        )
    
    if job_data["status"] == "done":
        return StatusResponse(
            status="done",
            count=job_data["count"],
            sample=job_data["all"][:10],  # Mostra 10 como exemplo
            all=job_data["all"],
            ghosts_details=job_data["ghosts_details"],
            real_ghosts=job_data["real_ghosts"],
            famous_ghosts=job_data["famous_ghosts"],
            real_ghosts_count=job_data["real_ghosts_count"],
            famous_ghosts_count=job_data["famous_ghosts_count"],
            profile_info=job_data["profile_info"]  # Sempre retorna os dados do perfil
        )
    
    # Retorna status com dados do perfil se disponíveis
    return StatusResponse(
        status=job_data["status"],
        profile_info=job_data.get("profile_info"),
        count=job_data.get("count", 0),  # Retorna count mesmo durante running
        real_ghosts_count=job_data.get("real_ghosts_count", 0),
        famous_ghosts_count=job_data.get("famous_ghosts_count", 0)
    )


@router.get("/health")
def health_check():
    """
    Endpoint de health check.
    """
    return {"status": "healthy", "jobs_active": len([j for j in MEM.values() if j["status"] == "running"])}


@router.get("/proxy-image")
async def proxy_image(url: str):
    """
    Endpoint para fazer proxy de uma imagem do Instagram.
    """
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        def generate():
            for chunk in response.iter_content(chunk_size=8192):
                yield chunk
        
        return StreamingResponse(generate(), media_type="image/jpeg")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao fazer proxy da imagem: {e}") 