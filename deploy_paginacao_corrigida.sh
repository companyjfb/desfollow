#!/bin/bash

echo "🚀 === DEPLOY PAGINAÇÃO CORRIGIDA ==="
echo "📊 Implementando lógica correta de paginação:"
echo "   1. Buscar todos os followers até terminar"
echo "   2. Buscar todos os following até terminar"
echo "   3. Analisar ghosts e finalizar scan"

# Parar o backend atual
echo "🛑 Parando backend atual..."
sudo systemctl stop desfollow-backend

# Fazer backup do arquivo atual
echo "💾 Fazendo backup do arquivo ig.py..."
sudo cp /root/desfollow/backend/app/ig.py /root/desfollow/backend/app/ig.py.backup.$(date +%Y%m%d_%H%M%S)

# Copiar arquivo corrigido
echo "📝 Copiando arquivo corrigido..."
sudo cp /root/desfollow/backend/app/ig.py /root/desfollow/backend/app/ig.py.corrigido

# Verificar se o arquivo foi copiado corretamente
if [ -f "/root/desfollow/backend/app/ig.py.corrigido" ]; then
    echo "✅ Arquivo corrigido copiado com sucesso"
else
    echo "❌ Erro ao copiar arquivo corrigido"
    exit 1
fi

# Reiniciar o backend
echo "🔄 Reiniciando backend..."
sudo systemctl start desfollow-backend

# Verificar status
echo "📊 Verificando status do backend..."
sleep 3
sudo systemctl status desfollow-backend --no-pager

# Testar conectividade
echo "🧪 Testando conectividade da API..."
curl -s http://localhost:8000/health || echo "❌ API não está respondendo"

echo "✅ DEPLOY CONCLUÍDO!"
echo "📊 Agora o scan deve:"
echo "   1. Buscar TODOS os followers até não ter mais pagination_token"
echo "   2. Buscar TODOS os following até não ter mais pagination_token"
echo "   3. Analisar os ghosts e mostrar resultados reais" 