#!/bin/bash
echo "🔧 Corrigindo erro de import..."
echo "================================"
echo ""

echo "📋 1. Verificando arquivo routes.py..."
cd ~/desfollow
grep -n "from typing import" backend/app/routes.py
echo ""

echo "📋 2. Verificando se Field está sendo importado do typing..."
grep -n "Field" backend/app/routes.py
echo ""

echo "📋 3. Corrigindo import se necessário..."
# Verificar se há import incorreto do Field
if grep -q "from typing import.*Field" backend/app/routes.py; then
    echo "❌ Encontrado import incorreto do Field"
    # Corrigir o import
    sed -i 's/from typing import \(.*\), Field/from typing import \1/' backend/app/routes.py
    echo "✅ Import corrigido!"
else
    echo "✅ Imports estão corretos"
fi
echo ""

echo "📋 4. Verificando se o virtualenv está ativo..."
if [ -z "$VIRTUAL_ENV" ]; then
    echo "❌ Virtualenv não está ativo"
    source ~/desfollow/venv/bin/activate
    echo "✅ Virtualenv ativado"
else
    echo "✅ Virtualenv já está ativo"
fi
echo ""

echo "📋 5. Verificando dependências..."
pip list | grep -E "(fastapi|pydantic|sqlalchemy)"
echo ""

echo "📋 6. Testando import manualmente..."
python3 -c "
try:
    from backend.app.routes import router
    print('✅ Import do routes.py funcionando')
except Exception as e:
    print(f'❌ Erro no import: {e}')
    exit(1)
"
echo ""

echo "📋 7. Reiniciando backend..."
systemctl restart desfollow
echo ""

echo "⏳ Aguardando 5 segundos..."
sleep 5
echo ""

echo "📋 8. Verificando status..."
systemctl status desfollow --no-pager -l
echo ""

echo "📋 9. Testando API..."
curl -s http://localhost:8000/health 2>/dev/null || echo "❌ Backend ainda não responde"
echo ""

echo "✅ Correção concluída!" 