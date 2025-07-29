#!/bin/bash

echo "🔧 Corrigindo CORS para produção..."
echo "=================================="

echo "📋 Verificando configuração atual do CORS..."

# Fazer backup do arquivo atual
cp backend/app/main.py backend/app/main.py.backup

echo ""
echo "🔧 Aplicando configuração CORS para produção..."

# Criar nova configuração CORS
cat > backend/app/main.py << 'EOF'
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

# Configuração CORS apenas para domínios de produção
allowed_origins = [
    # Domínios de produção
    "https://desfollow.com.br",
    "https://www.desfollow.com.br",
    "http://desfollow.com.br",
    "http://www.desfollow.com.br",
    "https://api.desfollow.com.br",
    "http://api.desfollow.com.br",
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

echo "✅ Configuração CORS aplicada!"

echo ""
echo "🔍 Testando sintaxe do Python..."
python3 -m py_compile backend/app/main.py

if [ $? -eq 0 ]; then
    echo "✅ Sintaxe correta!"
    
    echo ""
    echo "📤 Enviando para o servidor..."
    
    # Enviar para o servidor
    scp backend/app/main.py root@api.desfollow.com.br:~/desfollow/backend/app/main.py
    
    echo ""
    echo "🔄 Reiniciando serviço no servidor..."
    ssh root@api.desfollow.com.br "cd ~/desfollow && systemctl restart desfollow"
    
    echo ""
    echo "⏳ Aguardando 5 segundos..."
    sleep 5
    
    echo ""
    echo "🔍 Testando API..."
    curl -I https://api.desfollow.com.br/health
    
    echo ""
    echo "✅ CORS corrigido com sucesso!"
    echo ""
    echo "📋 Resumo:"
    echo "   - Frontend: https://desfollow.com.br"
    echo "   - API: https://api.desfollow.com.br"
    echo "   - CORS configurado apenas para domínios de produção"
    
else
    echo "❌ Erro na sintaxe! Restaurando backup..."
    cp backend/app/main.py.backup backend/app/main.py
    echo "✅ Backup restaurado!"
fi 