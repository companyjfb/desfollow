#!/bin/bash

echo "🧹 Limpando jobs ativos órfãos (Supabase)..."
echo "============================================="

echo "📋 Verificando jobs ativos antes da limpeza..."
curl -s http://api.desfollow.com.br/health | jq '.' 2>/dev/null || curl -s http://api.desfollow.com.br/health

echo ""
echo "🔧 Conectando ao Supabase..."

# Verificar se o arquivo .env existe
if [ ! -f "backend/.env" ]; then
    echo "❌ Arquivo backend/.env não encontrado!"
    echo "🔧 Verificando se existe env.production..."
    if [ -f "backend/env.production" ]; then
        echo "✅ Encontrado env.production, copiando para .env..."
        cp backend/env.production backend/.env
    else
        echo "❌ Nenhum arquivo de configuração encontrado!"
        exit 1
    fi
fi

# Verificar se DATABASE_URL está configurada
if ! grep -q "DATABASE_URL" backend/.env; then
    echo "❌ DATABASE_URL não encontrada no backend/.env!"
    exit 1
fi

echo "✅ DATABASE_URL encontrada!"

# Executar script Python para limpar jobs
echo ""
echo "🧹 Limpando jobs com status 'running' ou 'queued'..."

cat > limpar_jobs_temp.py << 'EOF'
import os
import psycopg2
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv('backend/.env')

DATABASE_URL = os.getenv('DATABASE_URL')
print(f"🔗 Conectando ao Supabase: {DATABASE_URL[:50]}...")

try:
    # Conectar ao Supabase
    conn = psycopg2.connect(DATABASE_URL)
    cursor = conn.cursor()
    
    print("✅ Conectado ao Supabase!")
    
    # Atualizar todos os scans com status 'running' para 'error'
    cursor.execute("""
        UPDATE scans 
        SET status = 'error', 
            error_message = 'Serviço reiniciado - job cancelado',
            updated_at = NOW()
        WHERE status IN ('running', 'queued')
    """)
    
    jobs_limpos = cursor.rowcount
    print(f"🧹 Jobs limpos: {jobs_limpos}")
    
    # Atualizar scans antigos para 'error'
    cursor.execute("""
        UPDATE scans 
        SET status = 'error', 
            error_message = 'Job expirado - mais de 1 hora',
            updated_at = NOW()
        WHERE created_at < NOW() - INTERVAL '1 hour' 
          AND status IN ('running', 'queued')
    """)
    
    jobs_antigos_limpos = cursor.rowcount
    print(f"🧹 Jobs antigos limpos: {jobs_antigos_limpos}")
    
    # Mostrar resumo dos status
    cursor.execute("""
        SELECT status, COUNT(*) as total 
        FROM scans 
        GROUP BY status 
        ORDER BY status
    """)
    
    print("\n📊 Resumo dos status:")
    for row in cursor.fetchall():
        print(f"   - {row[0]}: {row[1]}")
    
    conn.commit()
    cursor.close()
    conn.close()
    
    print("✅ Limpeza concluída com sucesso!")
    
except Exception as e:
    print(f"❌ Erro ao conectar ao Supabase: {e}")
    exit(1)
EOF

python3 limpar_jobs_temp.py

echo ""
echo "🔧 Reiniciando o serviço para garantir limpeza..."

systemctl restart desfollow

echo ""
echo "⏳ Aguardando 5 segundos..."
sleep 5

echo ""
echo "🔍 Verificando jobs ativos após limpeza..."
curl -s http://api.desfollow.com.br/health | jq '.' 2>/dev/null || curl -s http://api.desfollow.com.br/health

echo ""
echo "🧹 Limpando arquivo temporário..."
rm -f limpar_jobs_temp.py

echo ""
echo "✅ Limpeza concluída!"
echo ""
echo "📋 Resumo:"
echo "   - Jobs 'running' e 'queued' foram marcados como 'error'"
echo "   - Jobs antigos (mais de 1 hora) foram limpos"
echo "   - Serviço foi reiniciado"
echo "   - jobs_active deve estar em 0 agora" 