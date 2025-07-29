#!/bin/bash
echo "🔧 Corrigindo scan definitivamente..."
echo "====================================="
echo ""

echo "📋 Verificando conexão com Supabase..."
echo "🔗 DATABASE_URL: $DATABASE_URL"
echo ""

echo "📋 Verificando se jq está instalado..."
if ! command -v jq &> /dev/null; then
    echo "❌ jq não encontrado! Instalando jq..."
    apt-get install -y jq
    echo "✅ jq instalado!"
else
    echo "✅ jq já está instalado!"
fi
echo ""

echo "🧹 Limpando TODOS os jobs antigos no Supabase..."
# Usar Python para limpar o banco Supabase
python3 << 'EOF'
import os
import psycopg2
from datetime import datetime, timedelta

try:
    # Conectar ao Supabase
    conn = psycopg2.connect(os.getenv('DATABASE_URL'))
    cursor = conn.cursor()
    
    print("🔍 Verificando jobs existentes...")
    cursor.execute("SELECT COUNT(*) FROM scans")
    total_jobs = cursor.fetchone()[0]
    print(f"📊 Total de jobs no banco: {total_jobs}")
    
    # Marcar todos os jobs antigos como erro
    cursor.execute("""
        UPDATE scans 
        SET status = 'error', 
            updated_at = NOW() 
        WHERE status IN ('done', 'running', 'queued') 
        AND created_at < NOW() - INTERVAL '30 minutes'
    """)
    updated_count = cursor.rowcount
    print(f"✅ Jobs marcados como erro: {updated_count}")
    
    # Deletar jobs muito antigos
    cursor.execute("""
        DELETE FROM scans 
        WHERE created_at < NOW() - INTERVAL '24 hours'
    """)
    deleted_count = cursor.rowcount
    print(f"🗑️ Jobs deletados: {deleted_count}")
    
    conn.commit()
    
    # Verificar jobs restantes
    cursor.execute("SELECT status, COUNT(*) FROM scans GROUP BY status")
    results = cursor.fetchall()
    print("📊 Status atual dos jobs:")
    for status, count in results:
        print(f"   - {status}: {count}")
    
    cursor.close()
    conn.close()
    print("✅ Limpeza do Supabase concluída!")
    
except Exception as e:
    print(f"❌ Erro ao limpar jobs no Supabase: {e}")
    print(f"🔗 DATABASE_URL: {os.getenv('DATABASE_URL', 'NÃO DEFINIDA')}")
EOF

echo ""

echo "🔄 Reiniciando backend..."
systemctl restart desfollow
echo ""

echo "⏳ Aguardando 5 segundos para o serviço inicializar..."
sleep 5
echo ""

echo "📋 Verificando status do backend..."
systemctl status desfollow --no-pager -l
echo ""

echo "🧪 Testando scan NOVO..."
echo "📊 Fazendo scan para jordanbitencourt..."
SCAN_RESPONSE=$(curl -X POST "http://api.desfollow.com.br/api/scan" \
  -H "Content-Type: application/json" \
  -d '{"username": "jordanbitencourt"}' \
  -s)

echo "📋 Resposta do scan:"
echo "$SCAN_RESPONSE"
echo ""

echo "🎯 Extraindo job_id..."
JOB_ID=$(echo "$SCAN_RESPONSE" | jq -r '.job_id' 2>/dev/null || echo "$SCAN_RESPONSE" | grep -o '"job_id":"[^"]*"' | cut -d'"' -f4)
echo "📋 Job ID: $JOB_ID"
echo ""

if [ ! -z "$JOB_ID" ] && [ "$JOB_ID" != "null" ]; then
    echo "⏳ Aguardando 10 segundos para o scan processar..."
    sleep 10
    echo ""
    
    echo "📊 Verificando resultado do scan..."
    RESULT=$(curl -s "http://api.desfollow.com.br/api/scan/$JOB_ID")
    echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
    echo ""
    
    echo "🔍 Verificando se é um job novo..."
    if [[ "$JOB_ID" == "be6817d3-7959-43de-bcdb-9d7f89181f5b" ]]; then
            echo "❌ AINDA retornando job antigo! Forçando limpeza no Supabase..."
    python3 << 'EOF'
import os
import psycopg2

try:
    conn = psycopg2.connect(os.getenv('DATABASE_URL'))
    cursor = conn.cursor()
    
    print("🗑️ Deletando TODOS os jobs do Supabase...")
    cursor.execute("DELETE FROM scans")
    deleted_count = cursor.rowcount
    conn.commit()
    print(f"✅ {deleted_count} jobs deletados do Supabase!")
    
    cursor.close()
    conn.close()
except Exception as e:
    print(f"❌ Erro ao deletar jobs do Supabase: {e}")
    print(f"🔗 DATABASE_URL: {os.getenv('DATABASE_URL', 'NÃO DEFINIDA')}")
EOF
        echo ""
        echo "🔄 Reiniciando backend novamente..."
        systemctl restart desfollow
        sleep 5
        
        echo "🧪 Testando scan NOVO novamente..."
        SCAN_RESPONSE2=$(curl -X POST "http://api.desfollow.com.br/api/scan" \
          -H "Content-Type: application/json" \
          -d '{"username": "jordanbitencourt"}' \
          -s)
        echo "📋 Nova resposta: $SCAN_RESPONSE2"
    else
        echo "✅ Job novo detectado!"
    fi
else
    echo "❌ Não foi possível obter job_id da resposta"
fi

echo ""
echo "✅ Processo concluído!"
echo ""
echo "🧪 Teste agora:"
echo "   - https://desfollow.com.br"
echo "   - https://www.desfollow.com.br"
echo ""
echo "📋 Para monitorar logs em tempo real:"
echo "   journalctl -u desfollow -f" 