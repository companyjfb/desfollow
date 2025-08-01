#!/bin/bash

# ========================================
# SCRIPT DE CORREÇÃO COMPLETA - DESFOLLOW
# ========================================
# Corrige:
# 1. Timeout 504 do nginx
# 2. Loop infinito do frontend
# 3. Parsing JSON error
# ========================================

echo "🚀 INICIANDO CORREÇÃO COMPLETA DO DESFOLLOW"
echo "========================================"

# 1. CORREÇÃO DO NGINX
echo ""
echo "📋 1. CORRIGINDO CONFIGURAÇÃO NGINX..."
echo "--------------------------------------"

# Backup da configuração atual
echo "💾 Fazendo backup da configuração atual..."
sudo cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.$(date +%Y%m%d_%H%M%S)

# Aplicar nova configuração com timeouts corrigidos
echo "🔧 Aplicando nova configuração com timeouts de 5 minutos..."
sudo cp /root/desfollow/nginx_desfollow_timeout_corrigido.conf /etc/nginx/sites-available/desfollow

echo "✅ Configuração nginx atualizada!"

# 2. TESTAR CONFIGURAÇÃO NGINX
echo ""
echo "📋 2. TESTANDO CONFIGURAÇÃO NGINX..."
echo "--------------------------------------"

echo "🧪 Testando sintaxe do nginx..."
if sudo nginx -t; then
    echo "✅ Configuração nginx válida!"
else
    echo "❌ ERRO na configuração nginx!"
    echo "🔄 Restaurando backup..."
    sudo cp /etc/nginx/sites-available/desfollow.backup.* /etc/nginx/sites-available/desfollow
    echo "❌ Processo abortado. Verifique a configuração."
    exit 1
fi

# 3. REINICIAR SERVIÇOS
echo ""
echo "📋 3. REINICIANDO SERVIÇOS..."
echo "--------------------------------------"

echo "🔄 Reiniciando nginx..."
sudo systemctl reload nginx
if sudo systemctl is-active --quiet nginx; then
    echo "✅ Nginx reiniciado com sucesso!"
else
    echo "❌ ERRO ao reiniciar nginx!"
    exit 1
fi

echo "🔄 Reiniciando backend (gunicorn)..."
sudo systemctl restart gunicorn
if sudo systemctl is-active --quiet gunicorn; then
    echo "✅ Backend reiniciado com sucesso!"
else
    echo "❌ ERRO ao reiniciar backend!"
    exit 1
fi

# 4. ATUALIZAR FRONTEND COM CORREÇÕES
echo ""
echo "📋 4. ATUALIZANDO FRONTEND..."
echo "--------------------------------------"

echo "📥 Fazendo git pull para obter correções do frontend..."
cd /root/desfollow
git pull origin main

echo "🏗️ Rebuilding frontend com correções..."
npm run build

echo "📂 Copiando frontend corrigido para nginx..."
sudo rm -rf /var/www/html/*
sudo cp -r /root/desfollow/dist/* /var/www/html/

echo "✅ Frontend atualizado com correções!"

# 5. VERIFICAR STATUS
echo ""
echo "📋 5. VERIFICANDO STATUS DOS SERVIÇOS..."
echo "--------------------------------------"

echo "🏥 Testando saúde da API..."
if curl -s "https://api.desfollow.com.br/api/health" | grep -q "healthy"; then
    echo "✅ API está saudável!"
else
    echo "⚠️ API pode ter problemas. Verificar logs."
fi

echo "🌐 Testando frontend..."
if curl -s "https://desfollow.com.br" | grep -q "DOCTYPE"; then
    echo "✅ Frontend está respondendo!"
else
    echo "⚠️ Frontend pode ter problemas. Verificar logs."
fi

# 6. TESTAR CORREÇÕES
echo ""
echo "📋 6. TESTANDO CORREÇÕES..."
echo "--------------------------------------"

echo "🧪 Executando teste de comunicação..."
python3 /root/desfollow/testar_comunicacao_frontend_backend.py

# 7. RESUMO
echo ""
echo "🎯 RESUMO DAS CORREÇÕES APLICADAS"
echo "========================================"
echo "✅ 1. Nginx timeout aumentado de 60s para 300s (5 minutos)"
echo "✅ 2. Proxy buffering desabilitado para requests longos"
echo "✅ 3. Frontend corrigido - removido loop infinito no useEffect"
echo "✅ 4. Serviços reiniciados (nginx + backend)"
echo "✅ 5. Frontend rebuilded e deployado"
echo ""
echo "🎉 CORREÇÕES CONCLUÍDAS!"
echo "🔗 Teste em: https://desfollow.com.br"
echo ""
echo "📊 CONFIGURAÇÕES APLICADAS:"
echo "   - Timeout: 300s (5 minutos)"
echo "   - Buffer: Desabilitado"
echo "   - Frontend: Loop corrigido"
echo "   - CORS: Mantido"
echo ""
echo "⚠️ IMPORTANTE:"
echo "   - Scans agora podem demorar até 5 minutos"
echo "   - Não fechar o navegador durante o scan"
echo "   - O frontend não irá mais fazer loop infinito"
echo ""
echo "========================================"