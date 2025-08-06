#!/bin/bash

echo "🔧 CORRIGINDO ARQUIVOS FALTANDO NO PROJETO"
echo "=========================================="

# Criar diretório lib se não existir
echo "📋 1. Criando diretório lib..."
mkdir -p src/lib

# Criar arquivo utils.ts
echo "📋 2. Criando src/lib/utils.ts..."
cat > src/lib/utils.ts << 'EOF'
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
EOF

# Verificar se components.json existe
if [ ! -f "components.json" ]; then
    echo "📋 3. Criando components.json..."
    cat > components.json << 'EOF'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.ts",
    "css": "src/index.css",
    "baseColor": "slate",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  }
}
EOF
else
    echo "✅ components.json já existe"
fi

# Verificar se vite.config.ts tem o alias configurado
echo "📋 4. Verificando vite.config.ts..."
if ! grep -q "resolve:" vite.config.ts 2>/dev/null; then
    echo "⚠️ Adicionando alias ao vite.config.ts..."
    
    # Backup do arquivo original
    cp vite.config.ts vite.config.ts.backup 2>/dev/null || true
    
    cat > vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
})
EOF
    echo "✅ vite.config.ts atualizado"
else
    echo "✅ vite.config.ts já tem alias configurado"
fi

# Verificar package.json tem as dependências necessárias
echo "📋 5. Verificando dependências..."
if ! grep -q "clsx" package.json 2>/dev/null; then
    echo "⚠️ Instalando dependências faltando..."
    npm install clsx tailwind-merge
    echo "✅ Dependências instaladas"
else
    echo "✅ Dependências já instaladas"
fi

# Testar build
echo "📋 6. Testando build..."
if npm run build; then
    echo "✅ Build realizado com sucesso!"
    
    # Se chegou aqui, vamos atualizar o frontend
    echo "📋 7. Atualizando frontend no servidor..."
    
    # Parar nginx temporariamente
    sudo systemctl stop nginx
    
    # Backup do frontend atual
    sudo mkdir -p /var/www/backup
    sudo cp -r /var/www/desfollow /var/www/backup/desfollow-$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    
    # Limpar diretório atual e copiar novo build
    sudo rm -rf /var/www/desfollow/*
    sudo cp -r dist/* /var/www/desfollow/
    
    # Configurar permissões
    sudo chown -R www-data:www-data /var/www/desfollow
    sudo chmod -R 755 /var/www/desfollow
    
    # Criar pasta para imagens se não existir
    sudo mkdir -p /var/www/desfollow/lovable-uploads
    
    # Baixar imagens necessárias
    echo "📋 8. Baixando imagens do projeto..."
    
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
        # Tentar baixar do Lovable
        if curl -f -o "/tmp/$img" "https://lovable.dev/uploads/$img" 2>/dev/null; then
            sudo cp "/tmp/$img" "/var/www/desfollow/lovable-uploads/$img"
            echo "✅ $img baixado"
        else
            echo "❌ Não foi possível baixar $img, criando placeholder..."
            # Criar placeholder SVG
            sudo tee "/var/www/desfollow/lovable-uploads/$img" > /dev/null << EOF
<svg width="64" height="64" xmlns="http://www.w3.org/2000/svg">
  <rect width="64" height="64" fill="#E5E7EB"/>
  <circle cx="32" cy="24" r="8" fill="#9CA3AF"/>
  <path d="M20 44a12 12 0 0124 0H20z" fill="#9CA3AF"/>
</svg>
EOF
        fi
    done
    
    # Criar placeholder geral
    sudo tee /var/www/desfollow/placeholder.svg > /dev/null << 'EOF'
<svg width="64" height="64" xmlns="http://www.w3.org/2000/svg">
  <rect width="64" height="64" fill="#E5E7EB"/>
  <circle cx="32" cy="24" r="8" fill="#9CA3AF"/>
  <path d="M20 44a12 12 0 0124 0H20z" fill="#9CA3AF"/>
</svg>
EOF
    
    # Configurar permissões finais
    sudo chown -R www-data:www-data /var/www/desfollow
    sudo chmod -R 755 /var/www/desfollow
    
    # Iniciar nginx
    sudo systemctl start nginx
    
    # Testar endpoints
    echo "📋 9. Testando frontend..."
    sleep 3
    curl -s -o /dev/null -w "Frontend HTTPS: %{http_code}\n" https://desfollow.com.br
    curl -s -o /dev/null -w "Imagem de teste: %{http_code}\n" https://desfollow.com.br/lovable-uploads/b7dde072-9f5b-476f-80ea-ff351b4129bd.png
    
    echo ""
    echo "✅ FRONTEND ATUALIZADO COM SUCESSO!"
    echo "🌐 Frontend: https://desfollow.com.br"
    echo "🌐 Frontend WWW: https://www.desfollow.com.br"
    echo "🖼️ Imagens: https://desfollow.com.br/lovable-uploads/"
    
else
    echo "❌ Erro no build! Verifique os logs acima."
    exit 1
fi

echo "🎉 Todos os arquivos corrigidos e frontend atualizado!"