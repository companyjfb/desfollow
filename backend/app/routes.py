import json
import os
from uuid import uuid4
from datetime import datetime, timedelta
from fastapi import APIRouter, HTTPException, BackgroundTasks, Depends, Query
from fastapi.responses import JSONResponse, Response
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from .ig import get_ghosts_with_profile, get_user_id_from_rapidapi, get_user_data_from_rapidapi
from .database import get_db, get_or_create_user, save_scan_result, get_user_scan_history, get_cached_user_data, Scan, PaidUser, Subscription
from sqlalchemy.orm import Session
import asyncio
import requests
import httpx
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
            # Atualizar cache com erro de perfil privado
            set_job(job_id, {
                "status": "error",
                "error": "Perfil privado - não é possível analisar contas privadas",
                "profile_info": profile_info
            })
            save_scan_result(db, job_id, username, "error", profile_info, error_message="Perfil privado - não é possível analisar contas privadas")
            return
        
        if profile_info and profile_info.get('followers_count', 0) > 0:
            # Atualizar cache do job com dados do perfil
            set_job(job_id, {
                "status": "running",
                "profile_info": profile_info,
                "count": 0,
                "real_ghosts_count": 0,
                "famous_ghosts_count": 0,
                "followers_count": profile_info.get('followers_count', 0),  # CORRIGIDO: usar o valor real imediatamente
                "following_count": profile_info.get('following_count', 0),  # CORRIGIDO: usar o valor real imediatamente  
                "profile_followers_count": profile_info.get('followers_count', 0),
                "profile_following_count": profile_info.get('following_count', 0)
            })
            print(f"✅ Cache do job atualizado com dados do perfil!")
            
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
            
            # Atualizar cache do job com resultado final
            set_job(job_id, {
                "status": "done",
                "profile_info": profile_info,
                "count": ghosts_result.get('ghosts_count', 0),
                "all": ghosts_result.get('ghosts', []),
                "real_ghosts": ghosts_result.get('real_ghosts', []),
                "famous_ghosts": ghosts_result.get('famous_ghosts', []),
                "real_ghosts_count": ghosts_result.get('real_ghosts_count', 0),
                "famous_ghosts_count": ghosts_result.get('famous_ghosts_count', 0),
                "followers_count": ghosts_result.get('followers_count', 0),
                "following_count": ghosts_result.get('following_count', 0),
                "profile_followers_count": profile_info.get('followers_count', 0),
                "profile_following_count": profile_info.get('following_count', 0)
            })
            print(f"✅ Cache do job atualizado com resultado final!")
            
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
            # Atualizar cache com erro
            set_job(job_id, {
                "status": "error",
                "error": "Não foi possível obter dados válidos do perfil"
            })
            # Salvar erro no banco
            save_scan_result(db, job_id, username, "error", error_message="Não foi possível obter dados válidos do perfil")
            print(f"❌ Erro: Não foi possível obter dados válidos do perfil")
            
    except Exception as e:
        print(f"❌ Erro no scan: {e}")
        traceback.print_exc()
        # Atualizar cache com erro
        set_job(job_id, {
            "status": "error",
            "error": str(e)
        })
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
async def proxy_image(url: str = Query(..., description="URL da imagem do Instagram")):
    """
    Endpoint para fazer proxy de uma imagem do Instagram.
    """
    try:
        # Headers para parecer um navegador real
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
        }
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(url, headers=headers)
            response.raise_for_status()
            
            # Detectar o tipo de conteúdo
            content_type = response.headers.get('Content-Type', 'image/jpeg')
            
            # Headers CORS para permitir acesso do frontend
            headers_out = {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Cache-Control': 'public, max-age=3600',  # Cache por 1 hora
            }
            
            return Response(
                content=response.content,
                media_type=content_type,
                headers=headers_out
            )
            
    except httpx.TimeoutException:
        raise HTTPException(status_code=408, detail="Timeout ao carregar imagem")
    except httpx.HTTPStatusError as e:
        raise HTTPException(status_code=e.response.status_code, detail=f"Erro HTTP: {e.response.status_code}")
    except Exception as e:
        print(f"❌ Erro no proxy de imagem: {e}")
        raise HTTPException(status_code=500, detail=f"Erro ao fazer proxy da imagem: {str(e)}")

# =============================================================================
# ENDPOINTS DE PAGAMENTO - PERFECT PAY
# =============================================================================

