#!/bin/bash

# Script de Deploy Completo para Desfollow
# Frontend: Hostinger
# Backend: VPS Hostinger
# Database: Supabase

echo "🚀 Iniciando deploy do Desfollow..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERRO] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[AVISO] $1${NC}"
}

# Verifica se está no diretório correto
if [ ! -f "package.json" ]; then
    error "Execute este script na raiz do projeto Desfollow"
    exit 1
fi

log "📋 Verificando pré-requisitos..."

# Verifica se Node.js está instalado
if ! command -v node &> /dev/null; then
    error "Node.js não encontrado. Instale o Node.js primeiro."
    exit 1
fi

# Verifica se Python está instalado
if ! command -v python3 &> /dev/null; then
    error "Python 3 não encontrado. Instale o Python 3 primeiro."
    exit 1
fi

log "✅ Pré-requisitos verificados"

# ============================================================================
# FRONTEND BUILD
# ============================================================================

log "🔨 Construindo frontend..."

# Instala dependências
npm install

# Build para produção
npm run build

if [ $? -eq 0 ]; then
    log "✅ Frontend construído com sucesso"
else
    error "❌ Erro ao construir frontend"
    exit 1
fi

# ============================================================================
# BACKEND PREPARATION
# ============================================================================

log "🔧 Preparando backend..."

# Vai para o diretório do backend
cd backend

# Instala dependências Python
pip install -r requirements.txt

# Verifica se o arquivo .env existe
if [ ! -f ".env" ]; then
    warning "⚠️ Arquivo .env não encontrado. Copiando exemplo..."
    cp env.example .env
    warning "📝 Configure as variáveis de ambiente no arquivo .env"
fi

# Volta para o diretório raiz
cd ..

# ============================================================================
# DOCKER BUILD (OPCIONAL)
# ============================================================================

if command -v docker &> /dev/null; then
    log "🐳 Construindo imagem Docker..."
    
    cd backend
    docker build -t desfollow-backend .
    
    if [ $? -eq 0 ]; then
        log "✅ Imagem Docker construída com sucesso"
    else
        warning "⚠️ Erro ao construir imagem Docker"
    fi
    
    cd ..
else
    warning "⚠️ Docker não encontrado. Pulando build Docker."
fi

# ============================================================================
# DEPLOY INSTRUCTIONS
# ============================================================================

log "📋 Instruções de Deploy:"

echo ""
echo "🎯 FRONTEND (Hostinger):"
echo "1. Faça upload da pasta 'dist' para o seu domínio"
echo "2. Configure o domínio no painel da Hostinger"
echo "3. Configure HTTPS no painel da Hostinger"
echo ""

echo "🔧 BACKEND (VPS Hostinger):"
echo "1. Conecte via SSH ao seu VPS"
echo "2. Clone o repositório: git clone <seu-repo>"
echo "3. Configure as variáveis de ambiente:"
echo "   - DATABASE_URL (Supabase)"
echo "   - RAPIDAPI_KEY"
echo "   - SECRET_KEY"
echo "   - FRONTEND_URL"
echo "4. Execute: pip install -r requirements.txt"
echo "5. Execute: gunicorn app.main:app -c gunicorn.conf.py"
echo ""

echo "🗄️ BANCO DE DADOS (Supabase):"
echo "1. Crie um projeto no Supabase"
echo "2. Configure as tabelas (users, scans, payments)"
echo "3. Obtenha a URL de conexão"
echo "4. Configure no arquivo .env"
echo ""

echo "🔐 CONFIGURAÇÕES DE SEGURANÇA:"
echo "1. Gere uma SECRET_KEY forte"
echo "2. Configure HTTPS no frontend"
echo "3. Configure firewall no VPS"
echo "4. Configure rate limiting"
echo ""

log "✅ Script de deploy concluído!"
echo ""
echo "📚 Próximos passos:"
echo "1. Configure as variáveis de ambiente"
echo "2. Deploy no Hostinger (frontend)"
echo "3. Deploy no VPS (backend)"
echo "4. Configure o banco Supabase"
echo "5. Teste a aplicação" 