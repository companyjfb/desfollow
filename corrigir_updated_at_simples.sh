#!/bin/bash

echo "🔧 Corrigindo coluna updated_at (versão simples)..."
echo "=================================================="

# Ativar ambiente virtual
source venv/bin/activate

echo "🗄️ Conectando ao banco e adicionando coluna updated_at..."

# Mudar para o diretório backend
cd backend

python3 -c "
import os
import sys
from dotenv import load_dotenv
import psycopg2

# Carregar variáveis de ambiente
load_dotenv()

DATABASE_URL = os.getenv('DATABASE_URL')
print(f'DATABASE_URL: {DATABASE_URL}')

if not DATABASE_URL:
    print('❌ DATABASE_URL não encontrada!')
    exit(1)

try:
    conn = psycopg2.connect(DATABASE_URL)
    cursor = conn.cursor()
    
    # Verificar se a coluna updated_at existe
    cursor.execute(\"\"\"
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'scans' AND column_name = 'updated_at'
    \"\"\")
    
    updated_at_exists = cursor.fetchone()
    
    if not updated_at_exists:
        print('❌ Coluna updated_at não existe')
        print('🔧 Adicionando coluna updated_at...')
        
        cursor.execute('ALTER TABLE scans ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP')
        print('✅ Coluna updated_at adicionada!')
    else:
        print('✅ Coluna updated_at já existe')
    
    # Verificar estrutura final da tabela scans
    cursor.execute(\"\"\"
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'scans' 
        ORDER BY column_name
    \"\"\")
    
    columns = cursor.fetchall()
    print('📊 Estrutura final da tabela scans:')
    for col in columns:
        print(f'  - {col[0]}: {col[1]}')
    
    conn.commit()
    cursor.close()
    conn.close()
    
    print('✅ Coluna updated_at corrigida com sucesso!')

except Exception as e:
    print(f'❌ Erro ao corrigir updated_at: {e}')
    import traceback
    traceback.print_exc()
"

# Voltar ao diretório raiz
cd ..

echo ""
echo "🔧 Reiniciando backend..."
systemctl restart desfollow

echo ""
echo "⏳ Aguardando 5 segundos..."
sleep 5

echo ""
echo "🔍 Testando endpoint de scan:"
curl -X POST http://localhost:8000/api/scan \
  -H "Content-Type: application/json" \
  -d '{"username":"test"}' \
  -v

echo ""
echo "✅ Correção de updated_at concluída!" 