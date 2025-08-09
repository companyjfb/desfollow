from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routes import router
from .routes import perfect_pay_webhook as perfect_pay_webhook_handler  # alias para reuso
from .routes import PerfectPayWebhookData
from .database import get_db
from sqlalchemy.orm import Session
from fastapi import Depends
from .auth_routes import router as auth_router
from .database import create_tables
import os
from dotenv import load_dotenv
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

app = FastAPI(
    title="Desfollow API",
    description="API para encontrar usuários que não retribuem follows no Instagram",
    version="1.0.0"
)

# Configuração CORS - PERMITIR TUDO
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permite todas as origens
    allow_credentials=True,
    allow_methods=["*"],  # Permite todos os métodos (GET, POST, OPTIONS, etc.)
    allow_headers=["*"],  # Permite todos os headers
)

# Inclui as rotas
app.include_router(router, prefix="/api")
app.include_router(auth_router, prefix="/api/auth", tags=["authentication"])

# Criar tabelas na inicialização
@app.on_event("startup")
async def startup_event():
    """Evento executado na inicialização da aplicação"""
    try:
        logger.info("🚀 Iniciando aplicação...")
        logger.info("📊 Criando/verificando tabelas no Supabase...")
        create_tables()
        logger.info("✅ Tabelas verificadas/criadas no Supabase!")
        logger.info("🎯 Aplicação pronta para receber requisições!")
    except Exception as e:
        logger.error(f"❌ Erro na inicialização: {e}")
        raise

@app.get("/")
async def root():
    """
    Endpoint raiz da API.
    """
    return {
        "message": "Desfollow API",
        "version": "1.0.0",
        "docs": "/docs"
    }

@app.get("/health")
async def health_check():
    """
    Endpoint de health check.
    """
    return {"status": "healthy"} 

# Alias sem prefixo para compatibilidade com URLs antigas de webhook
@app.post("/webhook/perfect-pay")
async def perfect_pay_webhook_alias(
    webhook_data: PerfectPayWebhookData,
    db: Session = Depends(get_db)
):
    return await perfect_pay_webhook_handler(webhook_data, db)