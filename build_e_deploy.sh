#!/bin/bash

echo "🚀 Build e Deploy via GitHub..."
echo "================================"

# Fazer build do frontend
echo "📦 Fazendo build do frontend..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Erro no build!"
    exit 1
fi

echo "✅ Build concluído!"

# Criar release no GitHub
echo "📋 Criando release no GitHub..."

# Fazer commit dos arquivos buildados
git add dist/
git commit -m "build: atualizar frontend buildado"

# Fazer push para GitHub
git push origin main

echo "✅ Frontend enviado para GitHub!"

echo ""
echo "📋 Próximos passos no servidor:"
echo "1. cd /root/desfollow"
echo "2. git pull origin main"
echo "3. chmod +x mover_frontend_vps.sh"
echo "4. ./mover_frontend_vps.sh"
echo ""
echo "✅ Build e deploy concluído!" 