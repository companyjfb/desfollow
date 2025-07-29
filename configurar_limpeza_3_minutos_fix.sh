#!/bin/bash

echo "🔧 Configurando Sistema de Limpeza 3 Minutos..."
echo "==============================================="
echo ""
echo "⏱️ NOVO SISTEMA: Jobs órfãos serão limpos após 3 minutos"
echo "🔄 FREQUÊNCIA: Verificação a cada 30 segundos"
echo "🎯 OBJETIVO: Manter jobs_active sempre baixo"
echo ""

# Função para verificar se comando foi executado com sucesso
check_success() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ Erro: $1"
        exit 1
    fi
}

echo "📋 1. Verificando dependências..."

# Verificar se psycopg2 está instalado
if ! python3 -c "import psycopg2" 2>/dev/null; then
    echo "❌ psycopg2 não está instalado!"
    echo "🔧 Instalando psycopg2..."
    pip3 install psycopg2-binary
    check_success "psycopg2-binary instalado"
else
    echo "✅ psycopg2 já está instalado!"
fi

# Verificar se requests está instalado
if ! python3 -c "import requests" 2>/dev/null; then
    echo "❌ requests não está instalado!"
    echo "🔧 Instalando requests..."
    pip3 install requests
    check_success "requests instalado"
else
    echo "✅ requests já está instalado!"
fi

# Verificar se python-dotenv está instalado
if ! python3 -c "import dotenv" 2>/dev/null; then
    echo "❌ python-dotenv não está instalado!"
    echo "🔧 Instalando python-dotenv..."
    pip3 install python-dotenv
    check_success "python-dotenv instalado"
else
    echo "✅ python-dotenv já está instalado!"
fi

echo ""
echo "📋 2. Parando serviço antigo (se existir)..."
systemctl stop desfollow-limpeza 2>/dev/null && echo "✅ Serviço antigo parado" || echo "ℹ️ Serviço antigo não estava rodando"

echo ""
echo "📋 3. Criando diretório de logs..."
mkdir -p /var/log/desfollow
check_success "Diretório de logs criado"

echo ""
echo "📋 4. Verificando arquivos do sistema..."

# Verificar se estamos no diretório correto
if [ ! -f "sistema_limpeza_3_minutos.py" ]; then
    echo "❌ Arquivo sistema_limpeza_3_minutos.py não encontrado!"
    echo "🔧 Certifique-se de estar no diretório correto (/root/desfollow)"
    exit 1
fi

# Verificar se já existe no local correto ou se precisa copiar
if [ "$(pwd)" != "/root/desfollow" ]; then
    echo "📁 Copiando arquivos para /root/desfollow..."
    cp sistema_limpeza_3_minutos.py /root/desfollow/
    check_success "Script principal copiado"
else
    echo "✅ Já estamos no diretório correto"
fi

# Tornar executável
chmod +x sistema_limpeza_3_minutos.py
check_success "Permissões de execução definidas"

# Copiar arquivo de serviço
cp desfollow-limpeza-3min.service /etc/systemd/system/
check_success "Arquivo de serviço copiado"

echo ""
echo "📋 5. Configurando systemd..."

# Recarregar systemd
systemctl daemon-reload
check_success "Daemon recarregado"

# Habilitar serviço
systemctl enable desfollow-limpeza-3min
check_success "Serviço habilitado"

echo ""
echo "📋 6. Testando conexão com banco antes de iniciar..."
python3 -c "
import sys
import os
sys.path.append('/root/desfollow')
sys.path.append('.')

# Tentar carregar o módulo
try:
    from sistema_limpeza_3_minutos import conectar_supabase
    conn = conectar_supabase()
    if conn:
        print('✅ Conexão com banco OK')
        conn.close()
    else:
        print('❌ Falha na conexão com banco')
        exit(1)
except Exception as e:
    print(f'❌ Erro ao testar conexão: {e}')
    exit(1)
"
check_success "Conexão com banco testada"

echo ""
echo "📋 7. Iniciando serviço..."
systemctl start desfollow-limpeza-3min
check_success "Serviço iniciado"

echo ""
echo "📋 8. Aguardando inicialização..."
sleep 5

echo ""
echo "📋 9. Verificando status do serviço..."
if systemctl is-active --quiet desfollow-limpeza-3min; then
    echo "✅ Serviço está ativo e rodando"
    systemctl status desfollow-limpeza-3min --no-pager --lines=5
else
    echo "❌ Serviço não está rodando - verificando erro..."
    systemctl status desfollow-limpeza-3min --no-pager --lines=10
fi
echo ""

echo "📋 10. Verificando logs iniciais..."
journalctl -u desfollow-limpeza-3min --no-pager -n 5
echo ""

echo "📋 11. Testando API health..."
# Fazer chamada HTTP como especificado na memória
API_RESPONSE=$(curl -s http://api.desfollow.com.br/api/health 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "$API_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "API respondeu: $API_RESPONSE"
else
    echo "⚠️ Não foi possível conectar à API"
fi
echo ""

echo "✅ SISTEMA DE LIMPEZA 3 MINUTOS CONFIGURADO!"
echo ""
echo "📊 CONFIGURAÇÕES:"
echo "   - Intervalo de verificação: 30 segundos"
echo "   - Jobs running limpos após: 3 minutos"
echo "   - Jobs queued limpos após: 2 minutos"
echo "   - Limpeza forçada se jobs > 5"
echo ""
echo "📋 COMANDOS ÚTEIS:"
echo "   - Ver status: systemctl status desfollow-limpeza-3min"
echo "   - Ver logs: journalctl -u desfollow-limpeza-3min -f"
echo "   - Parar: systemctl stop desfollow-limpeza-3min"
echo "   - Reiniciar: systemctl restart desfollow-limpeza-3min"
echo ""
echo "📁 ARQUIVOS:"
echo "   - Script: /root/desfollow/sistema_limpeza_3_minutos.py"
echo "   - Logs: /var/log/desfollow/limpeza_3min.log"
echo "   - Serviço: /etc/systemd/system/desfollow-limpeza-3min.service"
echo ""
echo "🎯 O sistema agora deve manter jobs_active sempre baixo!"
echo ""

# Mostrar comando para monitorar em tempo real
echo "📊 Para monitorar em tempo real:"
echo "   watch -n 2 'curl -s http://api.desfollow.com.br/api/health | python3 -m json.tool'" 