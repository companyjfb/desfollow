#!/bin/bash
echo "🧹 Limpando jobs ativos (versão corrigida)..."
echo "============================================="
echo ""

echo "📋 1. Verificando jobs ativos..."
HEALTH_RESPONSE=$(curl -s https://api.desfollow.com.br/health)
echo "$HEALTH_RESPONSE"
echo ""

echo "📋 2. Limpando cache de jobs..."
rm -f /tmp/desfollow_jobs.json
echo "✅ Cache limpo!"
echo ""

echo "📋 3. Carregando variáveis de ambiente..."
cd ~/desfollow
source venv/bin/activate

# Carregar .env se existir
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo "✅ Variáveis de ambiente carregadas"
else
    echo "❌ Arquivo .env não encontrado"
fi

echo "📋 4. Verificando DATABASE_URL..."
if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL não encontrada"
    echo "📋 Tentando carregar de env.production..."
    if [ -f "env.production" ]; then
        export $(cat env.production | grep -v '^#' | xargs)
        echo "✅ DATABASE_URL carregada de env.production"
    else
        echo "❌ env.production também não encontrado"
        echo "📋 Usando DATABASE_URL padrão do Supabase..."
        export DATABASE_URL="postgresql://postgres:[password]@db.[project].supabase.co:5432/postgres"
    fi
fi
echo ""

echo "📋 5. Verificando jobs no banco Supabase..."
python3 -c "
import os
import psycopg2
from datetime import datetime, timedelta

try:
    # Conectar ao Supabase
    DATABASE_URL = os.getenv('DATABASE_URL')
    if not DATABASE_URL:
        print('❌ DATABASE_URL não encontrada')
        exit(1)
    
    print(f'🔗 Conectando ao banco...')
    conn = psycopg2.connect(DATABASE_URL)
    cursor = conn.cursor()
    
    # Verificar jobs antigos (mais de 3 minutos)
    cutoff_time = datetime.utcnow() - timedelta(minutes=3)
    
    # Marcar jobs antigos como erro
    cursor.execute('''
        UPDATE scans 
        SET status = 'error', 
            updated_at = NOW() 
        WHERE status IN ('running', 'queued') 
        AND updated_at < %s
    ''', (cutoff_time,))
    
    updated_count = cursor.rowcount
    print(f'✅ {updated_count} jobs antigos marcados como erro')
    
    # Verificar jobs ativos restantes
    cursor.execute('''
        SELECT COUNT(*) 
        FROM scans 
        WHERE status IN ('running', 'queued')
    ''')
    
    active_count = cursor.fetchone()[0]
    print(f'📊 Jobs ativos restantes: {active_count}')
    
    conn.commit()
    conn.close()
    
except Exception as e:
    print(f'❌ Erro ao limpar banco: {e}')
    print('📋 Tentando limpeza alternativa...')
    
    # Limpeza alternativa - apenas limpar cache
    import json
    try:
        with open('/tmp/desfollow_jobs.json', 'w') as f:
            json.dump({}, f)
        print('✅ Cache limpo como alternativa')
    except:
        print('❌ Não foi possível limpar cache')
"
echo ""

echo "📋 6. Reiniciando backend para aplicar limpeza..."
systemctl restart desfollow
echo ""

echo "⏳ Aguardando 5 segundos..."
sleep 5
echo ""

echo "📋 7. Verificando resultado..."
FINAL_RESPONSE=$(curl -s https://api.desfollow.com.br/health)
echo "$FINAL_RESPONSE"
echo ""

echo "📋 8. Se ainda houver jobs, forçar limpeza..."
# Extrair jobs_active sem jq
ACTIVE_JOBS=$(echo "$FINAL_RESPONSE" | grep -o '"jobs_active":[0-9]*' | grep -o '[0-9]*' || echo "0")

if [ "$ACTIVE_JOBS" -gt 0 ]; then
    echo "⚠️  Ainda há $ACTIVE_JOBS jobs ativos"
    echo "📋 Forçando limpeza completa..."
    
    python3 -c "
import os
import psycopg2

try:
    DATABASE_URL = os.getenv('DATABASE_URL')
    if DATABASE_URL:
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()
        
        # Forçar todos os jobs como erro
        cursor.execute('''
            UPDATE scans 
            SET status = 'error', 
                updated_at = NOW() 
            WHERE status IN ('running', 'queued')
        ''')
        
        updated_count = cursor.rowcount
        print(f'✅ {updated_count} jobs forçados como erro')
        
        conn.commit()
        conn.close()
    else:
        print('❌ DATABASE_URL não disponível')
        
except Exception as e:
    print(f'❌ Erro: {e}')
    
# Sempre limpar cache como fallback
import json
try:
    with open('/tmp/desfollow_jobs.json', 'w') as f:
        json.dump({}, f)
    print('✅ Cache limpo como fallback')
except:
    print('❌ Não foi possível limpar cache')
"
    
    echo ""
    echo "📋 Verificando resultado final..."
    curl -s https://api.desfollow.com.br/health
fi

echo ""
echo "✅ Limpeza concluída!"
echo ""
echo "📋 Para monitorar:"
echo "   curl -s https://api.desfollow.com.br/health" 