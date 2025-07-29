#!/bin/bash

echo "🔍 Verificando backend Desfollow..."
echo "=================================="

# 1. Verificar se o serviço está rodando
echo "📊 Status do serviço:"
systemctl status desfollow --no-pager

echo ""
echo "📋 Últimos logs do backend:"
journalctl -u desfollow --no-pager -n 20

echo ""
echo "🔍 Verificando se há erros específicos:"
journalctl -u desfollow --no-pager | grep -i "error\|exception\|traceback" | tail -10

echo ""
echo "🔧 Verificando arquivo .env:"
if [ -f "backend/.env" ]; then
    echo "✅ Arquivo .env encontrado"
    grep "DATABASE_URL" backend/.env
else
    echo "❌ Arquivo .env não encontrado!"
    echo "Copiando env.example..."
    cp backend/env.example backend/.env
fi

echo ""
echo "🗄️ Testando conexão com banco:"
cd backend
python3 -c "
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

DATABASE_URL = os.getenv('DATABASE_URL')
print(f'DATABASE_URL: {DATABASE_URL}')

try:
    conn = psycopg2.connect(DATABASE_URL)
    print('✅ Conexão com banco OK!')
    conn.close()
except Exception as e:
    print(f'❌ Erro na conexão: {e}')
"

echo ""
echo "🚀 Testando importação do módulo:"
python3 -c "
try:
    from app.main import app
    print('✅ Importação do app OK!')
except Exception as e:
    print(f'❌ Erro na importação: {e}')
"

echo ""
echo "🔧 Reiniciando backend..."
systemctl restart desfollow

echo ""
echo "⏳ Aguardando 3 segundos..."
sleep 3

echo ""
echo "📊 Status após reinicialização:"
systemctl status desfollow --no-pager

echo ""
echo "🔍 Testando endpoint de health:"
curl -I http://localhost:8000/api/health

echo ""
echo "✅ Verificação concluída!" 