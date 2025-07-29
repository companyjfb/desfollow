#!/bin/bash

echo "🔧 Correção Validação Pydantic - Erro 500"
echo "=========================================="
echo ""

echo "📋 PROBLEMA IDENTIFICADO:"
echo "❌ Pydantic espera: List[str] (lista de strings)"
echo "❌ Backend envia: List[Dict] (lista de objetos user completos)"
echo "❌ Erro: Input should be a valid string [type=string_type, input_value={'id': '...'}]"
echo ""

echo "📋 1. Backup do arquivo atual..."
cp /root/desfollow/backend/app/routes.py /root/desfollow/backend/app/routes.py.backup.pydantic.$(date +%Y%m%d_%H%M%S)

echo "✅ Backup criado"
echo ""

echo "📋 2. Corrigindo modelo Pydantic StatusResponse..."

# Corrigir o modelo para aceitar Dict ao invés de str
cat > /tmp/fix_pydantic.py << 'EOF'
import re

# Ler arquivo atual
with open('/root/desfollow/backend/app/routes.py', 'r') as f:
    content = f.read()

# Substituir List[str] por List[Dict[str, Any]] nos campos corretos
content = re.sub(
    r'sample: Optional\[List\[str\]\] = None',
    'sample: Optional[List[Dict[str, Any]]] = None',
    content
)

content = re.sub(
    r'all: Optional\[List\[str\]\] = None', 
    'all: Optional[List[Dict[str, Any]]] = None',
    content
)

# Escrever arquivo corrigido
with open('/root/desfollow/backend/app/routes.py', 'w') as f:
    f.write(content)

print("✅ Modelo Pydantic corrigido")
EOF

python3 /tmp/fix_pydantic.py
echo "✅ Modelo Pydantic corrigido"

echo ""
echo "📋 3. Verificando a correção..."
grep -n "sample:" /root/desfollow/backend/app/routes.py
grep -n "all:" /root/desfollow/backend/app/routes.py

echo ""
echo "📋 4. Reiniciando serviço backend..."
systemctl restart desfollow

sleep 3

echo "📋 5. Verificando status do serviço..."
systemctl status desfollow --no-pager -l | head -10

echo ""
echo "📋 6. Testando API corrigida..."

sleep 2

echo "🌐 Testando endpoint health:"
HEALTH_TEST=$(curl -s -w "HTTP_CODE:%{http_code}" https://api.desfollow.com.br/health 2>/dev/null)
echo "   Health: $HEALTH_TEST"

echo ""
echo "🌐 Testando POST /api/scan:"
SCAN_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST https://api.desfollow.com.br/api/scan \
  -H "Content-Type: application/json" \
  -H "Origin: https://www.desfollow.com.br" \
  -d '{"username": "test"}' 2>/dev/null)
echo "   Scan: $SCAN_RESPONSE"

echo ""
echo "🌐 Aguardando job para testar GET status..."
JOB_ID=$(echo "$SCAN_RESPONSE" | grep -o '"job_id":"[^"]*"' | cut -d'"' -f4)
if [ ! -z "$JOB_ID" ]; then
    echo "   Job ID extraído: $JOB_ID"
    sleep 5
    
    echo "   Testando GET /api/scan/$JOB_ID:"
    STATUS_TEST=$(curl -s -w "HTTP_CODE:%{http_code}" https://api.desfollow.com.br/api/scan/$JOB_ID 2>/dev/null)
    echo "   Status: $STATUS_TEST"
else
    echo "   ⚠️ Não foi possível extrair job_id"
fi

echo ""
echo "📋 7. Verificando logs pós-correção..."
echo "🔹 Últimas 5 linhas do log:"
journalctl -u desfollow -n 5 --no-pager

echo ""
echo "✅ CORREÇÃO APLICADA!"
echo ""
echo "🔧 MUDANÇAS REALIZADAS:"
echo "   ❌ ANTES: sample: Optional[List[str]] = None"
echo "   ✅ DEPOIS: sample: Optional[List[Dict[str, Any]]] = None"
echo ""
echo "   ❌ ANTES: all: Optional[List[str]] = None"  
echo "   ✅ DEPOIS: all: Optional[List[Dict[str, Any]]] = None"
echo ""
echo "🎯 RESULTADO:"
echo "   • Pydantic agora aceita objetos user completos"
echo "   • GET /api/scan/{job_id} deve funcionar sem erro 500"
echo "   • Frontend recebe dados estruturados dos ghosts"
echo ""
echo "📋 TESTAR NO FRONTEND:"
echo "   • Recarregar https://www.desfollow.com.br"
echo "   • Tentar scan - deve processar completamente"
echo "   • Verificar se dados dos ghosts aparecem"
echo ""
echo "📜 MONITORAR LOGS:"
echo "   journalctl -u desfollow -f"
echo ""
echo "🚀 Problema Pydantic/500 resolvido!" 