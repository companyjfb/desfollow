#!/bin/bash

echo "🔧 REINICIANDO BACKEND COM CORS CORRIGIDO - DESFOLLOW"
echo "===================================================="

# Parar backend atual
echo "📋 1. Parando backend atual..."
sudo pkill -f "python.*main.py" 2>/dev/null || echo "Backend não estava rodando"
sudo pkill -f "uvicorn" 2>/dev/null || echo "Uvicorn não estava rodando"
sudo pkill -f "gunicorn" 2>/dev/null || echo "Gunicorn não estava rodando"

# Aguardar
sleep 3

# Verificar se o backend foi parado
echo "📋 2. Verificando processos..."
if pgrep -f "python.*main.py" > /dev/null; then
    echo "⚠️ Backend ainda está rodando, forçando parada..."
    sudo pkill -9 -f "python.*main.py"
    sleep 2
fi

# Navegar para o diretório do backend
echo "📋 3. Navegando para diretório do backend..."
cd /root/desfollow/backend

# Verificar se existe requirements.txt e instalar dependências
if [ -f "requirements.txt" ]; then
    echo "📋 4. Verificando dependências..."
    if ! python -c "from fastapi.middleware.cors import CORSMiddleware" 2>/dev/null; then
        echo "Instalando dependências..."
        pip install -r requirements.txt
    else
        echo "✅ Dependências já instaladas"
    fi
else
    echo "⚠️ requirements.txt não encontrado"
fi

# Verificar se main.py existe
if [ -f "app/main.py" ]; then
    echo "✅ main.py encontrado"
    
    # Verificar se CORS foi adicionado
    if grep -q "CORSMiddleware" app/main.py; then
        echo "✅ CORS encontrado no código"
        
        # Mostrar configuração CORS
        echo "📋 Configuração CORS:"
        grep -A 6 "add_middleware" app/main.py
        
    else
        echo "❌ CORS não encontrado no código"
        exit 1
    fi
    
else
    echo "❌ main.py não encontrado"
    exit 1
fi

# Iniciar backend
echo "📋 5. Iniciando backend..."

# Verificar se gunicorn.conf.py existe
if [ -f "gunicorn.conf.py" ]; then
    echo "Usando gunicorn..."
    nohup gunicorn -c gunicorn.conf.py app.main:app > /root/desfollow/backend.log 2>&1 &
    BACKEND_PID=$!
else
    echo "Usando uvicorn..."
    nohup python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 > /root/desfollow/backend.log 2>&1 &
    BACKEND_PID=$!
fi

echo "Backend iniciado com PID: $BACKEND_PID"

# Aguardar backend inicializar
echo "📋 6. Aguardando backend inicializar..."
sleep 5

# Verificar se backend está rodando
if kill -0 $BACKEND_PID 2>/dev/null; then
    echo "✅ Backend está rodando"
    
    # Testar endpoint
    echo "📋 7. Testando backend..."
    
    # Teste simples
    echo "Teste health check:"
    curl -s http://127.0.0.1:8000/health | head -1 || echo "Erro no teste local"
    
    # Teste CORS
    echo ""
    echo "Teste CORS (OPTIONS):"
    curl -X OPTIONS \
         -H "Origin: https://www.desfollow.com.br" \
         -H "Access-Control-Request-Method: POST" \
         -H "Access-Control-Request-Headers: Content-Type" \
         -v \
         http://127.0.0.1:8000/api/scan 2>&1 | grep -i "access-control\|< HTTP"
    
    echo ""
    echo "✅ BACKEND REINICIADO COM CORS!"
    echo "=============================="
    echo "🔗 Backend local: http://127.0.0.1:8000"
    echo "🔗 API externa: https://api.desfollow.com.br"
    echo ""
    echo "📱 CORS CONFIGURADO:"
    echo "• allow_origins: ['*'] (todas as origens)"
    echo "• allow_credentials: True"
    echo "• allow_methods: ['*'] (todos os métodos)"
    echo "• allow_headers: ['*'] (todos os headers)"
    echo ""
    echo "Agora teste o scan no frontend!"
    
else
    echo "❌ Erro ao iniciar backend"
    echo "📋 Verificando logs..."
    tail -20 /root/desfollow/backend.log
fi

# Voltar para diretório original
cd /root/desfollow