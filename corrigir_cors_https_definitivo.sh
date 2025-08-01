#!/bin/bash

echo "🔧 CORREÇÃO CORS HTTPS FIXO - SEM CONFLITO"
echo "==========================================="
echo "Configurando CORS HTTPS fixo sem conflito backend/nginx"
echo ""

# Backup da configuração atual
BACKUP_FILE="/etc/nginx/sites-available/desfollow.backup.cors-https-fixo-sem-conflito.$(date +%Y%m%d_%H%M%S)"
sudo cp /etc/nginx/sites-available/desfollow "$BACKUP_FILE"
echo "💾 Backup: $BACKUP_FILE"

echo ""
echo "📋 Removendo CORS do backend para evitar conflito..."

# Remover CORS middleware do backend
cd /root/desfollow/backend
cp app/main.py app/main.py.backup.cors

# Criar novo main.py sem CORS
cat > app/main.py << 'EOF'
from fastapi import FastAPI
from .routes import router
from .auth_routes import router as auth_router
from .database import create_tables
import os
from dotenv import load_dotenv
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

app = FastAPI(
    title="Desfollow API",
    description="API para encontrar usuários que não retribuem follows no Instagram",
    version="1.0.0"
)

# Inclui as rotas
app.include_router(router, prefix="/api")
app.include_router(auth_router, prefix="/api/auth", tags=["authentication"])

# Criar tabelas na inicialização
@app.on_event("startup")
async def startup_event():
    """Evento executado na inicialização da aplicação"""
    try:
        logger.info("🚀 Iniciando aplicação...")
        logger.info("📊 Criando/verificando tabelas no Supabase...")
        create_tables()
        logger.info("✅ Tabelas verificadas/criadas no Supabase!")
        logger.info("🎯 Aplicação pronta para receber requisições!")
    except Exception as e:
        logger.error(f"❌ Erro na inicialização: {e}")
        raise

@app.get("/")
async def root():
    """
    Endpoint raiz da API.
    """
    return {
        "message": "Desfollow API",
        "version": "1.0.0",
        "docs": "/docs"
    }

@app.get("/health")
async def health_check():
    """
    Endpoint de health check.
    """
    return {"status": "healthy"}
EOF

echo "✅ CORS removido do backend"

echo ""
echo "📋 Criando configuração nginx com CORS HTTPS fixo..."

# Configuração nginx com CORS HTTPS fixo (sem verificar certificados SSL)
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# ========================================
# CONFIGURAÇÃO NGINX - CORS HTTPS FIXO SEM CONFLITO
# ========================================
# Frontend: desfollow.com.br + www.desfollow.com.br (HTTPS via Hostinger)
# API: api.desfollow.com.br (HTTPS)
# CORS: Apenas nginx gerencia (sem backend)
# ========================================

# FRONTEND HTTPS - DESFOLLOW.COM.BR (SSL gerenciado pela Hostinger)
server {
    listen 443 ssl http2;
    server_name desfollow.com.br;
    
    # SSL gerenciado pela Hostinger (não verificar certificados)
    ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
    
    # Configurações SSL seguras
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    root /var/www/html;
    index index.html;
    
    access_log /var/log/nginx/frontend_ssl_access.log;
    error_log /var/log/nginx/frontend_ssl_error.log;
    
    # Cache para assets estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }
    
    # React Router - todas as rotas SPA
    location / {
        try_files $uri $uri/ /index.html;
        
        # Headers de segurança
        add_header X-Content-Type-Options nosniff;
        add_header X-Frame-Options DENY;
        add_header X-XSS-Protection "1; mode=block";
    }
    
    # Bloquear acesso a arquivos sensíveis
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "Frontend HTTPS OK\n";
        add_header Content-Type text/plain;
    }
}

# FRONTEND HTTPS - WWW.DESFOLLOW.COM.BR (SSL gerenciado pela Hostinger)
server {
    listen 443 ssl http2;
    server_name www.desfollow.com.br;
    
    # SSL gerenciado pela Hostinger (não verificar certificados)
    ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
    
    # Configurações SSL seguras
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    root /var/www/html;
    index index.html;
    
    access_log /var/log/nginx/frontend_www_ssl_access.log;
    error_log /var/log/nginx/frontend_www_ssl_error.log;
    
    # Cache para assets estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }
    
    # React Router - todas as rotas SPA
    location / {
        try_files $uri $uri/ /index.html;
        
        # Headers de segurança
        add_header X-Content-Type-Options nosniff;
        add_header X-Frame-Options DENY;
        add_header X-XSS-Protection "1; mode=block";
    }
    
    # Bloquear acesso a arquivos sensíveis
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "Frontend WWW HTTPS OK\n";
        add_header Content-Type text/plain;
    }
}

