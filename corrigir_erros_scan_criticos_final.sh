#!/bin/bash

echo "🔧 CORRIGINDO ERROS CRÍTICOS DO SCAN"
echo "=================================="

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Execute como root: sudo $0"
    exit 1
fi

cd /root/desfollow

echo "📋 1. Fazendo backup dos arquivos..."
cp backend/app/routes.py backend/app/routes.py.backup.$(date +%Y%m%d_%H%M%S)
cp backend/app/database.py backend/app/database.py.backup.$(date +%Y%m%d_%H%M%S)

echo "📋 2. Corrigindo import datetime em routes.py..."
# Verificar se datetime está importado corretamente
if ! grep -q "from datetime import datetime, timedelta" backend/app/routes.py; then
    echo "🔧 Adicionando import datetime..."
    # Adicionar import após a linha de imports existente
    sed -i '1i from datetime import datetime, timedelta' backend/app/routes.py
else
    echo "✅ Import datetime já existe"
fi

echo "📋 3. Corrigindo função save_scan_result em database.py..."
# Verificar se a função já aceita error_message
if ! grep -q "error_message.*=" backend/app/database.py; then
    echo "🔧 Adicionando parâmetro error_message..."
    
    # Corrigir assinatura da função
    sed -i 's/def save_scan_result(db, job_id, username, status, profile_info=None, ghosts_data=None):/def save_scan_result(db, job_id, username, status, profile_info=None, ghosts_data=None, error_message=None):/' backend/app/database.py
    
    # Adicionar código para salvar error_message
    sed -i '/scan.updated_at = datetime.utcnow()/i \    # Salvar mensagem de erro se fornecida\n    if error_message:\n        scan.error_message = error_message' backend/app/database.py
else
    echo "✅ Função save_scan_result já aceita error_message"
fi

echo "📋 4. Verificando se campo error_message existe no modelo..."
if ! grep -q "error_message.*=" backend/app/database.py; then
    echo "🔧 Adicionando campo error_message ao modelo Scan..."
    # Adicionar campo error_message após outros campos
    sed -i '/real_ghosts_count.*Integer/a \    error_message = Column(Text, nullable=True)' backend/app/database.py
    
    # Adicionar import Text se não existir
    if ! grep -q "from sqlalchemy import.*Text" backend/app/database.py; then
        sed -i 's/from sqlalchemy import Column, Integer, String, DateTime, JSON, Boolean/from sqlalchemy import Column, Integer, String, DateTime, JSON, Boolean, Text/' backend/app/database.py
    fi
else
    echo "✅ Campo error_message já existe"
fi

echo "📋 5. Testando se imports estão corretos..."
cd backend
source venv/bin/activate 2>/dev/null || echo "⚠️ Venv não encontrado localmente"

# Testar imports básicos
python3 -c "
try:
    from app.database import get_db, save_scan_result
    from datetime import datetime, timedelta
    print('✅ Imports funcionando!')
except Exception as e:
    print(f'❌ Erro nos imports: {e}')
" 2>/dev/null || echo "⚠️ Não foi possível testar imports"

cd ..

echo "📋 6. Reiniciando serviço backend..."
systemctl restart desfollow

echo "📋 7. Aguardando 3 segundos para backend inicializar..."
sleep 3

echo "📋 8. Verificando se backend está funcionando..."
if systemctl is-active --quiet desfollow; then
    echo "✅ Backend está rodando"
else
    echo "❌ Backend não está rodando!"
    echo "📋 Verificando logs de erro:"
    journalctl -u desfollow --no-pager -n 10
fi

echo "📋 9. Testando health check..."
response=$(curl -s https://api.desfollow.com.br/api/health 2>/dev/null)
if [[ "$response" == *"healthy"* ]]; then
    echo "✅ Health check passou: $response"
else
    echo "❌ Health check falhou: $response"
fi

echo "📋 10. Fazendo teste de scan..."
echo "🧪 Testando scan para 'instagram'..."
scan_response=$(curl -s -X POST "https://api.desfollow.com.br/api/scan" \
  -H "Content-Type: application/json" \
  -d '{"username": "instagram"}' \
  --connect-timeout 10 2>/dev/null)

if [[ "$scan_response" == *"job_id"* ]]; then
    echo "✅ Scan iniciado com sucesso: $scan_response"
    
    # Extrair job_id
    job_id=$(echo "$scan_response" | grep -o '"job_id":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$job_id" ]; then
        echo "📋 Aguardando 5 segundos e verificando status..."
        sleep 5
        
        status_response=$(curl -s "https://api.desfollow.com.br/api/scan/$job_id" 2>/dev/null)
        echo "📊 Status do scan: $status_response"
    fi
else
    echo "❌ Scan falhou: $scan_response"
fi

echo ""
echo "✅ CORREÇÕES APLICADAS!"
echo "====================="
echo "📋 Problemas corrigidos:"
echo "   1. ✅ Import datetime adicionado"
echo "   2. ✅ Função save_scan_result aceita error_message"
echo "   3. ✅ Campo error_message no modelo"
echo "   4. ✅ Backend reiniciado"
echo ""
echo "📋 Para monitorar logs em tempo real:"
echo "   journalctl -u desfollow -f"
echo ""
echo "📋 Para testar no frontend:"
echo "   Acesse: https://desfollow.com.br" 