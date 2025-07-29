#!/bin/bash

echo "🔍 Verificando erro 500 detalhado..."
echo "===================================="

echo "📊 Status do serviço:"
systemctl status desfollow --no-pager

echo ""
echo "📋 Últimos logs do backend (últimos 50):"
journalctl -u desfollow --no-pager -n 50

echo ""
echo "🔍 Verificando erros específicos:"
journalctl -u desfollow --no-pager | grep -i "error\|exception\|traceback" | tail -20

echo ""
echo "🔧 Testando endpoint com mais detalhes:"
curl -X POST http://localhost:8000/api/scan \
  -H "Content-Type: application/json" \
  -d '{"username":"test"}' \
  -v 2>&1

echo ""
echo "🔍 Verificando se há problemas de importação:"
cd backend
python3 -c "
import os
from dotenv import load_dotenv
load_dotenv()

try:
    from app.main import app
    print('✅ Importação do app OK!')
except Exception as e:
    print(f'❌ Erro na importação: {e}')
    import traceback
    traceback.print_exc()

try:
    from app.database import get_db
    print('✅ Importação do database OK!')
except Exception as e:
    print(f'❌ Erro na importação do database: {e}')
    import traceback
    traceback.print_exc()

try:
    from app.routes import scan
    print('✅ Importação das rotas OK!')
except Exception as e:
    print(f'❌ Erro na importação das rotas: {e}')
    import traceback
    traceback.print_exc()
"
cd ..

echo ""
echo "🔍 Verificando arquivo .env:"
if [ -f "backend/.env" ]; then
    echo "✅ Arquivo .env encontrado"
    echo "Conteúdo:"
    cat backend/.env
else
    echo "❌ Arquivo .env não encontrado!"
fi

echo ""
echo "🔍 Testando conexão com banco:"
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
    cursor = conn.cursor()
    
    # Testar query simples
    cursor.execute('SELECT COUNT(*) FROM scans')
    count = cursor.fetchone()[0]
    print(f'✅ Conexão OK! Tabela scans tem {count} registros')
    
    # Verificar estrutura da tabela scans
    cursor.execute('''
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'scans' 
        ORDER BY column_name
    ''')
    
    columns = cursor.fetchall()
    print('📊 Estrutura da tabela scans:')
    for col in columns:
        print(f'  - {col[0]}: {col[1]}')
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f'❌ Erro na conexão: {e}')
    import traceback
    traceback.print_exc()
"
cd ..

echo ""
echo "✅ Verificação concluída!" 