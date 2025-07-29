#!/bin/bash

echo "🔧 Corrigindo CORS Duplicado..."
echo "==============================="
echo ""
echo "🎯 Problema: Headers CORS duplicados entre nginx e backend"
echo "🛠️ Solução: Deixar CORS apenas no backend, nginx apenas proxy"
echo ""

# Função para verificar sucesso
check_success() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ Erro: $1"
        exit 1
    fi
}

echo "📋 1. Atualizando código..."
cd /root/desfollow
git pull origin main
check_success "Código atualizado"

echo ""
echo "📋 2. Criando configuração nginx SEM headers CORS..."

# Backup
cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.cors.$(date +%Y%m%d_%H%M%S)

# Criar configuração nginx que NÃO adiciona headers CORS (deixa pro backend)
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Configuração Nginx - SEM CORS (deixa pro backend)

# Frontend HTTP (desfollow.com.br e www.desfollow.com.br)
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;

    # APENAS headers de segurança (SEM CORS)
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Configuração do frontend React
    root /var/www/desfollow;
    index index.html;

    # SPA - Single Page Application
    location / {
        try_files $uri $uri/ /index.html;
        
        # Cache para arquivos estáticos
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # API Proxy - SEM headers CORS (backend vai adicionar)
    location /api/ {
        # Proxy simples - backend cuida do CORS
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Logs
    access_log /var/log/nginx/desfollow_frontend_access.log;
    error_log /var/log/nginx/desfollow_frontend_error.log;
}

# API HTTP - Redirecionar para HTTPS
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# API HTTPS - Acesso direto à API
server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;

    # SSL
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # APENAS headers de segurança (SEM CORS)
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Strict-Transport-Security "max-age=31536000" always;

    # Proxy simples - backend cuida do CORS
    location / {
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

    # Logs
    access_log /var/log/nginx/desfollow_api_ssl_access.log;
    error_log /var/log/nginx/desfollow_api_ssl_error.log;
}
EOF

check_success "Configuração nginx SEM CORS criada"

echo ""
echo "📋 3. Atualizando backend para CORS completo e correto..."

# Atualizar CORS no backend para ser mais específico
cat > /tmp/cors_fix.py << 'EOF'
import re

# Ler arquivo atual
with open('/root/desfollow/backend/app/main.py', 'r') as f:
    content = f.read()

# CORS específico e correto
new_cors_config = '''# Configuração CORS para domínios de produção (HTTP e HTTPS)
allowed_origins = [
    # Domínios de produção - HTTP
    "http://desfollow.com.br",
    "http://www.desfollow.com.br",
    # Domínios de produção - HTTPS  
    "https://desfollow.com.br",
    "https://www.desfollow.com.br",
    "https://api.desfollow.com.br",
    # Para desenvolvimento local
    "http://localhost:3000",
    "http://localhost:5173",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:5173",
]

# Adiciona domínios de produção se configurados
frontend_url = os.getenv("FRONTEND_URL")
if frontend_url:
    allowed_origins.append(frontend_url)
    allowed_origins.append(frontend_url.replace("https://", "http://"))

logger.info(f"CORS allowed origins: {allowed_origins}")

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)'''

# Substituir toda a seção de CORS
pattern = r'# Configuração CORS.*?allow_headers=\[".*?"\],\s*\)'
content = re.sub(pattern, new_cors_config, content, flags=re.DOTALL)

# Se não encontrou o padrão, substituir o padrão mais simples
if 'allowed_origins' not in content:
    pattern = r'allowed_origins = \[.*?\]'
    replacement = '''allowed_origins = [
    "http://desfollow.com.br",
    "http://www.desfollow.com.br", 
    "https://desfollow.com.br",
    "https://www.desfollow.com.br",
    "https://api.desfollow.com.br",
    "http://localhost:3000",
    "http://localhost:5173",
]'''
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Salvar arquivo
with open('/root/desfollow/backend/app/main.py', 'w') as f:
    f.write(content)

print("✅ CORS atualizado no backend")
EOF

python3 /tmp/cors_fix.py
check_success "Backend CORS corrigido"

echo ""
echo "📋 4. Aplicando configurações..."

# Testar nginx
nginx -t
check_success "Nginx sintaxe OK"

# Recarregar nginx
systemctl reload nginx
check_success "Nginx recarregado"

# Reiniciar backend
systemctl restart desfollow
check_success "Backend reiniciado"

echo ""
echo "📋 5. Aguardando estabilização..."
sleep 8

echo ""
echo "📋 6. Testando CORS..."

echo "🔍 Testando frontend:"
FRONTEND_TEST=$(curl -s http://desfollow.com.br/ | head -1)
if echo "$FRONTEND_TEST" | grep -q "DOCTYPE\|html"; then
    echo "✅ Frontend OK!"
else
    echo "⚠️ Frontend: $FRONTEND_TEST"
fi

echo ""
echo "🔍 Testando CORS via proxy:"
echo "Headers da resposta /api/health:"
curl -I http://desfollow.com.br/api/health 2>/dev/null | grep -i "access-control"

echo ""
echo "🔍 Testando API direta:"
echo "Headers da resposta https://api.desfollow.com.br/:"
curl -I https://api.desfollow.com.br/ 2>/dev/null | grep -i "access-control"

echo ""
echo "✅ CORREÇÃO CORS CONCLUÍDA!"
echo ""
echo "🎯 MUDANÇAS:"
echo "   ❌ Nginx NÃO adiciona mais headers CORS"
echo "   ✅ Backend cuida de TODO o CORS"
echo "   ✅ Evita duplicação de headers"
echo "   ✅ CORS específico por domínio"
echo ""
echo "🔍 TESTE NO NAVEGADOR:"
echo "   Acesse: http://desfollow.com.br/"
echo "   Faça um scan - CORS deve funcionar!"
echo ""
echo "📊 Se ainda houver problemas:"
echo "   - Abra DevTools (F12)"
echo "   - Verifique se ainda há múltiplos Access-Control-Allow-Origin"
echo "   - Deve haver apenas UM header por resposta" 