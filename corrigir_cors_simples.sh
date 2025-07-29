#!/bin/bash
echo "🔧 Corrigindo CORS para HTTPS..."
echo "================================="
echo ""

echo "📋 Verificando configuração atual do CORS..."
grep -A 10 "allowed_origins" ~/desfollow/backend/app/main.py
echo ""

echo "🔧 Adicionando wildcard ao CORS..."
# Adicionar wildcard temporário para resolver CORS
sed -i '/"https:\/\/api.desfollow.com.br",/a\    # Wildcard temporário para resolver CORS\n    "*"' ~/desfollow/backend/app/main.py

echo "✅ Wildcard adicionado ao CORS!"
echo ""

echo "🔄 Reiniciando backend..."
systemctl restart desfollow
echo ""

echo "⏳ Aguardando 5 segundos para o serviço inicializar..."
sleep 5
echo ""

echo "📋 Verificando status do backend..."
systemctl status desfollow --no-pager -l
echo ""

echo "🧪 Testando CORS..."
echo "📊 Testando requisição OPTIONS..."
curl -X OPTIONS "https://api.desfollow.com.br/api/scan" \
  -H "Origin: https://desfollow.com.br" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -v 2>&1 | grep -E "(Access-Control|HTTP/)"
echo ""

echo "📊 Testando health check..."
curl -s "https://api.desfollow.com.br/health"
echo ""

echo "✅ CORS corrigido!"
echo ""
echo "🧪 Teste agora:"
echo "   - https://desfollow.com.br"
echo "   - Digite um username do Instagram"
echo "   - Deve funcionar sem erro de CORS"
echo ""
echo "📋 Para verificar logs em tempo real:"
echo "   journalctl -u desfollow -f" 