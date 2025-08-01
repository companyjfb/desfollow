#!/bin/bash

echo "🎯 APLICANDO SIMULAÇÃO DE VALORES NO SERVIDOR"
echo "=============================================="
echo ""
echo "📋 1. Fazendo git pull das mudanças..."
ssh root@144.22.209.79 "cd /root/desfollow && git pull origin main"

echo ""
echo "📋 2. Verificando últimas mudanças aplicadas..."
ssh root@144.22.209.79 "cd /root/desfollow && git log --oneline -2"

echo ""
echo "📋 3. Buildando frontend com novas simulações..."
ssh root@144.22.209.79 "cd /root/desfollow && npm run build"

echo ""
echo "📋 4. Movendo frontend para pasta de produção..."
ssh root@144.22.209.79 "cp -r /root/desfollow/dist/* /var/www/desfollow/"

echo ""
echo "📋 5. Reiniciando backend..."
ssh root@144.22.209.79 "systemctl restart desfollow"

echo ""
echo "📋 6. Verificando status do serviço..."
ssh root@144.22.209.79 "systemctl status desfollow --no-pager -l"

echo ""
echo "🎯 SIMULAÇÃO APLICADA COM SUCESSO!"
echo ""
echo "📊 Mudanças implementadas:"
echo "   ✅ Backend: 22 -> 126 parasitas (~5.7x)"
echo "   ✅ Frontend: 24 -> 242 parasitas (~10.1x)"
echo "   ✅ Cards reais mantidos intactos"
echo ""
echo "🔗 Teste em: https://desfollow.com.br"