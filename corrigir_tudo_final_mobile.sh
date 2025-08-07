#!/bin/bash

echo "🔧 CORREÇÃO COMPLETA FINAL MOBILE - DESFOLLOW"
echo "============================================="

# Parar nginx
echo "📋 1. Parando nginx..."
sudo systemctl stop nginx

# Corrigir diretórios (estava usando /var/www/html mas deveria ser /var/www/desfollow)
echo "📋 2. Corrigindo estrutura de diretórios..."
sudo mkdir -p /var/www/desfollow/lovable-uploads
sudo mkdir -p /var/www/desfollow/assets

# Copiar conteúdo do /var/www/html para /var/www/desfollow se existir
if [ -d "/var/www/html" ]; then
    echo "Copiando conteúdo de /var/www/html para /var/www/desfollow..."
    sudo cp -r /var/www/html/* /var/www/desfollow/ 2>/dev/null || echo "Nada para copiar"
fi

# Baixar TODAS as imagens usando a mesma lista do arquivo de referência
echo "📋 3. Baixando todas as imagens necessárias..."

# Lista de TODAS as imagens (do arquivo de referência)
IMAGES=(
    "1d8d06b0-0cee-415e-830b-f8094ab140fd.png"
    "33aa29b9-8e1b-4bbd-a830-a39142d2eef1.png" 
    "3f21f968-4705-48bb-921d-907787e583ff.png"
    "5d54a518-3ff7-4b96-b3dd-77d03dd31085.png"
    "82f11f27-4149-4c8f-b121-63897652035d.png"
    "8e9dfc00-1145-43b9-9f22-4a3de6e807ca.png"
    "9f866110-593f-4b97-8114-69e63345ffb3.png"
    "a1ff2d2a-90ed-4aca-830b-0fa8e772a3ad.png"
    "a9f1cd9e-460a-4d40-af75-71acabe926f4.png"
    "ac56c453-f95e-4cc3-81cf-3e0af07a8e7a.png"
    "af2d2ebb-fbfe-482f-8498-03515c511b97.png"
    "b1878feb-16ec-438c-8e37-5258266aedd6.png"
    "b69b3d01-243c-426a-88d2-7611e32539a1.png"
    "b7dde072-9f5b-476f-80ea-ff351b4129bd.png"
    "c66eb0c2-8d6f-4575-93e6-9aa364372325.png"
    "c86c9416-e19f-4e6c-b96a-981764455220.png"
    "da90f167-2ab5-4f82-a0e3-3d89f44d82f8.png"
    "e4cc8fae-cf86-4234-83bc-7a4cbb3e3537.png"
    "e68925cd-de9e-4a40-af01-9140ea754f19.png"
    "f0a979d5-6bb6-41bf-b8da-6791918e6540.png"
    "f49c8773-7b38-43af-8a3b-1142b88459e2.png"
    "f7070929-4370-4211-b4f1-2d25ab32b73a.png"
)

# Baixar imagens via HTTP da Hostinger
for img in "${IMAGES[@]}"; do
    echo "📥 Baixando $img..."
    sudo wget -q -O "/var/www/desfollow/lovable-uploads/$img" "http://www.desfollow.com.br/lovable-uploads/$img"
    if [ $? -eq 0 ]; then
        echo "✅ $img baixado com sucesso"
    else
        echo "⚠️ Erro ao baixar $img"
    fi
done

# Baixar favicon e outros arquivos
echo "📥 Baixando favicon.ico..."
sudo wget -q -O "/var/www/desfollow/favicon.ico" "http://www.desfollow.com.br/favicon.ico"

echo "📥 Baixando robots.txt..."  
sudo wget -q -O "/var/www/desfollow/robots.txt" "http://www.desfollow.com.br/robots.txt"

# Ajustar permissões
echo "📋 4. Ajustando permissões..."
sudo chown -R www-data:www-data /var/www/desfollow/
sudo chmod -R 755 /var/www/desfollow/

# Criar configuração nginx ULTRA SIMPLES
echo "📋 5. Aplicando configuração nginx ULTRA SIMPLES..."
sudo tee /etc/nginx/sites-available/desfollow > /dev/null << 'EOF'
# CONFIGURAÇÃO NGINX ULTRA SIMPLES - DESFOLLOW MOBILE
# ===================================================

# HTTP para HTTPS redirect
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

# FRONTEND HTTPS - CONFIGURAÇÃO MÍNIMA
server {
    listen 443 ssl;
    server_name desfollow.com.br www.desfollow.com.br;
    
    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/desfollow.com.br/privkey.pem;
    
    # SSL MÍNIMO - máxima compatibilidade
    ssl_protocols TLSv1.2;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    
    # Diretório correto
    root /var/www/desfollow;
    index index.html;
    
    # Logs
    access_log /var/log/nginx/frontend_access.log;
    error_log /var/log/nginx/frontend_error.log;
    
    # Servir TODAS as imagens e assets
    location / {
        try_files $uri $uri/ /index.html;
    }
}

# API SIMPLES
server {
    listen 80;
    server_name api.desfollow.com.br;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name api.desfollow.com.br;
    
    ssl_certificate /etc/letsencrypt/live/api.desfollow.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.desfollow.com.br/privkey.pem;
    
    ssl_protocols TLSv1.2;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    
    location / {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization';
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
        
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Testar configuração
echo "📋 6. Testando configuração..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração válida"
    
    # Iniciar nginx
    echo "📋 7. Iniciando nginx..."
    sudo systemctl start nginx
    
    # Aguardar
    sleep 3
    
    # Testes
    echo "📋 8. Executando testes finais..."
    
    echo "Verificando estrutura de diretórios:"
    ls -la /var/www/desfollow/ | head -5
    echo ""
    ls -la /var/www/desfollow/lovable-uploads/ | head -5
    
    echo ""
    echo "Teste HTTP redirect:"
    curl -sI http://desfollow.com.br | head -2
    
    echo ""
    echo "Teste HTTPS:"
    timeout 10 curl -sI https://desfollow.com.br --insecure | head -2
    
    echo ""
    echo "Teste imagem:"
    timeout 10 curl -sI https://desfollow.com.br/lovable-uploads/82f11f27-4149-4c8f-b121-63897652035d.png --insecure | head -2
    
    echo ""
    echo "✅ CORREÇÃO COMPLETA FINALIZADA!"
    echo "==============================="
    echo "🔗 Frontend: https://desfollow.com.br"
    echo "🔗 API: https://api.desfollow.com.br"
    echo ""
    echo "📱 CORREÇÕES APLICADAS:"
    echo "• Diretório correto: /var/www/desfollow"
    echo "• Todas as imagens baixadas"
    echo "• SSL ultra simples (TLS 1.2 apenas)"
    echo "• Configuração mínima nginx"
    echo "• Permissões corretas"
    
else
    echo "❌ Erro na configuração nginx"
    sudo nginx -t
fi

echo ""
echo "📋 9. TESTE NO MOBILE:"
echo "1. Força refresh no Safari (cmd+shift+R)"
echo "2. Tenta em modo privado"
echo "3. Limpa cache e dados do Safari"
echo "4. Testa em rede 4G (não WiFi)"