class PerfectPayWebhookData(BaseModel):
    """Modelo para dados do webhook da Perfect Pay - ESTRUTURA REAL"""
    token: str
    code: str
    sale_amount: float
    currency_enum: int
    currency_enum_key: Optional[str] = None
    coupon_code: Optional[str] = None
    installments: int
    installment_amount: Optional[float] = None
    shipping_type_enum: Optional[int] = None
    shipping_type_enum_key: Optional[str] = None
    shipping_amount: Optional[float] = None
    payment_method_enum: int
    payment_method_enum_key: Optional[str] = None
    payment_type_enum: int
    payment_type_enum_key: Optional[str] = None
    payment_format_enum: Optional[int] = None
    payment_format_enum_key: Optional[str] = None
    original_code: Optional[str] = None
    billet_url: Optional[str] = None
    billet_number: Optional[str] = None
    billet_expiration: Optional[str] = None
    quantity: int
    sale_status_enum: int
    sale_status_enum_key: Optional[str] = None
    sale_status_detail: str
    date_created: str
    date_approved: Optional[str] = None
    tracking: Optional[str] = None
    url_tracking: Optional[str] = None
    checkout_type_enum: Optional[str] = None
    academy_access_url: Optional[str] = None
    product: Dict[str, Any]
    plan: Dict[str, Any]
    plan_itens: List[Any]
    customer: Dict[str, Any]
    metadata: Dict[str, Any]
    subscription: Optional[Dict[str, Any]] = None
    webhook_owner: str
    commission: List[Dict[str, Any]]
    url_send_webhook_pay: Optional[str] = None

def get_extraction_method(metadata: Dict, username: str) -> str:
    """Retorna qual método foi usado para extrair o username"""
    if metadata.get('utm_perfect') == username:
        return "utm_perfect (principal)"
    elif metadata.get('src', '').replace('user_', '') == username:
        return "src field (user_prefix)"
    elif metadata.get('utm_content') == username:
        return "utm_content"
    elif metadata.get('username') == username:
        return "username field"
    elif metadata.get('utm_source') == username:
        return "utm_source"
    elif metadata.get('utm_campaign') == username:
        return "utm_campaign"
    else:
        return "email fallback"

