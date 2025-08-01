#!/bin/bash

echo "🔍 VERIFICAÇÃO DE STATUS DA API"
echo "==============================="
echo "Verificando se a API está funcionando corretamente"
echo ""

echo "📋 Verificando se o backend está rodando..."
systemctl status desfollow-backend

echo ""
echo "📋 Verificando se o nginx está rodando..."
systemctl status nginx

echo ""
echo "📋 Verificando se a porta 8000 está em uso..."
netstat -tlnp | grep :8000

echo ""
echo "📋 Verificando logs do backend..."
echo "=== Últimos 20 logs do backend ==="
journalctl -u desfollow-backend --no-pager -n 20

echo ""
echo "📋 Testando conectividade local..."
echo "🧪 Testando http://localhost:8000/health..."
curl -s -w "Status: %{http_code}, Tempo: %{time_total}s\n" http://localhost:8000/health

echo ""
echo "📋 Testando conectividade via nginx..."
echo "🧪 Testando http://api.desfollow.com.br/health..."
curl -s -w "Status: %{http_code}, Tempo: %{time_total}s\n" http://api.desfollow.com.br/health

echo ""
echo "📋 Testando HTTPS da API..."
echo "🧪 Testando https://api.desfollow.com.br/health..."
curl -s -w "Status: %{http_code}, Tempo: %{time_total}s\n" https://api.desfollow.com.br/health

echo ""
echo "📋 Verificando configuração do nginx..."
echo "=== Configuração atual ==="
cat /etc/nginx/sites-available/desfollow

echo ""
echo "📋 Verificando se há erros no nginx..."
echo "=== Últimos 10 logs do nginx ==="
tail -10 /var/log/nginx/error.log

echo ""
echo "📋 Verificando uso de memória e CPU..."
echo "=== Status do sistema ==="
free -h
echo ""
top -bn1 | head -10

echo ""
echo "📋 Verificando se há processos órfãos..."
ps aux | grep gunicorn

echo ""
echo "🔍 DIAGNÓSTICO COMPLETO!"
echo "========================="
echo "Se a API não estiver respondendo, execute:"
echo "1. systemctl restart desfollow-backend"
echo "2. systemctl restart nginx"
echo "3. ./verificar_status_api.sh (novamente)" 