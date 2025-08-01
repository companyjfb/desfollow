#!/bin/bash

echo "🔍 Monitor de Scan em Tempo Real"
echo "================================="

# Função para mostrar timestamp
show_time() {
    echo -e "\n[$(date '+%H:%M:%S')] ========================================="
}

# Função para verificar logs do backend
check_backend_logs() {
    echo "🐍 Backend Logs:"
    
    # Verificar logs do gunicorn
    gunicorn_logs=$(tail -n 3 /var/log/desfollow/backend.log 2>/dev/null | tail -n 3)
    if [ ! -z "$gunicorn_logs" ]; then
        echo "   Gunicorn:"
        echo "$gunicorn_logs" | sed 's/^/     /'
    fi
    
    # Verificar logs do Python
    python_logs=$(tail -n 3 /var/log/desfollow/python.log 2>/dev/null | tail -n 3)
    if [ ! -z "$python_logs" ]; then
        echo "   Python:"
        echo "$python_logs" | sed 's/^/     /'
    fi
    
    # Verificar logs do sistema de limpeza
    cleanup_logs=$(tail -n 3 /var/log/desfollow/limpeza_10min.log 2>/dev/null | tail -n 3)
    if [ ! -z "$cleanup_logs" ]; then
        echo "   Limpeza:"
        echo "$cleanup_logs" | sed 's/^/     /'
    fi
}

# Função para verificar processos Python
check_python_processes() {
    echo "🐍 Processos Python:"
    
    # Listar processos Python relacionados ao desfollow
    desfollow_processes=$(ps aux | grep python | grep desfollow | grep -v grep)
    if [ ! -z "$desfollow_processes" ]; then
        echo "   Processos Desfollow:"
        echo "$desfollow_processes" | sed 's/^/     /'
    else
        echo "   Nenhum processo Desfollow encontrado"
    fi
    
    # Contar total de processos Python
    python_count=$(ps aux | grep python | grep -v grep | wc -l)
    echo "   Total Python: $python_count"
}

# Função para verificar jobs ativos
check_active_jobs() {
    echo "📊 Jobs Ativos:"
    
    # Verificar API health
    api_response=$(curl -s http://api.desfollow.com.br/api/health 2>/dev/null)
    if [ $? -eq 0 ]; then
        jobs_active=$(echo "$api_response" | jq -r '.jobs_active // 0' 2>/dev/null || echo "0")
        echo "   API Health: $jobs_active jobs ativos"
    else
        echo "   API Health: ❌ Não respondeu"
    fi
    
    # Verificar cache de jobs
    if [ -f "/tmp/desfollow_jobs.json" ]; then
        cache_jobs=$(jq 'length' /tmp/desfollow_jobs.json 2>/dev/null || echo "0")
        echo "   Cache jobs: $cache_jobs"
        
        # Mostrar detalhes dos jobs em cache
        if [ "$cache_jobs" -gt 0 ]; then
            echo "   Detalhes cache:"
            jq -r 'to_entries[] | "     \(.key): \(.value.status) - \(.value.start_time // "N/A")"' /tmp/desfollow_jobs.json 2>/dev/null || echo "     Erro ao ler cache"
        fi
    else
        echo "   Cache jobs: Arquivo não existe"
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

# Função para verificar serviços
check_services() {
    echo "⚙️ Serviços:"
    
    # Verificar status dos serviços
    services=("desfollow-limpeza-10min.service" "nginx" "gunicorn")
    
    for service in "${services[@]}"; do
        status=$(systemctl is-active "$service" 2>/dev/null || echo "not-found")
        echo "   $service: $status"
    done
}

# Função para verificar conexões de rede
check_network() {
    echo "🌐 Rede:"
    
    # Verificar conexões ativas
    connections=$(netstat -tuln | grep -E ":(80|443|8000)" | wc -l)
    echo "   Conexões ativas: $connections"
    
    # Verificar portas em uso
    ports=$(netstat -tuln | grep -E ":(80|443|8000)" | awk '{print $4}' | sort | uniq)
    if [ ! -z "$ports" ]; then
        echo "   Portas em uso:"
        echo "$ports" | sed 's/^/     /'
    fi
}

# Função para verificar logs de erro
check_error_logs() {
    echo "❌ Logs de Erro:"
    
    # Verificar logs de erro do nginx
    nginx_errors=$(tail -n 2 /var/log/nginx/error.log 2>/dev/null | tail -n 2)
    if [ ! -z "$nginx_errors" ]; then
        echo "   Nginx:"
        echo "$nginx_errors" | sed 's/^/     /'
    fi
    
    # Verificar logs de erro do sistema
    system_errors=$(journalctl -p err --since "5 minutes ago" --no-pager 2>/dev/null | tail -n 3)
    if [ ! -z "$system_errors" ]; then
        echo "   Sistema:"
        echo "$system_errors" | sed 's/^/     /'
    fi
}

# Loop principal de monitoramento
echo "🚀 Iniciando monitoramento em tempo real... (Ctrl+C para parar)"
echo "📊 Monitorando: Backend, Jobs, Recursos, Serviços, Rede e Erros"
echo ""

while true; do
    show_time
    check_backend_logs
    check_python_processes
    check_active_jobs
    check_system_resources
    check_services
    check_network
    check_error_logs
    
    echo ""
    echo "⏳ Aguardando 10 segundos..."
    sleep 10
done 