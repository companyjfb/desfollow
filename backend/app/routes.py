import json
import os
from uuid import uuid4
from fastapi import APIRouter, HTTPException, BackgroundTasks, Depends
from pydantic import BaseModel
from .ig import get_ghosts_with_profile, get_user_id_from_rapidapi
from .database import get_db, get_or_create_user, save_scan_result, get_user_scan_history, get_cached_user_data, Scan
from sqlalchemy.orm import Session
import asyncio
import requests
import os
import time
from fastapi.responses import StreamingResponse

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
    
    # Verificar se já existe scan recente no banco (últimas 24h)
    from datetime import datetime, timedelta
    recent_scans = db.query(Scan).filter(
        Scan.username == username,
        Scan.status == "done",
        Scan.updated_at >= datetime.utcnow() - timedelta(hours=24)
    ).order_by(Scan.updated_at.desc()).limit(1).all()
    
    if recent_scans:
        recent_scan = recent_scans[0]
        print(f"📋 Scan recente encontrado no banco: {recent_scan.job_id}")
        
        # Retornar job_id do scan existente
        return ScanResponse(job_id=recent_scan.job_id)
    
    job_id = str(uuid4())
    set_job(job_id, {"status": "queued"})
    
    print(f"📋 Job criado: {job_id}")
    
    # Adiciona tarefa em background
    bg.add_task(run_scan_with_database, job_id, username, db)
    
    return ScanResponse(job_id=job_id)

async def run_scan_with_database(job_id: str, username: str, db: Session):
    """
    Executa o scan com integração ao banco de dados e paginação otimizada.
    """
    try:
        print(f"🚀 Iniciando scan com banco para job {job_id}: {username}")
        set_job(job_id, {"status": "running"})
        
        # Verificar cache do usuário
        cached_data = get_cached_user_data(db, username)
        if cached_data:
            print(f"📋 Dados em cache encontrados para: {username}")
            profile_info = cached_data['profile_info']
        else:
            print(f"📱 Obtendo dados do perfil para: {username}")
            profile_info = get_profile_info(username)
        
        if profile_info:
            # Salvar/atualizar usuário no banco
            user = get_or_create_user(db, username, profile_info)
            
            # Salvar scan inicial
            save_scan_result(db, job_id, username, "running", profile_info)
            
            print(f"✅ Dados do perfil salvos no banco!")
            
            # Pequeno delay para garantir que o frontend detecte os dados
            await asyncio.sleep(0.1)
            
            # Obter ghosts com paginação otimizada (5 páginas de 25 usuários)
            print(f"📱 Obtendo ghosts com paginação otimizada...")
            ghosts_result = await get_ghosts_with_profile(username, profile_info, db_session=db)
            
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
            # Salvar erro no banco
            save_scan_result(db, job_id, username, "error", error_message="Não foi possível obter dados do perfil")
            print(f"❌ Erro: Não foi possível obter dados do perfil")
            
    except Exception as e:
        print(f"❌ Erro no scan {job_id}: {e}")
        save_scan_result(db, job_id, username, "error", error_message=str(e))

def get_profile_info(username: str) -> dict:
    """
    Obtém informações do perfil via RapidAPI.
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
            if 'user' in data:
                user_data = data['user']
                return {
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
        
        return None
    except Exception as e:
        print(f"❌ Erro ao obter dados do perfil: {e}")
        return None

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
            return StatusResponse(
                status="done",
                count=scan.ghosts_count,
                sample=scan.ghosts_data[:10] if scan.ghosts_data else [],
                all=scan.ghosts_data,
                real_ghosts=scan.real_ghosts,
                famous_ghosts=scan.famous_ghosts,
                real_ghosts_count=scan.real_ghosts_count,
                famous_ghosts_count=scan.famous_ghosts_count,
                profile_info=scan.profile_info
            )
        
        # Retorna status com dados do perfil se disponíveis
        return StatusResponse(
            status=scan.status,
            profile_info=scan.profile_info,
            count=scan.ghosts_count or 0,
            real_ghosts_count=scan.real_ghosts_count or 0,
            famous_ghosts_count=scan.famous_ghosts_count or 0
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
        return StatusResponse(
            status="done",
            count=job_data["count"],
            sample=job_data["all"][:10] if job_data.get("all") else [],
            all=job_data["all"],
            real_ghosts=job_data["real_ghosts"],
            famous_ghosts=job_data["famous_ghosts"],
            real_ghosts_count=job_data["real_ghosts_count"],
            famous_ghosts_count=job_data["famous_ghosts_count"],
            profile_info=job_data["profile_info"]
        )
    
    # Retorna status com dados do perfil se disponíveis
    return StatusResponse(
        status=job_data["status"],
        profile_info=job_data.get("profile_info"),
        count=job_data.get("count", 0),
        real_ghosts_count=job_data.get("real_ghosts_count", 0),
        famous_ghosts_count=job_data.get("famous_ghosts_count", 0)
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
    return {"status": "healthy", "jobs_active": len([j for j in jobs.values() if j["status"] == "running"])}

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