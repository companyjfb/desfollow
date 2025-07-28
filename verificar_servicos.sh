#!/bin/bash

# Script para verificar e corrigir serviços do Desfollow

echo "🔍 Verificando serviços do Desfollow..."

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

# Verifica se está rodando como root
if [ "$EUID" -ne 0 ]; then
    error "Execute este script como root (sudo)"
    exit 1
fi

log "📊 Verificando status dos serviços..."

# Verificar se o backend está rodando
if systemctl is-active --quiet desfollow; then
    log "✅ Backend está rodando"
else
    error "❌ Backend não está rodando"
    log "🚀 Iniciando backend..."
    systemctl start desfollow
    sleep 3
    
    if systemctl is-active --quiet desfollow; then
        log "✅ Backend iniciado com sucesso"
    else
        error "❌ Falha ao iniciar backend"
        systemctl status desfollow
    fi
fi

# Verificar se o Nginx está rodando
if systemctl is-active --quiet nginx; then
    log "✅ Nginx está rodando"
else
    error "❌ Nginx não está rodando"
    log "🚀 Iniciando Nginx..."
    systemctl start nginx
    sleep 2
    
    if systemctl is-active --quiet nginx; then
        log "✅ Nginx iniciado com sucesso"
    else
        error "❌ Falha ao iniciar Nginx"
        systemctl status nginx
    fi
fi

log "🔍 Testando conectividade..."

# Testar se o backend está respondendo localmente
if curl -s http://localhost:8000/ > /dev/null 2>&1; then
    log "✅ Backend está respondendo localmente"
else
    error "❌ Backend não está respondendo localmente"
    log "📋 Verificando logs do backend..."
    journalctl -u desfollow --no-pager -n 20
fi

# Testar se o Nginx está respondendo
if curl -s http://localhost/ > /dev/null 2>&1; then
    log "✅ Nginx está respondendo localmente"
else
    error "❌ Nginx não está respondendo localmente"
fi

log "🌐 Testando domínios..."

# Testar API
if curl -s -I http://api.desfollow.com.br/health > /dev/null 2>&1; then
    log "✅ API está respondendo"
else
    error "❌ API não está respondendo"
fi

# Testar frontend
if curl -s -I http://desfollow.com.br > /dev/null 2>&1; then
    log "✅ Frontend está respondendo"
else
    error "❌ Frontend não está respondendo"
fi

log "📋 Verificando configuração do Nginx..."

# Verificar se a configuração está correta
nginx -t

if [ $? -eq 0 ]; then
    log "✅ Configuração do Nginx válida"
else
    error "❌ Erro na configuração do Nginx"
fi

log "📊 Status dos serviços:"
echo ""
systemctl status nginx --no-pager -l
echo ""
systemctl status desfollow --no-pager -l

log "🔧 Comandos úteis:"
echo ""
echo "Para ver logs do Nginx:"
echo "tail -f /var/log/nginx/desfollow_api_error.log"
echo ""
echo "Para ver logs do backend:"
echo "journalctl -u desfollow -f"
echo ""
echo "Para reiniciar serviços:"
echo "systemctl restart nginx desfollow"
echo ""
echo "Para testar API:"
echo "curl -I http://api.desfollow.com.br/health"
echo ""
echo "Para testar frontend:"
echo "curl -I http://desfollow.com.br" 