#!/bin/bash

echo "🔧 Correção Manual do Import datetime..."
echo "======================================="
echo ""

cd /root/desfollow

echo "🔍 1. VERIFICANDO ARQUIVO routes.py ATUAL..."

echo "📋 Primeiras 20 linhas do arquivo:"
head -20 backend/app/routes.py

echo ""
echo "🔍 2. PROCURANDO IMPORTS DE DATETIME..."

echo "📋 Imports relacionados a datetime:"
grep -n "datetime\|timedelta" backend/app/routes.py

echo ""
echo "🔍 3. ADICIONANDO IMPORT CORRETO MANUALMENTE..."

# Backup primeiro
cp backend/app/routes.py backend/app/routes.py.backup2

# Criar versão corrigida
cat > /tmp/fix_imports.py << 'EOF'
import os

# Ler o arquivo atual
with open('backend/app/routes.py', 'r') as f:
    lines = f.readlines()

# Remover qualquer import incorreto de datetime existente
cleaned_lines = []
for line in lines:
    # Pular linhas que tentam importar datetime de forma incorreta
    if 'from datetime import datetime, timedelta' in line and line.strip().startswith('from'):
        continue
    cleaned_lines.append(line)

# Encontrar onde adicionar o import (após outros imports, antes do primeiro código)
insert_index = 0
for i, line in enumerate(cleaned_lines):
    if line.strip().startswith('import ') or line.strip().startswith('from '):
        insert_index = i + 1
    elif line.strip() and not line.strip().startswith('#'):
        break

# Inserir o import correto
cleaned_lines.insert(insert_index, 'from datetime import datetime, timedelta\n')

# Salvar arquivo corrigido
with open('backend/app/routes.py', 'w') as f:
    f.writelines(cleaned_lines)

print("✅ Import adicionado na posição correta!")
EOF

python3 /tmp/fix_imports.py

echo ""
echo "🔍 4. VERIFICANDO RESULTADO..."

echo "📋 Primeiras 25 linhas após correção:"
head -25 backend/app/routes.py

echo ""
echo "📋 Todos os imports de datetime:"
grep -n "datetime\|timedelta" backend/app/routes.py

echo ""
echo "🔍 5. VERIFICANDO SE LINHA 132 AINDA TEM PROBLEMA..."

echo "📋 Linha 132 e vizinhas:"
sed -n '130,135p' backend/app/routes.py

echo ""
echo "🔍 6. REINICIANDO BACKEND..."

systemctl restart desfollow
sleep 5

if systemctl is-active --quiet desfollow; then
    echo "✅ Backend reiniciado!"
else
    echo "❌ Erro no restart!"
    systemctl status desfollow --no-pager -l
    exit 1
fi

echo ""
echo "🔍 7. TESTE RÁPIDO..."

# Teste pequeno
echo "📝 Teste rápido com instagram..."

RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{"username":"instagram"}' http://127.0.0.1:8000/api/scan)
echo "📋 Resposta: $RESPONSE"

JOB_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('job_id', 'N/A'))" 2>/dev/null)

if [ "$JOB_ID" != "N/A" ]; then
    echo "🆔 Job criado: $JOB_ID"
    echo ""
    echo "⏳ Aguardando 10 segundos..."
    sleep 10
    
    echo "🔍 Verificando se ainda dá erro de datetime..."
    journalctl -u desfollow --no-pager -n 10 | grep -E "datetime|NameError"
    
    if journalctl -u desfollow --no-pager -n 10 | grep -q "NameError.*datetime"; then
        echo "❌ AINDA TEM ERRO DE DATETIME!"
        echo ""
        echo "🔍 Vamos verificar exatamente onde está o problema..."
        
        echo "📋 Linha exata do erro:"
        grep -n "datetime.utcnow" backend/app/routes.py
        
    else
        echo "✅ ERRO DE DATETIME CORRIGIDO!"
    fi
fi

echo ""
echo "✅ VERIFICAÇÃO CONCLUÍDA!" 