#!/bin/bash

echo "🧪 === TESTE SCAN PAGINAÇÃO CORRIGIDA ==="

# Verificar se o backend está rodando
echo "📊 Verificando status do backend..."
if ! curl -s http://localhost:8000/health > /dev/null; then
    echo "❌ Backend não está respondendo. Iniciando..."
    sudo systemctl start desfollow-backend
    sleep 5
fi

# Testar scan completo
echo "🚀 Testando scan completo com paginação corrigida..."
echo "📊 Usando usuário de teste: johndoe"

# Fazer requisição de scan
echo "📡 Fazendo requisição de scan..."
curl -X POST "http://localhost:8000/scan" \
  -H "Content-Type: application/json" \
  -d '{"username": "johndoe"}' \
  -w "\nStatus: %{http_code}\nTempo: %{time_total}s\n" \
  -o /tmp/scan_response.json

# Verificar resposta
if [ $? -eq 0 ]; then
    echo "✅ Requisição enviada com sucesso"
    echo "📄 Resposta do scan:"
    cat /tmp/scan_response.json | jq '.' 2>/dev/null || cat /tmp/scan_response.json
else
    echo "❌ Erro na requisição"
fi

# Monitorar logs do backend
echo "📊 Monitorando logs do backend..."
echo "🔍 Últimas 20 linhas dos logs:"
sudo journalctl -u desfollow-backend -n 20 --no-pager

echo "✅ TESTE CONCLUÍDO!"
echo "📊 Verifique os logs acima para ver se a paginação está funcionando corretamente" 