@router.post("/webhook/perfect-pay")
async def perfect_pay_webhook(webhook_data: PerfectPayWebhookData, db: Session = Depends(get_db)):
    """
    Endpoint para receber webhooks da Perfect Pay - ASSINATURAS MENSAIS
    """
    try:
        print(f"🎯 Webhook Perfect Pay recebido - Código: {webhook_data.code}")
        print(f"📊 Status da venda: {webhook_data.sale_status_enum} ({webhook_data.sale_status_enum_key})")
        print(f"💰 Valor: R$ {webhook_data.sale_amount}")
        print(f"👤 Cliente: {webhook_data.customer.get('email', 'N/A')}")
        print(f"📧 Email: {webhook_data.customer.get('email')}")
        print(f"📱 Telefone: {webhook_data.customer.get('phone_formated_ddi', 'N/A')}")
        print(f"🔑 Webhook Owner: {webhook_data.webhook_owner}")
        if webhook_data.subscription:
            print(f"📋 Assinatura: {webhook_data.subscription.get('code')} - Status: {webhook_data.subscription.get('status')}")
            print(f"📅 Próxima cobrança: {webhook_data.subscription.get('next_charge_date')}")
        
        # Extrair username do metadata com ESTRATÉGIA MÚLTIPLA OTIMIZADA
        username = None
        if webhook_data.metadata:
            print(f"🔍 Metadata recebido: {webhook_data.metadata}")
            
            # 1. PRIORIDADE: UTM personalizado 'utm_perfect' (principal)
            username = webhook_data.metadata.get('utm_perfect')
            
            # 2. BACKUP: Extrair do campo 'src' (user_USERNAME)
            if not username and webhook_data.metadata.get('src'):
                src_value = webhook_data.metadata.get('src', '')
                if src_value.startswith('user_'):
                    username = src_value.replace('user_', '')
            
            # 3. BACKUP: UTM content
            if not username:
                username = webhook_data.metadata.get('utm_content')
            
            # 4. FALLBACK: Parâmetro dedicado 'username'
            if not username:
                username = webhook_data.metadata.get('username')
            
            # 5. ÚLTIMO RECURSO: UTMs tradicionais
            if not username:
                username = (
                    webhook_data.metadata.get('utm_source') or
                    webhook_data.metadata.get('utm_campaign')
                )
        
        # 5. ÚLTIMA TENTATIVA: Extrair de qualquer campo que contenha username
        if not username and webhook_data.metadata:
            import re
            for key, value in webhook_data.metadata.items():
                if value and isinstance(value, str):
                    # Buscar padrões como "username=valor" ou "user_valor"
                    match = re.search(r'(?:username[=:]|user_)([^&\s]+)', value)
                    if match:
                        username = match.group(1)
                        print(f"🔍 Username extraído de {key}: {username}")
                        break
        
        if not username:
            print(f"❌ Não foi possível extrair username do webhook!")
            print(f"📋 Metadata disponível: {webhook_data.metadata}")
            # FALLBACK: usar email como base para username
            email = webhook_data.customer.get('email')
            if email:
                username = email.split('@')[0]
                print(f"💡 FALLBACK: Usando parte do email como username: {username}")
            
            if not username:
                raise HTTPException(status_code=400, detail="Username não encontrado no metadata do webhook")
        
        print(f"✅ Username extraído: {username}")
        print(f"📋 Método de extração usado: {get_extraction_method(webhook_data.metadata, username)}")
        
        # Buscar assinatura existente para este usuário
        subscription = db.query(Subscription).filter(Subscription.username == username).first()
        
        if subscription:
            # Atualizar assinatura existente COMPLETAMENTE
            print(f"📝 Atualizando assinatura existente para {username}")
            print(f"📊 Status anterior: {subscription.subscription_status}")
            print(f"📊 Novo status do webhook: {webhook_data.sale_status_enum} ({webhook_data.sale_status_enum_key})")
            
            # Atualizar todos os campos com dados novos
            subscription.perfect_pay_code = webhook_data.code
            subscription.perfect_pay_customer_email = webhook_data.customer.get('email')
            subscription.perfect_pay_customer_name = webhook_data.customer.get('full_name')
            subscription.perfect_pay_customer_cpf = webhook_data.customer.get('identification_number')
            subscription.monthly_amount = webhook_data.sale_amount
            subscription.last_sale_status = webhook_data.sale_status_enum
            subscription.webhook_data = webhook_data.dict()
            subscription.updated_at = datetime.utcnow()
            
            # FORÇAR STATUS BASEADO NO WEBHOOK
            if webhook_data.sale_status_enum in [2, 10]:  # approved ou completed
                subscription.subscription_status = "active"
                subscription.current_period_start = datetime.utcnow()
                subscription.last_payment_date = datetime.utcnow()
                subscription.total_payments_received = (subscription.total_payments_received or 0) + 1
                
                # Calcular nova data de expiração
                from dateutil.relativedelta import relativedelta
                
                # Se há dados de assinatura da PerfectPay, usar a data EXATA
                if webhook_data.subscription and webhook_data.subscription.get('next_charge_date'):
                    from dateutil.parser import parse
                    try:
                        next_charge = parse(webhook_data.subscription['next_charge_date'])
                        subscription.next_billing_date = next_charge
                        subscription.current_period_end = next_charge
                        print(f"📅 Data EXATA da PerfectPay: {next_charge}")
                    except Exception as e:
                        print(f"⚠️ Erro ao parse da data ({e}), calculando 1 mês")
                        subscription.current_period_end = datetime.utcnow() + relativedelta(months=1)
                        subscription.next_billing_date = subscription.current_period_end
                else:
                    # Fallback: adicionar 1 mês
                    subscription.current_period_end = datetime.utcnow() + relativedelta(months=1)
                    subscription.next_billing_date = subscription.current_period_end
                
                print(f"✅ Assinatura ATIVADA para {username}")
                print(f"📅 Válida até: {subscription.current_period_end}")
                print(f"💳 Total de pagamentos: {subscription.total_payments_received}")
            elif webhook_data.sale_status_enum in [5, 6]:  # rejected ou cancelled
                subscription.subscription_status = "cancelled"
                print(f"❌ Assinatura CANCELADA para {username}")
            else:
                subscription.subscription_status = "pending"
                print(f"⏳ Assinatura em PENDÊNCIA para {username}")
        else:
            # Criar nova assinatura
            from dateutil.relativedelta import relativedelta
            
            subscription = Subscription(
                username=username,
                perfect_pay_code=webhook_data.code,
                perfect_pay_customer_email=webhook_data.customer.get('email'),
                perfect_pay_customer_name=webhook_data.customer.get('full_name'),
                perfect_pay_customer_cpf=webhook_data.customer.get('identification_number'),
                monthly_amount=webhook_data.sale_amount,
                currency="BRL" if webhook_data.currency_enum == 1 else "USD",
                payment_method=get_payment_method_name(webhook_data.payment_method_enum),
                payment_type=get_payment_type_name(webhook_data.payment_type_enum),
                last_sale_status=webhook_data.sale_status_enum,
                subscription_start=datetime.utcnow(),
                webhook_data=webhook_data.dict()
            )
            
            # Se pagamento foi aprovado/completado, ativar assinatura
            if webhook_data.sale_status_enum in [2, 10]:  # approved ou completed
                subscription.subscription_status = "active"
                subscription.current_period_start = datetime.utcnow()
                subscription.current_period_end = datetime.utcnow() + relativedelta(months=1)
                subscription.next_billing_date = subscription.current_period_end
                subscription.last_payment_date = datetime.utcnow()
                subscription.total_payments_received = 1
                
                # Se há dados de assinatura da PerfectPay, usar a data correta
                if webhook_data.subscription and webhook_data.subscription.get('next_charge_date'):
                    from dateutil.parser import parse
                    try:
                        next_charge = parse(webhook_data.subscription['next_charge_date'])
                        subscription.next_billing_date = next_charge
                        subscription.current_period_end = next_charge
                        print(f"📅 Data de próxima cobrança da PerfectPay: {next_charge}")
                    except:
                        print(f"⚠️ Erro ao parse da data, usando data padrão")
                
                print(f"🎉 Nova assinatura ATIVA criada para {username}")
                print(f"📅 Válida até: {subscription.current_period_end}")
            else:
                subscription.subscription_status = "pending"
                print(f"⏳ Nova assinatura PENDENTE criada para {username}")
            
            db.add(subscription)
        
        db.commit()
        
        # Log detalhado do status
        if webhook_data.sale_status_enum == 2:  # approved
            print(f"✅ Pagamento APROVADO - Assinatura ativa para {username}")
        elif webhook_data.sale_status_enum == 10:  # completed
            print(f"🎉 Pagamento COMPLETADO - Assinatura ativa para {username}")
        elif webhook_data.sale_status_enum == 5:  # rejected
            print(f"❌ Pagamento REJEITADO para {username}")
        elif webhook_data.sale_status_enum == 6:  # cancelled
            print(f"🚫 Pagamento CANCELADO para {username}")
        else:
            print(f"📋 Status do pagamento: {webhook_data.sale_status_enum} para {username}")
        
        return JSONResponse({"status": "success", "message": "Webhook de assinatura processado com sucesso"})

