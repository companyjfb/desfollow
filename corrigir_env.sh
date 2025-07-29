#!/bin/bash
echo "🔧 Corrigindo localização do arquivo .env..."
echo "============================================"
echo ""

echo "📋 1. Verificando onde está o arquivo .env..."
cd ~/desfollow
find . -name ".env" -type f
echo ""

echo "📋 2. Verificando conteúdo do backend/.env..."
if [ -f "backend/.env" ]; then
    echo "✅ Arquivo backend/.env existe"
    echo "📊 Primeiras 5 linhas (sem senhas):"
    head -5 backend/.env | sed 's/=.*/=***/' || echo "❌ Erro ao ler backend/.env"
else
    echo "❌ Arquivo backend/.env não encontrado"
fi
echo ""

echo "📋 3. Copiando .env para a raiz..."
if [ -f "backend/.env" ]; then
    cp backend/.env .env
    echo "✅ .env copiado para a raiz"
    echo "📊 Verificando se foi copiado:"
    ls -la .env
else
    echo "❌ Não foi possível copiar .env"
fi
echo ""

echo "📋 4. Verificando se o backend está configurado para carregar .env..."
cd ~/desfollow/backend
if [ -f ".env" ]; then
    echo "✅ backend/.env existe"
    echo "📊 Verificando se o main.py carrega .env..."
    grep -n "load_dotenv\|dotenv" app/main.py || echo "❌ Não encontrou carregamento de .env no main.py"
else
    echo "❌ backend/.env não existe"
fi
echo ""

echo "📋 5. Verificando se o backend carrega .env automaticamente..."
cd ~/desfollow
python3 -c "
import os
from dotenv import load_dotenv

print('📊 Tentando carregar .env da raiz...')
try:
    load_dotenv()
    print('✅ .env carregado da raiz')
except Exception as e:
    print(f'❌ Erro ao carregar da raiz: {e}')

print('📊 Tentando carregar backend/.env...')
try:
    load_dotenv('backend/.env')
    print('✅ backend/.env carregado')
except Exception as e:
    print(f'❌ Erro ao carregar backend/.env: {e}')

print(f'📊 DATABASE_URL: {os.getenv(\"DATABASE_URL\", \"NÃO DEFINIDA\")}')
print(f'📊 SUPABASE_URL: {os.getenv(\"SUPABASE_URL\", \"NÃO DEFINIDA\")}')
print(f'📊 RAPIDAPI_KEY: {os.getenv(\"RAPIDAPI_KEY\", \"NÃO DEFINIDA\")}')
"
echo ""

echo "📋 6. Testando conexão com Supabase..."
python3 -c "
import os
import psycopg2
from dotenv import load_dotenv

try:
    # Tentar carregar de ambos os locais
    load_dotenv()
    load_dotenv('backend/.env')
    
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

echo "📋 7. Reiniciando backend para aplicar configuração..."
systemctl restart desfollow
echo ""

echo "⏳ Aguardando 5 segundos..."
sleep 5
echo ""

echo "📋 8. Verificando se o backend está funcionando..."
systemctl status desfollow --no-pager -l | head -5
echo ""

echo "📋 9. Testando API..."
curl -s https://api.desfollow.com.br/health
echo ""
echo ""

echo "✅ Correção concluída!"
echo ""
echo "📋 Se ainda houver problemas:"
echo "   1. Verificar se backend/.env tem DATABASE_URL válida"
echo "   2. Verificar se o main.py carrega dotenv"
echo "   3. Verificar se as credenciais do Supabase estão corretas" 