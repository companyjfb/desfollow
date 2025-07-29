#!/bin/bash

echo "🔧 Instalando dependências para sistema de limpeza..."
echo "=================================================="

echo "📋 Verificando dependências..."

# Verificar se psycopg2 está instalado
if ! python3 -c "import psycopg2" 2>/dev/null; then
    echo "❌ psycopg2 não está instalado!"
    echo "🔧 Instalando psycopg2..."
    pip3 install psycopg2-binary
else
    echo "✅ psycopg2 já está instalado!"
fi

# Verificar se python-dotenv está instalado
if ! python3 -c "import dotenv" 2>/dev/null; then
    echo "❌ python-dotenv não está instalado!"
    echo "🔧 Instalando python-dotenv..."
    pip3 install python-dotenv
else
    echo "✅ python-dotenv já está instalado!"
fi

echo ""
echo "🛑 Parando serviço atual..."
systemctl stop desfollow-limpeza

echo "🚀 Reiniciando serviço..."
systemctl start desfollow-limpeza

echo ""
echo "📋 Verificando status..."
systemctl status desfollow-limpeza --no-pager

echo ""
echo "🔍 Verificando logs..."
journalctl -u desfollow-limpeza --no-pager -n 10

echo ""
echo "✅ Dependências instaladas e serviço reiniciado!"
echo ""
echo "📋 Para monitorar:"
echo "   journalctl -u desfollow-limpeza -f"
echo "   tail -f /var/log/desfollow/limpeza_automatica.log" 