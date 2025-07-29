#!/bin/bash

echo "🔍 Verificando logs detalhados do backend..."
echo "============================================"

echo "📊 Status do serviço:"
systemctl status desfollow --no-pager

echo ""
echo "📋 Últimos logs do backend:"
journalctl -u desfollow --no-pager -n 30

echo ""
echo "🔍 Verificando se há erros específicos:"
journalctl -u desfollow --no-pager | grep -i "error\|exception\|traceback" | tail -10

echo ""
echo "🔧 Testando endpoints localmente:"

echo "1. Testando endpoint raiz:"
curl -v http://localhost:8000/ 2>&1

echo ""
echo "2. Testando endpoint health:"
curl -v http://localhost:8000/api/health 2>&1

echo ""
echo "3. Testando endpoint scan (POST):"
curl -X POST http://localhost:8000/api/scan \
  -H "Content-Type: application/json" \
  -d '{"username":"test"}' \
  -v 2>&1

echo ""
echo "🔍 Verificando configuração do Nginx:"
nginx -t

echo ""
echo "📋 Status do Nginx:"
systemctl status nginx --no-pager

echo ""
echo "🔍 Verificando se a API está respondendo:"
curl -I https://api.desfollow.com.br/api/health

echo ""
echo "✅ Verificação concluída!" 