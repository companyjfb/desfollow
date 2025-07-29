#!/bin/bash

echo "🔍 Verificando arquivo .env..."
echo "=============================="

# Verificar se o arquivo .env existe
if [ ! -f "backend/.env" ]; then
    echo "❌ Arquivo .env não encontrado!"
    echo "Copiando env.example..."
    cp backend/env.example backend/.env
fi

echo "📋 Conteúdo atual do .env:"
cat backend/.env

echo ""
echo "🔧 Verificando se DATABASE_URL está correta..."

# Verificar se a DATABASE_URL está correta
if grep -q "DATABASE_URL" backend/.env; then
    echo "✅ DATABASE_URL encontrada no .env"
    DATABASE_URL=$(grep "DATABASE_URL" backend/.env | cut -d'=' -f2)
    echo "URL: $DATABASE_URL"
    
    # Verificar se a URL está correta
    if [[ $DATABASE_URL == *"supabase.co"* ]]; then
        echo "✅ URL do Supabase detectada"
    else
        echo "❌ URL não parece ser do Supabase"
        echo "URL esperada: postgresql://postgres:Desfollow-DB2026!!!@db.czojjbhgslgbthxzbmyc.supabase.co:5432/postgres"
    fi
else
    echo "❌ DATABASE_URL não encontrada no .env"
    echo "🔧 Adicionando DATABASE_URL..."
    echo "DATABASE_URL=postgresql://postgres:Desfollow-DB2026!!!@db.czojjbhgslgbthxzbmyc.supabase.co:5432/postgres" >> backend/.env
    echo "✅ DATABASE_URL adicionada!"
fi

echo ""
echo "🔧 Verificando outras variáveis necessárias..."

# Verificar RAPIDAPI_KEY
if ! grep -q "RAPIDAPI_KEY" backend/.env; then
    echo "🔧 Adicionando RAPIDAPI_KEY..."
    echo "RAPIDAPI_KEY=dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01" >> backend/.env
    echo "✅ RAPIDAPI_KEY adicionada!"
fi

# Verificar RAPIDAPI_HOST
if ! grep -q "RAPIDAPI_HOST" backend/.env; then
    echo "🔧 Adicionando RAPIDAPI_HOST..."
    echo "RAPIDAPI_HOST=instagram-premium-api-2023.p.rapidapi.com" >> backend/.env
    echo "✅ RAPIDAPI_HOST adicionada!"
fi

echo ""
echo "📋 Conteúdo final do .env:"
cat backend/.env

echo ""
echo "🔧 Testando carregamento do .env..."

# Testar se o .env está sendo carregado corretamente
cd backend
python3 -c "
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv('DATABASE_URL')
RAPIDAPI_KEY = os.getenv('RAPIDAPI_KEY')
RAPIDAPI_HOST = os.getenv('RAPIDAPI_HOST')

print(f'DATABASE_URL: {DATABASE_URL}')
print(f'RAPIDAPI_KEY: {RAPIDAPI_KEY}')
print(f'RAPIDAPI_HOST: {RAPIDAPI_HOST}')

if DATABASE_URL:
    print('✅ DATABASE_URL carregada com sucesso!')
else:
    print('❌ DATABASE_URL não foi carregada!')
"

cd ..

echo ""
echo "✅ Verificação do .env concluída!" 