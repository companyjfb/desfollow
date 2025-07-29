#!/bin/bash

echo "🔧 Verificando e iniciando PostgreSQL..."
echo "======================================"

echo "📋 Verificando status do PostgreSQL..."
systemctl status postgresql --no-pager

echo ""
echo "🔧 Tentando iniciar PostgreSQL..."
systemctl start postgresql

echo ""
echo "⏳ Aguardando 5 segundos..."
sleep 5

echo ""
echo "📋 Verificando se PostgreSQL está rodando..."
if systemctl is-active --quiet postgresql; then
    echo "✅ PostgreSQL está rodando!"
    
    echo ""
    echo "🔍 Testando conexão com o banco..."
    sudo -u postgres psql -d desfollow -c "SELECT version();" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Conexão com banco OK!"
        
        echo ""
        echo "🔧 Agora executando limpeza de jobs..."
        ./limpar_jobs_ativos.sh
        
    else
        echo "❌ Erro na conexão com o banco!"
        echo "🔧 Verificando se o banco existe..."
        sudo -u postgres psql -l | grep desfollow
        
        echo ""
        echo "🔧 Criando banco se não existir..."
        sudo -u postgres createdb desfollow 2>/dev/null || echo "Banco já existe"
        
        echo ""
        echo "🔍 Testando conexão novamente..."
        sudo -u postgres psql -d desfollow -c "SELECT version();"
        
        if [ $? -eq 0 ]; then
            echo "✅ Conexão OK! Executando limpeza..."
            ./limpar_jobs_ativos.sh
        else
            echo "❌ Ainda não conseguiu conectar ao banco!"
        fi
    fi
    
else
    echo "❌ PostgreSQL não conseguiu iniciar!"
    echo "🔧 Verificando logs..."
    journalctl -u postgresql --no-pager -n 20
    
    echo ""
    echo "🔧 Tentando instalar PostgreSQL se necessário..."
    apt update
    apt install -y postgresql postgresql-contrib
    
    echo ""
    echo "🔧 Iniciando PostgreSQL novamente..."
    systemctl start postgresql
    systemctl enable postgresql
    
    echo ""
    echo "⏳ Aguardando 10 segundos..."
    sleep 10
    
    if systemctl is-active --quiet postgresql; then
        echo "✅ PostgreSQL iniciado com sucesso!"
        echo "🔧 Agora execute: ./limpar_jobs_ativos.sh"
    else
        echo "❌ Ainda não conseguiu iniciar PostgreSQL!"
    fi
fi 