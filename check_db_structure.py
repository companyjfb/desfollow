#!/usr/bin/env python3

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
    sys.exit(1)

try:
    conn = psycopg2.connect(DATABASE_URL)
    cursor = conn.cursor()
    
    # Verificar estrutura da tabela users
    cursor.execute("""
        SELECT column_name, is_nullable, data_type, column_default
        FROM information_schema.columns 
        WHERE table_name = 'users'
        ORDER BY ordinal_position
    """)
    
    columns = cursor.fetchall()
    print('📊 Estrutura atual da tabela users:')
    print('=' * 50)
    
    for col in columns:
        column_name, is_nullable, data_type, column_default = col
        print(f'{column_name}: {is_nullable} ({data_type}) - Default: {column_default}')
    
    # Verificar constraints
    cursor.execute("""
        SELECT conname, contype, pg_get_constraintdef(oid)
        FROM pg_constraint
        WHERE conrelid = 'users'::regclass
    """)
    
    constraints = cursor.fetchall()
    print('\n🔒 Constraints da tabela users:')
    print('=' * 50)
    
    for constraint in constraints:
        print(f'{constraint[0]}: {constraint[1]} - {constraint[2]}')
    
    conn.close()
    print('\n✅ Verificação concluída!')

except Exception as e:
    print(f'❌ Erro ao verificar estrutura: {e}') 