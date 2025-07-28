#!/bin/bash

# Script para verificar e corrigir serviços do Desfollow (Versão Rápida)

echo "🔍 Verificando serviços do Desfollow (Rápido)..."

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
    sleep 2
    
    if systemctl is-active --quiet desfollow; then
        log "✅ Backend iniciado com sucesso"
    else
        error "❌ Falha ao iniciar backend"
        log "📋 Últimos logs do backend:"
        journalctl -u desfollow --no-pager -n 10
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
        log "📋 Últimos logs do Nginx:"
        journalctl -u nginx --no-pager -n 10
    fi
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
systemctl status nginx --no-pager -l | head -20
echo ""
systemctl status desfollow --no-pager -l | head -20

log "🔧 Comandos úteis para debug:"
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
echo "Para testar API (com timeout):"
echo "timeout 5 curl -I http://api.desfollow.com.br/health"
echo ""
echo "Para testar frontend (com timeout):"
echo "timeout 5 curl -I http://desfollow.com.br"
echo ""
echo "Para verificar se a porta 8000 está aberta:"
echo "netstat -tlnp | grep :8000"
echo ""
echo "Para verificar se o processo está rodando:"
echo "ps aux | grep gunicorn"
echo ""
echo "Para reiniciar tudo:"
echo "systemctl restart nginx desfollow && sleep 3 && systemctl status nginx desfollow" 