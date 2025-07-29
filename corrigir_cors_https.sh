#!/bin/bash
echo "🔧 Corrigindo CORS para HTTPS..."
echo "================================="
echo ""

echo "📋 Verificando configuração atual do CORS..."
grep -A 10 "allowed_origins" ~/desfollow/backend/app/main.py
echo ""

echo "🔧 Atualizando configuração do CORS..."
cat > /tmp/cors_fix.py << 'EOF'
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
    # Wildcard para desenvolvimento (remover em produção)
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
    try:
        logger.info("Iniciando aplicação...")
        create_tables()
        logger.info("Tabelas criadas com sucesso!")
    except Exception as e:
        logger.error(f"Erro ao criar tabelas: {e}")

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
EOF

echo "✅ Configuração CORS atualizada!"
echo ""

echo "🔄 Reiniciando backend..."
systemctl restart desfollow
echo ""

echo "⏳ Aguardando 5 segundos para o serviço inicializar..."
sleep 5
echo ""

echo "📋 Verificando status do backend..."
systemctl status desfollow --no-pager -l
echo ""

echo "🧪 Testando CORS..."
echo "📊 Testando requisição OPTIONS..."
curl -X OPTIONS "https://api.desfollow.com.br/api/scan" \
  -H "Origin: https://desfollow.com.br" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -v 2>&1 | grep -E "(Access-Control|HTTP/)"
echo ""

echo "📊 Testando health check..."
curl -s "https://api.desfollow.com.br/health"
echo ""

echo "✅ CORS corrigido!"
echo ""
echo "🧪 Teste agora:"
echo "   - https://desfollow.com.br"
echo "   - Digite um username do Instagram"
echo "   - Deve funcionar sem erro de CORS"
echo ""
echo "📋 Para verificar logs em tempo real:"
echo "   journalctl -u desfollow -f" 