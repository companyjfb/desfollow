#!/bin/bash

echo "🔍 DIAGNÓSTICO NGINX - CONFLITOS DE CONFIGURAÇÃO"
echo "=============================================="
echo

echo "📋 1. Verificando configurações ativas..."
echo "Sites habilitados:"
ls -la /etc/nginx/sites-enabled/
echo

echo "📋 2. Procurando limit_req_zone em todos os arquivos..."
echo "No nginx.conf principal:"
grep -n "limit_req_zone" /etc/nginx/nginx.conf 2>/dev/null || echo "Nenhum encontrado em nginx.conf"
echo

echo "Em sites-enabled:"
grep -r "limit_req_zone" /etc/nginx/sites-enabled/ 2>/dev/null || echo "Nenhum encontrado em sites-enabled"
echo

echo "Em sites-available:"
grep -r "limit_req_zone" /etc/nginx/sites-available/ 2>/dev/null || echo "Nenhum encontrado em sites-available"
echo

echo "📋 3. Verificando backups que podem estar interferindo..."
find /etc/nginx/ -name "*backup*" -o -name "*desfollow*" 2>/dev/null
echo

echo "📋 4. Testando configuração atual..."
sudo nginx -t
echo

echo "📋 5. Status do Nginx..."
sudo systemctl status nginx --no-pager -l