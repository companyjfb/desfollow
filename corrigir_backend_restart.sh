#!/bin/bash

# ========================================
# CORREÇÃO: REINICIAR BACKEND CORRETAMENTE
# ========================================

echo "🔍 DESCOBRINDO COMO O BACKEND ESTÁ RODANDO..."
echo "=============================================="

# 1. Verificar processos Python/Gunicorn rodando
echo "📋 1. VERIFICANDO PROCESSOS PYTHON..."
echo "--------------------------------------"
echo "🔍 Processos Python rodando:"
ps aux | grep -v grep | grep python | head -10

echo ""
echo "🔍 Processos Gunicorn rodando:"
ps aux | grep -v grep | grep gunicorn | head -10

echo ""
echo "🔍 Processos na porta 8000:"
sudo lsof -i :8000

# 2. Verificar serviços systemd relacionados ao desfollow
echo ""
echo "📋 2. VERIFICANDO SERVIÇOS SYSTEMD..."
echo "--------------------------------------"
echo "🔍 Serviços relacionados ao desfollow:"
sudo systemctl list-units --all | grep -i desfollow

echo ""
echo "🔍 Serviços python/gunicorn:"
sudo systemctl list-units --all | grep -E "(python|gunicorn|fastapi)"

# 3. Verificar se há script de execução manual
echo ""
echo "📋 3. VERIFICANDO SCRIPTS DE EXECUÇÃO..."
echo "--------------------------------------"
echo "🔍 Arquivos de execução no projeto:"
ls -la /root/desfollow/ | grep -E "\.(sh|py)$" | grep -E "(run|start|launch)"

echo ""
echo "🔍 Verificando se há processos sendo executados via screen/tmux:"
screen -list 2>/dev/null || echo "Screen não está sendo usado"
tmux list-sessions 2>/dev/null || echo "Tmux não está sendo usado"

# 4. Tentar diferentes métodos de restart
echo ""
echo "📋 4. TENTANDO REINICIAR BACKEND..."
echo "--------------------------------------"

# Método 1: Matar processo e reiniciar
echo "🔄 Método 1: Killing processos Python na porta 8000..."
sudo pkill -f "python.*8000" 2>/dev/null || echo "Nenhum processo Python na porta 8000"
sudo pkill -f "gunicorn.*8000" 2>/dev/null || echo "Nenhum processo Gunicorn na porta 8000"

# Aguardar um pouco
sleep 2

# Método 2: Verificar se existe um serviço personalizado
echo ""
echo "🔄 Método 2: Procurando serviços personalizados..."
if sudo systemctl list-units --all | grep -q "desfollow"; then
    echo "✅ Encontrado serviço desfollow, reiniciando..."
    sudo systemctl restart desfollow
elif sudo systemctl list-units --all | grep -q "fastapi"; then
    echo "✅ Encontrado serviço fastapi, reiniciando..."
    sudo systemctl restart fastapi
else
    echo "⚠️ Nenhum serviço padrão encontrado"
fi

# Método 3: Executar manualmente se necessário
echo ""
echo "🔄 Método 3: Executando backend manualmente..."
cd /root/desfollow/backend

# Verificar se existe arquivo de execução específico
if [ -f "run_production.py" ]; then
    echo "✅ Encontrado run_production.py, executando..."
    nohup python3 run_production.py > /tmp/backend.log 2>&1 &
elif [ -f "main.py" ]; then
    echo "✅ Executando via uvicorn..."
    nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 --env-file env.production > /tmp/backend.log 2>&1 &
elif [ -f "app/main.py" ]; then
    echo "✅ Executando via uvicorn (pasta app)..."
    cd /root/desfollow/backend
    nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 --env-file env.production > /tmp/backend.log 2>&1 &
else
    echo "❌ Não foi possível determinar como executar o backend"
fi

# 5. Aguardar e verificar se funcionou
echo ""
echo "📋 5. VERIFICANDO SE BACKEND REINICIOU..."
echo "--------------------------------------"

sleep 3

echo "🔍 Verificando porta 8000..."
if sudo lsof -i :8000 | grep -q LISTEN; then
    echo "✅ Backend está rodando na porta 8000!"
    
    echo "🧪 Testando API..."
    if curl -s http://127.0.0.1:8000/health | grep -q "healthy"; then
        echo "✅ API está respondendo corretamente!"
    else
        echo "⚠️ API não está respondendo ao health check"
    fi
else
    echo "❌ Backend não está rodando na porta 8000"
    echo "📄 Últimas linhas do log:"
    tail -10 /tmp/backend.log 2>/dev/null || echo "Nenhum log encontrado"
fi

# 6. Continuar com o resto das correções
echo ""
echo "📋 6. CONTINUANDO CORREÇÕES..."
echo "--------------------------------------"

# Rebuildar frontend
echo "🏗️ Rebuilding frontend com correções..."
cd /root/desfollow
npm run build

echo "📂 Copiando frontend corrigido para nginx..."
sudo rm -rf /var/www/html/*
sudo cp -r /root/desfollow/dist/* /var/www/html/

echo "✅ Frontend atualizado com correções!"

# Testar novamente
echo ""
echo "📋 7. TESTE FINAL..."
echo "--------------------------------------"

echo "🧪 Executando teste de comunicação..."
python3 /root/desfollow/testar_comunicacao_frontend_backend.py

echo ""
echo "🎯 CORREÇÃO BACKEND CONCLUÍDA!"
echo "========================================"