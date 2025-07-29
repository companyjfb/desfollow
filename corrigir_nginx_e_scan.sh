#!/bin/bash
echo "🔧 Corrigindo Nginx e forçando novo scan..."
echo "============================================="
echo ""

echo "📋 Verificando erro do Nginx..."
nginx -t
echo ""

echo "🔧 Corrigindo configuração do Nginx..."
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

# Configuração para api.desfollow.com.br (backend)
server {
    listen 80;
    listen [::]:80;
    server_name api.desfollow.com.br;
    
    # Configurações de segurança
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
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

echo "🔄 Recarregando Nginx..."
systemctl reload nginx
echo ""

echo "📋 Verificando status do Nginx..."
systemctl status nginx --no-pager -l
echo ""

echo "🧹 Limpando jobs antigos do banco..."
psql $DATABASE_URL -c "UPDATE scans SET status = 'error' WHERE status = 'done' AND created_at < NOW() - INTERVAL '1 hour';"
echo ""

echo "🔄 Reiniciando backend..."
systemctl restart desfollow
echo ""

echo "⏳ Aguardando 3 segundos para o serviço inicializar..."
sleep 3
echo ""

echo "📋 Verificando status do backend..."
systemctl status desfollow --no-pager -l
echo ""

echo "🧪 Testando scan novo..."
echo "📊 Fazendo scan para jordanbitencourt..."
SCAN_RESPONSE=$(curl -X POST "http://api.desfollow.com.br/api/scan" \
  -H "Content-Type: application/json" \
  -d '{"username": "jordanbitencourt"}' \
  -s)

echo "📋 Resposta do scan:"
echo "$SCAN_RESPONSE"
echo ""

echo "🎯 Extraindo job_id..."
JOB_ID=$(echo "$SCAN_RESPONSE" | grep -o '"job_id":"[^"]*"' | cut -d'"' -f4)
echo "📋 Job ID: $JOB_ID"
echo ""

if [ ! -z "$JOB_ID" ]; then
    echo "⏳ Aguardando 5 segundos para o scan processar..."
    sleep 5
    echo ""
    
    echo "📊 Verificando resultado do scan..."
    curl -s "http://api.desfollow.com.br/api/scan/$JOB_ID" | jq .
else
    echo "❌ Não foi possível obter job_id da resposta"
fi

echo ""
echo "✅ Processo concluído!"
echo ""
echo "🧪 Teste agora:"
echo "   - https://desfollow.com.br"
echo "   - https://www.desfollow.com.br"
echo "   - Ambos devem mostrar o frontend correto"
echo ""
echo "📋 Para monitorar logs em tempo real:"
echo "   journalctl -u desfollow -f" 