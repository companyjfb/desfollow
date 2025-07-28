#!/bin/bash

echo "🔍 Verificando logs do backend Desfollow..."
echo "=========================================="

# Verificar status do serviço
echo "📊 Status do serviço:"
systemctl status desfollow --no-pager

echo ""
echo "📋 Últimos logs do backend:"
journalctl -u desfollow --no-pager -n 50

echo ""
echo "🔍 Verificando se há erros específicos:"
journalctl -u desfollow --no-pager | grep -i "error\|exception\|traceback" | tail -10

echo ""
echo "📊 Jobs ativos na memória:"
curl -s http://localhost:8000/api/health | jq .

echo ""
echo "🔍 Testando scan com logs em tempo real:"
echo "Pressione Ctrl+C para parar o monitoramento..."

# Monitorar logs em tempo real durante um teste
journalctl -u desfollow -f &
LOG_PID=$!

# Aguardar um pouco para ver logs
sleep 2

# Fazer um teste de scan
echo "🚀 Iniciando teste de scan..."
curl -X POST http://localhost:8000/api/scan \
  -H "Content-Type: application/json" \
  -d '{"username":"instagram"}' \
  -s | jq .

# Aguardar mais um pouco para ver os logs
sleep 5

# Parar o monitoramento
kill $LOG_PID 2>/dev/null

echo ""
echo "✅ Verificação concluída!" 