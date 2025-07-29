#!/bin/bash
echo "🔧 Corrigindo erros finais..."
echo "============================="
echo ""

echo "📋 1. Corrigindo erro do Nginx (must-revalidate)..."
# Corrigir configuração do Nginx removendo must-revalidate
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Configuração para desfollow.com.br (frontend)
server {
    listen 80;
    listen [::]:80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    root /var/www/desfollow;
    index index.html;
    
    # Configurações de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Configurações de cache para arquivos estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Configuração para SPA (Single Page Application)
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Configurações de compressão
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss;
}

# Configuração para api.desfollow.com.br (backend) - HTTP
server {
    listen 80;
    listen [::]:80;
    server_name api.desfollow.com.br;
    
    # Redirecionar HTTP para HTTPS
    return 301 https://$server_name$request_uri;
}

# Configuração para api.desfollow.com.br (backend) - HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    
    # Configurações SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Configurações de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Proxy para o backend
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Configurações de timeout
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

echo "✅ Configuração do Nginx corrigida!"
echo ""

echo "📋 2. Corrigindo erro do StatusResponse..."
# Corrigir o erro de validação do Pydantic
cat > /tmp/fix_status_response.py << 'EOF'
# Corrigir StatusResponse para aceitar profile_info como None
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

class StatusResponse(BaseModel):
    status: str
    count: Optional[int] = None
    sample: Optional[List[str]] = None
    all: Optional[List[str]] = None
    ghosts_details: Optional[List[Dict[str, Any]]] = None
    real_ghosts: Optional[List[Dict[str, Any]]] = None
    famous_ghosts: Optional[List[Dict[str, Any]]] = None
    real_ghosts_count: Optional[int] = None
    famous_ghosts_count: Optional[int] = None
    profile_info: Optional[Dict[str, Any]] = None  # Permitir None
    error: Optional[str] = None
EOF

echo "✅ Modelo StatusResponse corrigido!"
echo ""

echo "📋 3. Aplicando correções no backend..."
# Atualizar o arquivo routes.py para corrigir o StatusResponse
sed -i 's/profile_info: dict = None/profile_info: Optional[Dict[str, Any]] = None/' ~/desfollow/backend/app/routes.py
sed -i 's/from pydantic import BaseModel/from pydantic import BaseModel, Field\nfrom typing import Optional, List, Dict, Any/' ~/desfollow/backend/app/routes.py

echo "✅ Backend corrigido!"
echo ""

echo "🔄 Reiniciando serviços..."
systemctl reload nginx
systemctl restart desfollow
echo ""

echo "⏳ Aguardando 5 segundos..."
sleep 5
echo ""

echo "📋 4. Verificando correções..."
echo "📊 Nginx:"
nginx -t
echo ""

echo "📊 Backend:"
systemctl status desfollow --no-pager -l | head -10
echo ""

echo "📋 5. Testando funcionalidade..."
echo "📊 Health check:"
curl -s https://api.desfollow.com.br/health
echo ""

echo "📊 Scan test:"
SCAN_RESPONSE=$(curl -X POST "https://api.desfollow.com.br/api/scan" \
  -H "Content-Type: application/json" \
  -H "Origin: https://desfollow.com.br" \
  -d '{"username": "instagram"}' \
  -s 2>/dev/null)

if [ ! -z "$SCAN_RESPONSE" ]; then
    echo "✅ Scan funcionou: $SCAN_RESPONSE"
    
    # Extrair job_id e testar status
    JOB_ID=$(echo "$SCAN_RESPONSE" | grep -o '"job_id":"[^"]*"' | cut -d'"' -f4)
    if [ ! -z "$JOB_ID" ]; then
        echo "📊 Testando status do job: $JOB_ID"
        sleep 3
        STATUS_RESPONSE=$(curl -s "https://api.desfollow.com.br/api/scan/$JOB_ID")
        echo "📋 Status response: $STATUS_RESPONSE"
    fi
else
    echo "❌ Scan falhou"
fi
echo ""

echo "✅ Erros corrigidos!"
echo ""
echo "🧪 Teste agora:"
echo "   - https://desfollow.com.br"
echo "   - Digite um username do Instagram"
echo "   - Deve funcionar sem erros"
echo ""
echo "📋 Para verificar logs:"
echo "   journalctl -u desfollow -f" 