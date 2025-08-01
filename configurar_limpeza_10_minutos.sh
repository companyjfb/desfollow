#!/bin/bash

echo "🚀 Configurando Sistema de Limpeza 10 Minutos..."

# Parar sistema antigo se estiver rodando
echo "🛑 Parando sistema de limpeza antigo..."
sudo systemctl stop desfollow-limpeza-3min.service 2>/dev/null || true
sudo systemctl stop desfollow-limpeza-simples.service 2>/dev/null || true
sudo systemctl stop desfollow-limpeza.service 2>/dev/null || true

# Criar diretório de logs
echo "📁 Criando diretório de logs..."
sudo mkdir -p /var/log/desfollow

# Tornar script executável
echo "🔧 Tornando script executável..."
chmod +x sistema_limpeza_10_minutos.py

# Criar service file
echo "⚙️ Criando service file..."
sudo tee /etc/systemd/system/desfollow-limpeza-10min.service > /dev/null <<EOF
[Unit]
Description=Desfollow Limpeza 10 Minutos
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/desfollow
ExecStart=/usr/bin/python3 /root/desfollow/sistema_limpeza_10_minutos.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Recarregar systemd
echo "🔄 Recarregando systemd..."
sudo systemctl daemon-reload

# Habilitar e iniciar serviço
echo "🚀 Habilitando e iniciando serviço..."
sudo systemctl enable desfollow-limpeza-10min.service
sudo systemctl start desfollow-limpeza-10min.service

# Verificar status
echo "📊 Verificando status..."
sudo systemctl status desfollow-limpeza-10min.service --no-pager

# Mostrar logs recentes
echo "📋 Logs recentes:"
sudo journalctl -u desfollow-limpeza-10min.service -n 10 --no-pager

echo "✅ Sistema de limpeza 10 minutos configurado!"
echo "📊 Para ver logs em tempo real: sudo journalctl -u desfollow-limpeza-10min.service -f"
echo "🛑 Para parar: sudo systemctl stop desfollow-limpeza-10min.service"
echo "🚀 Para reiniciar: sudo systemctl restart desfollow-limpeza-10min.service" 