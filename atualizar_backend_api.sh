#!/bin/bash

echo "🔧 Atualizando backend com correções da API..."
echo "=============================================="

echo "📥 Fazendo pull das correções..."
cd ~/desfollow
git pull

echo ""
echo "🔄 Reiniciando o serviço desfollow..."
systemctl restart desfollow

echo ""
echo "⏳ Aguardando 3 segundos para o serviço inicializar..."
sleep 3

echo ""
echo "📋 Verificando status do serviço..."
systemctl status desfollow --no-pager -l

echo ""
echo "📊 Verificando logs recentes..."
journalctl -u desfollow --no-pager -n 20

echo ""
echo "✅ Backend atualizado!"
echo ""
echo "🧪 Teste o scan agora:"
echo "   - Acesse: https://desfollow.com.br"
echo "   - Digite um username do Instagram"
echo "   - Deve mostrar dados reais (não simulados)"
echo ""
echo "📋 Para monitorar logs em tempo real:"
echo "   journalctl -u desfollow -f" 