@router.post("/subscription/force-active/{username}")
async def force_subscription_active(username: str, db: Session = Depends(get_db)):
    """Força uma assinatura para ativa - usar apenas para debug"""
    try:
        subscription = db.query(Subscription).filter(Subscription.username == username).first()
        
        if not subscription:
            raise HTTPException(status_code=404, detail="Assinatura não encontrada")
        
        # Forçar status ativo
        subscription.subscription_status = "active"
        subscription.last_sale_status = 2  # approved
        
        # Garantir datas válidas se necessário
        if not subscription.current_period_end:
            from dateutil.relativedelta import relativedelta
            subscription.current_period_end = datetime.utcnow() + relativedelta(months=1)
            subscription.next_billing_date = subscription.current_period_end
        
        subscription.updated_at = datetime.utcnow()
        db.commit()
        
        print(f"🔧 Status FORÇADO para ativo para {username}")
        
        return JSONResponse({
            "success": True,
            "username": username,
            "new_status": "active",
            "current_period_end": subscription.current_period_end.isoformat() if subscription.current_period_end else None,
            "message": "Status forçado para ativo com sucesso"
        })
        
    except Exception as e:
        print(f"❌ Erro ao forçar status: {e}")
        raise HTTPException(status_code=500, detail=f"Erro: {str(e)}")
        
    except Exception as e:
        print(f"❌ Erro ao processar webhook Perfect Pay: {e}")
        print(f"❌ Traceback: {traceback.format_exc()}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao processar webhook: {str(e)}")

