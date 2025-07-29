#!/bin/bash

echo "🔍 Verificação Rápida do Sistema de Limpeza..."
echo "============================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para verificar jobs
check_api() {
    local jobs=$(curl -s http://api.desfollow.com.br/api/health 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('jobs_active', 'erro'))" 2>/dev/null)
    if [ -z "$jobs" ]; then
        echo "erro"
    else
        echo "$jobs"
    fi
}

echo "📊 1. Status do Serviço:"
if systemctl is-active --quiet desfollow-limpeza-3min; then
    echo -e "   ${GREEN}✅ Serviço ATIVO${NC}"
    
    # Mostrar tempo de execução
    UPTIME=$(systemctl show desfollow-limpeza-3min --property=ActiveEnterTimestamp --value)
    echo "   ⏰ Iniciado: $UPTIME"
else
    echo -e "   ${RED}❌ Serviço INATIVO${NC}"
    echo "   🔧 Para iniciar: systemctl start desfollow-limpeza-3min"
fi

echo ""
echo "📊 2. Jobs Ativos na API:"
JOBS=$(check_api)
if [ "$JOBS" = "erro" ] || [ -z "$JOBS" ]; then
    echo -e "   ${RED}❌ Erro ao conectar com API${NC}"
    JOBS="erro"
else
    if [ "$JOBS" -le 5 ]; then
        echo -e "   ${GREEN}✅ Jobs ativos: $JOBS (ÓTIMO)${NC}"
    elif [ "$JOBS" -le 10 ]; then
        echo -e "   ${YELLOW}⚠️ Jobs ativos: $JOBS (ACEITÁVEL)${NC}"
    else
        echo -e "   ${RED}❌ Jobs ativos: $JOBS (MUITOS!)${NC}"
    fi
fi

echo ""
echo "📊 3. Logs Recentes (última atividade):"
LAST_LOG=$(journalctl -u desfollow-limpeza-3min --no-pager -n 1 --output=short-iso)
if [ -n "$LAST_LOG" ]; then
    echo "   $LAST_LOG"
else
    echo -e "   ${YELLOW}⚠️ Nenhum log encontrado${NC}"
fi

echo ""
echo "📊 4. Atividade de Limpeza (últimos 5 minutos):"
CLEANUP_COUNT=$(journalctl -u desfollow-limpeza-3min --since "5 minutes ago" --no-pager | grep -c "Limpeza\|limpo\|jobs órfãos" 2>/dev/null || echo "0")
if [ "$CLEANUP_COUNT" -gt 0 ]; then
    echo -e "   ${GREEN}✅ $CLEANUP_COUNT atividades de limpeza detectadas${NC}"
else
    echo -e "   ${YELLOW}ℹ️ Nenhuma limpeza necessária (normal se poucos jobs)${NC}"
fi

echo ""
echo "📊 5. Arquivo de Cache:"
if [ -f "/tmp/desfollow_jobs.json" ]; then
    CACHE_SIZE=$(stat -c%s "/tmp/desfollow_jobs.json" 2>/dev/null || echo "0")
    echo -e "   ${GREEN}✅ Cache existe (${CACHE_SIZE} bytes)${NC}"
else
    echo -e "   ${YELLOW}ℹ️ Cache não existe (normal se nenhum job ativo)${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Resumo geral
if systemctl is-active --quiet desfollow-limpeza-3min && [ "$JOBS" != "erro" ] && [ -n "$JOBS" ] && [ "$JOBS" -le 5 ]; then
    echo -e "🎯 ${GREEN}SISTEMA FUNCIONANDO PERFEITAMENTE!${NC}"
elif systemctl is-active --quiet desfollow-limpeza-3min; then
    echo -e "⚠️ ${YELLOW}Sistema ativo, mas pode precisar de otimização${NC}"
else
    echo -e "🚨 ${RED}SISTEMA PRECISA DE ATENÇÃO!${NC}"
fi

echo ""
echo "📋 Comandos úteis:"
echo "   🔄 Reiniciar: systemctl restart desfollow-limpeza-3min"
echo "   📄 Ver logs: journalctl -u desfollow-limpeza-3min -f"
echo "   📊 Monitorar: watch -n 3 'curl -s http://api.desfollow.com.br/api/health | python3 -m json.tool'" 