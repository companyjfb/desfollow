#!/bin/bash

echo "🔧 Corrigindo constraint da coluna email..."
echo "=========================================="

# Ativar ambiente virtual
source venv/bin/activate

echo "🗄️ Conectando ao banco e corrigindo constraint..."

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
    
    # Verificar constraint atual da coluna email
    cursor.execute(\"\"\"
        SELECT conname, contype, pg_get_constraintdef(oid)
        FROM pg_constraint
        WHERE conrelid = 'users'::regclass
        AND conname LIKE '%email%'
    \"\"\")
    
    email_constraints = cursor.fetchall()
    print('🔍 Constraints atuais da coluna email:')
    for constraint in email_constraints:
        print(f'  - {constraint[0]}: {constraint[1]} - {constraint[2]}')
    
    # Verificar se a coluna email tem NOT NULL
    cursor.execute(\"\"\"
        SELECT is_nullable 
        FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'email'
    \"\"\")
    
    result = cursor.fetchone()
    if result and result[0] == 'NO':
        print('❌ Coluna email tem constraint NOT NULL')
        print('🔧 Removendo constraint NOT NULL...')
        
        # Remover constraint NOT NULL
        cursor.execute('ALTER TABLE users ALTER COLUMN email DROP NOT NULL')
        print('✅ Constraint NOT NULL removida!')
    else:
        print('✅ Coluna email já permite NULL')
    
    # Verificar se há constraint UNIQUE na coluna email
    cursor.execute(\"\"\"
        SELECT conname 
        FROM pg_constraint 
        WHERE conrelid = 'users'::regclass 
        AND contype = 'u' 
        AND conname LIKE '%email%'
    \"\"\")
    
    unique_constraint = cursor.fetchone()
    if unique_constraint:
        print(f'⚠️ Encontrada constraint UNIQUE: {unique_constraint[0]}')
        print('🔧 Removendo constraint UNIQUE...')
        
        cursor.execute(f'ALTER TABLE users DROP CONSTRAINT {unique_constraint[0]}')
        print('✅ Constraint UNIQUE removida!')
    
    # Verificar estrutura final
    cursor.execute(\"\"\"
        SELECT column_name, is_nullable, data_type
        FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'email'
    \"\"\")
    
    final_result = cursor.fetchone()
    if final_result:
        column_name, is_nullable, data_type = final_result
        print(f'📊 Estado final da coluna email: {column_name} - {is_nullable} ({data_type})')
    
    conn.commit()
    cursor.close()
    conn.close()
    
    print('✅ Correção da constraint concluída!')

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
echo "✅ Correção da constraint concluída!" 