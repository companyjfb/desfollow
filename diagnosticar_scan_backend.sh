#!/bin/bash

echo "🔍 DIAGNOSTICANDO SCAN BACKEND EM TEMPO REAL"
echo "==========================================="

echo "📋 1. Verificando logs do backend em tempo real..."
echo "📋 Últimas 50 linhas dos logs do FastAPI:"
journalctl -u desfollow --no-pager -n 50

echo ""
echo "📋 2. Verificando se backend está respondendo..."
echo "🔍 Testando health check:"
curl -s https://api.desfollow.com.br/api/health | jq . 2>/dev/null || curl -s https://api.desfollow.com.br/api/health

echo ""
echo "📋 3. Verificando jobs ativos no banco..."
echo "🔍 Jobs ativos:"
curl -s "https://api.desfollow.com.br/api/health" | jq '.jobs_active // "N/A"' 2>/dev/null || echo "Erro ao verificar jobs"

echo ""
echo "📋 4. Verificando último scan na tabela..."
echo "🔍 Conectando ao banco para verificar scans recentes..."

# Script Python para verificar banco
cat > /tmp/check_scans.py << 'EOF'
import os
import sys
from datetime import datetime, timedelta

# Adicionar o diretório do backend ao path
sys.path.append('/root/desfollow/backend')

try:
    from app.database import get_db, Scan
    from sqlalchemy.orm import Session
    
    # Criar sessão
    db = next(get_db())
    
    print("📊 ÚLTIMOS 5 SCANS:")
    print("=" * 80)
    
    # Buscar últimos 5 scans
    recent_scans = db.query(Scan).order_by(Scan.created_at.desc()).limit(5).all()
    
    if not recent_scans:
        print("❌ Nenhum scan encontrado no banco!")
    else:
        for scan in recent_scans:
            print(f"🆔 Job ID: {scan.job_id}")
            print(f"👤 Username: {scan.username}")
            print(f"📊 Status: {scan.status}")
            print(f"⏰ Criado: {scan.created_at}")
            print(f"🔄 Atualizado: {scan.updated_at}")
            print(f"👥 Seguidores: {scan.followers_count}")
            print(f"👻 Ghosts: {scan.ghosts_count}")
            print(f"📄 Profile Info: {'✅ Sim' if scan.profile_info else '❌ Não'}")
            if scan.error_message:
                print(f"❌ Erro: {scan.error_message}")
            print("-" * 40)
    
    print("")
    print("📊 ESTATÍSTICAS GERAIS:")
    print("=" * 30)
    
    # Contar por status
    from sqlalchemy import func
    status_counts = db.query(Scan.status, func.count(Scan.id)).group_by(Scan.status).all()
    
    for status, count in status_counts:
        print(f"{status}: {count}")
    
    # Verificar scans das últimas 24h
    yesterday = datetime.utcnow() - timedelta(days=1)
    recent_count = db.query(Scan).filter(Scan.created_at >= yesterday).count()
    print(f"📅 Scans últimas 24h: {recent_count}")
    
    db.close()
    
except Exception as e:
    print(f"❌ Erro ao conectar ao banco: {e}")
    import traceback
    traceback.print_exc()
EOF

cd /root/desfollow/backend
source venv/bin/activate
python /tmp/check_scans.py

echo ""
echo "📋 5. Verificando se processo FastAPI está rodando..."
ps aux | grep -E "(uvicorn|fastapi|desfollow)" | grep -v grep

echo ""
echo "📋 6. Verificando logs detalhados do sistema..."
echo "🔍 Últimas 20 linhas do log de erro do Nginx API:"
tail -20 /var/log/nginx/api_error.log 2>/dev/null || echo "Log não encontrado"

echo ""
echo "📋 7. Testando endpoint de scan diretamente..."
echo "🔍 Fazendo scan de teste via API:"

# Fazer um teste simples
TEST_RESPONSE=$(curl -s -X POST "https://api.desfollow.com.br/api/scan" \
  -H "Content-Type: application/json" \
  -d '{"username": "instagram"}' \
  --connect-timeout 10)

echo "Resposta do scan:"
echo "$TEST_RESPONSE" | jq . 2>/dev/null || echo "$TEST_RESPONSE"

echo ""
echo "📋 8. Monitorando logs em tempo real..."
echo "🔍 Para monitorar logs em tempo real, execute:"
echo "   journalctl -u desfollow -f"
echo "   tail -f /var/log/nginx/api_error.log"

echo ""
echo "📋 9. Comandos úteis para debug:"
echo "   systemctl status desfollow"
echo "   systemctl restart desfollow" 
echo "   cd /root/desfollow/backend && source venv/bin/activate && python -c 'from app.database import get_db; print(\"DB OK\")'"

rm -f /tmp/check_scans.py 