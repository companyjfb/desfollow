#!/bin/bash

echo "🗄️ Configurando Supabase..."
echo "============================"

# Verificar se o arquivo .env existe
if [ ! -f "backend/.env" ]; then
    echo "❌ Arquivo .env não encontrado!"
    echo "Copiando env.example..."
    cp backend/env.example backend/.env
fi

echo "📋 Configuração atual do .env:"
grep "DATABASE_URL" backend/.env

echo ""
echo "🔍 Testando conexão com Supabase..."

# Testar conexão com o banco
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
    print('✅ Conexão com Supabase OK!')
    
    # Testar se as tabelas existem
    cursor = conn.cursor()
    cursor.execute(\"\"\"
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public'
    \"\"\")
    
    tables = cursor.fetchall()
    print(f'📊 Tabelas encontradas: {len(tables)}')
    for table in tables:
        print(f'  - {table[0]}')
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f'❌ Erro na conexão: {e}')
"

echo ""
echo "🔧 Criando tabelas se não existirem..."

# Executar script SQL para criar tabelas
python3 -c "
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

DATABASE_URL = os.getenv('DATABASE_URL')

try:
    conn = psycopg2.connect(DATABASE_URL)
    cursor = conn.cursor()
    
    # Criar tabela users
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            username VARCHAR(255) UNIQUE NOT NULL,
            email VARCHAR(255) UNIQUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Criar tabela scans
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS scans (
            id SERIAL PRIMARY KEY,
            user_id INTEGER REFERENCES users(id),
            username VARCHAR(255) NOT NULL,
            job_id VARCHAR(255) UNIQUE NOT NULL,
            status VARCHAR(50) NOT NULL,
            followers_count INTEGER,
            following_count INTEGER,
            ghosts_count INTEGER,
            real_ghosts_count INTEGER,
            famous_ghosts_count INTEGER,
            profile_info JSONB,
            ghosts_data JSONB,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Criar tabela payments
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS payments (
            id SERIAL PRIMARY KEY,
            user_id INTEGER REFERENCES users(id),
            amount DECIMAL(10,2) NOT NULL,
            currency VARCHAR(3) DEFAULT 'BRL',
            status VARCHAR(50) NOT NULL,
            payment_method VARCHAR(50),
            transaction_id VARCHAR(255),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Criar índices
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_scans_job_id ON scans(job_id)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_scans_user_id ON scans(user_id)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id)')
    
    conn.commit()
    cursor.close()
    conn.close()
    
    print('✅ Tabelas criadas com sucesso!')
    
except Exception as e:
    print(f'❌ Erro ao criar tabelas: {e}')
"

echo ""
echo "🔍 Testando backend com banco..."

# Reiniciar backend
systemctl restart desfollow

# Aguardar um pouco
sleep 3

# Testar se está funcionando
curl -I http://localhost:8000/api/health

echo ""
echo "✅ Configuração do Supabase concluída!" 