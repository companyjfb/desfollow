#!/bin/bash

echo "🔧 Corrigindo StatusResponse..."
echo "==============================="

echo "🔍 Verificando arquivo routes.py atual..."
cd backend
grep -A 10 -B 5 "class StatusResponse" app/routes.py

echo ""
echo "🔧 Atualizando StatusResponse para aceitar None..."

# Fazer backup
cp app/routes.py app/routes.py.backup

# Atualizar StatusResponse
cat > app/routes.py << 'EOF'
import os
import json
import uuid
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.database import get_db, get_or_create_user, save_scan_result, get_cached_user_data
from app.ig import get_ghosts_with_profile

router = APIRouter()

# Cache em memória para jobs (temporário)
MEM = {}

class ScanRequest(BaseModel):
    username: str = Field(..., description="Username do Instagram")

class StatusResponse(BaseModel):
    status: str = Field(..., description="Status do job")
    job_id: str = Field(..., description="ID do job")
    count: Optional[int] = Field(None, description="Número de ghosts encontrados")
    followers_count: Optional[int] = Field(None, description="Número de seguidores")
    profile_info: Optional[Dict[str, Any]] = Field(None, description="Informações do perfil")
    ghosts_data: Optional[List[Dict[str, Any]]] = Field(None, description="Dados dos ghosts")
    real_ghosts: Optional[List[Dict[str, Any]]] = Field(None, description="Ghosts reais")
    famous_ghosts: Optional[List[Dict[str, Any]]] = Field(None, description="Ghosts famosos")
    error_message: Optional[str] = Field(None, description="Mensagem de erro")

class HistoryResponse(BaseModel):
    scans: List[Dict[str, Any]] = Field(..., description="Histórico de scans")

def get_profile_info(username: str) -> Dict[str, Any]:
    """Função helper para obter informações do perfil"""
    try:
        # Aqui você pode implementar a lógica para buscar informações do perfil
        # Por enquanto, retornamos um dicionário básico
        return {
            "username": username,
            "full_name": "",
            "profile_pic_url": "",
            "biography": "",
            "is_private": False,
            "is_verified": False,
            "followers_count": 0,
            "following_count": 0,
            "posts_count": 0
        }
    except Exception as e:
        print(f"Erro ao obter informações do perfil: {e}")
        return {}

@router.post("/scan")
async def scan(request: ScanRequest, db: Session = Depends(get_db)):
    """Iniciar um novo scan"""
    try:
        username = request.username.strip()
        
        # Verificar se já existe um scan recente (últimas 24h)
        from app.database import Scan
        from datetime import datetime, timedelta
        
        recent_scan = db.query(Scan).filter(
            Scan.username == username,
            Scan.status == "done",
            Scan.updated_at >= datetime.now() - timedelta(hours=24)
        ).order_by(Scan.updated_at.desc()).limit(1).first()
        
        if recent_scan:
            print(f"✅ Scan recente encontrado para {username}")
            return {"job_id": recent_scan.job_id}
        
        # Criar novo job
        job_id = str(uuid.uuid4())
        
        # Salvar usuário no banco
        user = get_or_create_user(db, username)
        
        # Obter informações do perfil
        profile_info = get_profile_info(username)
        
        # Criar scan no banco
        scan_record = Scan(
            user_id=user.id,
            username=username,
            job_id=job_id,
            status="processing",
            profile_info=profile_info,
            created_at=datetime.now(),
            updated_at=datetime.now()
        )
        db.add(scan_record)
        db.commit()
        
        print(f"🚀 Novo scan iniciado para {username} com job_id: {job_id}")
        
        # Iniciar processamento em background
        import asyncio
        asyncio.create_task(run_scan_with_database(job_id, username, db))
        
        return {"job_id": job_id}
        
    except Exception as e:
        print(f"❌ Erro ao iniciar scan: {e}")
        raise HTTPException(status_code=500, detail=str(e))

async def run_scan_with_database(job_id: str, username: str, db: Session):
    """Executar scan com integração ao banco de dados"""
    try:
        print(f"🔍 Iniciando análise para {username}...")
        
        # Obter informações do perfil
        profile_info = get_profile_info(username)
        
        # Executar análise
        result = await get_ghosts_with_profile(username, db)
        
        # Salvar resultado no banco
        save_scan_result(db, job_id, username, result, profile_info)
        
        print(f"✅ Análise concluída para {username}")
        
    except Exception as e:
        print(f"❌ Erro na análise: {e}")
        # Salvar erro no banco
        save_scan_result(db, job_id, username, {"error": str(e)}, {})

@router.get("/scan/{job_id}")
async def status(job_id: str, db: Session = Depends(get_db)):
    """Verificar status de um job"""
    try:
        from app.database import Scan
        
        # Buscar no banco primeiro
        scan_record = db.query(Scan).filter(Scan.job_id == job_id).first()
        
        if not scan_record:
            # Fallback para cache em memória
            if job_id not in MEM:
                raise HTTPException(status_code=404, detail="Job não encontrado")
            
            job_data = MEM[job_id]
            return StatusResponse(
                status=job_data.get("status", "unknown"),
                job_id=job_id,
                count=job_data.get("count"),
                followers_count=job_data.get("followers_count"),
                profile_info=job_data.get("profile_info", {}),
                ghosts_data=job_data.get("ghosts_data", []),
                real_ghosts=job_data.get("real_ghosts", []),
                famous_ghosts=job_data.get("famous_ghosts", []),
                error_message=job_data.get("error_message")
            )
        
        # Retornar dados do banco
        return StatusResponse(
            status=scan_record.status,
            job_id=scan_record.job_id,
            count=scan_record.ghosts_count,
            followers_count=scan_record.followers_count,
            profile_info=scan_record.profile_info or {},
            ghosts_data=scan_record.ghosts_data or [],
            real_ghosts=scan_record.real_ghosts or [],
            famous_ghosts=scan_record.famous_ghosts or [],
            error_message=scan_record.error_message
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Erro ao verificar status: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/health")
async def health_check():
    """Verificar saúde da API"""
    return {
        "status": "healthy",
        "jobs_active": len(MEM)
    }

@router.get("/user/{username}/history")
async def get_user_history(username: str, db: Session = Depends(get_db)):
    """Obter histórico de scans de um usuário"""
    try:
        from app.database import Scan
        
        scans = db.query(Scan).filter(
            Scan.username == username,
            Scan.status == "done"
        ).order_by(Scan.updated_at.desc()).limit(10).all()
        
        history = []
        for scan in scans:
            history.append({
                "job_id": scan.job_id,
                "created_at": scan.created_at.isoformat(),
                "updated_at": scan.updated_at.isoformat(),
                "ghosts_count": scan.ghosts_count,
                "followers_count": scan.followers_count,
                "status": scan.status
            })
        
        return HistoryResponse(scans=history)
        
    except Exception as e:
        print(f"❌ Erro ao obter histórico: {e}")
        raise HTTPException(status_code=500, detail=str(e))
EOF

echo "✅ StatusResponse atualizado!"

echo ""
echo "🔧 Reiniciando backend..."
systemctl restart desfollow

echo ""
echo "⏳ Aguardando 5 segundos..."
sleep 5

echo ""
echo "🔍 Testando endpoint de status:"
curl -X GET https://api.desfollow.com.br/api/scan/493e4cf0-e39a-4e6d-adaf-c32c3bb77703 \
  -H "Origin: https://www.desfollow.com.br" \
  -v

echo ""
echo "✅ Correção StatusResponse concluída!" 