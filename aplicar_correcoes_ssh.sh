#!/bin/bash

echo "🔧 Aplicando Correções do Sistema de Limpeza 3 Minutos..."
echo "========================================================"
echo ""

# Função para verificar sucesso
check_success() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ Erro: $1"
        exit 1
    fi
}

echo "📋 1. Atualizando código do GitHub..."
cd /root/desfollow
git pull origin main
check_success "Código atualizado"

echo ""
echo "📋 2. Testando URL correta da API..."
API_RESPONSE=$(curl -s http://api.desfollow.com.br/api/health 2>/dev/null)
if echo "$API_RESPONSE" | grep -q "jobs_active"; then
    echo "✅ API respondeu corretamente: $API_RESPONSE"
else
    echo "⚠️ API response: $API_RESPONSE"
fi

echo ""
echo "📋 3. Criando arquivo de serviço corrigido..."

# Criar novo arquivo de serviço
cat > /etc/systemd/system/desfollow-limpeza-3min.service << 'EOF'
[Unit]
Description=Desfollow Limpeza Automática 3 Minutos
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/desfollow
ExecStart=/usr/bin/python3 /root/desfollow/sistema_limpeza_3_minutos.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

check_success "Arquivo de serviço criado"

echo ""
echo "📋 4. Aplicando configurações do systemd..."

# Parar serviço se estiver rodando
systemctl stop desfollow-limpeza-3min 2>/dev/null

# Recarregar systemd
systemctl daemon-reload
check_success "Daemon recarregado"

# Habilitar serviço
systemctl enable desfollow-limpeza-3min
check_success "Serviço habilitado"

echo ""
echo "📋 5. Testando script antes de iniciar..."

# Testar script diretamente
timeout 10s python3 /root/desfollow/sistema_limpeza_3_minutos.py &
SCRIPT_PID=$!
sleep 3
kill $SCRIPT_PID 2>/dev/null
wait $SCRIPT_PID 2>/dev/null

if [ $? -eq 0 ] || [ $? -eq 143 ]; then  # 143 = SIGTERM (normal)
    echo "✅ Script funciona corretamente"
else
    echo "❌ Script tem problemas - verificando erro..."
    python3 /root/desfollow/sistema_limpeza_3_minutos.py &
    sleep 2
    kill %1 2>/dev/null
fi

echo ""
echo "📋 6. Iniciando serviço..."
systemctl start desfollow-limpeza-3min
check_success "Serviço iniciado"

echo ""
echo "📋 7. Aguardando inicialização..."
sleep 5

echo ""
echo "📋 8. Verificando status final..."
if systemctl is-active --quiet desfollow-limpeza-3min; then
    echo "✅ Serviço está ativo e funcionando!"
    systemctl status desfollow-limpeza-3min --no-pager --lines=3
else
    echo "❌ Serviço ainda não está ativo - verificando logs..."
    journalctl -u desfollow-limpeza-3min --no-pager -n 10
    exit 1
fi

echo ""
echo "📋 9. Testando monitoramento..."
API_JOBS=$(curl -s http://api.desfollow.com.br/api/health 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('jobs_active', 'erro'))" 2>/dev/null)

if [ "$API_JOBS" != "erro" ]; then
    echo "✅ Sistema funcionando: $API_JOBS jobs ativos"
else
    echo "⚠️ Não foi possível verificar jobs ativos"
fi

echo ""
echo "✅ TODAS AS CORREÇÕES APLICADAS COM SUCESSO!"
echo ""
echo "📊 Para monitorar:"
echo "   journalctl -u desfollow-limpeza-3min -f"
echo "   watch -n 3 'curl -s http://api.desfollow.com.br/api/health | python3 -m json.tool'"
echo ""
echo "📋 Sistema configurado para:"
echo "   - Limpar jobs running > 3 minutos"
echo "   - Limpar jobs queued > 2 minutos"
echo "   - Verificar a cada 30 segundos"
echo "   - Limpeza forçada se jobs > 5" 