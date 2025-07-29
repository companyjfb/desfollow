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

    # Criar tabela users (estrutura expandida)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            username VARCHAR(255) UNIQUE NOT NULL,
            full_name VARCHAR(255),
            email VARCHAR(255) UNIQUE,
            profile_pic_url TEXT,
            profile_pic_url_hd TEXT,
            biography TEXT,
            is_private BOOLEAN DEFAULT FALSE,
            is_verified BOOLEAN DEFAULT FALSE,
            followers_count INTEGER DEFAULT 0,
            following_count INTEGER DEFAULT 0,
            posts_count INTEGER DEFAULT 0,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    # Criar tabela scans (estrutura expandida)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS scans (
            id SERIAL PRIMARY KEY,
            user_id INTEGER REFERENCES users(id),
            username VARCHAR(255) NOT NULL,
            job_id VARCHAR(255) UNIQUE NOT NULL,
            status VARCHAR(50) NOT NULL,
            followers_count INTEGER DEFAULT 0,
            following_count INTEGER DEFAULT 0,
            ghosts_count INTEGER DEFAULT 0,
            real_ghosts_count INTEGER DEFAULT 0,
            famous_ghosts_count INTEGER DEFAULT 0,
            profile_info JSONB,
            ghosts_data JSONB,
            real_ghosts JSONB,
            famous_ghosts JSONB,
            error_message TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    # Criar tabela user_followers (nova tabela)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS user_followers (
            id SERIAL PRIMARY KEY,
            follower_id INTEGER REFERENCES users(id) NOT NULL,
            following_id INTEGER REFERENCES users(id) NOT NULL,
            is_following_back BOOLEAN DEFAULT FALSE,
            is_ghost BOOLEAN DEFAULT FALSE,
            ghost_type VARCHAR(50),
            last_checked TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(follower_id, following_id)
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

    # Criar índices para performance
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_scans_job_id ON scans(job_id)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_scans_user_id ON scans(user_id)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_scans_username ON scans(username)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_scans_status ON scans(status)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_user_followers_follower ON user_followers(follower_id)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_user_followers_following ON user_followers(following_id)')
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