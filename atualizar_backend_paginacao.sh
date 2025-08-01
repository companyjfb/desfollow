#!/bin/bash
echo "🔥 Aplicando correções críticas de paginação no backend..."
echo "=========================================================="

echo ""
echo "📋 1. Atualizando código no servidor..."
ssh root@144.22.209.79 "cd /var/www/desfollow && git pull origin main"

echo ""
echo "📋 2. Verificando mudanças aplicadas..."
ssh root@144.22.209.79 "cd /var/www/desfollow && git log --oneline -1"

echo ""
echo "📋 3. Reiniciando serviço desfollow..."
ssh root@144.22.209.79 "systemctl restart desfollow && sleep 3"

echo ""
echo "📋 4. Verificando status do serviço..."
ssh root@144.22.209.79 "systemctl status desfollow --no-pager -l"

echo ""
echo "📋 5. Verificando logs em tempo real..."
echo "📊 Últimas 10 linhas dos logs:"
ssh root@144.22.209.79 "journalctl -u desfollow --no-pager -n 10"

echo ""
echo "🚀 Atualização concluída!"
echo ""
echo "📌 Para testar a nova paginação:"
echo "   curl -X POST https://api.desfollow.com.br/api/scan -H \"Content-Type: application/json\" -d '{\"username\": \"instagram\"}'"
echo ""
echo "📌 Para monitorar logs em tempo real:"
echo "   ssh root@144.22.209.79 'journalctl -u desfollow -f'"