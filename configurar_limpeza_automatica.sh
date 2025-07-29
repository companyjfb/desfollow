#!/bin/bash

echo "🔧 Configurando sistema de limpeza automática..."
echo "================================================"

echo "📋 Verificando dependências..."

# Verificar se psycopg2 está instalado
if ! python3 -c "import psycopg2" 2>/dev/null; then
    echo "❌ psycopg2 não está instalado!"
    echo "🔧 Instalando psycopg2..."
    pip3 install psycopg2-binary
else
    echo "✅ psycopg2 já está instalado!"
fi

echo ""
echo "🔧 Configurando serviço de limpeza automática..."

# Copiar arquivo de serviço
cp desfollow-limpeza.service /etc/systemd/system/

# Recarregar systemd
systemctl daemon-reload

# Habilitar e iniciar o serviço
systemctl enable desfollow-limpeza
systemctl start desfollow-limpeza

echo ""
echo "📋 Verificando status do serviço..."
systemctl status desfollow-limpeza --no-pager

echo ""
echo "🔍 Verificando logs..."
journalctl -u desfollow-limpeza --no-pager -n 10

echo ""
echo "✅ Sistema de limpeza automática configurado!"
echo ""
echo "📋 Comandos úteis:"
echo "   - Ver status: systemctl status desfollow-limpeza"
echo "   - Ver logs: journalctl -u desfollow-limpeza -f"
echo "   - Parar: systemctl stop desfollow-limpeza"
echo "   - Iniciar: systemctl start desfollow-limpeza"
echo "   - Reiniciar: systemctl restart desfollow-limpeza"
echo ""
echo "📊 O sistema irá:"
echo "   - Limpar jobs running > 30 minutos"
echo "   - Limpar jobs queued > 10 minutos"
echo "   - Limpar jobs antigos > 24 horas"
echo "   - Alertar se houver > 20 jobs ativos"
echo "   - Executar a cada 5 minutos"
echo ""
echo "📁 Logs: /var/log/desfollow/limpeza_automatica.log" 