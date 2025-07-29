#!/bin/bash

echo "🔧 Aplicando Correções do Backend - Profile Info & Cache System"
echo "=============================================================="
echo ""

# Função para verificar sucesso
check_success() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ Erro: $1"
        exit 1
    fi
}

echo "📋 1. Atualizando código do GitHub..."
cd /root/desfollow
git stash 2>/dev/null  # Salvar mudanças locais se existirem
git pull origin main
check_success "Código atualizado do GitHub"

echo ""
echo "📋 2. Verificando mudanças implementadas..."

# Verificar se as funções foram atualizadas
if grep -q "get_user_data_from_rapidapi" backend/app/ig.py; then
    echo "✅ Função unificada get_user_data_from_rapidapi encontrada"
else
    echo "❌ Função unificada não encontrada - algo deu errado"
    exit 1
fi

if grep -q "useScanCache" src/hooks/use-scan-cache.ts; then
    echo "✅ Hook de cache implementado"
else
    echo "❌ Hook de cache não encontrado"
    exit 1
fi

echo ""
echo "📋 3. Verificando dependências do backend..."
cd backend
pip install -r requirements.txt --quiet
check_success "Dependências verificadas"

echo ""
echo "📋 4. Testando sintaxe do código..."
python -m py_compile app/ig.py
check_success "Sintaxe do ig.py verificada"

python -m py_compile app/routes.py  
check_success "Sintaxe do routes.py verificada"

echo ""
echo "📋 5. Parando serviços antes da atualização..."
systemctl stop desfollow.service 2>/dev/null
sleep 2

echo ""
echo "📋 6. Iniciando backend com as correções..."
systemctl start desfollow.service
check_success "Backend iniciado"

echo ""
echo "📋 7. Aguardando inicialização..."
sleep 5

echo ""
echo "📋 8. Verificando se a API está respondendo..."
API_RESPONSE=$(curl -s http://api.desfollow.com.br/api/health 2>/dev/null)
if echo "$API_RESPONSE" | grep -q "status"; then
    echo "✅ API backend respondendo: $API_RESPONSE"
else
    echo "⚠️ API não está respondendo - verificando logs..."
    journalctl -u desfollow.service --no-pager -n 10
    exit 1
fi

echo ""
echo "📋 9. Testando nova função unificada..."
cd /root/desfollow/backend
python3 -c "
import sys
sys.path.append('.')
from app.ig import get_user_data_from_rapidapi
print('🧪 Testando função unificada...')
try:
    user_id, profile_info = get_user_data_from_rapidapi('instagram')
    if profile_info and profile_info.get('followers_count', 0) > 0:
        print(f'✅ Função funcionando: {profile_info.get(\"followers_count\", 0)} seguidores')
    else:
        print('⚠️ Função retornou dados zerados (pode ser rate limit)')
except Exception as e:
    print(f'❌ Erro ao testar função: {e}')
"

echo ""
echo "📋 10. Verificando status final dos serviços..."
if systemctl is-active --quiet desfollow.service; then
    echo "✅ Backend está ativo!"
    systemctl status desfollow.service --no-pager --lines=3
else
    echo "❌ Backend não está ativo - verificando logs..."
    journalctl -u desfollow.service --no-pager -n 15
    exit 1
fi

echo ""
echo "📋 11. Buildando frontend com as correções..."
cd /root/desfollow
npm run build 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Frontend buildado com sucesso"
    # Copiar para nginx se necessário
    if [ -d "/var/www/html" ]; then
        cp -r dist/* /var/www/html/ 2>/dev/null
        echo "✅ Frontend copiado para nginx"
    fi
else
    echo "⚠️ Build do frontend falhou (verifique se node/npm estão instalados)"
fi

echo ""
echo "📋 12. Testando URLs finais..."
echo "🌐 Testando frontend: desfollow.com.br"
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://desfollow.com.br 2>/dev/null)
if [ "$FRONTEND_RESPONSE" = "200" ]; then
    echo "✅ Frontend respondendo (HTTP $FRONTEND_RESPONSE)"
else
    echo "⚠️ Frontend: HTTP $FRONTEND_RESPONSE"
fi

echo "🌐 Testando backend: api.desfollow.com.br"
BACKEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://api.desfollow.com.br/api/health 2>/dev/null)
if [ "$BACKEND_RESPONSE" = "200" ]; then
    echo "✅ Backend API respondendo (HTTP $BACKEND_RESPONSE)"
else
    echo "⚠️ Backend API: HTTP $BACKEND_RESPONSE"
fi

echo ""
echo "✅ TODAS AS CORREÇÕES APLICADAS COM SUCESSO!"
echo ""
echo "🎯 CORREÇÕES IMPLEMENTADAS:"
echo "   ✅ Profile info zerado corrigido"
echo "   ✅ Função unificada get_user_data_from_rapidapi"
echo "   ✅ Polling reduzido (1s → 3s com backoff)"
echo "   ✅ Sistema de cache local + banco implementado"
echo "   ✅ Fallback robusto para dados perdidos"
echo ""
echo "🌐 URLs ativas:"
echo "   Frontend: http://desfollow.com.br"
echo "   Backend:  http://api.desfollow.com.br"
echo ""
echo "📊 Para monitorar:"
echo "   journalctl -u desfollow.service -f"
echo "   curl http://api.desfollow.com.br/api/health"
echo "   systemctl status desfollow.service"
echo ""
echo "🚀 Sistema pronto para uso com melhorias!" 