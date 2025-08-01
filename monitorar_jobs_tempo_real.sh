#!/bin/bash

echo "🔍 Monitor de Jobs em Tempo Real"
echo "================================="

# Função para mostrar timestamp
show_time() {
    echo -e "\n[$(date '+%H:%M:%S')] ========================================="
}

# Função para verificar jobs ativos
check_active_jobs() {
    echo "📊 Jobs Ativos:"
    
    # Verificar API
    api_response=$(curl -s http://api.desfollow.com.br/api/health 2>/dev/null)
    if [ $? -eq 0 ]; then
        jobs_active=$(echo "$api_response" | jq -r '.jobs_active // 0' 2>/dev/null || echo "0")
        echo "   API Health: $jobs_active jobs ativos"
    else
        echo "   API Health: ❌ Não respondeu"
    fi
    
    # Verificar processos Python
    python_processes=$(ps aux | grep python | grep -v grep | wc -l)
    echo "   Processos Python: $python_processes"
    
    # Verificar cache de jobs
    if [ -f "/tmp/desfollow_jobs.json" ]; then
        cache_jobs=$(jq 'length' /tmp/desfollow_jobs.json 2>/dev/null || echo "0")
        echo "   Cache jobs: $cache_jobs"
    else
        echo "   Cache jobs: Arquivo não existe"
    fi
}

# Função para verificar logs do sistema de limpeza
check_cleanup_logs() {
    echo "🧹 Sistema de Limpeza:"
    
    # Verificar status do serviço
    service_status=$(systemctl is-active desfollow-limpeza-10min.service 2>/dev/null)
    echo "   Status: $service_status"
    
    # Verificar logs recentes
    recent_logs=$(journalctl -u desfollow-limpeza-10min.service -n 3 --no-pager 2>/dev/null | tail -n 3)
    if [ ! -z "$recent_logs" ]; then
        echo "   Logs recentes:"
        echo "$recent_logs" | sed 's/^/     /'
    fi
}

# Função para verificar recursos do sistema
check_system_resources() {
    echo "💻 Recursos do Sistema:"
    
    # CPU
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo "   CPU: ${cpu_usage}%"
    
    # Memória
    memory_info=$(free -h | grep Mem | awk '{print $3 "/" $2 " (" $3/$2*100 "%)"}')
    echo "   Memória: $memory_info"
    
    # Disco
    disk_usage=$(df -h / | tail -1 | awk '{print $5}')
    echo "   Disco: $disk_usage"
}

# Função para verificar jobs no banco
check_database_jobs() {
    echo "🗄️ Jobs no Banco (últimas 24h):"
    
    # Tentar conectar ao banco e verificar jobs
    # Nota: Isso requer acesso ao banco, pode não funcionar em todos os ambientes
    echo "   (Verificação do banco requer acesso direto)"
}

# Loop principal de monitoramento
echo "🚀 Iniciando monitoramento... (Ctrl+C para parar)"
echo ""

while true; do
    show_time
    check_active_jobs
    check_cleanup_logs
    check_system_resources
    check_database_jobs
    
    echo ""
    echo "⏳ Aguardando 30 segundos..."
    sleep 30
done 