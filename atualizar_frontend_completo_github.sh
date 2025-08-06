#!/bin/bash

echo "📦 ATUALIZANDO FRONTEND COMPLETO DO GITHUB"
echo "=========================================="

# Backup do frontend atual
echo "📋 1. Fazendo backup do frontend atual..."
sudo mkdir -p /var/www/backup
sudo cp -r /var/www/desfollow /var/www/backup/desfollow-$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Baixar repositório completo
echo "📋 2. Baixando repositório do GitHub..."
cd /tmp
rm -rf desfollow-temp
git clone https://github.com/companyjfb/desfollow.git desfollow-temp
cd desfollow-temp

# Buildar frontend
echo "📋 3. Instalando dependências e buildando frontend..."
npm install

# Verificar se o build foi bem-sucedido
if npm run build; then
    echo "✅ Build realizado com sucesso!"
    
    # Parar nginx temporariamente
    echo "📋 4. Parando nginx..."
    sudo systemctl stop nginx
    
    # Limpar diretório atual
    echo "📋 5. Limpando diretório atual..."
    sudo rm -rf /var/www/desfollow/*
    
    # Copiar novo build
    echo "📋 6. Copiando novo build..."
    sudo cp -r dist/* /var/www/desfollow/
    
    # Verificar se arquivos foram copiados
    echo "📋 7. Verificando arquivos copiados..."
    sudo ls -la /var/www/desfollow/
    echo ""
    echo "📁 Conteúdo da pasta assets:"
    sudo ls -la /var/www/desfollow/assets/ 2>/dev/null || echo "Pasta assets não encontrada"
    
    # Verificar se há pasta lovable-uploads no build
    if [ -d "dist/lovable-uploads" ]; then
        echo "✅ Pasta lovable-uploads encontrada no build"
        sudo ls -la /var/www/desfollow/lovable-uploads/ | head -10
    else
        echo "⚠️ Pasta lovable-uploads não encontrada no build"
        echo "📋 Criando pasta lovable-uploads..."
        sudo mkdir -p /var/www/desfollow/lovable-uploads
        
        # Verificar se há imagens no repositório
        if [ -d "public/lovable-uploads" ]; then
            echo "✅ Encontrada pasta public/lovable-uploads, copiando..."
            sudo cp -r public/lovable-uploads/* /var/www/desfollow/lovable-uploads/
        elif [ -d "src/assets" ]; then
            echo "✅ Encontrada pasta src/assets, copiando..."
            sudo cp -r src/assets/* /var/www/desfollow/lovable-uploads/ 2>/dev/null || true
        else
            echo "📋 Baixando imagens diretamente do GitHub raw..."
            
            # Lista de imagens conhecidas
            IMAGES=(
                "b7dde072-9f5b-476f-80ea-ff351b4129bd.png"  # Logo
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
            
            for img in "${IMAGES[@]}"; do
                echo "⬇️ Baixando $img..."
                # Tentar baixar do GitHub raw (se estiver commitado)
                curl -f -o "/tmp/$img" "https://raw.githubusercontent.com/companyjfb/desfollow/main/public/lovable-uploads/$img" 2>/dev/null && \
                    sudo cp "/tmp/$img" "/var/www/desfollow/lovable-uploads/$img" && \
                    echo "✅ $img baixado do GitHub" || \
                    
                # Se não conseguir do GitHub, tentar do Lovable
                curl -f -o "/tmp/$img" "https://lovable.dev/uploads/$img" 2>/dev/null && \
                    sudo cp "/tmp/$img" "/var/www/desfollow/lovable-uploads/$img" && \
                    echo "✅ $img baixado do Lovable" || \
                    echo "❌ Não foi possível baixar $img"
            done
        fi
    fi
    
    # Criar placeholder.svg se não existir
    if [ ! -f "/var/www/desfollow/placeholder.svg" ]; then
        echo "📋 Criando placeholder.svg..."
        sudo tee /var/www/desfollow/placeholder.svg > /dev/null << 'EOF'
<svg width="64" height="64" xmlns="http://www.w3.org/2000/svg">
  <rect width="64" height="64" fill="#E5E7EB"/>
  <path d="M32 20a6 6 0 110 12 6 6 0 010-12zM20 44a12 12 0 0124 0H20z" fill="#9CA3AF"/>
</svg>
EOF
    fi
    
    # Configurar permissões
    echo "📋 8. Configurando permissões..."
    sudo chown -R www-data:www-data /var/www/desfollow
    sudo chmod -R 755 /var/www/desfollow
    
    # Iniciar nginx
    echo "📋 9. Iniciando nginx..."
    sudo systemctl start nginx
    
    # Verificar status
    echo "📋 10. Verificando status..."
    sudo systemctl status nginx --no-pager | head -5
    
    # Testar endpoints
    echo "📋 11. Testando frontend..."
    echo "• Frontend principal:"
    curl -s -o /dev/null -w "Status: %{http_code}\n" https://desfollow.com.br
    echo "• Imagem de teste:"
    curl -s -o /dev/null -w "Status: %{http_code}\n" https://desfollow.com.br/lovable-uploads/b7dde072-9f5b-476f-80ea-ff351b4129bd.png
    
    echo ""
    echo "✅ FRONTEND ATUALIZADO COM SUCESSO!"
    echo "🌐 Frontend: https://desfollow.com.br"
    echo "🌐 Frontend WWW: https://www.desfollow.com.br"
    echo "🖼️ Imagens: https://desfollow.com.br/lovable-uploads/"
    
else
    echo "❌ Erro no build do frontend!"
    echo "Restaurando backup..."
    if [ -d "/var/www/backup" ]; then
        latest_backup=$(ls -t /var/www/backup/ | head -1)
        if [ -n "$latest_backup" ]; then
            sudo rm -rf /var/www/desfollow/*
            sudo cp -r "/var/www/backup/$latest_backup/"* /var/www/desfollow/
            echo "✅ Backup restaurado"
        fi
    fi
    sudo systemctl start nginx
fi

# Limpeza
echo "📋 12. Limpando arquivos temporários..."
cd /
rm -rf /tmp/desfollow-temp

echo "🎉 Processo concluído!"