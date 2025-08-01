#!/bin/bash

echo "🧪 Testando Sistema de Limpeza 10 Minutos..."

# Verificar se o serviço está rodando
echo "📊 Verificando status do serviço..."
sudo systemctl status desfollow-limpeza-10min.service --no-pager

# Verificar logs recentes
echo "📋 Logs recentes do sistema de limpeza:"
sudo journalctl -u desfollow-limpeza-10min.service -n 20 --no-pager

# Verificar logs do arquivo
echo "📄 Logs do arquivo de limpeza:"
sudo tail -n 20 /var/log/desfollow/limpeza_10min.log 2>/dev/null || echo "Arquivo de log ainda não criado"

# Verificar jobs ativos na API
echo "🔍 Verificando jobs ativos na API..."
curl -s http://api.desfollow.com.br/api/health | jq '.' 2>/dev/null || echo "API não respondeu"

# Verificar processos Python
echo "🐍 Verificando processos Python:"
ps aux | grep python | grep -v grep

# Verificar uso de recursos
echo "💾 Verificando uso de recursos:"
free -h
echo "🖥️ CPU:"
top -bn1 | grep "Cpu(s)"

# Verificar jobs no banco
echo "🗄️ Verificando jobs no banco (últimas 24h):"
echo "SELECT status, COUNT(*) FROM scans WHERE created_at >= NOW() - INTERVAL '1 day' GROUP BY status;"

# Testar execução manual
echo "🧪 Testando execução manual do script..."
cd /root/desfollow
timeout 30 python3 sistema_limpeza_10_minutos.py &
PID=$!
sleep 5
kill $PID 2>/dev/null || true

echo "✅ Teste concluído!"
echo "📊 Para monitoramento contínuo:"
echo "   sudo journalctl -u desfollow-limpeza-10min.service -f"
echo "   tail -f /var/log/desfollow/limpeza_10min.log" 