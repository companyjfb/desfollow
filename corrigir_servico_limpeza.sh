#!/bin/bash

echo "🔧 Corrigindo serviço de limpeza automática..."
echo "=============================================="

echo "🛑 Parando serviço atual..."
systemctl stop desfollow-limpeza

echo "🗑️ Removendo serviço antigo..."
rm -f /etc/systemd/system/desfollow-limpeza.service

echo "📋 Criando diretório de logs..."
mkdir -p /var/log/desfollow
chmod 755 /var/log/desfollow

echo "🔧 Instalando serviço simplificado..."
cp desfollow-limpeza-simples.service /etc/systemd/system/desfollow-limpeza.service

echo "🔄 Recarregando systemd..."
systemctl daemon-reload

echo "🚀 Iniciando serviço..."
systemctl enable desfollow-limpeza
systemctl start desfollow-limpeza

echo ""
echo "📋 Verificando status..."
systemctl status desfollow-limpeza --no-pager

echo ""
echo "🔍 Verificando logs..."
journalctl -u desfollow-limpeza --no-pager -n 5

echo ""
echo "✅ Serviço corrigido!"
echo ""
echo "📋 Para monitorar:"
echo "   journalctl -u desfollow-limpeza -f"
echo "   tail -f /var/log/desfollow/limpeza_automatica.log" 