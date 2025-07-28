#!/bin/bash

# Script de Deploy Backend - Desfollow
# Execute este script no VPS

echo "🚀 Deploy Backend - Desfollow"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERRO] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[AVISO] $1${NC}"
}

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    error "Execute este script como root (sudo)"
    exit 1
fi

log "📋 Atualizando sistema..."
apt update && apt upgrade -y

log "🔧 Instalando dependências..."
apt install -y python3 python3-pip python3-venv nginx git curl wget

log "📁 Baixando código do backend..."
mkdir -p /root/desfollow
cd /root/desfollow

# Clonar apenas o necessário
git clone https://github.com/companyjfb/desfollow.git .
rm -rf src/ public/ dist/ frontend/ # Remove frontend
rm -f *.bat *.md # Remove arquivos Windows
rm -f test_*.py # Remove arquivos de teste

log "🐍 Configurando ambiente Python..."
python3 -m venv venv
source venv/bin/activate

log "📦 Instalando dependências Python..."
pip install fastapi uvicorn gunicorn psycopg2-binary sqlalchemy python-dotenv python-jose passlib requests

log "📝 Configurando variáveis de ambiente..."
cat > backend/.env << 'EOF'
# Configurações do Banco de Dados (Supabase)
DATABASE_URL=postgresql://postgres:Desfollow-DB2026###@czojjbhgslgbthxzbmyc.supabase.co:5432/postgres

# Configurações da API
RAPIDAPI_KEY=dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01
RAPIDAPI_HOST=instagram-premium-api-2023.p.rapidapi.com

# Configurações de Segurança
SECRET_KEY=desfollow_secret_key_2024_production_secure_123
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Configurações de Produção
ENVIRONMENT=production
DEBUG=False
ALLOWED_HOSTS=desfollow.com.br,www.desfollow.com.br,api.desfollow.com.br

# Configurações do Frontend
FRONTEND_URL=https://desfollow.com.br
EOF

warning "⚠️ IMPORTANTE: Edite o arquivo backend/.env com sua DATABASE_URL do Supabase!"

log "🔧 Configurando serviço do sistema..."
cat > /etc/systemd/system/desfollow.service << 'EOF'
[Unit]
Description=Desfollow Backend
After=network.target

[Service]
User=root
WorkingDirectory=/root/desfollow/backend
Environment="PATH=/root/desfollow/venv/bin"
ExecStart=/root/desfollow/venv/bin/gunicorn app.main:app -c gunicorn.conf.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

log "📋 Criando configuração do Gunicorn..."
cat > backend/gunicorn.conf.py << 'EOF'
# Configuração do Gunicorn para produção
import multiprocessing

# Configurações básicas
bind = "0.0.0.0:8000"
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "uvicorn.workers.UvicornWorker"
timeout = 120
keepalive = 2

# Configurações de logging
accesslog = "-"
errorlog = "-"
loglevel = "info"

# Configurações de segurança
limit_request_line = 4094
limit_request_fields = 100
limit_request_field_size = 8190

# Configurações de performance
max_requests = 1000
max_requests_jitter = 50
preload_app = True

# Configurações de worker
worker_connections = 1000
worker_tmp_dir = "/dev/shm"
EOF

log "🌐 Configurando Nginx..."
cat > /etc/nginx/sites-available/desfollow << 'EOF'
server {
    listen 80;
    server_name api.desfollow.com.br;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=5r/s;

    # Headers de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Configuração da API
    location / {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Configuração específica para autenticação
    location /api/auth/ {
        limit_req zone=login burst=10 nodelay;
        
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Configuração para health check
    location /health {
        access_log off;
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
    }

    # Logs
    access_log /var/log/nginx/desfollow_access.log;
    error_log /var/log/nginx/desfollow_error.log;
}
EOF

log "🔗 Habilitando configuração do Nginx..."
ln -sf /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

log "🧪 Testando configuração do Nginx..."
nginx -t

if [ $? -eq 0 ]; then
    log "✅ Configuração do Nginx válida"
else
    error "❌ Erro na configuração do Nginx"
    exit 1
fi

log "🚀 Iniciando serviços..."
systemctl daemon-reload
systemctl enable desfollow
systemctl start desfollow
systemctl restart nginx

log "📊 Verificando status dos serviços..."

# Verificar se o serviço está rodando
if systemctl is-active --quiet desfollow; then
    log "✅ Serviço Desfollow está rodando"
else
    error "❌ Serviço Desfollow não está rodando"
    systemctl status desfollow
fi

# Verificar se o Nginx está rodando
if systemctl is-active --quiet nginx; then
    log "✅ Nginx está rodando"
else
    error "❌ Nginx não está rodando"
    systemctl status nginx
fi

log "🔧 Configurando firewall..."
ufw allow ssh
ufw allow 80
ufw allow 443
ufw --force enable

log "✅ Deploy do Backend concluído!"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "1. Edite o arquivo backend/.env com sua DATABASE_URL do Supabase"
echo "2. Reinicie o serviço: systemctl restart desfollow"
echo "3. Teste a API: curl http://localhost:8000/health"
echo "4. Configure o DNS para api.desfollow.com.br"
echo "5. Deploy do frontend no Hostinger"
echo ""
echo "🔍 Comandos úteis:"
echo "- Ver logs: journalctl -u desfollow -f"
echo "- Status: systemctl status desfollow"
echo "- Reiniciar: systemctl restart desfollow"
echo "- Logs Nginx: tail -f /var/log/nginx/error.log" 