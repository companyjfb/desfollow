#!/bin/bash

echo "🔧 Corrigindo configuração do Nginx..."
echo "====================================="

echo "📋 Verificando configuração atual..."
nginx -t

echo ""
echo "🔧 Aplicando nova configuração..."

# Fazer backup da configuração atual
cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.$(date +%Y%m%d_%H%M%S)

# Aplicar nova configuração
cp nginx_desfollow_complete.conf /etc/nginx/sites-available/desfollow

echo "✅ Nova configuração aplicada!"

echo ""
echo "🔍 Verificando sintaxe da nova configuração..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Sintaxe da configuração está correta!"
    
    echo ""
    echo "🔧 Verificando se o diretório do frontend existe..."
    if [ ! -d "/var/www/desfollow" ]; then
        echo "❌ Diretório /var/www/desfollow não existe!"
        echo "🔧 Criando diretório..."
        mkdir -p /var/www/desfollow
        chown www-data:www-data /var/www/desfollow
        echo "✅ Diretório criado!"
    else
        echo "✅ Diretório /var/www/desfollow existe!"
    fi
    
    echo ""
    echo "🔧 Verificando se os arquivos do frontend estão no lugar..."
    if [ ! -f "/var/www/desfollow/index.html" ]; then
        echo "❌ Arquivo index.html não encontrado em /var/www/desfollow!"
        echo "🔧 Copiando arquivos do frontend..."
        
        # Verificar se existe build do frontend
        if [ -d "dist" ]; then
            cp -r dist/* /var/www/desfollow/
            chown -R www-data:www-data /var/www/desfollow
            echo "✅ Arquivos do frontend copiados!"
        else
            echo "⚠️ Diretório 'dist' não encontrado. Criando index.html básico..."
            cat > /var/www/desfollow/index.html << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Desfollow - Encontre quem não retribui seus follows</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .container { max-width: 600px; margin: 0 auto; }
        h1 { color: #333; }
        p { color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚧 Em Manutenção</h1>
        <p>O Desfollow está sendo configurado. Volte em alguns minutos!</p>
        <p>API: <a href="https://api.desfollow.com.br">api.desfollow.com.br</a></p>
    </div>
</body>
</html>
EOF
            chown www-data:www-data /var/www/desfollow/index.html
            echo "✅ index.html básico criado!"
        fi
    else
        echo "✅ Arquivo index.html encontrado!"
    fi
    
    echo ""
    echo "🔧 Recarregando Nginx..."
    systemctl reload nginx
    
    if [ $? -eq 0 ]; then
        echo "✅ Nginx recarregado com sucesso!"
        
        echo ""
        echo "🔍 Testando configuração..."
        echo "📱 Frontend (www.desfollow.com.br):"
        curl -I http://www.desfollow.com.br 2>/dev/null | head -5
        
        echo ""
        echo "🔧 API (api.desfollow.com.br):"
        curl -I http://api.desfollow.com.br 2>/dev/null | head -5
        
        echo ""
        echo "✅ Configuração corrigida com sucesso!"
        echo ""
        echo "📋 Resumo:"
        echo "   - Frontend: https://www.desfollow.com.br"
        echo "   - API: https://api.desfollow.com.br"
        echo "   - Logs: /var/log/nginx/desfollow_*_access.log"
        
    else
        echo "❌ Erro ao recarregar Nginx!"
        echo "🔧 Restaurando configuração anterior..."
        cp /etc/nginx/sites-available/desfollow.backup.* /etc/nginx/sites-available/desfollow
        systemctl reload nginx
        echo "✅ Configuração anterior restaurada!"
    fi
    
else
    echo "❌ Erro na sintaxe da configuração!"
    echo "🔧 Restaurando configuração anterior..."
    cp /etc/nginx/sites-available/desfollow.backup.* /etc/nginx/sites-available/desfollow
    echo "✅ Configuração anterior restaurada!"
fi 