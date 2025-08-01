#!/bin/bash

echo "🔍 Monitor de Logs do Backend"
echo "=============================="

# Função para mostrar timestamp
show_time() {
    echo -e "\n[$(date '+%H:%M:%S')] ========================================="
}

# Função para verificar logs do backend
check_backend_logs() {
    echo "🐍 Backend Logs:"
    
    # Verificar logs do gunicorn
    if [ -f "/var/log/desfollow/backend.log" ]; then
        echo "   Gunicorn (últimas 5 linhas):"
        tail -n 5 /var/log/desfollow/backend.log | sed 's/^/     /'
    else
        echo "   Gunicorn: Arquivo de log não encontrado"
    fi
    
    # Verificar logs do Python
    if [ -f "/var/log/desfollow/python.log" ]; then
        echo "   Python (últimas 5 linhas):"
        tail -n 5 /var/log/desfollow/python.log | sed 's/^/     /'
    else
        echo "   Python: Arquivo de log não encontrado"
    fi
    
    # Verificar logs do sistema de limpeza
    if [ -f "/var/log/desfollow/limpeza_10min.log" ]; then
        echo "   Limpeza (últimas 3 linhas):"
        tail -n 3 /var/log/desfollow/limpeza_10min.log | sed 's/^/     /'
    else
        echo "   Limpeza: Arquivo de log não encontrado"
    fi
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
    else
        echo "   Cache jobs: Arquivo não existe"
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
}

# Loop principal de monitoramento
echo "🚀 Iniciando monitoramento de logs... (Ctrl+C para parar)"
echo "📊 Monitorando: Backend, Jobs e Processos"
echo ""

while true; do
    show_time
    check_backend_logs
    check_active_jobs
    check_python_processes
    
    echo ""
    echo "⏳ Aguardando 5 segundos..."
    sleep 5
done 