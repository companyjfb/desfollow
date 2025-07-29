#!/bin/bash

echo "🔧 Corrigindo estrutura do banco de dados..."
echo "============================================"

# Ativar ambiente virtual
source venv/bin/activate

echo "🗄️ Conectando ao banco e corrigindo tabelas..."

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
    
    # Verificar se a coluna username existe na tabela scans
    cursor.execute(\"\"\"
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'scans' AND column_name = 'username'
    \"\"\")
    
    username_exists = cursor.fetchone()
    
    if not username_exists:
        print('❌ Coluna username não existe na tabela scans')
        print('🔧 Adicionando coluna username...')
        
        cursor.execute('ALTER TABLE scans ADD COLUMN username VARCHAR(255)')
        print('✅ Coluna username adicionada!')
        
        # Criar índice para performance
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_scans_username ON scans(username)')
        print('✅ Índice criado!')
    else:
        print('✅ Coluna username já existe')
    
    # Verificar se a coluna job_id existe
    cursor.execute(\"\"\"
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'scans' AND column_name = 'job_id'
    \"\"\")
    
    job_id_exists = cursor.fetchone()
    
    if not job_id_exists:
        print('❌ Coluna job_id não existe na tabela scans')
        print('🔧 Adicionando coluna job_id...')
        
        cursor.execute('ALTER TABLE scans ADD COLUMN job_id VARCHAR(255)')
        print('✅ Coluna job_id adicionada!')
        
        # Criar índice para performance
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_scans_job_id ON scans(job_id)')
        print('✅ Índice criado!')
    else:
        print('✅ Coluna job_id já existe')
    
    # Verificar se a tabela user_followers existe
    cursor.execute(\"\"\"
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_name = 'user_followers'
    \"\"\")
    
    user_followers_exists = cursor.fetchone()
    
    if not user_followers_exists:
        print('❌ Tabela user_followers não existe')
        print('🔧 Criando tabela user_followers...')
        
        cursor.execute('''
            CREATE TABLE user_followers (
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
        print('✅ Tabela user_followers criada!')
    else:
        print('✅ Tabela user_followers já existe')
    
    # Verificar estrutura da tabela users
    cursor.execute(\"\"\"
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'users'
    \"\"\")
    
    user_columns = [row[0] for row in cursor.fetchall()]
    print(f'📊 Colunas da tabela users: {user_columns}')
    
    # Adicionar colunas que podem estar faltando
    missing_columns = []
    
    if 'full_name' not in user_columns:
        missing_columns.append('full_name VARCHAR(255)')
    
    if 'profile_pic_url' not in user_columns:
        missing_columns.append('profile_pic_url TEXT')
    
    if 'profile_pic_url_hd' not in user_columns:
        missing_columns.append('profile_pic_url_hd TEXT')
    
    if 'biography' not in user_columns:
        missing_columns.append('biography TEXT')
    
    if 'is_private' not in user_columns:
        missing_columns.append('is_private BOOLEAN DEFAULT FALSE')
    
    if 'is_verified' not in user_columns:
        missing_columns.append('is_verified BOOLEAN DEFAULT FALSE')
    
    if 'followers_count' not in user_columns:
        missing_columns.append('followers_count INTEGER DEFAULT 0')
    
    if 'following_count' not in user_columns:
        missing_columns.append('following_count INTEGER DEFAULT 0')
    
    if 'posts_count' not in user_columns:
        missing_columns.append('posts_count INTEGER DEFAULT 0')
    
    if 'last_updated' not in user_columns:
        missing_columns.append('last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP')
    
    if missing_columns:
        print(f'🔧 Adicionando colunas faltantes: {missing_columns}')
        for column in missing_columns:
            try:
                cursor.execute(f'ALTER TABLE users ADD COLUMN {column}')
                print(f'✅ Coluna adicionada: {column}')
            except Exception as e:
                print(f'⚠️ Coluna já existe: {column}')
    
    conn.commit()
    cursor.close()
    conn.close()
    
    print('✅ Estrutura do banco corrigida com sucesso!')

except Exception as e:
    print(f'❌ Erro ao corrigir banco: {e}')
"

echo ""
echo "🔧 Reiniciando backend..."
systemctl restart desfollow

echo ""
echo "⏳ Aguardando 3 segundos..."
sleep 3

echo ""
echo "🔍 Testando endpoint de health:"
curl -I http://localhost:8000/api/health

echo ""
echo "✅ Correção concluída!" 