@router.get("/subscription/check/{username}")
async def check_subscription_status(username: str, verify_with_api: bool = True, db: Session = Depends(get_db)):
    """
    Verifica se um usuário tem assinatura ativa com VERIFICAÇÃO DUPLA
    """
    try:
        # 1. Buscar assinatura local
        subscription = db.query(Subscription).filter(Subscription.username == username).first()
        
        if not subscription:
            # Se não encontrou local, tentar buscar diretamente na Perfect Pay
            if verify_with_api:
                print(f"🔍 Usuário {username} não encontrado localmente. Buscando na Perfect Pay...")
                # Buscar apenas por username nos metadados (sem email/cpf)
                sales_data = await get_perfect_pay_sales(username=username)
                sales = sales_data.get("sales", {}).get("data", [])
                
                if sales:
                    print(f"💡 Encontradas {len(sales)} vendas na Perfect Pay para {username}")
                    # Analisar venda mais recente
                    latest_sale = max(sales, key=lambda x: x.get("date_created", ""))
                    sale_status = latest_sale.get("sale_status_enum", latest_sale.get("sale_status"))
                    
                    # Só criar assinatura se status for ativo (2=approved, 10=completed)
                    if sale_status in [2, 10, "approved", "completed"]:
                        print(f"🆕 Criando assinatura local baseada na Perfect Pay para {username}")
                        
                        # Extrair dados do cliente da venda
                        customer_data = latest_sale.get("customer", {})
                        
                        from dateutil.relativedelta import relativedelta
                        subscription = Subscription(
                            username=username,
                            perfect_pay_code=latest_sale.get("code"),  # Usar 'code' ao invés de 'transaction_token'
                            perfect_pay_customer_email=customer_data.get("email"),
                            perfect_pay_customer_name=customer_data.get("full_name"),
                            perfect_pay_customer_cpf=customer_data.get("identification_number"),
                            subscription_status="active",
                            monthly_amount=float(latest_sale.get("sale_amount", 29.0)),
                            current_period_start=datetime.now(),
                            current_period_end=datetime.now() + relativedelta(months=1),
                            last_sale_status=sale_status if isinstance(sale_status, int) else 2,
                            total_payments_received=1
                        )
                        db.add(subscription)
                        db.commit()
                        print(f"✅ Assinatura criada localmente para {username}")
                        print(f"   Email: {customer_data.get('email', 'N/A')}")
                        print(f"   Nome: {customer_data.get('full_name', 'N/A')}")
                    else:
                        print(f"❌ Venda encontrada mas status inativo: {sale_status}")
            
            if not subscription:
                return JSONResponse({
                    "has_active_subscription": False,
                    "username": username,
                    "message": "Usuário não encontrado na base de assinaturas",
                    "verification_method": "local_and_api" if verify_with_api else "local_only"
                })
        
        # 2. Verificação local básica
        is_active_local = subscription.is_active()
        is_payment_current = subscription.is_payment_current()
        days_remaining = subscription.days_until_expiry()
        
        # 3. VERIFICAÇÃO DUPLA com Perfect Pay (apenas se habilitada)
        is_active_perfect_pay = True
        verification_method = "local_only"
        
        if verify_with_api and subscription:
            print(f"🔍 Verificação dupla: consultando Perfect Pay para {username}")
            is_active_perfect_pay = await verify_subscription_with_perfect_pay(username, subscription)
            verification_method = "local_and_api"
            
            # COMENTADO: não deixar Perfect Pay cancelar assinatura se pagamento local foi aprovado
            # if not is_active_perfect_pay and subscription.subscription_status == "active":
            #     subscription.subscription_status = "cancelled"
            #     db.commit()
            #     print(f"🔄 Status local atualizado para cancelado baseado na Perfect Pay")
            if not is_active_perfect_pay and subscription.subscription_status == "active":
                print(f"⚠️ Perfect Pay retornou inativo, mas mantendo ativo localmente pois pagamento foi aprovado")
        
        # 4. Decisão final: PRIORIZAR status local se pagamento está current
        # Se o pagamento foi aprovado localmente, não deixar a API externa cancelar
        if is_payment_current and is_active_local:
            final_status = True
            print(f"🔒 FORÇANDO STATUS ATIVO - pagamento aprovado localmente")
        else:
            final_status = is_active_local and is_payment_current and is_active_perfect_pay
        
        print(f"📊 Verificação final para {username}:")
        print(f"   Local ativo: {is_active_local}")
        print(f"   Pagamento atual: {is_payment_current}")
        print(f"   Perfect Pay ativo: {is_active_perfect_pay}")
        print(f"   Status final: {final_status}")
        
        return JSONResponse({
            "has_active_subscription": final_status,
            "username": username,
            "subscription_status": subscription.subscription_status,
            "is_active_local": is_active_local,
            "is_payment_current": is_payment_current,
            "is_active_perfect_pay": is_active_perfect_pay,
            "days_remaining": days_remaining,
            "is_expiring_soon": subscription.is_expiring_soon(),
            "current_period_end": subscription.current_period_end.isoformat() if subscription.current_period_end else None,
            "last_payment_date": subscription.last_payment_date.isoformat() if subscription.last_payment_date else None,
            "next_billing_date": subscription.next_billing_date.isoformat() if subscription.next_billing_date else None,
            "total_payments_received": subscription.total_payments_received,
            "monthly_amount": subscription.monthly_amount,
            "perfect_pay_code": subscription.perfect_pay_code,
            "verification_method": verification_method
        })
        
    except Exception as e:
        print(f"❌ Erro ao verificar status de assinatura: {e}")
        print(f"❌ Traceback: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Erro ao verificar assinatura: {str(e)}")

# Manter endpoint antigo para compatibilidade durante transição
@router.get("/payment/check/{username}")
async def check_payment_status_legacy(username: str, db: Session = Depends(get_db)):
    """
    LEGACY: Redireciona para verificação de assinatura
    """
    return await check_subscription_status(username, True, db)

