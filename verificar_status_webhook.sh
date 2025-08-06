#!/bin/bash

echo "🔍 VERIFICANDO STATUS DO WEBHOOK PERFECT PAY"
echo "==========================================="
echo ""

# 1. Verificar se a API está rodando
echo "📋 1. Verificando se API está rodando..."
curl -s -I https://api.desfollow.com.br/api/health | head -1

# 2. Verificar rotas disponíveis via OpenAPI
echo ""
echo "📋 2. Verificando rotas disponíveis..."
curl -s https://api.desfollow.com.br/openapi.json | jq -r '.paths | keys[]' | grep -i webhook || echo "❌ Nenhuma rota webhook encontrada"

# 3. Testar endpoint webhook específico com GET (deve dar 405)
echo ""
echo "📋 3. Testando endpoint webhook (deve dar 405 Method Not Allowed)..."
curl -s -I https://api.desfollow.com.br/api/webhook/perfect-pay | head -1

# 4. Verificar logs recentes do webhook
echo ""
echo "📋 4. Verificando logs recentes do webhook..."
echo "Últimas tentativas de webhook nos logs:"
journalctl -u gunicorn --since "10 minutes ago" | grep -i webhook | tail -5 || echo "❌ Nenhum log de webhook encontrado"

# 5. Verificar se gunicorn está rodando
echo ""
echo "📋 5. Verificando status do gunicorn..."
systemctl status gunicorn --no-pager | grep -E "(Active|Main PID|Memory)"

# 6. Verificar processos Python
echo ""
echo "📋 6. Verificando processos FastAPI/Gunicorn..."
ps aux | grep -E "(gunicorn|fastapi|python.*main)" | grep -v grep

# 7. Teste manual do webhook
echo ""
echo "📋 7. Testando webhook manualmente..."
curl -X POST https://api.desfollow.com.br/api/webhook/perfect-pay \
  -H "Content-Type: application/json" \
  -d '{
    "token": "test_token",
    "code": "PP_TEST_001", 
    "sale_amount": 29.0,
    "currency_enum": 1,
    "installments": 1,
    "shipping_type_enum": 1,
    "payment_method_enum": 1,
    "payment_type_enum": 1,
    "quantity": 1,
    "sale_status_enum": 2,
    "sale_status_detail": "Test",
    "date_created": "2025-01-08T10:00:00",
    "product": {"name": "Test"},
    "plan": {"name": "Test"},
    "plan_itens": [],
    "customer": {"email": "test@test.com", "full_name": "Test User"},
    "metadata": {"username": "testuser"},
    "webhook_owner": "desfollow",
    "commission": []
  }' || echo "❌ Erro ao testar webhook"

echo ""
echo "✅ VERIFICAÇÃO COMPLETA!"
echo "========================"