#!/bin/bash

echo "🔧 CORRIGINDO CONFIGURAÇÃO BANCO - VOLTANDO PARA SUPABASE"
echo "======================================================="

cd /root/desfollow

echo "📋 1. Verificando configuração atual..."
echo "🔍 DATABASE_URL atual:"
grep "DATABASE_URL" backend/.env 2>/dev/null || echo "❌ Arquivo .env não encontrado"

echo ""
echo "📋 2. Verificando se dependências Supabase estão instaladas..."
cd backend
source venv/bin/activate

python3 -c "
try:
    import psycopg2
    print('✅ psycopg2 disponível')
except ImportError:
    print('❌ psycopg2 não instalado')

try:
    import sqlalchemy
    print('✅ sqlalchemy disponível') 
except ImportError:
    print('❌ sqlalchemy não instalado')
"

echo ""
echo "📋 3. Instalando dependências necessárias para Supabase..."
pip install psycopg2-binary sqlalchemy python-dotenv

echo ""
echo "📋 4. Verificando arquivo .env..."
if [ ! -f ".env" ]; then
    echo "📋 Criando arquivo .env a partir do exemplo..."
    cp env.example .env
    echo "✅ Arquivo .env criado"
else
    echo "✅ Arquivo .env já existe"
fi

echo ""
echo "📋 5. Verificando configuração DATABASE_URL..."
DATABASE_URL=$(grep "DATABASE_URL" .env | head -1)
echo "🔍 DATABASE_URL encontrado: $DATABASE_URL"

if [[ "$DATABASE_URL" == *"supabase.co"* ]]; then
    echo "✅ DATABASE_URL aponta para Supabase"
else
    echo "❌ DATABASE_URL não aponta para Supabase"
    echo "📋 Corrigindo DATABASE_URL..."
    sed -i 's|DATABASE_URL=.*|DATABASE_URL=postgresql://postgres:Desfollow-DB2026!!!@db.czojjbhgslgbthxzbmyc.supabase.co:5432/postgres|' .env
    echo "✅ DATABASE_URL corrigido para Supabase"
fi

echo ""
echo "📋 6. Testando conexão com Supabase..."
python3 -c "
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

DATABASE_URL = os.getenv('DATABASE_URL')
print(f'🔍 Testando conexão: {DATABASE_URL[:50]}...')

try:
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        result = conn.execute(text('SELECT 1 as test'))
        print('✅ Conexão com Supabase funcionando!')
        
        # Verificar se tabelas existem
        result = conn.execute(text(\"SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'\"))
        tables = [row[0] for row in result]
        print(f'📊 Tabelas encontradas: {tables}')
        
except Exception as e:
    print(f'❌ Erro na conexão: {e}')
"

echo ""
echo "📋 7. Reiniciando backend..."
cd ..
systemctl restart desfollow

echo ""
echo "📋 8. Aguardando 3 segundos..."
sleep 3

echo ""
echo "📋 9. Testando health check..."
response=$(curl -s https://api.desfollow.com.br/api/health 2>/dev/null)
if [[ "$response" == *"healthy"* ]]; then
    echo "✅ Backend funcionando com Supabase: $response"
else
    echo "❌ Backend com problemas: $response"
    echo "📋 Verificando logs:"
    journalctl -u desfollow --no-pager -n 5
fi

echo ""
echo "✅ CONFIGURAÇÃO SUPABASE VERIFICADA!"
echo "=================================="
echo "📋 Próximos passos:"
echo "   1. Verificar se scan funciona no frontend"
echo "   2. Monitorar logs: journalctl -u desfollow -f"
echo "   3. Verificar dados no Supabase Dashboard" 