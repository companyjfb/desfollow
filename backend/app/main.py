from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routes import router
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

# Configuração CORS para domínios de produção (HTTP e HTTPS)
allowed_origins = [
    # Domínios de produção - HTTP
    "http://desfollow.com.br",
    "http://www.desfollow.com.br",
    "http://api.desfollow.com.br",
    # Domínios de produção - HTTPS
    "https://desfollow.com.br",
    "https://www.desfollow.com.br",
    "https://api.desfollow.com.br",
    # Wildcard temporário para resolver CORS
    "*"
]

# Adiciona domínios de produção se configurados
frontend_url = os.getenv("FRONTEND_URL")
if frontend_url:
    allowed_origins.append(frontend_url)
    allowed_origins.append(frontend_url.replace("https://", "http://"))

logger.info(f"CORS allowed origins: {allowed_origins}")

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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