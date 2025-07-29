#!/bin/bash

echo "🔧 Corrigindo Erros Críticos do Sistema de Scan..."
echo "================================================"
echo ""

cd /root/desfollow

echo "🔍 1. CORRIGINDO IMPORT DE DATETIME em routes.py..."

# Backup do arquivo original
cp backend/app/routes.py backend/app/routes.py.backup

# Adicionar import de datetime no início do arquivo
python3 << 'EOF'
import re

# Ler o arquivo
with open('backend/app/routes.py', 'r') as f:
    content = f.read()

# Verificar se datetime já está importado
if 'from datetime import datetime, timedelta' not in content:
    # Adicionar import após as outras importações
    lines = content.split('\n')
    import_lines = []
    other_lines = []
    imports_ended = False
    
    for line in lines:
        if line.strip().startswith('import ') or line.strip().startswith('from '):
            if not imports_ended:
                import_lines.append(line)
            else:
                other_lines.append(line)
        else:
            if not imports_ended:
                imports_ended = True
            other_lines.append(line)
    
    # Adicionar o import necessário
    import_lines.append('from datetime import datetime, timedelta')
    
    # Recompor o conteúdo
    new_content = '\n'.join(import_lines) + '\n' + '\n'.join(other_lines)
    
    # Salvar arquivo corrigido
    with open('backend/app/routes.py', 'w') as f:
        f.write(new_content)
    
    print("✅ Import de datetime adicionado!")
else:
    print("ℹ️ Import de datetime já existe")
EOF

echo ""
echo "🔍 2. CORRIGINDO FUNÇÃO save_scan_result em database.py..."

# Backup do arquivo original
cp backend/app/database.py backend/app/database.py.backup

# Adicionar suporte para error_message na função save_scan_result
python3 << 'EOF'
# Ler o arquivo
with open('backend/app/database.py', 'r') as f:
    content = f.read()

# Encontrar e modificar a função save_scan_result
import re

# Padrão para encontrar a definição da função
pattern = r'def save_scan_result\(db, job_id, username, status, profile_info=None, ghosts_data=None\):'
replacement = 'def save_scan_result(db, job_id, username, status, profile_info=None, ghosts_data=None, error_message=None):'

content = re.sub(pattern, replacement, content)

# Adicionar lógica para salvar error_message na função
# Encontrar onde scan.updated_at é definido e adicionar error_message antes
pattern = r'(    scan\.updated_at = datetime\.utcnow\(\))'
replacement = r'    # Salvar mensagem de erro se fornecida\n    if error_message:\n        scan.error_message = error_message\n    \n\1'

content = re.sub(pattern, replacement, content)

# Salvar arquivo corrigido
with open('backend/app/database.py', 'w') as f:
    f.write(content)

print("✅ Função save_scan_result corrigida para aceitar error_message!")
EOF

echo ""
echo "🔍 3. VERIFICANDO IMPORTS NO ARQUIVO database.py..."

# Verificar se datetime está importado em database.py
if ! grep -q "from datetime import datetime" backend/app/database.py; then
    echo "⚠️ Adicionando import de datetime em database.py..."
    
    python3 << 'EOF'
# Ler o arquivo
with open('backend/app/database.py', 'r') as f:
    content = f.read()

# Adicionar import se não existir
if 'from datetime import datetime' not in content:
    lines = content.split('\n')
    import_lines = []
    other_lines = []
    imports_ended = False
    
    for line in lines:
        if line.strip().startswith('import ') or line.strip().startswith('from '):
            if not imports_ended:
                import_lines.append(line)
            else:
                other_lines.append(line)
        else:
            if not imports_ended:
                imports_ended = True
            other_lines.append(line)
    
    # Adicionar o import necessário
    import_lines.append('from datetime import datetime')
    
    # Recompor o conteúdo
    new_content = '\n'.join(import_lines) + '\n' + '\n'.join(other_lines)
    
    # Salvar arquivo corrigido
    with open('backend/app/database.py', 'w') as f:
        f.write(new_content)
    
    print("✅ Import de datetime adicionado em database.py!")
EOF
else
    echo "ℹ️ Import de datetime já existe em database.py"
fi

echo ""
echo "🔍 4. REINICIANDO BACKEND PARA APLICAR CORREÇÕES..."

systemctl restart desfollow
sleep 5

if systemctl is-active --quiet desfollow; then
    echo "✅ Backend reiniciado com sucesso!"
else
    echo "❌ Erro ao reiniciar backend!"
    echo "📋 Status:"
    systemctl status desfollow --no-pager -l
    exit 1
fi

echo ""
echo "🔍 5. TESTANDO SCAN APÓS CORREÇÃO..."

# Testar um scan
echo "📝 Testando scan para 'instagram'..."

SCAN_RESPONSE=$(curl -s -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"instagram"}' \
  http://127.0.0.1:8000/api/scan)

HTTP_CODE="${SCAN_RESPONSE: -3}"
RESPONSE_BODY="${SCAN_RESPONSE%???}"

echo "📊 Status Code: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Endpoint respondeu!"
    
    # Extrair job_id
    JOB_ID=$(echo "$RESPONSE_BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('job_id', 'N/A'))" 2>/dev/null)
    echo "🆔 Job ID: $JOB_ID"
    
    if [ "$JOB_ID" != "N/A" ]; then
        echo ""
        echo "⏳ Aguardando 15 segundos para processamento..."
        sleep 15
        
        echo "🔍 Verificando status final..."
        STATUS_RESPONSE=$(curl -s http://127.0.0.1:8000/api/scan/$JOB_ID)
        echo "📋 Status:"
        echo "$STATUS_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$STATUS_RESPONSE"
        
        # Verificar se tem profile_info agora
        PROFILE_INFO=$(echo "$STATUS_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print('SIM' if data.get('profile_info') else 'NÃO')" 2>/dev/null)
        echo ""
        if [ "$PROFILE_INFO" = "SIM" ]; then
            echo "🎉 SUCESSO! Profile info foi obtido corretamente!"
        else
            echo "⚠️ Profile info ainda está null - verificar logs:"
            echo "   journalctl -u desfollow -f"
        fi
    fi
else
    echo "❌ Erro no endpoint: $HTTP_CODE"
fi

echo ""
echo "🔍 6. VERIFICANDO LOGS PÓS-CORREÇÃO..."

echo "📋 Logs mais recentes (últimas 20 linhas):"
journalctl -u desfollow --no-pager -n 20

echo ""
echo "✅ CORREÇÃO CONCLUÍDA!"
echo ""
echo "📊 RESUMO DAS CORREÇÕES:"
echo "   1. ✅ Adicionado import: 'from datetime import datetime, timedelta' em routes.py"
echo "   2. ✅ Corrigida função save_scan_result() para aceitar error_message"
echo "   3. ✅ Verificado import de datetime em database.py"
echo "   4. ✅ Backend reiniciado"
echo ""
echo "🎯 PRÓXIMOS PASSOS:"
echo "   - Se profile_info ainda for null, verificar logs em tempo real"
echo "   - Testar scan manual no frontend"
echo "   - Monitorar se dados estão sendo salvos no banco" 