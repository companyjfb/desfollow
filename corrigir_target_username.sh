#!/bin/bash

echo "🔧 Corrigindo constraint da coluna target_username..."
echo "=================================================="

# Ativar ambiente virtual
source venv/bin/activate

echo "🗄️ Conectando ao banco e corrigindo constraints..."

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
    
    print('🔍 Verificando estrutura atual da tabela scans...')
    
    # Verificar se a coluna target_username tem NOT NULL
    cursor.execute(\"\"\"
        SELECT is_nullable 
        FROM information_schema.columns 
        WHERE table_name = 'scans' AND column_name = 'target_username'
    \"\"\")
    
    result = cursor.fetchone()
    if result and result[0] == 'NO':
        print('❌ Coluna target_username tem constraint NOT NULL')
        print('🔧 Removendo constraint NOT NULL...')
        
        # Remover constraint NOT NULL
        cursor.execute('ALTER TABLE scans ALTER COLUMN target_username DROP NOT NULL')
        print('✅ Constraint NOT NULL removida!')
    else:
        print('✅ Coluna target_username já permite NULL')
    
    # Verificar se há constraint UNIQUE na coluna target_username
    cursor.execute(\"\"\"
        SELECT conname 
        FROM pg_constraint 
        WHERE conrelid = 'scans'::regclass 
        AND contype = 'u' 
        AND conname LIKE '%target_username%'
    \"\"\")
    
    unique_constraints = cursor.fetchall()
    for constraint in unique_constraints:
        print(f'⚠️ Encontrada constraint UNIQUE: {constraint[0]}')
        print(f'🔧 Removendo constraint UNIQUE: {constraint[0]}...')
        
        try:
            cursor.execute(f'ALTER TABLE scans DROP CONSTRAINT {constraint[0]}')
            print(f'✅ Constraint UNIQUE removida: {constraint[0]}')
        except Exception as e:
            print(f'⚠️ Erro ao remover constraint: {e}')
    
    # Verificar estrutura final
    cursor.execute(\"\"\"
        SELECT column_name, is_nullable, data_type
        FROM information_schema.columns 
        WHERE table_name = 'scans' AND column_name = 'target_username'
    \"\"\")
    
    final_result = cursor.fetchone()
    if final_result:
        column_name, is_nullable, data_type = final_result
        print(f'📊 Estado final da coluna target_username: {column_name} - {is_nullable} ({data_type})')
    
    # Verificar se há registros com target_username NULL
    cursor.execute(\"\"\"
        SELECT COUNT(*) 
        FROM scans 
        WHERE target_username IS NULL
    \"\"\")
    
    null_count = cursor.fetchone()[0]
    print(f'📊 Registros com target_username NULL: {null_count}')
    
    # Verificar todas as colunas da tabela scans
    cursor.execute(\"\"\"
        SELECT column_name, is_nullable, data_type
        FROM information_schema.columns 
        WHERE table_name = 'scans'
        ORDER BY ordinal_position
    \"\"\")
    
    all_columns = cursor.fetchall()
    print('\\n📊 Estrutura completa da tabela scans:')
    print('=' * 50)
    for col in all_columns:
        column_name, is_nullable, data_type = col
        print(f'{column_name}: {is_nullable} ({data_type})')
    
    conn.commit()
    cursor.close()
    conn.close()
    
    print('\\n✅ Correção da constraint concluída!')

except Exception as e:
    print(f'❌ Erro ao corrigir constraint: {e}')
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
curl -X POST https://api.desfollow.com.br/api/scan \
  -H "Content-Type: application/json" \
  -d '{"username":"test"}' \
  -v

echo ""
echo "✅ Correção da target_username concluída!" 