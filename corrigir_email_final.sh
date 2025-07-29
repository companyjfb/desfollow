#!/bin/bash

echo "🔧 Correção final do problema do email..."
echo "========================================"

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
    
    print('🔍 Verificando estrutura atual da tabela users...')
    
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
    
    unique_constraints = cursor.fetchall()
    for constraint in unique_constraints:
        print(f'⚠️ Encontrada constraint UNIQUE: {constraint[0]}')
        print(f'🔧 Removendo constraint UNIQUE: {constraint[0]}...')
        
        try:
            cursor.execute(f'ALTER TABLE users DROP CONSTRAINT {constraint[0]}')
            print(f'✅ Constraint UNIQUE removida: {constraint[0]}')
        except Exception as e:
            print(f'⚠️ Erro ao remover constraint: {e}')
    
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
    
    # Verificar se há registros com email NULL
    cursor.execute(\"\"\"
        SELECT COUNT(*) 
        FROM users 
        WHERE email IS NULL
    \"\"\")
    
    null_count = cursor.fetchone()[0]
    print(f'📊 Registros com email NULL: {null_count}')
    
    if null_count > 0:
        print('🔧 Atualizando registros com email NULL...')
        cursor.execute(\"\"\"
            UPDATE users 
            SET email = username || '@desfollow.com.br'
            WHERE email IS NULL
        \"\"\")
        print(f'✅ {cursor.rowcount} registros atualizados!')
    
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
echo "✅ Correção final concluída!" 