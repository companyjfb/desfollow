#!/bin/bash
echo "🔍 Diagnosticando problemas com rotas da API..."
echo "==============================================="
echo ""

echo "📋 1. Verificando se o backend está carregando as rotas..."
cd ~/desfollow
source venv/bin/activate

python3 -c "
import sys
sys.path.append('backend')

try:
    from app.main import app
    print('✅ App carregou corretamente')
    
    # Verificar rotas registradas
    routes = []
    for route in app.routes:
        if hasattr(route, 'path'):
            routes.append(route.path)
    
    print(f'📊 Rotas encontradas: {len(routes)}')
    for route in routes:
        print(f'   - {route}')
        
except Exception as e:
    print(f'❌ Erro ao carregar app: {e}')
"
echo ""

echo "📋 2. Verificando se o router está sendo importado..."
python3 -c "
import sys
sys.path.append('backend')

try:
    from app.routes import router
    print('✅ Router carregou corretamente')
    
    # Verificar rotas do router
    routes = []
    for route in router.routes:
        if hasattr(route, 'path'):
            routes.append(route.path)
    
    print(f'📊 Rotas do router: {len(routes)}')
    for route in routes:
        print(f'   - {route}')
        
except Exception as e:
    print(f'❌ Erro ao carregar router: {e}')
"
echo ""

echo "📋 3. Verificando se o main.py está incluindo as rotas..."
grep -n "router\|include_router" backend/app/main.py
echo ""

echo "📋 4. Testando endpoints diretamente..."
echo "📊 Testando /health:"
curl -s https://api.desfollow.com.br/health
echo ""
echo ""

echo "📊 Testando /scan (POST):"
curl -s -X POST https://api.desfollow.com.br/scan \
  -H "Content-Type: application/json" \
  -d '{"username": "test"}' \
  -w "\nStatus: %{http_code}\n"
echo ""
echo ""

echo "📊 Testando /scan/{job_id} (GET):"
curl -s https://api.desfollow.com.br/scan/test-job-id \
  -w "\nStatus: %{http_code}\n"
echo ""
echo ""

echo "📋 5. Verificando logs do backend..."
echo "📊 Últimos logs:"
journalctl -u desfollow --no-pager -n 10
echo ""

echo "📋 6. Verificando se o gunicorn está carregando corretamente..."
cd ~/desfollow
if [ -f "gunicorn.conf.py" ]; then
    echo "📊 Configuração do gunicorn:"
    cat gunicorn.conf.py
else
    echo "❌ gunicorn.conf.py não encontrado"
fi
echo ""

echo "📋 7. Verificando se o backend está rodando na porta correta..."
netstat -tlnp | grep :8000 || echo "❌ Backend não está na porta 8000"
echo ""

echo "📋 8. Testando backend localmente..."
curl -s http://localhost:8000/health || echo "❌ Backend local não responde"
echo ""

echo "📋 9. Verificando se há problemas de import..."
python3 -c "
import sys
sys.path.append('backend')

try:
    print('📊 Testando imports...')
    from app.database import get_db
    print('✅ database.py importado')
    
    from app.ig import get_user_id_from_rapidapi
    print('✅ ig.py importado')
    
    from app.routes import router
    print('✅ routes.py importado')
    
    print('✅ Todos os imports funcionando')
    
except Exception as e:
    print(f'❌ Erro nos imports: {e}')
"
echo ""

echo "✅ Diagnóstico concluído!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Se rotas não carregarem, verificar imports"
echo "   2. Se backend não responder, reiniciar serviço"
echo "   3. Se gunicorn falhar, verificar configuração" 