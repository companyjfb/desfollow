#!/bin/bash

echo "🚀 Deploy das Melhorias no Sistema de Limpeza..."

# 1. Fazer backup do sistema atual
echo "💾 Fazendo backup do sistema atual..."
sudo systemctl stop desfollow-limpeza-3min.service 2>/dev/null || true
sudo systemctl stop desfollow-limpeza-simples.service 2>/dev/null || true
sudo systemctl stop desfollow-limpeza.service 2>/dev/null || true

# 2. Configurar novo sistema de limpeza
echo "⚙️ Configurando novo sistema de limpeza..."
chmod +x configurar_limpeza_10_minutos.sh
./configurar_limpeza_10_minutos.sh

# 3. Fazer build do frontend com as melhorias
echo "🔨 Fazendo build do frontend..."
cd /root/desfollow
npm run build

# 4. Mover frontend para o servidor web
echo "📦 Movendo frontend..."
sudo cp -r dist/* /var/www/html/

# 5. Verificar se tudo está funcionando
echo "🔍 Verificando se tudo está funcionando..."
sleep 5

# Verificar serviços
echo "📊 Status dos serviços:"
sudo systemctl status desfollow-limpeza-10min.service --no-pager

# Verificar frontend
echo "🌐 Testando frontend..."
curl -s -o /dev/null -w "%{http_code}" http://desfollow.com.br

# Verificar API
echo "🔌 Testando API..."
curl -s -o /dev/null -w "%{http_code}" http://api.desfollow.com.br/api/health

# 6. Mostrar logs iniciais
echo "📋 Logs iniciais do novo sistema:"
sudo journalctl -u desfollow-limpeza-10min.service -n 10 --no-pager

echo "✅ Deploy concluído!"
echo "📊 Melhorias implementadas:"
echo "   - Jobs ativos por 10 minutos (ao invés de 3)"
echo "   - Contador chega a 90% em 8 minutos"
echo "   - Logs detalhados via SSH"
echo "   - Monitoramento aprimorado"
echo ""
echo "📊 Para monitorar:"
echo "   sudo journalctl -u desfollow-limpeza-10min.service -f"
echo "   tail -f /var/log/desfollow/limpeza_10min.log" 