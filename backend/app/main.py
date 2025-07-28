from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routes import router
from .auth_routes import router as auth_router
from .database import create_tables
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="Desfollow API",
    description="API para encontrar usuários que não retribuem follows no Instagram",
    version="1.0.0"
)

# Configuração CORS para permitir requisições do frontend
allowed_origins = [
    "http://localhost:3000", 
    "http://127.0.0.1:3000",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "http://localhost:8081",
    "http://127.0.0.1:8081",
    "http://10.102.37.150:8081",  # IP local da rede
    "http://10.102.37.150:3000",
    "http://192.168.0.187:8080",  # Novo IP
    "http://192.168.0.187:3000",
    "http://192.168.0.187:8081",
    # Domínios de produção
    "https://desfollow.com.br",
    "https://www.desfollow.com.br",
    "http://desfollow.com.br",
    "http://www.desfollow.com.br"
]

# Adiciona domínios de produção se configurados
frontend_url = os.getenv("FRONTEND_URL")
if frontend_url:
    allowed_origins.append(frontend_url)
    allowed_origins.append(frontend_url.replace("https://", "http://"))

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
    create_tables()

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