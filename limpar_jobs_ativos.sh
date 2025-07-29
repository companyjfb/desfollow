#!/bin/bash

echo "🧹 Limpando jobs ativos órfãos..."
echo "=================================="

echo "📋 Verificando jobs ativos antes da limpeza..."
curl -s http://api.desfollow.com.br/health | jq '.' 2>/dev/null || curl -s http://api.desfollow.com.br/health

echo ""
echo "🔧 Conectando ao banco de dados..."

# Verificar se o PostgreSQL está rodando
if ! systemctl is-active --quiet postgresql; then
    echo "❌ PostgreSQL não está rodando!"
    exit 1
fi

echo "✅ PostgreSQL está rodando!"

# Executar comandos SQL para limpar jobs
echo ""
echo "🧹 Limpando jobs com status 'running' ou 'queued'..."

psql -U postgres -d desfollow -c "
-- Atualizar todos os scans com status 'running' para 'error'
UPDATE scans 
SET status = 'error', 
    error_message = 'Serviço reiniciado - job cancelado',
    updated_at = NOW()
WHERE status IN ('running', 'queued');

-- Mostrar quantos registros foram atualizados
SELECT COUNT(*) as jobs_limpos FROM scans WHERE status = 'error' AND error_message = 'Serviço reiniciado - job cancelado';
"

echo ""
echo "🧹 Limpando jobs antigos (mais de 1 hora)..."

psql -U postgres -d desfollow -c "
-- Atualizar scans antigos para 'error'
UPDATE scans 
SET status = 'error', 
    error_message = 'Job expirado - mais de 1 hora',
    updated_at = NOW()
WHERE created_at < NOW() - INTERVAL '1 hour' 
  AND status IN ('running', 'queued');

-- Mostrar quantos registros foram atualizados
SELECT COUNT(*) as jobs_antigos_limpos FROM scans WHERE status = 'error' AND error_message = 'Job expirado - mais de 1 hora';
"

echo ""
echo "🧹 Verificando jobs restantes..."

psql -U postgres -d desfollow -c "
-- Mostrar resumo dos status
SELECT status, COUNT(*) as total 
FROM scans 
GROUP BY status 
ORDER BY status;
"

echo ""
echo "🔧 Reiniciando o serviço para garantir limpeza..."

systemctl restart desfollow

echo ""
echo "⏳ Aguardando 5 segundos..."
sleep 5

echo ""
echo "🔍 Verificando jobs ativos após limpeza..."
curl -s http://api.desfollow.com.br/health | jq '.' 2>/dev/null || curl -s http://api.desfollow.com.br/health

echo ""
echo "✅ Limpeza concluída!"
echo ""
echo "📋 Resumo:"
echo "   - Jobs 'running' e 'queued' foram marcados como 'error'"
echo "   - Jobs antigos (mais de 1 hora) foram limpos"
echo "   - Serviço foi reiniciado"
echo "   - jobs_active deve estar em 0 agora" 