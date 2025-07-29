#!/bin/bash

echo "🧪 Testando Sistema de Limpeza 3 Minutos..."
echo "============================================"
echo ""

# Função para exibir timestamp
timestamp() {
    date "+%H:%M:%S"
}

# Função para verificar jobs ativos
check_jobs() {
    local jobs=$(curl -s http://api.desfollow.com.br/health 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('jobs_active', 'erro'))" 2>/dev/null)
    echo "$jobs"
}

echo "📋 1. Verificando status inicial..."
echo "⏰ $(timestamp) - Verificando API health..."

INITIAL_JOBS=$(check_jobs)
if [ "$INITIAL_JOBS" = "erro" ]; then
    echo "❌ Erro ao conectar com a API!"
    echo "🔧 Verifique se o backend está rodando:"
    echo "   systemctl status desfollow"
    exit 1
else
    echo "✅ API respondendo: $INITIAL_JOBS jobs ativos"
fi

echo ""
echo "📋 2. Verificando se serviço de limpeza está rodando..."
if systemctl is-active --quiet desfollow-limpeza-3min; then
    echo "✅ Serviço de limpeza está ativo"
else
    echo "❌ Serviço de limpeza NÃO está rodando!"
    echo "🔧 Para iniciar: systemctl start desfollow-limpeza-3min"
    exit 1
fi

echo ""
echo "📋 3. Verificando logs recentes do serviço..."
echo "📄 Últimas 3 linhas do log:"
journalctl -u desfollow-limpeza-3min --no-pager -n 3 | grep -v "^-- "
echo ""

echo "📋 4. Monitoramento em tempo real (60 segundos)..."
echo "⏱️ Observando jobs_active por 1 minuto..."
echo ""

for i in {1..12}; do
    current_time=$(timestamp)
    current_jobs=$(check_jobs)
    
    if [ "$current_jobs" = "erro" ]; then
        echo "❌ $current_time - Erro na API"
    else
        echo "📊 $current_time - Jobs ativos: $current_jobs"
        
        # Se houver muitos jobs, destacar
        if [ "$current_jobs" -gt 5 ]; then
            echo "⚠️  ATENÇÃO: Muitos jobs ativos ($current_jobs)!"
        fi
    fi
    
    # Não aguardar na última iteração
    if [ $i -lt 12 ]; then
        sleep 5
    fi
done

echo ""
echo "📋 5. Verificando se houve limpezas recentes..."
echo "📄 Procurando por atividade de limpeza nos logs:"

# Verificar se há atividade de limpeza nos últimos 2 minutos
CLEANUP_ACTIVITY=$(journalctl -u desfollow-limpeza-3min --since "2 minutes ago" --no-pager | grep -E "(Limpeza|jobs órfãos|Cache limpo)" | wc -l)

if [ $CLEANUP_ACTIVITY -gt 0 ]; then
    echo "✅ Sistema de limpeza está ativo ($CLEANUP_ACTIVITY atividades detectadas)"
    echo "📄 Atividades recentes:"
    journalctl -u desfollow-limpeza-3min --since "2 minutes ago" --no-pager | grep -E "(Limpeza|jobs órfãos|Cache limpo)" | tail -3
else
    echo "ℹ️ Nenhuma atividade de limpeza detectada (isso é normal se não há jobs órfãos)"
fi

echo ""
echo "📋 6. Verificando arquivos do sistema..."

# Verificar arquivo de cache
if [ -f "/tmp/desfollow_jobs.json" ]; then
    cache_size=$(stat -c%s "/tmp/desfollow_jobs.json" 2>/dev/null || echo "0")
    echo "✅ Cache de jobs existe (${cache_size} bytes)"
    
    # Mostrar conteúdo do cache se for pequeno
    if [ $cache_size -lt 1000 ]; then
        echo "📄 Conteúdo do cache:"
        cat /tmp/desfollow_jobs.json | python3 -m json.tool 2>/dev/null || echo "   (cache vazio ou inválido)"
    fi
else
    echo "ℹ️ Cache de jobs não existe (normal se não há jobs ativos)"
fi

# Verificar arquivo de log
if [ -f "/var/log/desfollow/limpeza_3min.log" ]; then
    log_size=$(stat -c%s "/var/log/desfollow/limpeza_3min.log" 2>/dev/null || echo "0")
    echo "✅ Log do sistema existe (${log_size} bytes)"
else
    echo "⚠️ Log do sistema não encontrado"
fi

echo ""
echo "📋 7. Resumo do teste..."

FINAL_JOBS=$(check_jobs)
echo "📊 Jobs no início: $INITIAL_JOBS"
echo "📊 Jobs no final: $FINAL_JOBS"

if [ "$FINAL_JOBS" = "erro" ]; then
    echo "❌ TESTE FALHOU: Problema de conectividade com API"
    exit 1
elif [ "$FINAL_JOBS" -le 5 ]; then
    echo "✅ TESTE PASSOU: Sistema mantém jobs baixos ($FINAL_JOBS ≤ 5)"
elif [ "$FINAL_JOBS" -le 10 ]; then
    echo "⚠️ TESTE PARCIAL: Jobs um pouco altos ($FINAL_JOBS), mas aceitável"
else
    echo "❌ TESTE FALHOU: Muitos jobs ativos ($FINAL_JOBS > 10)"
    echo "🔧 Possíveis soluções:"
    echo "   - Reiniciar serviço: systemctl restart desfollow-limpeza-3min"
    echo "   - Verificar logs: journalctl -u desfollow-limpeza-3min -f"
    echo "   - Limpeza manual: ./limpar_jobs_rapido.sh"
fi

echo ""
echo "✅ TESTE CONCLUÍDO!"
echo ""
echo "📋 Para monitoramento contínuo:"
echo "   journalctl -u desfollow-limpeza-3min -f"
echo "   watch -n 5 'curl -s http://api.desfollow.com.br/health | python3 -m json.tool'" 