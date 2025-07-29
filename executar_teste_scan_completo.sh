#!/bin/bash

echo "🧪 Executando Teste Completo do Fluxo de Scan..."
echo "================================================"
echo ""

cd /root/desfollow

# Verificar se foi fornecido um username
if [ $# -eq 0 ]; then
    echo "❌ Uso: $0 <username>"
    echo "📝 Exemplo: $0 instagram"
    echo "📝 Exemplo: $0 jordan.bitencourt"
    exit 1
fi

USERNAME="$1"

# Remover @ se presente
USERNAME=$(echo "$USERNAME" | sed 's/^@//')

echo "🎯 Username para teste: $USERNAME"
echo ""

# Verificar se o backend está rodando
echo "🔍 Verificando status do backend..."
if systemctl is-active --quiet desfollow; then
    echo "✅ Backend está rodando"
else
    echo "❌ Backend não está rodando!"
    echo "🔧 Iniciando backend..."
    systemctl start desfollow
    sleep 5
    
    if systemctl is-active --quiet desfollow; then
        echo "✅ Backend iniciado com sucesso"
    else
        echo "❌ Falha ao iniciar backend"
        echo "📋 Status do serviço:"
        systemctl status desfollow --no-pager -l
        exit 1
    fi
fi

echo ""
echo "🔍 Verificando se arquivo de teste existe..."
if [ ! -f "testar_fluxo_scan_step_by_step.py" ]; then
    echo "❌ Arquivo de teste não encontrado!"
    exit 1
fi

echo "✅ Arquivo de teste encontrado"
echo ""

# Ativar ambiente virtual se existir
if [ -d "venv" ]; then
    echo "🔧 Ativando ambiente virtual..."
    source venv/bin/activate
    echo "✅ Ambiente virtual ativado"
fi

echo ""
echo "🚀 INICIANDO TESTE STEP-BY-STEP..."
echo "=================================="
echo ""

# Executar o teste Python
python3 testar_fluxo_scan_step_by_step.py "$USERNAME"

RESULT=$?

echo ""
echo "=================================="
echo "📊 RESULTADO DO TESTE"
echo "=================================="

if [ $RESULT -eq 0 ]; then
    echo "🎉 TESTE CONCLUÍDO COM SUCESSO!"
    echo ""
    echo "✅ O sistema de scan está funcionando corretamente"
    echo "✅ Todas as etapas foram completadas"
    echo "✅ Paginação com max_id está funcionando"
    echo "✅ Classificação de ghosts está funcionando"
    echo "✅ Salvamento no banco está funcionando"
    echo ""
    echo "🎯 PRÓXIMOS PASSOS:"
    echo "   1. Testar no frontend: https://www.desfollow.com.br"
    echo "   2. Fazer scan real de um usuário"
    echo "   3. Verificar se resultados aparecem corretamente"
else
    echo "⚠️ TESTE CONCLUÍDO COM PROBLEMAS"
    echo ""
    echo "🔍 DIAGNÓSTICO:"
    echo "   - Verifique as etapas que falharam acima"
    echo "   - Analise logs do backend para erros específicos"
    echo "   - Teste APIs RapidAPI manualmente se necessário"
    echo ""
    echo "🔧 COMANDOS ÚTEIS PARA DEBUGGING:"
    echo "   journalctl -u desfollow -f"
    echo "   curl -s https://instagram-premium-api-2023.p.rapidapi.com/v1/user/web_profile_info?username=$USERNAME -H 'x-rapidapi-key: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01'"
fi

echo ""
echo "📋 Para executar teste novamente:"
echo "   ./executar_teste_scan_completo.sh $USERNAME"
echo ""
echo "📋 Para testar outro usuário:"
echo "   ./executar_teste_scan_completo.sh <outro_username>"

exit $RESULT 