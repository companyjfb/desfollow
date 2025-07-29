#!/bin/bash
echo "🔍 Verificando logs do backend..."
echo "=================================="
echo ""

echo "📋 Status do serviço desfollow:"
systemctl status desfollow --no-pager -l
echo ""

echo "📊 Logs recentes (últimas 50 linhas):"
journalctl -u desfollow --no-pager -n 50
echo ""

echo "🔍 Logs em tempo real (Ctrl+C para parar):"
echo "Pressione Ctrl+C para parar de monitorar..."
journalctl -u desfollow -f 