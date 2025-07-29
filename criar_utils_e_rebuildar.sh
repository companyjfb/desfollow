#!/bin/bash

echo "🔧 Criando arquivo utils.ts e rebuildando frontend..."
echo "=================================================="

echo "📋 Criando diretório lib se não existir..."
mkdir -p src/lib

echo "📝 Criando arquivo utils.ts..."
cat > src/lib/utils.ts << 'EOF'
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
EOF

echo "✅ Arquivo utils.ts criado!"

echo ""
echo "🔧 Rebuildando frontend..."
npm run build

echo "📁 Copiando arquivos para Nginx..."
cp -r dist/* /var/www/desfollow/

echo "🔄 Recarregando Nginx..."
systemctl reload nginx

echo ""
echo "✅ Frontend atualizado!"
echo ""
echo "📋 Verificando se funcionou..."
echo "   - Acesse: http://www.desfollow.com.br"
echo "   - Verifique no console do browser se as requisições são HTTP"
echo "   - Teste: curl http://api.desfollow.com.br/api/health" 