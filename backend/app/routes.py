import json
import os
from uuid import uuid4
from datetime import datetime, timedelta
from fastapi import APIRouter, HTTPException, BackgroundTasks, Depends
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from .ig import get_ghosts_with_profile, get_user_id_from_rapidapi, get_user_data_from_rapidapi
from .database import get_db, get_or_create_user, save_scan_result, get_user_scan_history, get_cached_user_data, Scan
from sqlalchemy.orm import Session
import asyncio
import requests
import os
import time
from fastapi.responses import StreamingResponse
import traceback

router = APIRouter()

# Cache compartilhado via arquivo JSON
CACHE_FILE = "/tmp/desfollow_jobs.json"

def load_jobs():
    """Carrega jobs do arquivo JSON"""
    try:
        if os.path.exists(CACHE_FILE):
            with open(CACHE_FILE, 'r') as f:
                return json.load(f)
    except Exception as e:
        print(f"❌ Erro ao carregar jobs: {e}")
    return {}

def save_jobs(jobs):
    """Salva jobs no arquivo JSON"""
    try:
        with open(CACHE_FILE, 'w') as f:
            json.dump(jobs, f)
    except Exception as e:
        print(f"❌ Erro ao salvar jobs: {e}")

def get_job(job_id):
    """Obtém um job específico"""
    jobs = load_jobs()
    return jobs.get(job_id)

def set_job(job_id, data):
    """Define um job específico"""
    jobs = load_jobs()
    jobs[job_id] = data
    save_jobs(jobs)

class ScanRequest(BaseModel):
    username: str

class ScanResponse(BaseModel):
    job_id: str

class StatusResponse(BaseModel):
    status: str
    count: Optional[int] = None
    sample: Optional[List[Dict[str, Any]]] = None
    all: Optional[List[Dict[str, Any]]] = None
    ghosts_details: Optional[List[Dict[str, Any]]] = None
    real_ghosts: Optional[List[Dict[str, Any]]] = None
    famous_ghosts: Optional[List[Dict[str, Any]]] = None
    real_ghosts_count: Optional[int] = None
    famous_ghosts_count: Optional[int] = None
    followers_count: Optional[int] = None  # Quantos seguidores analisamos
    following_count: Optional[int] = None  # Quantos seguindo analisamos
    profile_followers_count: Optional[int] = None  # Total de seguidores do perfil
    profile_following_count: Optional[int] = None  # Total de seguindo do perfil
    profile_info: Optional[Dict[str, Any]] = None
    error: Optional[str] = None

@router.post("/scan", response_model=ScanResponse)
async def scan(payload: ScanRequest, bg: BackgroundTasks, db: Session = Depends(get_db)):
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
    
    # Verificar se existe scan recente no banco (últimas 24h) - APENAS PARA LOG
    from datetime import datetime, timedelta
    recent_scans = db.query(Scan).filter(
        Scan.username == username,
        Scan.status == "done",
        Scan.updated_at >= datetime.utcnow() - timedelta(hours=24)
    ).order_by(Scan.updated_at.desc()).limit(1).all()
    
    if recent_scans:
        recent_scan = recent_scans[0]
        print(f"📋 Scan recente encontrado no banco: {recent_scan.job_id}")
        print(f"📊 Dados disponíveis para reutilização: {recent_scan.ghosts_count} ghosts")
    else:
        print(f"📋 Nenhum scan recente encontrado, será feito novo scan")
    
    # SEMPRE criar novo job_id para cada scan
    print(f"🆕 Criando novo job_id para scan atual")
    
    job_id = str(uuid4())
    set_job(job_id, {"status": "queued"})
    
    print(f"📋 Job criado: {job_id}")
    
    # Adiciona tarefa em background
    bg.add_task(run_scan_with_database, job_id, username, db)
    
    return ScanResponse(job_id=job_id)