@router.post("/subscription/sync/{username}")
async def force_sync_with_perfect_pay(username: str, db: Session = Depends(get_db)):
    """
    Força sincronização com Perfect Pay para corrigir inconsistências
    """
    try:
        print(f"🔄 Iniciando sincronização forçada para {username}")
        
        # Buscar assinatura local para obter dados do cliente
        subscription = db.query(Subscription).filter(Subscription.username == username).first()
        
        # Buscar vendas na Perfect Pay usando dados disponíveis
        if subscription and (subscription.perfect_pay_customer_email or subscription.perfect_pay_customer_cpf):
            print(f"🔍 Buscando por dados do cliente: {subscription.perfect_pay_customer_email}")
            sales_data = await get_perfect_pay_sales(
                username=username,
                customer_email=subscription.perfect_pay_customer_email,
                customer_cpf=subscription.perfect_pay_customer_cpf
            )
        else:
            print(f"🔍 Buscando apenas por username nos metadados")
            sales_data = await get_perfect_pay_sales(username=username)
        
        sales = sales_data.get("sales", {}).get("data", [])
        
        if not sales:
            return JSONResponse({
                "success": False,
                "message": f"Nenhuma venda encontrada na Perfect Pay para {username}",
                "sales_found": 0,
                "search_criteria": {
                    "username": username,
                    "email": subscription.perfect_pay_customer_email if subscription else None,
                    "cpf": subscription.perfect_pay_customer_cpf if subscription else None
                }
            })
        
        # Analisar venda mais recente
        latest_sale = max(sales, key=lambda x: x.get("date_created", ""))
        sale_status = latest_sale.get("sale_status_enum", latest_sale.get("sale_status"))
        customer_data = latest_sale.get("customer", {})
        
        print(f"📊 Venda mais recente: {latest_sale.get('code')} - Status: {sale_status}")
        
        if not subscription:
            # Criar nova assinatura com dados completos do cliente
            from dateutil.relativedelta import relativedelta
            subscription = Subscription(
                username=username,
                perfect_pay_code=latest_sale.get("code"),
                perfect_pay_customer_email=customer_data.get("email"),
                perfect_pay_customer_name=customer_data.get("full_name"),
                perfect_pay_customer_cpf=customer_data.get("identification_number"),
                subscription_status="active" if sale_status in [2, 10, "approved", "completed"] else "cancelled",
                monthly_amount=float(latest_sale.get("sale_amount", 29.0)),
                current_period_start=datetime.now() if sale_status in [2, 10, "approved", "completed"] else None,
                current_period_end=datetime.now() + relativedelta(months=1) if sale_status in [2, 10, "approved", "completed"] else None,
                last_sale_status=sale_status if isinstance(sale_status, int) else (2 if sale_status == "approved" else 10 if sale_status == "completed" else 6),
                total_payments_received=len([s for s in sales if s.get("sale_status_enum", s.get("sale_status")) in [2, 10, "approved", "completed"]])
            )
            db.add(subscription)
            action = "created"
        else:
            # Atualizar assinatura existente com dados mais recentes
            subscription.perfect_pay_code = latest_sale.get("code")
            subscription.perfect_pay_customer_email = customer_data.get("email") or subscription.perfect_pay_customer_email
            subscription.perfect_pay_customer_name = customer_data.get("full_name") or subscription.perfect_pay_customer_name
            subscription.perfect_pay_customer_cpf = customer_data.get("identification_number") or subscription.perfect_pay_customer_cpf
            subscription.subscription_status = "active" if sale_status in [2, 10, "approved", "completed"] else "cancelled"
            subscription.last_sale_status = sale_status if isinstance(sale_status, int) else (2 if sale_status == "approved" else 10 if sale_status == "completed" else 6)
            subscription.total_payments_received = len([s for s in sales if s.get("sale_status_enum", s.get("sale_status")) in [2, 10, "approved", "completed"]])
            action = "updated"
        
        db.commit()
        
        print(f"✅ Sincronização completa para {username}: {action}")
        
        return JSONResponse({
            "success": True,
            "message": f"Sincronização completa - assinatura {action}",
            "username": username,
            "sales_found": len(sales),
            "latest_sale_status": sale_status,
            "subscription_status": subscription.subscription_status,
            "action": action
        })
        
    except Exception as e:
        print(f"❌ Erro na sincronização forçada: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erro na sincronização: {str(e)}")

def get_payment_method_name(method_enum: int) -> str:
    """Converte enum de método de pagamento para string"""
    methods = {
        0: 'none',
        1: 'visa',
        2: 'bolbradesco',
        3: 'amex',
        4: 'elo',
        5: 'hipercard',
        6: 'master',
        7: 'melicard',
        8: 'free_price'
    }
    return methods.get(method_enum, 'unknown')

def get_payment_type_name(type_enum: int) -> str:
    """Converte enum de tipo de pagamento para string"""
    types = {
        0: 'none',
        1: 'credit_card',
        2: 'ticket',
        3: 'paypal',
        4: 'credit_card_recurrent',
        5: 'free_price',
        6: 'credit_card_upsell'
    }
    return types.get(type_enum, 'unknown')

