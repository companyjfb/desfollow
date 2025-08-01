#!/bin/bash

echo "🧪 Executando Teste de Paginação da API do Instagram..."

# Verificar se estamos no diretório correto
cd /root/desfollow

# Tornar script executável
chmod +x testar_paginacao_instagram.py

# Executar teste
echo "🚀 Iniciando teste..."
python3 testar_paginacao_instagram.py

# Verificar resultado
if [ -f "teste_paginacao_resultado.json" ]; then
    echo "📊 Resultado do teste:"
    cat teste_paginacao_resultado.json | jq '.' 2>/dev/null || cat teste_paginacao_resultado.json
    
    echo ""
    echo "📋 Logs do teste:"
    echo "=================="
    tail -n 50 /var/log/desfollow/limpeza_10min.log 2>/dev/null || echo "Log de limpeza não encontrado"
else
    echo "❌ Arquivo de resultado não foi criado"
fi

echo ""
echo "✅ Teste concluído!"
echo "📊 Para ver logs completos: tail -f /var/log/desfollow/limpeza_10min.log" 