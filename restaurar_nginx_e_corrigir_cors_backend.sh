#!/bin/bash

echo "🔧 RESTAURANDO NGINX E CORRIGINDO CORS NO BACKEND"
echo "================================================"

# Parar nginx
echo "📋 1. Parando nginx..."
sudo systemctl stop nginx

# Criar configuração nginx SIMPLES sem CORS
echo "📋 2. Criando configuração nginx SIMPLES (sem CORS)..."
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# CONFIGURAÇÃO NGINX SIMPLES - SEM CORS - DESFOLLOW
# CORS será tratado pelo backend Python
# ===============================================

# HTTP para HTTPS redirect
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# FRONTEND HTTPS
server {
    listen 443 ssl http2;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Certificados SSL (ajustar conforme necessário)
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    
    # SSL básico
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Diretório
    root /var/www/desfollow;
    index index.html;
    
    # Logs
    access_log /var/log/nginx/frontend_access.log;
    error_log /var/log/nginx/frontend_error.log;
    
    # Servir arquivos
    location / {
        try_files $uri $uri/ /index.html;
    }
}

# API HTTPS - SEM CORS (backend Python vai tratar)
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL da API
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    
    # SSL básico
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Logs
    access_log /var/log/nginx/api_access.log;
    error_log /var/log/nginx/api_error.log;
    
    # Proxy SIMPLES para backend (sem CORS - backend vai tratar)
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # Timeouts
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
EOF

# Testar configuração
echo "📋 3. Testando configuração nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração nginx válida"
    
    # Iniciar nginx
    echo "📋 4. Iniciando nginx..."
    sudo systemctl start nginx
    
    echo "✅ Nginx restaurado!"
    
else
    echo "❌ Erro na configuração nginx"
    sudo nginx -t
fi

# Agora corrigir CORS no backend Python
echo ""
echo "📋 5. Corrigindo CORS no backend Python..."

# Verificar se o arquivo main.py existe
if [ -f "backend/app/main.py" ]; then
    echo "✅ Arquivo main.py encontrado"
    
    # Fazer backup do main.py
    cp backend/app/main.py backend/app/main.py.backup.$(date +%Y%m%d_%H%M%S)
    
    # Verificar se FastAPI CORS já está importado
    if grep -q "from fastapi.middleware.cors import CORSMiddleware" backend/app/main.py; then
        echo "✅ CORSMiddleware já importado"
    else
        echo "📋 Adicionando import CORSMiddleware..."
        sed -i '1i from fastapi.middleware.cors import CORSMiddleware' backend/app/main.py
    fi
    
    # Verificar se CORS já está configurado
    if grep -q "add_middleware(CORSMiddleware" backend/app/main.py; then
        echo "✅ CORS já configurado, atualizando..."
        
        # Remover configuração CORS existente
        sed -i '/app\.add_middleware(CORSMiddleware/,/)/d' backend/app/main.py
    fi
    
    # Adicionar configuração CORS TOTAL
    echo "📋 Adicionando configuração CORS TOTAL..."
    
    # Encontrar linha do app = FastAPI() e adicionar CORS após ela
    sed -i '/app = FastAPI/a\\n# CORS Configuration - TOTAL\napp.add_middleware(\n    CORSMiddleware,\n    allow_origins=["*"],  # Permite todas as origens\n    allow_credentials=True,\n    allow_methods=["*"],  # Permite todos os métodos\n    allow_headers=["*"],  # Permite todos os headers\n)' backend/app/main.py
    
    echo "✅ CORS adicionado ao backend!"
    
    # Reiniciar backend
    echo "📋 6. Reiniciando backend..."
    sudo pkill -f "python.*main.py" 2>/dev/null || echo "Backend não estava rodando"
    
    # Aguardar um pouco
    sleep 2
    
    # Iniciar backend em background
    cd backend
    nohup python app/main.py > ../backend.log 2>&1 &
    cd ..
    
    echo "✅ Backend reiniciado!"
    
else
    echo "❌ Arquivo main.py não encontrado em backend/app/"
    echo "Verificando estrutura do projeto..."
    find . -name "main.py" -type f | head -5
fi

echo ""
echo "📋 7. Testando..."
sleep 5

echo "Teste API status:"
curl -I https://api.desfollow.com.br/api/status 2>/dev/null | head -3

echo ""
echo "Teste frontend:"
curl -I https://desfollow.com.br 2>/dev/null | head -3

echo ""
echo "✅ CORREÇÃO CONCLUÍDA!"
echo "===================="
echo "🔗 Frontend: https://desfollow.com.br"
echo "🔗 API: https://api.desfollow.com.br"
echo ""
echo "📱 MUDANÇAS:"
echo "• Nginx: Configuração SIMPLES sem CORS"
echo "• Backend: CORS configurado no FastAPI"
echo "• Allow Origins: * (todas as origens)"
echo "• Allow Methods: * (todos os métodos)"
echo "• Allow Headers: * (todos os headers)"
echo ""
echo "Agora teste o scan no frontend!"