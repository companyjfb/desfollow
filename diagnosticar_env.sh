#!/bin/bash
echo "🔍 Diagnosticando problemas com .env..."
echo "======================================"
echo ""

echo "📋 1. Verificando arquivos de ambiente..."
cd ~/desfollow
ls -la | grep -E "\.(env|production)"
echo ""

echo "📋 2. Verificando conteúdo do .env..."
if [ -f ".env" ]; then
    echo "✅ Arquivo .env existe"
    echo "📊 Primeiras 5 linhas (sem senhas):"
    head -5 .env | sed 's/=.*/=***/' || echo "❌ Erro ao ler .env"
else
    echo "❌ Arquivo .env não encontrado"
fi
echo ""

echo "📋 3. Verificando env.production..."
if [ -f "env.production" ]; then
    echo "✅ Arquivo env.production existe"
    echo "📊 Primeiras 5 linhas (sem senhas):"
    head -5 env.production | sed 's/=.*/=***/' || echo "❌ Erro ao ler env.production"
else
    echo "❌ Arquivo env.production não encontrado"
fi
echo ""

echo "📋 4. Verificando variáveis de ambiente atuais..."
echo "📊 DATABASE_URL: ${DATABASE_URL:-'NÃO DEFINIDA'}"
echo "📊 SUPABASE_URL: ${SUPABASE_URL:-'NÃO DEFINIDA'}"
echo "📊 RAPIDAPI_KEY: ${RAPIDAPI_KEY:-'NÃO DEFINIDA'}"
echo ""

echo "📋 5. Tentando carregar .env manualmente..."
if [ -f ".env" ]; then
    echo "📋 Carregando .env..."
    set -a
    source .env
    set +a
    echo "✅ .env carregado"
    echo "📊 DATABASE_URL após carregar: ${DATABASE_URL:-'AINDA NÃO DEFINIDA'}"
else
    echo "❌ Não foi possível carregar .env"
fi
echo ""

echo "📋 6. Verificando se o backend consegue acessar as variáveis..."
python3 -c "
import os
from dotenv import load_dotenv

print('📊 Tentando carregar .env com python-dotenv...')
try:
    load_dotenv()
    print('✅ python-dotenv carregou .env')
except Exception as e:
    print(f'❌ Erro ao carregar com python-dotenv: {e}')

print(f'📊 DATABASE_URL no Python: {os.getenv(\"DATABASE_URL\", \"NÃO DEFINIDA\")}')
print(f'📊 SUPABASE_URL no Python: {os.getenv(\"SUPABASE_URL\", \"NÃO DEFINIDA\")}')
print(f'📊 RAPIDAPI_KEY no Python: {os.getenv(\"RAPIDAPI_KEY\", \"NÃO DEFINIDA\")}')
"
echo ""

echo "📋 7. Testando conexão com Supabase..."
python3 -c "
import os
import psycopg2
from dotenv import load_dotenv

try:
    load_dotenv()
    DATABASE_URL = os.getenv('DATABASE_URL')
    
    if not DATABASE_URL:
        print('❌ DATABASE_URL não encontrada')
        exit(1)
    
    print(f'🔗 Tentando conectar ao Supabase...')
    print(f'📊 URL (mascarada): {DATABASE_URL.split(\"@\")[1] if \"@\" in DATABASE_URL else \"URL inválida\"}')
    
    conn = psycopg2.connect(DATABASE_URL)
    cursor = conn.cursor()
    
    cursor.execute('SELECT version()')
    version = cursor.fetchone()
    print(f'✅ Conectado ao PostgreSQL: {version[0]}')
    
    cursor.execute('SELECT COUNT(*) FROM scans')
    count = cursor.fetchone()
    print(f'📊 Total de scans no banco: {count[0]}')
    
    conn.close()
    
except Exception as e:
    print(f'❌ Erro ao conectar: {e}')
"
echo ""

echo "📋 8. Verificando se o backend está usando as variáveis corretas..."
systemctl status desfollow --no-pager -l | head -10
echo ""

echo "📋 9. Testando API com variáveis carregadas..."
curl -s https://api.desfollow.com.br/health
echo ""
echo ""

echo "✅ Diagnóstico concluído!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Se DATABASE_URL não estiver definida, verificar .env"
echo "   2. Se conexão falhar, verificar credenciais do Supabase"
echo "   3. Se backend não carregar, reiniciar serviço" 