# =============================================================================
# VERIFICAÇÃO DUPLA COM API PERFECT PAY
# =============================================================================

PERFECT_PAY_ACCESS_TOKEN = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIzIiwianRpIjoiZDYwMDY0YWIwYzhjOWY1NGZhMTY1OGQzMzJiOGZhOTNhNTg4MTY0MThmMmYxYmYyMjM2N2JiNTkxNWRmYjQ1NDhjZjAzOTg3ODg0YjgwN2UiLCJpYXQiOjE3NTQ1MDkyNTIuODcwOTMyLCJuYmYiOjE3NTQ1MDkyNTIuODcwOTM1LCJleHAiOjE5MTIyNzU2NTIuODU1ODI4LCJzdWIiOiIyNTYyNzU4Iiwic2NvcGVzIjpbInBlcnNvbmFsX2FjY2VzcyJdfQ.iXYukZAu7kKC_4xBkPO5F9ywh7En28L-e-Yqa6hWk_n3YPZ7nHVMsaKRH_MU5RdKMun2S97P4cZ7KiS0dW-TKWK07s5RE_sSmHsQrchb-P8c5svPfMF9qjta1boX0BJLfvfBMdZx8_-4Ba61mwGCdwbJXH8n3nKDBfWCUMkKEkgoAfa2H1qJ9HM7KUXXRj9WUyAk8GJ8fqkVZdACNsMCQHMw-igjbblEYznFgDo7PxVeYhtS1Pfg1cOTy3IrwSmpv--mPhrLYIKGYJ5kPT4kSnIKjst-qa5ZIuwTN-PD91VBIpFDTeTXymFbgHIF-tXYb60746TcjyH11OHK6lpaAOr0ejJiCSsQPX3_82IBghFSfvzH2PDP7UdNtEzUc0-_Qdrn3CYS_NeieduPsNZVSiIHna0-t7DCycNAT-VNxTsSQzBDEbZTVlKAkkY7-aSWPKA6fPHhzlFmxAvzRV0nOlrcBwAk7_74WeXiDnn3A9YJsSfBvz0BzmqRfwxmqWFVp0ayEAp9iJmaZLDBnGGOM0yclSSrdfSZCO9lg2O4-GdZZdKWFwmUtWhBpaYVAe6Z983NmuAS1A-ToC-bl2FW9mcYM9UPXQ3RTWeGY2ugFDMURU9QfSV5VuLhLusLrvX1xQwnjUbu5XMtfE2FPu4sWyTFKuJKB3CmBDI7yLENxLk"

async def get_perfect_pay_sales(username: str = None, transaction_token: str = None, customer_email: str = None, customer_cpf: str = None) -> Dict[str, Any]:
    """
    Busca vendas na API da Perfect Pay usando múltiplas estratégias de identificação
    """
    try:
        headers = {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": f"Bearer {PERFECT_PAY_ACCESS_TOKEN}"
        }
        
        # Buscar vendas dos últimos 90 dias para dar mais margem
        from datetime import datetime, timedelta
        end_date = datetime.now()
        start_date = end_date - timedelta(days=90)
        
        payload = {
            "start_date_sale": start_date.strftime("%Y-%m-%d"),
            "end_date_sale": end_date.strftime("%Y-%m-%d"),
            "sale_status": [2, 10]  # approved e completed
        }
        
        # Se temos transaction_token específico, usar ele
        if transaction_token:
            payload["transaction_token"] = transaction_token
            print(f"🔍 Buscando por transaction_token: {transaction_token}")
        
        print(f"🔍 Consultando Perfect Pay API...")
        print(f"📅 Período: {start_date.strftime('%Y-%m-%d')} a {end_date.strftime('%Y-%m-%d')}")
        
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.post(
                "https://app.perfectpay.com.br/api/v1/sales/get",
                headers=headers,
                json=payload
            )
            
            if response.status_code == 200:
                data = response.json()
                total_sales = data.get('sales', {}).get('total_items', 0)
                print(f"✅ Perfect Pay API - {total_sales} vendas encontradas")
                
                # Se temos filtros para aplicar
                if username or customer_email or customer_cpf:
                    filtered_sales = []
                    
                    for sale in data.get("sales", {}).get("data", []):
                        match_found = False
                        customer_data = sale.get("customer", {})
                        metadata = sale.get("metadata", {})
                        
                        # ESTRATÉGIA 1: Buscar por dados do cliente (MAIS CONFIÁVEL)
                        if customer_email and customer_data.get("email"):
                            if customer_data["email"].lower() == customer_email.lower():
                                print(f"✅ Match por email: {customer_email}")
                                match_found = True
                        
                        if customer_cpf and customer_data.get("identification_number"):
                            # Limpar formatação para comparar
                            cpf_clean = customer_cpf.replace(".", "").replace("-", "").replace("/", "")
                            cpf_sale_clean = customer_data["identification_number"].replace(".", "").replace("-", "").replace("/", "")
                            if cpf_clean == cpf_sale_clean:
                                print(f"✅ Match por CPF: {customer_cpf}")
                                match_found = True
                        
                        # ESTRATÉGIA 2: Buscar por username nos metadados (BACKUP)
                        if username and not match_found:
                            sale_username = (
                                metadata.get("username") or
                                metadata.get("utm_perfect") or
                                metadata.get("utm_content") or
                                (metadata.get("src", "").replace("user_", "") if metadata.get("src", "").startswith("user_") else None)
                            )
                            
                            if sale_username == username:
                                print(f"✅ Match por username nos metadados: {username}")
                                match_found = True
                        
                        # ESTRATÉGIA 3: Extrair @ do email para comparar com username
                        if username and not match_found and customer_data.get("email"):
                            email_username = customer_data["email"].split("@")[0]
                            if email_username.lower() == username.lower():
                                print(f"✅ Match por @ do email: {email_username} = {username}")
                                match_found = True
                        
                        if match_found:
                            filtered_sales.append(sale)
                    
                    print(f"🎯 Vendas filtradas: {len(filtered_sales)} de {total_sales}")
                    return {"sales": {"data": filtered_sales, "total_items": len(filtered_sales)}}
                
                return data
            else:
                print(f"❌ Erro na Perfect Pay API: {response.status_code} - {response.text}")
                return {"sales": {"data": [], "total_items": 0}}
                
    except Exception as e:
        print(f"❌ Erro ao consultar Perfect Pay API: {e}")
        return {"sales": {"data": [], "total_items": 0}}

