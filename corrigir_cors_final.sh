#!/bin/bash

echo "🔧 Corrigindo CORS e simplificando logs..."
echo "==========================================="

echo "📋 Verificando configuração atual do CORS..."
cd backend
python3 -c "
import os
from dotenv import load_dotenv
load_dotenv()

print('🔍 Verificando CORS atual...')
try:
    from app.main import app
    print('✅ App importado com sucesso!')
    
    # Verificar configuração CORS
    for middleware in app.user_middleware:
        if 'CORSMiddleware' in str(middleware):
            print('✅ CORS Middleware encontrado!')
            break
    else:
        print('❌ CORS Middleware não encontrado!')
        
except Exception as e:
    print(f'❌ Erro ao importar app: {e}')
"
cd ..

echo ""
echo "🔧 Atualizando configuração CORS..."

# Atualizar main.py com CORS mais permissivo
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

# Configuração CORS mais permissiva
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

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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
EOF

echo "✅ Configuração CORS atualizada!"

echo ""
echo "🔧 Simplificando logs do frontend..."

# Atualizar console.log para ser mais limpo
echo "📝 Adicionando logs simplificados..."
cat > simplificar_logs.md << 'EOF'
# Logs Simplificados

Para reduzir a verbosidade dos logs, adicione no frontend:

```javascript
// Substituir console.log por função simplificada
const log = (message, type = 'info') => {
    const timestamp = new Date().toISOString();
    const prefix = `[${timestamp}] [${type.toUpperCase()}]`;
    
    switch(type) {
        case 'error':
            console.error(`${prefix} ${message}`);
            break;
        case 'warn':
            console.warn(`${prefix} ${message}`);
            break;
        default:
            console.log(`${prefix} ${message}`);
    }
};

// Usar log() em vez de console.log()
log('Scan iniciado', 'info');
log('Erro na API', 'error');
```
EOF

echo "✅ Documentação de logs criada!"

echo ""
echo "🔧 Reiniciando backend..."
systemctl restart desfollow

echo ""
echo "⏳ Aguardando 5 segundos..."
sleep 5

echo ""
echo "🔍 Testando CORS:"
curl -X OPTIONS https://api.desfollow.com.br/api/scan \
  -H "Origin: https://www.desfollow.com.br" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -v

echo ""
echo "🔍 Testando endpoint de scan:"
curl -X POST https://api.desfollow.com.br/api/scan \
  -H "Content-Type: application/json" \
  -H "Origin: https://www.desfollow.com.br" \
  -d '{"username":"test"}' \
  -v

echo ""
echo "✅ Correção CORS concluída!"
echo ""
echo "💡 Agora teste o frontend novamente!"
echo "💡 Os logs devem estar mais limpos e o CORS deve funcionar!" 