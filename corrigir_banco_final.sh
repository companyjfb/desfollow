#!/bin/bash

echo "🔧 Corrigindo estrutura final do banco de dados..."
echo "=================================================="

# Ativar ambiente virtual
source venv/bin/activate

echo "🗄️ Conectando ao banco e corrigindo tabelas..."

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
    
    # Verificar estrutura atual da tabela scans
    cursor.execute(\"\"\"
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'scans'
        ORDER BY column_name
    \"\"\")
    
    existing_columns = [row[0] for row in cursor.fetchall()]
    print(f'📊 Colunas atuais da tabela scans: {existing_columns}')
    
    # Lista de colunas que devem existir
    required_columns = [
        ('username', 'VARCHAR(255)'),
        ('job_id', 'VARCHAR(255)'),
        ('followers_count', 'INTEGER DEFAULT 0'),
        ('following_count', 'INTEGER DEFAULT 0'),
        ('ghosts_count', 'INTEGER DEFAULT 0'),
        ('real_ghosts_count', 'INTEGER DEFAULT 0'),
        ('famous_ghosts_count', 'INTEGER DEFAULT 0'),
        ('profile_info', 'JSONB'),
        ('ghosts_data', 'JSONB'),
        ('real_ghosts', 'JSONB'),
        ('famous_ghosts', 'JSONB'),
        ('error_message', 'TEXT')
    ]
    
    # Adicionar colunas faltantes
    for column_name, column_type in required_columns:
        if column_name not in existing_columns:
            print(f'❌ Coluna {column_name} não existe')
            print(f'🔧 Adicionando coluna {column_name}...')
            
            try:
                cursor.execute(f'ALTER TABLE scans ADD COLUMN {column_name} {column_type}')
                print(f'✅ Coluna {column_name} adicionada!')
            except Exception as e:
                print(f'⚠️ Erro ao adicionar {column_name}: {e}')
        else:
            print(f'✅ Coluna {column_name} já existe')
    
    # Criar índices para performance
    indexes = [
        'CREATE INDEX IF NOT EXISTS idx_scans_job_id ON scans(job_id)',
        'CREATE INDEX IF NOT EXISTS idx_scans_username ON scans(username)',
        'CREATE INDEX IF NOT EXISTS idx_scans_status ON scans(status)',
        'CREATE INDEX IF NOT EXISTS idx_scans_user_id ON scans(user_id)'
    ]
    
    for index_sql in indexes:
        try:
            cursor.execute(index_sql)
            print(f'✅ Índice criado: {index_sql}')
        except Exception as e:
            print(f'⚠️ Erro ao criar índice: {e}')
    
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
    
    conn.commit()
    cursor.close()
    conn.close()
    
    print('✅ Estrutura do banco corrigida com sucesso!')

except Exception as e:
    print(f'❌ Erro ao corrigir banco: {e}')
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
echo "✅ Correção final concluída!" 