async def verify_subscription_with_perfect_pay(username: str, subscription: Subscription) -> bool:
    """
    Verifica o status real da assinatura na Perfect Pay usando dados cruzados
    """
    try:
        # ESTRATÉGIA DE BUSCA EM ORDEM DE PRIORIDADE:
        
        # 1. PRIORITY: Transaction token específico (mais confiável)
        if subscription.perfect_pay_code:
            print(f"🎯 Verificando por transaction_token: {subscription.perfect_pay_code}")
            sales_data = await get_perfect_pay_sales(transaction_token=subscription.perfect_pay_code)
        else:
            # 2. DADOS DO CLIENTE (email + CPF) - MAIS CONFIÁVEL que metadados
            print(f"🔍 Verificando por dados do cliente para {username}")
            sales_data = await get_perfect_pay_sales(
                username=username,
                customer_email=subscription.perfect_pay_customer_email,
                customer_cpf=subscription.perfect_pay_customer_cpf
            )
        
        sales = sales_data.get("sales", {}).get("data", [])
        
        if not sales:
            print(f"⚠️ Nenhuma venda encontrada na Perfect Pay para {username}")
            print(f"📧 Email usado na busca: {subscription.perfect_pay_customer_email}")
            print(f"📄 CPF usado na busca: {subscription.perfect_pay_customer_cpf}")
            return False
        
        # 3. Analisar venda mais recente
        latest_sale = max(sales, key=lambda x: x.get("date_created", ""))
        sale_status = latest_sale.get("sale_status_enum", latest_sale.get("sale_status"))
        
        print(f"📊 Venda mais recente encontrada:")
        print(f"   Transaction: {latest_sale.get('code', 'N/A')}")
        print(f"   Status: {sale_status}")
        print(f"   Data: {latest_sale.get('date_created', 'N/A')}")
        print(f"   Email: {latest_sale.get('customer', {}).get('email', 'N/A')}")
        
        # 4. Verificar se ainda está ativo
        # Status 2 = approved, 10 = completed (documentação Perfect Pay)
        if sale_status in [2, 10, "approved", "completed"]:
            print(f"✅ Assinatura confirmada ATIVA na Perfect Pay para {username}")
            return True
        elif sale_status in [6, 7, 13, "cancelled", "refunded", "expired"]:
            print(f"❌ Assinatura CANCELADA/EXPIRADA na Perfect Pay para {username}")
            print(f"   Status code: {sale_status}")
            # Atualizar status local
            subscription.subscription_status = "cancelled"
            return False
        else:
            print(f"⚠️ Status DESCONHECIDO na Perfect Pay: {sale_status}")
            print(f"   Mantendo status local por segurança")
            return True  # Em caso de status desconhecido, não bloquear
            
    except Exception as e:
        print(f"❌ Erro ao verificar assinatura na Perfect Pay: {e}")
        print(f"   Mantendo status local para não bloquear usuário")
        return True  # Em caso de erro, manter status local para não bloquear usuário 