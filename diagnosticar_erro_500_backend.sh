#!/bin/bash

echo "🔍 Diagnóstico Erro 500 - Backend API"
echo "===================================="
echo ""

echo "📋 1. Verificando status dos serviços..."
echo "🔹 Nginx:"
systemctl status nginx --no-pager -l | head -10

echo ""
echo "🔹 Backend (desfollow):"
systemctl status desfollow --no-pager -l | head -10

echo ""
echo "📋 2. Verificando se API está respondendo..."
echo "🌐 Testando endpoint base:"
curl -s -w "HTTP_CODE:%{http_code}\n" https://api.desfollow.com.br || echo "❌ Falha na conexão"

echo ""
echo "🌐 Testando endpoint health:"
curl -s -w "HTTP_CODE:%{http_code}\n" https://api.desfollow.com.br/health || echo "❌ Falha na conexão"

echo ""
echo "📋 3. Verificando logs recentes do backend..."
echo "🔹 Últimas 20 linhas do log do serviço:"
journalctl -u desfollow -n 20 --no-pager

echo ""
echo "📋 4. Verificando logs do Nginx..."
echo "🔹 Últimas 10 linhas do log de erro da API:"
tail -10 /var/log/nginx/api_ssl_error.log 2>/dev/null || echo "⚠️ Log não encontrado"

echo ""
echo "🔹 Últimas 10 linhas do log de acesso da API:"
tail -10 /var/log/nginx/api_ssl_access.log 2>/dev/null || echo "⚠️ Log não encontrado"

echo ""
echo "📋 5. Testando endpoint específico que está falhando..."
echo "🔹 Tentando POST /api/scan:"
SCAN_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST https://api.desfollow.com.br/api/scan \
  -H "Content-Type: application/json" \
  -H "Origin: https://www.desfollow.com.br" \
  -d '{"username": "test"}' 2>/dev/null)
echo "Response: $SCAN_RESPONSE"

echo ""
echo "📋 6. Verificando se banco Supabase está conectado..."
echo "🔹 Verificando variáveis de ambiente:"
if [ -f "/root/desfollow/.env" ]; then
    echo "✅ Arquivo .env encontrado"
    if grep -q "DATABASE_URL" /root/desfollow/.env; then
        echo "✅ DATABASE_URL configurado"
    else
        echo "❌ DATABASE_URL não encontrado"
    fi
    if grep -q "RAPIDAPI_KEY" /root/desfollow/.env; then
        echo "✅ RAPIDAPI_KEY configurado" 
    else
        echo "❌ RAPIDAPI_KEY não encontrado"
    fi
else
    echo "❌ Arquivo .env não encontrado"
fi

echo ""
echo "📋 7. Verificando processo Python..."
ps aux | grep python | grep -v grep || echo "⚠️ Nenhum processo Python encontrado"

echo ""
echo "📋 8. Verificando porta 8000..."
netstat -tlnp | grep :8000 || echo "⚠️ Porta 8000 não está sendo escutada"

echo ""
echo "📋 9. Testando conexão direta com backend (bypass nginx)..."
DIRECT_TEST=$(curl -s -w "HTTP_CODE:%{http_code}" http://127.0.0.1:8000 2>/dev/null)
echo "Backend direto (127.0.0.1:8000): $DIRECT_TEST"

echo ""
echo "📋 10. Verificando recursos do sistema..."
echo "🔹 Memória:"
free -h | head -2

echo "🔹 Disco:"
df -h / | tail -1

echo "🔹 CPU:"
uptime

echo ""
echo "📋 RESUMO DO DIAGNÓSTICO:"
echo "========================"
echo ""
echo "🔍 PRÓXIMOS PASSOS BASEADOS NO DIAGNÓSTICO:"
echo ""
echo "Se o serviço desfollow estiver inativo:"
echo "   sudo systemctl start desfollow"
echo "   sudo systemctl status desfollow"
echo ""
echo "Se houver erro de conexão com banco:"
echo "   Verificar configuração DATABASE_URL no .env"
echo "   Testar conexão com Supabase"
echo ""
echo "Se houver erro de API externa:"
echo "   Verificar RAPIDAPI_KEY no .env"
echo "   Testar endpoints Instagram API"
echo ""
echo "Para logs em tempo real:"
echo "   journalctl -u desfollow -f"
echo ""
echo "Para reiniciar tudo:"
echo "   sudo systemctl restart desfollow"
echo "   sudo systemctl reload nginx" 