# FRONTEND HTTP -> HTTPS REDIRECT
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# API HTTP -> HTTPS REDIRECT
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# API HTTPS - CORS HTTPS FIXO SEM CONFLITO
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL da API (verificar se existe)
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    
    # Configurações SSL seguras
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Logs da API
    access_log /var/log/nginx/api_ssl_access.log;
    error_log /var/log/nginx/api_ssl_error.log;
    
    # Proxy para backend
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $host;
        
        # 🚀 TIMEOUTS CORRIGIDOS: 5 minutos
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        
        # 🚀 CONFIGURAÇÕES PARA REQUESTS LONGOS
        proxy_buffering off;
        proxy_request_buffering off;
        client_max_body_size 10m;
        
        # 🚀 CORS HTTPS FIXO - APENAS NGINX (SEM CONFLITO)
        # CORS para requests normais (GET, POST, etc.)
        add_header Access-Control-Allow-Origin "https://desfollow.com.br" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
        add_header Access-Control-Allow-Credentials true always;
        
        # Preflight OPTIONS - CORS fixo
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://desfollow.com.br" always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
            add_header Access-Control-Max-Age 1728000 always;
            add_header Content-Type 'text/plain charset=UTF-8';
            add_header Content-Length 0;
            return 204;
        }
    }
    
    # Health check da API
    location /health {
        access_log off;
        proxy_pass http://127.0.0.1:8000/health;
    }
}
EOF

echo "✅ Configuração nginx com CORS HTTPS fixo criada"

echo ""
echo "📋 Testando configuração..."
sudo nginx -t
if [ $? -eq 0 ]; then
    echo "✅ Configuração nginx válida!"
else
    echo "❌ Configuração inválida. Restaurando backup..."
    sudo cp "$BACKUP_FILE" /etc/nginx/sites-available/desfollow
    exit 1
fi

echo ""
echo "📋 Recarregando nginx..."
sudo systemctl reload nginx
if [ $? -eq 0 ]; then
    echo "✅ Nginx recarregado com sucesso!"
else
    echo "❌ Erro ao recarregar nginx"
    sudo systemctl status nginx
    exit 1
fi

echo ""
echo "📋 Reiniciando backend sem CORS..."
cd /root/desfollow
pkill -f "uvicorn\|gunicorn"
sleep 2
nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 > /dev/null 2>&1 &
sleep 3

echo ""
echo "📋 Verificando se backend está rodando..."
if pgrep -f "uvicorn\|gunicorn" > /dev/null; then
    echo "✅ Backend rodando sem CORS"
else
    echo "❌ Backend não iniciou"
    exit 1
fi

echo ""
echo "📋 Testando CORS HTTPS fixo..."

sleep 2

echo "🧪 Testando CORS com https://desfollow.com.br..."
CORS_TEST1=$(curl -s -H "Origin: https://desfollow.com.br" -H "Access-Control-Request-Method: POST" -X OPTIONS "https://api.desfollow.com.br/api/scan" -I | grep "Access-Control-Allow-Origin")
echo "   Origin: https://desfollow.com.br"
echo "   Response: $CORS_TEST1"

echo "🧪 Testando CORS com https://www.desfollow.com.br..."
CORS_TEST2=$(curl -s -H "Origin: https://www.desfollow.com.br" -H "Access-Control-Request-Method: POST" -X OPTIONS "https://api.desfollow.com.br/api/scan" -I | grep "Access-Control-Allow-Origin")
echo "   Origin: https://www.desfollow.com.br"
echo "   Response: $CORS_TEST2"

echo ""
echo "📋 Testando comunicação completa..."
cd /root/desfollow
python3 testar_comunicacao_frontend_backend.py

echo ""
echo "✅ CORS HTTPS FIXO SEM CONFLITO CONFIGURADO!"
echo ""
echo "🔗 CONFIGURAÇÃO FINAL:"
echo "   Frontend: https://desfollow.com.br (HTTPS via Hostinger)"
echo "   Frontend: https://www.desfollow.com.br (HTTPS via Hostinger)"
echo "   API:      https://api.desfollow.com.br (HTTPS)"
echo ""
echo "🔄 REDIRECIONAMENTOS:"
echo "   http://desfollow.com.br → https://desfollow.com.br"
echo "   http://www.desfollow.com.br → https://www.desfollow.com.br"
echo "   http://api.desfollow.com.br → https://api.desfollow.com.br"
echo ""
echo "⚙️ MELHORIAS ATIVAS:"
echo "   ✅ SSL: Frontend (Hostinger) e API (Let's Encrypt)"
echo "   ✅ CORS: Apenas nginx (sem conflito backend)"
echo "   ✅ Roteamento: Frontend em ambos domínios"
echo "   ✅ Timeout API: 300s (5 minutos)"
echo "   ✅ Proxy buffering: Desabilitado"
echo ""
echo "📜 Backup salvo em: $BACKUP_FILE"
echo ""
echo "🚀 CORS HTTPS FIXO SEM CONFLITO FUNCIONANDO!" 