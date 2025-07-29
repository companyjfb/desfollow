#!/bin/bash

echo "🚀 BUILDANDO FRONTEND DEFINITIVO"
echo "================================"
echo ""

cd /root/desfollow

# 1. Verificar se projeto existe
echo "📋 1. Verificando projeto..."
if [ ! -f "package.json" ]; then
    echo "❌ package.json não encontrado!"
    echo "❌ Execute este script no diretório raiz do projeto"
    exit 1
fi
echo "✅ Projeto encontrado"

# 2. Verificar Node.js
echo ""
echo "📋 2. Verificando Node.js..."
if ! command -v node &> /dev/null; then
    echo "❌ Node.js não encontrado!"
    echo "📋 Instalando Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    echo "✅ Node.js instalado"
else
    echo "✅ Node.js encontrado: $(node --version)"
fi

# 3. Verificar npm
echo ""
echo "📋 3. Verificando npm..."
if ! command -v npm &> /dev/null; then
    echo "❌ npm não encontrado!"
    exit 1
else
    echo "✅ npm encontrado: $(npm --version)"
fi

# 4. Instalar dependências
echo ""
echo "📋 4. Instalando dependências..."
npm install
if [ $? -ne 0 ]; then
    echo "❌ Erro ao instalar dependências"
    exit 1
fi
echo "✅ Dependências instaladas"

# 5. Buildar projeto
echo ""
echo "📋 5. Buildando projeto React..."
npm run build
if [ $? -ne 0 ]; then
    echo "❌ Erro ao buildar projeto"
    exit 1
fi
echo "✅ Projeto buildado com sucesso"

# 6. Verificar se dist existe
echo ""
echo "📋 6. Verificando build..."
if [ ! -d "dist" ]; then
    echo "❌ Pasta dist não encontrada após build"
    echo "❌ Verifique a configuração do Vite"
    exit 1
fi
echo "✅ Pasta dist encontrada"

# 7. Criar diretório de destino
echo ""
echo "📋 7. Preparando diretório de destino..."
mkdir -p /var/www/html/desfollow
echo "✅ Diretório criado"

# 8. Fazer backup se já existir
echo ""
echo "📋 8. Fazendo backup do frontend anterior..."
if [ -d "/var/www/html/desfollow" ] && [ "$(ls -A /var/www/html/desfollow 2>/dev/null)" ]; then
    mv /var/www/html/desfollow /var/www/html/desfollow.backup.$(date +%Y%m%d_%H%M%S)
    mkdir -p /var/www/html/desfollow
    echo "✅ Backup criado"
else
    echo "ℹ️ Nenhum frontend anterior encontrado"
fi

# 9. Mover arquivos buildados
echo ""
echo "📋 9. Movendo arquivos buildados..."
cp -r dist/* /var/www/html/desfollow/
if [ $? -ne 0 ]; then
    echo "❌ Erro ao mover arquivos"
    exit 1
fi
echo "✅ Arquivos movidos"

# 10. Definir permissões
echo ""
echo "📋 10. Definindo permissões..."
chown -R www-data:www-data /var/www/html/desfollow
chmod -R 755 /var/www/html/desfollow
echo "✅ Permissões definidas"

# 11. Verificar estrutura
echo ""
echo "📋 11. Verificando estrutura do frontend..."
if [ -f "/var/www/html/desfollow/index.html" ]; then
    echo "✅ index.html encontrado"
else
    echo "❌ index.html não encontrado!"
    exit 1
fi

# Listar principais arquivos
echo "📋 Arquivos principais:"
ls -la /var/www/html/desfollow/ | head -10

# 12. Testar se Nginx consegue servir
echo ""
echo "📋 12. Testando acesso ao frontend..."
test_response=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: www.desfollow.com.br" http://localhost/)
if [ "$test_response" = "200" ]; then
    echo "✅ Frontend acessível via Nginx"
else
    echo "⚠️ Frontend pode não estar acessível (HTTP $test_response)"
    echo "📋 Verifique a configuração do Nginx"
fi

echo ""
echo "✅ FRONTEND BUILDADO E DEPLOYADO!"
echo "================================="
echo ""
echo "🌐 ACESSO:"
echo "   • Local: http://localhost (com Host header)"
echo "   • Produção: https://www.desfollow.com.br"
echo "   • Produção: https://desfollow.com.br"
echo ""
echo "📁 LOCALIZAÇÃO:"
echo "   /var/www/html/desfollow/"
echo ""
echo "📋 VERIFICAÇÕES:"
echo "   1. Teste: curl -H 'Host: www.desfollow.com.br' http://localhost"
echo "   2. Logs: tail -f /var/log/nginx/frontend_access.log"
echo "   3. Browser: https://www.desfollow.com.br" 