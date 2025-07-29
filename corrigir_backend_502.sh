#!/bin/bash
echo "🔧 Corrigindo erro 502 do backend..."
echo "===================================="
echo ""

echo "📋 1. Verificando logs do backend..."
journalctl -u desfollow --no-pager -n 20
echo ""

echo "📋 2. Verificando sintaxe do Python..."
cd ~/desfollow
python3 -m py_compile backend/app/routes.py
if [ $? -eq 0 ]; then
    echo "✅ Sintaxe do routes.py está correta"
else
    echo "❌ Erro de sintaxe no routes.py"
    exit 1
fi
echo ""

echo "📋 3. Verificando imports..."
python3 -c "
try:
    from backend.app.routes import router
    print('✅ Imports do routes.py funcionando')
except Exception as e:
    print(f'❌ Erro nos imports: {e}')
    exit(1)
"
echo ""

echo "📋 4. Verificando dependências..."
python3 -c "
try:
    from typing import Optional, List, Dict, Any
    from pydantic import BaseModel, Field
    print('✅ Dependências funcionando')
except Exception as e:
    print(f'❌ Erro nas dependências: {e}')
    exit(1)
"
echo ""

echo "📋 5. Testando aplicação..."
python3 -c "
try:
    from backend.app.main import app
    print('✅ Aplicação carrega corretamente')
except Exception as e:
    print(f'❌ Erro ao carregar aplicação: {e}')
    exit(1)
"
echo ""

echo "📋 6. Reiniciando backend..."
systemctl restart desfollow
echo ""

echo "⏳ Aguardando 10 segundos..."
sleep 10
echo ""

echo "📋 7. Verificando status..."
systemctl status desfollow --no-pager -l
echo ""

echo "📋 8. Testando conectividade..."
echo "📊 Health check local:"
curl -s http://localhost:8000/health 2>/dev/null || echo "❌ Backend local não responde"
echo ""

echo "📊 Health check via Nginx:"
curl -s https://api.desfollow.com.br/health 2>/dev/null || echo "❌ Nginx não responde"
echo ""

echo "📋 9. Se ainda falhar, verificar arquivo de configuração..."
if ! systemctl is-active --quiet desfollow; then
    echo "❌ Backend ainda falhando, verificando configuração..."
    cat ~/desfollow/gunicorn.conf.py
    echo ""
    echo "📋 Verificando se o arquivo main.py existe..."
    ls -la ~/desfollow/backend/app/
    echo ""
    echo "📋 Tentando iniciar manualmente..."
    cd ~/desfollow
    source venv/bin/activate
    python3 -c "from backend.app.main import app; print('✅ App carrega')"
fi
echo ""

echo "✅ Diagnóstico concluído!"
echo ""
echo "📋 Se o backend ainda falhar:"
echo "   journalctl -u desfollow -f"
echo "   cd ~/desfollow && source venv/bin/activate && python3 -m backend.app.main" 