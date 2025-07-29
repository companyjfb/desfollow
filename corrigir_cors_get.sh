#!/bin/bash

echo "🔧 Corrigindo CORS para endpoint GET..."
echo "======================================"

echo "🔍 Verificando logs do backend..."
journalctl -u desfollow --no-pager -n 20

echo ""
echo "🔍 Testando endpoint GET especificamente..."
curl -X GET https://api.desfollow.com.br/api/scan/test-job-id \
  -H "Origin: https://www.desfollow.com.br" \
  -v

echo ""
echo "🔧 Verificando se o problema é no endpoint de status..."

# Verificar se há problemas no endpoint de status
cd backend
python3 -c "
import os
from dotenv import load_dotenv
load_dotenv()

print('🔍 Verificando endpoint de status...')
try:
    from app.routes import status
    print('✅ Endpoint status importado!')
except Exception as e:
    print(f'❌ Erro ao importar status: {e}')
    import traceback
    traceback.print_exc()

try:
    from app.database import get_db
    print('✅ Database importado!')
except Exception as e:
    print(f'❌ Erro ao importar database: {e}')
    import traceback
    traceback.print_exc()
"
cd ..

echo ""
echo "🔧 Atualizando configuração CORS para ser mais específica..."

# Atualizar main.py com CORS mais específico
cat > backend/app/main.py << 'EOF'
import os
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Carregar variáveis de ambiente
load_dotenv()

# Criar aplicação FastAPI
app = FastAPI(
    title="Desfollow API",
    description="API para análise de seguidores do Instagram",
    version="1.0.0"
)

# Configuração CORS mais específica
allowed_origins = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "http://localhost:8081",
    "http://127.0.0.1:8081",
    "http://10.102.37.150:8081",
    "http://10.102.37.150:3000",
    "http://192.168.0.187:8080",
    "http://192.168.0.187:3000",
    "http://192.168.0.187:8081",
    # Domínios de produção
    "https://desfollow.com.br",
    "https://www.desfollow.com.br",
    "http://desfollow.com.br",
    "http://www.desfollow.com.br",
    "https://api.desfollow.com.br",
    "http://api.desfollow.com.br",
    # Adicionar wildcard para desenvolvimento
    "*"
]

frontend_url = os.getenv("FRONTEND_URL")
if frontend_url:
    allowed_origins.append(frontend_url)
    allowed_origins.append(frontend_url.replace("https://", "http://"))

logger.info(f"CORS allowed origins: {allowed_origins}")

# Configuração CORS mais permissiva
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "HEAD"],
    allow_headers=["*"],
    expose_headers=["*"],
    max_age=600,
)

# Importar rotas
from app.routes import router
app.include_router(router, prefix="/api")

@app.on_event("startup")
async def startup_event():
    try:
        logger.info("Iniciando aplicação...")
        from app.database import create_tables
        create_tables()
        logger.info("Tabelas criadas com sucesso!")
    except Exception as e:
        logger.error(f"Erro ao criar tabelas: {e}")

@app.get("/")
async def root():
    return {
        "message": "Desfollow API",
        "version": "1.0.0",
        "docs": "/docs"
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "jobs_active": 0
    }

# Adicionar middleware personalizado para debug CORS
@app.middleware("http")
async def cors_debug_middleware(request, call_next):
    logger.info(f"CORS Debug: {request.method} {request.url}")
    logger.info(f"CORS Debug: Origin: {request.headers.get('origin')}")
    
    response = await call_next(request)
    
    logger.info(f"CORS Debug: Response headers: {dict(response.headers)}")
    return response
EOF

echo "✅ Configuração CORS atualizada!"

echo ""
echo "🔧 Reiniciando backend..."
systemctl restart desfollow

echo ""
echo "⏳ Aguardando 5 segundos..."
sleep 5

echo ""
echo "🔍 Testando CORS para GET:"
curl -X OPTIONS https://api.desfollow.com.br/api/scan/test-job-id \
  -H "Origin: https://www.desfollow.com.br" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -v

echo ""
echo "🔍 Testando GET real:"
curl -X GET https://api.desfollow.com.br/api/scan/test-job-id \
  -H "Origin: https://www.desfollow.com.br" \
  -v

echo ""
echo "✅ Correção CORS GET concluída!"
echo ""
echo "💡 Agora teste o frontend novamente!"
echo "💡 O CORS deve funcionar para todos os endpoints!" 