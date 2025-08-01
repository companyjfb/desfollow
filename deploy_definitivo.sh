#!/bin/bash
set -e

echo "🚀 DEPLOY AUTOMÁTICO DESFOLLOW"
echo "================================"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

# Função para verificar se comando existe
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "Comando $1 não encontrado"
        exit 1
    fi
}

# Verificar dependências
log_step "Verificando dependências..."
check_command git
check_command npm
check_command nginx
check_command systemctl

# 1. Atualizar código do backend
log_step "1. Atualizando código do backend..."
cd /root/desfollow
git pull origin main
log_info "Backend atualizado!"

# 2. Verificar se precisa aplicar correções de paginação
if grep -q "🔥 CORREÇÃO CRÍTICA" backend/app/ig.py; then
    log_info "Correções de paginação já aplicadas!"
else
    log_warn "Correções de paginação não encontradas no backend"
fi

# 3. Instalar dependências do frontend
log_step "2. Instalando dependências do frontend..."
npm install --silent

# 4. Build do frontend
log_step "3. Buildando frontend para produção..."
npm run build
log_info "Frontend buildado!"

# 5. Aplicar configuração nginx
log_step "4. Aplicando configuração nginx..."
if [ -f "nginx_config_definitiva.conf" ]; then
    cp nginx_config_definitiva.conf /etc/nginx/sites-enabled/desfollow
    log_info "Configuração nginx atualizada!"
else
    log_warn "Arquivo nginx_config_definitiva.conf não encontrado"
fi

# 6. Backup e deploy do frontend
log_step "5. Fazendo backup e deploy do frontend..."
if [ -d "/var/www/desfollow_backup" ]; then
    rm -rf /var/www/desfollow_backup
fi

# Fazer backup apenas se existir conteúdo
if [ -d "/var/www/desfollow" ] && [ "$(ls -A /var/www/desfollow 2>/dev/null)" ]; then
    cp -r /var/www/desfollow /var/www/desfollow_backup
    log_info "Backup criado!"
fi

# Criar diretório se não existir
mkdir -p /var/www/desfollow

# Limpar pasta de destino (exceto .git)
find /var/www/desfollow -mindepth 1 -not -path '*/.git*' -delete 2>/dev/null || true

# Copiar arquivos buildados
if [ -d "dist" ] && [ "$(ls -A dist 2>/dev/null)" ]; then
    cp -r dist/* /var/www/desfollow/
    log_info "Frontend deployado!"
else
    log_error "Pasta dist não encontrada ou vazia!"
    exit 1
fi

# 7. Testar configuração nginx
log_step "6. Testando configuração nginx..."
if nginx -t; then
    log_info "Configuração nginx OK!"
else
    log_error "Erro na configuração nginx!"
    # Restaurar backup se houver erro
    if [ -f "/etc/nginx/sites-enabled/desfollow.backup" ]; then
        cp /etc/nginx/sites-enabled/desfollow.backup /etc/nginx/sites-enabled/desfollow
        log_warn "Configuração anterior restaurada"
    fi
    exit 1
fi

# 8. Recarregar nginx
log_step "7. Recarregando nginx..."
systemctl reload nginx
log_info "Nginx recarregado!"

# 9. Reiniciar backend
log_step "8. Reiniciando backend..."
systemctl restart desfollow
sleep 3

# 10. Verificar serviços
log_step "9. Verificando serviços..."
if systemctl is-active --quiet nginx; then
    log_info "Nginx: ativo"
else
    log_error "Nginx: inativo"
fi

if systemctl is-active --quiet desfollow; then
    log_info "Backend: ativo"
else
    log_error "Backend: inativo"
fi

# 11. Testar endpoints
log_step "10. Testando endpoints..."

# Testar frontend
if curl -s -I https://desfollow.com.br | head -1 | grep -q "200\|301\|302"; then
    log_info "Frontend: acessível (https://desfollow.com.br)"
else
    log_warn "Frontend: problema de acesso"
fi

# Testar API
if curl -s -I https://api.desfollow.com.br/api/health | head -1 | grep -q "200"; then
    log_info "API: acessível (https://api.desfollow.com.br)"
else
    log_warn "API: problema de acesso"
fi

# 12. Resumo final
echo ""
log_info "🎉 DEPLOY CONCLUÍDO COM SUCESSO!"
echo ""
echo "📋 URLs:"
echo "   Frontend: https://desfollow.com.br"
echo "   API: https://api.desfollow.com.br"
echo ""
echo "📋 Para monitorar:"
echo "   Frontend logs: tail -f /var/log/nginx/frontend_access.log"
echo "   API logs: journalctl -u desfollow -f"
echo "   Backend com paginação corrigida: 10 páginas ~250 usuários"
echo ""
echo "📋 Para testar paginação:"
echo "   curl -X POST https://api.desfollow.com.br/api/scan -H \"Content-Type: application/json\" -d '{\"username\": \"instagram\"}'"