async def run_scan_with_database(job_id: str, username: str, db: Session):
    """
    Executa scan com integração ao banco de dados - versão otimizada e corrigida.
    """
    try:
        print(f"🚀 Iniciando scan com banco para job {job_id}: {username}")
        
        # Verificar se há scan recente VÁLIDO para reutilizar
        should_reuse_data = False
        user_id = None  # Inicializar user_id
        
        recent_scan = db.query(Scan).filter(
            Scan.username == username,
            Scan.status == "done"
        ).order_by(Scan.created_at.desc()).first()
        
        if recent_scan:
            # Verificar se os dados são VÁLIDOS (não zerados)
            profile_followers = recent_scan.profile_info.get('followers_count', 0) if recent_scan.profile_info else 0
            ghosts_count = recent_scan.ghosts_count or 0
            
            # Só reutilizar se há dados válidos (não zerados)
            if profile_followers > 0 and ghosts_count > 0:
                print(f"✅ Dados recentes VÁLIDOS encontrados: {profile_followers} seguidores, {ghosts_count} ghosts")
                profile_info = recent_scan.profile_info
                
                # Recriar resultado do scan
                ghosts_result = {
                    "ghosts": recent_scan.ghosts_data or [],
                    "ghosts_count": recent_scan.ghosts_count or 0,
                    "real_ghosts": recent_scan.real_ghosts or [],
                    "famous_ghosts": recent_scan.famous_ghosts or [],
                    "real_ghosts_count": recent_scan.real_ghosts_count or 0,
                    "famous_ghosts_count": recent_scan.famous_ghosts_count or 0,
                    "followers_count": len(recent_scan.ghosts_data or []),
                    "following_count": len(recent_scan.ghosts_data or []),
                    "profile_followers_count": profile_followers,
                    "profile_following_count": recent_scan.profile_info.get('following_count', 0) if recent_scan.profile_info else 0,
                    "all": recent_scan.ghosts_data or []
                }
                
                print(f"📊 Estatísticas dos dados reutilizados:")
                print(f"   - Seguidores perfil: {profile_followers}")
                print(f"   - Ghosts totais: {ghosts_result.get('ghosts_count', 0)}")
                
                # Salvar resultado reutilizado
                save_scan_result(db, job_id, username, "done", profile_info, ghosts_result)
                should_reuse_data = True
            else:
                print(f"⚠️ Dados recentes INVÁLIDOS encontrados (zerados)")
                print(f"📊 Seguidores perfil: {profile_followers}, Ghosts: {ghosts_count}")
                print(f"🔄 Forçando scan novo para obter dados válidos...")
        
        # Se não deve reutilizar dados, fazer scan novo
        if not should_reuse_data:
            print(f"📱 Obtendo dados frescos do Instagram...")
            # Inicializar profile_info
            profile_info = None
            
            # Verificar cache do usuário - MAS VERIFICAR SE É VÁLIDO
            cached_data = get_cached_user_data(db, username)
            if cached_data and cached_data.get('profile_info'):
                cached_profile = cached_data['profile_info']
                cached_followers = cached_profile.get('followers_count', 0) if cached_profile else 0
                
                if cached_followers > 0:
                    print(f"📋 Dados VÁLIDOS em cache encontrados para: {username} ({cached_followers} seguidores)")
                    profile_info = cached_profile
                else:
                    print(f"⚠️ Cache com dados zerados encontrado - buscando dados frescos")
                    cached_data = None
            
            # Se não há cache válido, buscar dados frescos da API
            if not cached_data or not profile_info or profile_info.get('followers_count', 0) == 0:
                print(f"📱 Obtendo dados frescos da API para: {username}")
                user_id, profile_info = get_user_data_from_rapidapi(username)
                
                # Se não conseguiu obter user_id, mas tem profile_info, ainda pode prosseguir
                if not user_id and not profile_info:
                    print(f"❌ Falha total ao obter dados do Instagram")
                    profile_info = None
                elif profile_info and profile_info.get('followers_count', 0) > 0:
                    print(f"✅ Dados frescos obtidos: {profile_info.get('followers_count', 0)} seguidores")
        else:
            # Dados foram reutilizados, terminar função
            return
        
        print(f"📊 Profile info obtido: {profile_info}")
        
        # Verificar se o perfil é privado
        if profile_info and profile_info.get('is_private', False):
            print(f"🔒 Perfil @{username} é privado - não é possível fazer análise")
            save_scan_result(db, job_id, username, "error", profile_info, error_message="Perfil privado - não é possível analisar contas privadas")
            return
        
        if profile_info and profile_info.get('followers_count', 0) > 0:
            # Salvar/atualizar usuário no banco
            user = get_or_create_user(db, username, profile_info)
            print(f"✅ Usuário criado/atualizado no banco: {user.id}")
            
            # Salvar scan inicial
            save_scan_result(db, job_id, username, "running", profile_info)
            print(f"✅ Scan inicial salvo no banco!")
            
            # Pequeno delay para garantir que o frontend detecte os dados
            await asyncio.sleep(0.1)
            
            # Obter ghosts com paginação otimizada (5 páginas de 25 usuários)
            print(f"📱 Obtendo ghosts com paginação otimizada...")
            ghosts_result = await get_ghosts_with_profile(username, profile_info, user_id, db_session=db)
            print(f"📊 Ghosts result: {ghosts_result}")
            
            # Salvar resultado final no banco
            save_scan_result(db, job_id, username, "done", profile_info, ghosts_result)
            
            print(f"✅ Scan concluído e salvo no banco!")
            print(f"📊 Estatísticas:")
            print(f"   - Seguidores encontrados: {ghosts_result.get('followers_count', 0)}")
            print(f"   - Seguindo encontrados: {ghosts_result.get('following_count', 0)}")
            print(f"   - Ghosts totais: {ghosts_result.get('ghosts_count', 0)}")
            print(f"   - Ghosts reais: {ghosts_result.get('real_ghosts_count', 0)}")
            print(f"   - Ghosts famosos: {ghosts_result.get('famous_ghosts_count', 0)}")
            
        else:
            print(f"❌ Profile info é None ou zerado, salvando erro no banco")
            # Salvar erro no banco
            save_scan_result(db, job_id, username, "error", error_message="Não foi possível obter dados válidos do perfil")
            print(f"❌ Erro: Não foi possível obter dados válidos do perfil")
            
    except Exception as e:
        print(f"❌ Erro no scan: {e}")
        traceback.print_exc()
        save_scan_result(db, job_id, username, "error", error_message=str(e))

