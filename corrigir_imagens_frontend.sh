#!/bin/bash

echo "🖼️ CORRIGINDO IMAGENS DO FRONTEND"
echo "================================="

# Criar diretório de imagens
echo "📋 1. Criando diretório de imagens..."
sudo mkdir -p /var/www/desfollow/lovable-uploads

# Download das imagens do frontend
echo "📋 2. Baixando imagens do frontend..."

# Logo principal
curl -o /tmp/logo.png "https://lovable.dev/uploads/b7dde072-9f5b-476f-80ea-ff351b4129bd.png" 2>/dev/null
if [ $? -eq 0 ]; then
    sudo cp /tmp/logo.png /var/www/desfollow/lovable-uploads/b7dde072-9f5b-476f-80ea-ff351b4129bd.png
    echo "✅ Logo baixado"
else
    # Criar logo simples como fallback
    echo "⚠️ Criando logo placeholder..."
    sudo tee /var/www/desfollow/lovable-uploads/b7dde072-9f5b-476f-80ea-ff351b4129bd.png > /dev/null << 'EOF'
<svg width="64" height="64" xmlns="http://www.w3.org/2000/svg">
  <rect width="64" height="64" fill="#3B82F6"/>
  <text x="32" y="40" text-anchor="middle" fill="white" font-size="24" font-weight="bold">D</text>
</svg>
EOF
fi

# Avatar placeholders para testimoniais
echo "📋 3. Criando avatares placeholder..."
AVATARS=(
    "b1878feb-16ec-438c-8e37-5258266aedd6.png"
    "e68925cd-de9e-4a40-af01-9140ea754f19.png"
    "33aa29b9-8e1b-4bbd-a830-a39142d2eef1.png"
    "9f866110-593f-4b97-8114-69e63345ffb3.png"
    "c86c9416-e19f-4e6c-b96a-981764455220.png"
    "e4cc8fae-cf86-4234-83bc-7a4cbb3e3537.png"
    "a1ff2d2a-90ed-4aca-830b-0fa8e772a3ad.png"
    "82f11f27-4149-4c8f-b121-63897652035d.png"
    "c66eb0c2-8d6f-4575-93e6-9aa364372325.png"
    "f0a979d5-6bb6-41bf-b8da-6791918e6540.png"
    "af2d2ebb-fbfe-482f-8498-03515c511b97.png"
    "8e9dfc00-1145-43b9-9f22-4a3de6e807ca.png"
)

for i in "${!AVATARS[@]}"; do
    avatar="${AVATARS[$i]}"
    # Tentar baixar da fonte original
    curl -o "/tmp/$avatar" "https://lovable.dev/uploads/$avatar" 2>/dev/null
    if [ $? -eq 0 ]; then
        sudo cp "/tmp/$avatar" "/var/www/desfollow/lovable-uploads/$avatar"
        echo "✅ Avatar $avatar baixado"
    else
        # Criar avatar placeholder colorido
        color_index=$((i % 6))
        colors=("#3B82F6" "#EF4444" "#10B981" "#F59E0B" "#8B5CF6" "#EC4899")
        color="${colors[$color_index]}"
        
        sudo tee "/var/www/desfollow/lovable-uploads/$avatar" > /dev/null << EOF
<svg width="64" height="64" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="32" r="32" fill="$color"/>
  <circle cx="32" cy="24" r="8" fill="white" opacity="0.9"/>
  <path d="M32 36c-8 0-16 4-16 8v8h32v-8c0-4-8-8-16-8z" fill="white" opacity="0.9"/>
</svg>
EOF
        echo "✅ Avatar placeholder $avatar criado"
    fi
done

# Criar placeholder geral
echo "📋 4. Criando placeholder geral..."
sudo tee /var/www/desfollow/placeholder.svg > /dev/null << 'EOF'
<svg width="64" height="64" xmlns="http://www.w3.org/2000/svg">
  <rect width="64" height="64" fill="#E5E7EB"/>
  <path d="M32 16a8 8 0 11-16 0 8 8 0 0116 0zM16 28a16 16 0 1132 0H16z" fill="#9CA3AF"/>
</svg>
EOF

# Configurar permissões
echo "📋 5. Configurando permissões..."
sudo chown -R www-data:www-data /var/www/desfollow/lovable-uploads
sudo chmod -R 755 /var/www/desfollow/lovable-uploads

# Verificar arquivos criados
echo "📋 6. Verificando arquivos criados..."
sudo ls -la /var/www/desfollow/lovable-uploads/ | head -10

# Atualizar configuração nginx para servir imagens
echo "📋 7. Otimizando nginx para imagens..."
sudo tee -a /etc/nginx/sites-available/desfollow-final > /dev/null << 'EOF'

# Configuração específica para imagens
location /lovable-uploads/ {
    alias /var/www/desfollow/lovable-uploads/;
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header Vary "Accept-Encoding";
    access_log off;
    
    # Fallback para imagens que não existem
    try_files $uri $uri/ /placeholder.svg;
}
EOF

# Testar e recarregar nginx
echo "📋 8. Recarregando nginx..."
sudo nginx -t
if [ $? -eq 0 ]; then
    sudo nginx -s reload
    echo "✅ Nginx recarregado"
else
    echo "❌ Erro na configuração nginx"
fi

echo ""
echo "✅ IMAGENS CONFIGURADAS COM SUCESSO!"
echo "🖼️ Imagens disponíveis em:"
echo "   - https://desfollow.com.br/lovable-uploads/"
echo "   - https://www.desfollow.com.br/lovable-uploads/"
echo "📱 Frontend deve carregar todas as imagens agora"