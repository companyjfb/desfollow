#!/bin/bash

echo "🔄 ATUALIZAÇÃO E DEPLOY AUTOMÁTICO"
echo "=================================="

# Definir diretórios
BACKEND_DIR="/root/desfollow"

# Verificar se estamos no diretório correto
if [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ Diretório $BACKEND_DIR não encontrado!"
    exit 1
fi

# Ir para o diretório do backend
cd $BACKEND_DIR

echo "📋 1. Fazendo git pull..."
git pull origin main

echo ""
echo "📋 2. Executando deploy..."
# Executar o script de deploy que agora está no repositório
if [ -f "deploy_definitivo.sh" ]; then
    chmod +x deploy_definitivo.sh
    ./deploy_definitivo.sh
else
    echo "❌ Script deploy_definitivo.sh não encontrado!"
    echo "   Certifique-se de que foi commitado no repositório"
    exit 1
fi