@router.get("/scan/{job_id}", response_model=StatusResponse)
def status(job_id: str, db: Session = Depends(get_db)):
    """
    Verifica o status de um scan em andamento com retry automático.
    """
    # Primeiro verificar no banco de dados
    scan = db.query(Scan).filter(Scan.job_id == job_id).first()
    
    if scan:
        if scan.status == "error":
            return StatusResponse(
                status="error",
                error=scan.error_message or "Erro desconhecido"
            )
        
        if scan.status == "done":
            # ✅ REGRA ESPECIAL: jordanbitencourt vê todos os dados
            is_special_user = scan.username == 'jordanbitencourt'
            
            # Para usuário especial, retornar TODOS os dados
            if is_special_user:
                print(f"🎯 Usuário especial detectado: {scan.username} - retornando TODOS os dados")
                return StatusResponse(
                    status="done",
                    count=scan.ghosts_count,
                    sample=scan.ghosts_data,  # TODOS os dados, não apenas 10
                    all=scan.ghosts_data,
                    real_ghosts=scan.real_ghosts,
                    famous_ghosts=scan.famous_ghosts,
                    real_ghosts_count=scan.real_ghosts_count,
                    famous_ghosts_count=scan.famous_ghosts_count,
                    followers_count=scan.followers_count,  # Quantos analisamos
                    following_count=scan.following_count,  # Quantos analisamos
                    profile_followers_count=scan.profile_followers_count,  # Total do perfil
                    profile_following_count=scan.profile_following_count,  # Total do perfil
                    profile_info=scan.profile_info
                )
            else:
                # Para usuários normais, limitar a 10 amostras
                return StatusResponse(
                    status="done",
                    count=scan.ghosts_count,
                    sample=scan.ghosts_data[:10] if scan.ghosts_data else [],
                    all=scan.ghosts_data,
                    real_ghosts=scan.real_ghosts,
                    famous_ghosts=scan.famous_ghosts,
                    real_ghosts_count=scan.real_ghosts_count,
                    famous_ghosts_count=scan.famous_ghosts_count,
                    followers_count=scan.followers_count,  # Quantos analisamos
                    following_count=scan.following_count,  # Quantos analisamos
                    profile_followers_count=scan.profile_followers_count,  # Total do perfil
                    profile_following_count=scan.profile_following_count,  # Total do perfil
                    profile_info=scan.profile_info
                )
    
    # Se não encontrou no banco, verificar no cache
    job_data = get_job(job_id)
    
    if not job_data:
        # Retry automático: aguardar um pouco e tentar novamente
        time.sleep(0.5)
        job_data = get_job(job_id)
        
        if not job_data:
            # Segundo retry
            time.sleep(1)
            job_data = get_job(job_id)
            
            if not job_data:
                raise HTTPException(status_code=404, detail="Job não encontrado")
    
    if job_data["status"] == "error":
        return StatusResponse(
            status="error",
            error=job_data.get("error", "Erro desconhecido")
        )
    
    if job_data["status"] == "done":
        # ✅ REGRA ESPECIAL: jordanbitencourt vê todos os dados
        username_from_cache = job_data.get("profile_info", {}).get("username", "")
        is_special_user = username_from_cache == 'jordanbitencourt'
        
        if is_special_user:
            print(f"🎯 Usuário especial detectado no cache: {username_from_cache} - retornando TODOS os dados")
            return StatusResponse(
                status="done",
                count=job_data["count"],
                sample=job_data["all"],  # TODOS os dados, não apenas 10
                all=job_data["all"],
                real_ghosts=job_data["real_ghosts"],
                famous_ghosts=job_data["famous_ghosts"],
                real_ghosts_count=job_data["real_ghosts_count"],
                famous_ghosts_count=job_data["famous_ghosts_count"],
                followers_count=job_data.get("followers_count", 0),
                following_count=job_data.get("following_count", 0),
                profile_followers_count=job_data.get("profile_followers_count", 0),
                profile_following_count=job_data.get("profile_following_count", 0),
                profile_info=job_data["profile_info"]
            )
        else:
            # Para usuários normais, limitar a 10 amostras
            return StatusResponse(
                status="done",
                count=job_data["count"],
                sample=job_data["all"][:10] if job_data.get("all") else [],
                all=job_data["all"],
                real_ghosts=job_data["real_ghosts"],
                famous_ghosts=job_data["famous_ghosts"],
                real_ghosts_count=job_data["real_ghosts_count"],
                famous_ghosts_count=job_data["famous_ghosts_count"],
                followers_count=job_data.get("followers_count", 0),
                following_count=job_data.get("following_count", 0),
                profile_followers_count=job_data.get("profile_followers_count", 0),
                profile_following_count=job_data.get("profile_following_count", 0),
                profile_info=job_data["profile_info"]
            )
    
    # Retorna status com dados do perfil se disponíveis
    return StatusResponse(
        status=job_data["status"],
        profile_info=job_data.get("profile_info"),
        count=job_data.get("count", 0),
        real_ghosts_count=job_data.get("real_ghosts_count", 0),
        famous_ghosts_count=job_data.get("famous_ghosts_count", 0),
        followers_count=job_data.get("followers_count", 0),
        following_count=job_data.get("following_count", 0),
        profile_followers_count=job_data.get("profile_followers_count", 0),
        profile_following_count=job_data.get("profile_following_count", 0)
    )

