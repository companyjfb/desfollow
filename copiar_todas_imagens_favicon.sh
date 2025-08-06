#!/bin/bash

echo "🖼️ Copiando todas as imagens e favicon para o servidor..."

# Criar diretórios necessários
sudo mkdir -p /var/www/desfollow/lovable-uploads
sudo mkdir -p /var/www/desfollow/assets

# Baixar todas as imagens do lovable-uploads da Hostinger para o servidor
echo "📥 Baixando todas as imagens da Hostinger para o servidor..."

# Lista de TODAS as imagens encontradas no dist local
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

# Baixar imagens da Hostinger para o servidor
for img in "${IMAGES[@]}"; do
    echo "📥 Baixando $img da Hostinger..."
    sudo wget -q -O "/var/www/desfollow/lovable-uploads/$img" "http://www.desfollow.com.br/lovable-uploads/$img"
    if [ $? -eq 0 ]; then
        echo "✅ $img baixado com sucesso"
    else
        echo "⚠️ Erro ao baixar $img"
    fi
done

# Baixar favicon e outros arquivos importantes da Hostinger
echo "📥 Baixando favicon.ico..."
sudo wget -q -O "/var/www/desfollow/favicon.ico" "http://www.desfollow.com.br/favicon.ico"
if [ $? -eq 0 ]; then
    echo "✅ favicon.ico baixado com sucesso"
else
    echo "⚠️ Erro ao baixar favicon.ico"
fi

echo "📥 Baixando placeholder.svg..."
sudo wget -q -O "/var/www/desfollow/placeholder.svg" "http://www.desfollow.com.br/placeholder.svg"
if [ $? -eq 0 ]; then
    echo "✅ placeholder.svg baixado com sucesso"
else
    echo "⚠️ Erro ao baixar placeholder.svg"
fi

echo "📥 Baixando robots.txt..."
sudo wget -q -O "/var/www/desfollow/robots.txt" "http://www.desfollow.com.br/robots.txt"
if [ $? -eq 0 ]; then
    echo "✅ robots.txt baixado com sucesso"
else
    echo "⚠️ Erro ao baixar robots.txt"
fi

# Copiar assets compilados (CSS e JS)
echo "📥 Copiando assets compilados..."
if [ -d "dist/assets" ]; then
    sudo cp -r dist/assets/* /var/www/desfollow/assets/ 2>/dev/null || echo "ℹ️ Sem assets para copiar"
else
    echo "⚠️ Pasta assets não encontrada no dist"
fi

# Ajustar permissões
echo "🔧 Ajustando permissões..."
sudo chown -R www-data:www-data /var/www/desfollow/lovable-uploads
sudo chown -R www-data:www-data /var/www/desfollow/assets
sudo chown www-data:www-data /var/www/desfollow/favicon.ico 2>/dev/null
sudo chown www-data:www-data /var/www/desfollow/placeholder.svg 2>/dev/null
sudo chown www-data:www-data /var/www/desfollow/robots.txt 2>/dev/null
sudo chmod -R 755 /var/www/desfollow/lovable-uploads
sudo chmod -R 755 /var/www/desfollow/assets
sudo chmod 644 /var/www/desfollow/favicon.ico 2>/dev/null
sudo chmod 644 /var/www/desfollow/placeholder.svg 2>/dev/null
sudo chmod 644 /var/www/desfollow/robots.txt 2>/dev/null

echo "✅ Todas as imagens e favicon copiados!"

# Testar algumas imagens
echo "🧪 Testando imagens via HTTPS..."
curl -I https://www.desfollow.com.br/lovable-uploads/b7dde072-9f5b-476f-80ea-ff351b4129bd.png | head -2
curl -I https://www.desfollow.com.br/favicon.ico | head -2

echo "🎉 Processo finalizado!"