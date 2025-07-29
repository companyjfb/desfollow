#!/bin/bash
echo "🌐 Atualizando frontend completo..."
echo "==================================="
echo "📥 Fazendo pull das últimas mudanças..."
cd ~/desfollow
git pull
echo ""

echo "🔧 Verificando se npm está instalado..."
if ! command -v npm &> /dev/null; then
    echo "❌ npm não encontrado! Instalando Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    apt-get install -y nodejs
    echo "✅ Node.js instalado!"
else
    echo "✅ npm já está instalado!"
fi
echo ""

echo "📦 Instalando dependências..."
npm install
echo ""

echo "🏗️ Fazendo build do frontend..."
npm run build
echo ""

echo "📁 Copiando arquivos para o servidor web..."
rm -rf /var/www/desfollow/*
cp -r dist/* /var/www/desfollow/
echo ""

echo "🔧 Definindo permissões..."
chown -R www-data:www-data /var/www/desfollow
chmod -R 755 /var/www/desfollow
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
    gzip_proxied expired no-cache no-store private must-revalidate auth;
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

echo "🔄 Recarregando Nginx..."
systemctl reload nginx
echo ""

echo "📋 Verificando status do Nginx..."
systemctl status nginx --no-pager -l
echo ""

echo "✅ Frontend atualizado!"
echo ""
echo "🧪 Teste agora:"
echo "   - https://desfollow.com.br"
echo "   - https://www.desfollow.com.br"
echo "   - Ambos devem mostrar a mesma versão"
echo ""
echo "📋 Para verificar se está funcionando:"
echo "   curl -I https://desfollow.com.br"
echo "   curl -I https://www.desfollow.com.br" 