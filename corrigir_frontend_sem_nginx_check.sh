#!/bin/bash

echo "🔥 CORREÇÃO FRONTEND - VERSÃO ROBUSTA"
echo "====================================="
echo ""

cd /root/desfollow

# 1. Atualizar código
echo "📋 1. Atualizando código..."
git pull origin main
echo "✅ Código atualizado"

# 2. Limpar tudo
echo ""
echo "📋 2. Limpando caches e builds antigos..."
rm -rf node_modules/.cache
rm -rf dist
npm cache clean --force
echo "✅ Caches limpos"

# 3. Instalar dependências
echo ""
echo "📋 3. Instalando dependências..."
npm install
if [ $? -ne 0 ]; then
    echo "❌ Erro ao instalar dependências"
    exit 1
fi
echo "✅ Dependências instaladas"

# 4. Build
echo ""
echo "📋 4. Fazendo build..."
npm run build
if [ $? -ne 0 ]; then
    echo "❌ Erro no build"
    exit 1
fi

if [ ! -d "dist" ]; then
    echo "❌ Build falhou - dist não encontrado"
    exit 1
fi
echo "✅ Build completado"

# 5. Criar TODOS os diretórios possíveis
echo ""
echo "📋 5. Criando diretórios de frontend..."
mkdir -p /var/www/html/desfollow
mkdir -p /var/www/desfollow
mkdir -p /var/www/html
mkdir -p /var/www/html/www
mkdir -p /usr/share/nginx/html
echo "✅ Diretórios criados"

# 6. Remover TODOS os frontends antigos
echo ""
echo "📋 6. Removendo frontends antigos..."
rm -rf /var/www/html/desfollow/*
rm -rf /var/www/desfollow/*
rm -rf /var/www/html/index.html
rm -rf /var/www/html/www/*
rm -rf /usr/share/nginx/html/index.html
echo "✅ Frontends antigos removidos"

# 7. Copiar para TODOS os locais possíveis
echo ""
echo "📋 7. Copiando frontend para TODOS os locais..."
cp -r dist/* /var/www/html/desfollow/
cp -r dist/* /var/www/desfollow/
cp -r dist/* /var/www/html/
cp -r dist/* /var/www/html/www/
cp -r dist/* /usr/share/nginx/html/
echo "✅ Frontend copiado para todos os locais"

# 8. Corrigir permissões em TODOS
echo ""
echo "📋 8. Corrigindo permissões..."
chown -R www-data:www-data /var/www/html/desfollow
chmod -R 755 /var/www/html/desfollow
chown -R www-data:www-data /var/www/desfollow
chmod -R 755 /var/www/desfollow
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
chown -R www-data:www-data /usr/share/nginx/html
chmod -R 755 /usr/share/nginx/html
echo "✅ Permissões corrigidas"

# 9. Configurar nginx básico se não existir
echo ""
echo "📋 9. Configurando nginx básico..."
cat > /etc/nginx/sites-available/desfollow << 'EOF'
# Frontend - desfollow.com.br
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    
    root /var/www/html/desfollow;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    access_log /var/log/nginx/frontend_access.log;
    error_log /var/log/nginx/frontend_error.log;
}

# API - api.desfollow.com.br
server {
    listen 80;
    server_name api.desfollow.com.br;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    access_log /var/log/nginx/api_access.log;
    error_log /var/log/nginx/api_error.log;
}
EOF

# 10. Habilitar site
echo ""
echo "📋 10. Habilitando site..."
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/desfollow
ln -s /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/
echo "✅ Site habilitado"

# 11. Testar e reiniciar nginx
echo ""
echo "📋 11. Testando e reiniciando nginx..."
nginx -t
if [ $? -eq 0 ]; then
    systemctl restart nginx
    echo "✅ Nginx reiniciado"
else
    echo "❌ Erro na configuração nginx"
    exit 1
fi

# 12. Verificar arquivos finais
echo ""
echo "📋 12. Verificando arquivos finais..."
echo "🔍 Arquivos em /var/www/html/desfollow:"
ls -la /var/www/html/desfollow/ | head -5

echo ""
echo "🔍 Verificando index.html:"
if [ -f "/var/www/html/desfollow/index.html" ]; then
    echo "✅ index.html encontrado"
    echo "📄 Tamanho: $(wc -c < /var/www/html/desfollow/index.html) bytes"
else
    echo "❌ index.html não encontrado"
fi

# 13. Teste final
echo ""
echo "📋 13. Teste final..."
curl -s -I http://localhost/ | head -1

echo ""
echo "✅ CORREÇÃO ROBUSTA COMPLETA!"
echo "============================="
echo ""
echo "🎯 TESTE AGORA:"
echo "1. https://www.desfollow.com.br"
echo "2. Ctrl+Shift+R (hard refresh)"
echo "3. Ou aba anônima"
echo ""
echo "📍 Frontend principal: /var/www/html/desfollow"
echo "📍 Configuração nginx: /etc/nginx/sites-enabled/desfollow"
echo ""
echo "🔍 LOGS SE NECESSÁRIO:"
echo "tail -f /var/log/nginx/frontend_error.log"