@router.get("/user/{username}/history")
def get_user_history(username: str, db: Session = Depends(get_db)):
    """
    Obtém histórico de scans de um usuário.
    """
    scans = get_user_scan_history(db, username)
    
    return {
        "username": username,
        "scans": [
            {
                "job_id": scan.job_id,
                "status": scan.status,
                "created_at": scan.created_at,
                "updated_at": scan.updated_at,
                "ghosts_count": scan.ghosts_count,
                "real_ghosts_count": scan.real_ghosts_count,
                "famous_ghosts_count": scan.famous_ghosts_count
            }
            for scan in scans
        ]
    }

@router.get("/health")
def health_check():
    """
    Endpoint de health check.
    """
    jobs = load_jobs()
    
    # Contar apenas jobs realmente ativos (running) e não órfãos
    active_jobs = 0
    for job_id, job_data in jobs.items():
        if job_data.get("status") == "running":
            # Verificar se o job não é órfão (mais de 30 minutos)
            if "start_time" in job_data:
                import time
                if time.time() - job_data["start_time"] < 1800:  # 30 minutos
                    active_jobs += 1
            else:
                # Se não tem start_time, considerar órfão
                job_data["status"] = "error"
                job_data["error"] = "Job órfão - sem start_time"
    
    # Salvar jobs limpos
    save_jobs(jobs)
    
    return {"status": "healthy", "jobs_active": active_jobs}

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