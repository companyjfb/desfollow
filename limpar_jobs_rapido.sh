#!/bin/bash
echo "🧹 Limpando jobs ativos rapidamente..."
echo "======================================"
echo ""

echo "📋 1. Verificando jobs ativos..."
curl -s https://api.desfollow.com.br/health | jq .
echo ""

echo "📋 2. Limpando cache de jobs..."
rm -f /tmp/desfollow_jobs.json
echo "✅ Cache limpo!"
echo ""

echo "📋 3. Verificando jobs no banco Supabase..."
cd ~/desfollow
source venv/bin/activate

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
    exit(1)
"
echo ""

echo "📋 4. Reiniciando backend para aplicar limpeza..."
systemctl restart desfollow
echo ""

echo "⏳ Aguardando 5 segundos..."
sleep 5
echo ""

echo "📋 5. Verificando resultado..."
curl -s https://api.desfollow.com.br/health | jq .
echo ""

echo "📋 6. Se ainda houver jobs, forçar limpeza..."
ACTIVE_JOBS=$(curl -s https://api.desfollow.com.br/health | jq -r '.jobs_active // 0')

if [ "$ACTIVE_JOBS" -gt 0 ]; then
    echo "⚠️  Ainda há $ACTIVE_JOBS jobs ativos"
    echo "📋 Forçando limpeza completa..."
    
    python3 -c "
import os
import psycopg2

try:
    DATABASE_URL = os.getenv('DATABASE_URL')
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
    
except Exception as e:
    print(f'❌ Erro: {e}')
"
    
    echo ""
    echo "📋 Verificando resultado final..."
    curl -s https://api.desfollow.com.br/health | jq .
fi

echo ""
echo "✅ Limpeza concluída!"
echo ""
echo "📋 Para monitorar:"
echo "   curl -s https://api.desfollow.com.br/health | jq ." 