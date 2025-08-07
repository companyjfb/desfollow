#!/bin/bash

echo "🔧 ADICIONANDO CORS À CONFIGURAÇÃO EXISTENTE - DESFOLLOW"
echo "======================================================="

# Verificar configuração atual
echo "📋 1. Verificando configuração atual..."
echo "Configuração nginx atual:"
sudo head -20 /etc/nginx/sites-available/desfollow

echo ""
echo "📋 2. Parando nginx..."
sudo systemctl stop nginx

# Backup
echo "📋 3. Fazendo backup..."
sudo cp /etc/nginx/sites-available/desfollow /etc/nginx/sites-available/desfollow.backup.$(date +%Y%m%d_%H%M%S)

# Verificar se já tem configuração CORS
if grep -q "Access-Control-Allow-Origin" /etc/nginx/sites-available/desfollow; then
    echo "✅ CORS já existe na configuração"
    echo "Vamos substituir por uma versão corrigida..."
    
    # Remover linhas CORS existentes
    sudo sed -i '/Access-Control-Allow/d' /etc/nginx/sites-available/desfollow
    sudo sed -i '/proxy_hide_header.*Access-Control/d' /etc/nginx/sites-available/desfollow
fi

# Adicionar CORS correto logo após o server_name da API
echo "📋 4. Adicionando CORS correto..."

# Criar script temporário para modificar arquivo
sudo tee /tmp/add_cors.sh > /dev/null << 'EOF'
#!/bin/bash

# Adicionar CORS após server_name api.desfollow.com.br
sed -i '/server_name api\.desfollow\.com\.br;/a\
\
    # CORS Headers - COMPLETO\
    add_header '\''Access-Control-Allow-Origin'\'' '\''*'\'' always;\
    add_header '\''Access-Control-Allow-Methods'\'' '\''GET, POST, PUT, DELETE, OPTIONS'\'' always;\
    add_header '\''Access-Control-Allow-Headers'\'' '\''DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization'\'' always;\
    add_header '\''Access-Control-Expose-Headers'\'' '\''Content-Length,Content-Range'\'' always;\
    add_header '\''Access-Control-Allow-Credentials'\'' '\''true'\'' always;' /etc/nginx/sites-available/desfollow

# Adicionar tratamento OPTIONS antes de qualquer location /
sed -i '/location \/ {/i\
    # Handle preflight OPTIONS requests\
    if ($request_method = '\''OPTIONS'\'') {\
        add_header '\''Access-Control-Allow-Origin'\'' '\''*'\'' always;\
        add_header '\''Access-Control-Allow-Methods'\'' '\''GET, POST, PUT, DELETE, OPTIONS'\'' always;\
        add_header '\''Access-Control-Allow-Headers'\'' '\''DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization'\'' always;\
        add_header '\''Access-Control-Max-Age'\'' 1728000 always;\
        add_header '\''Content-Type'\'' '\''text/plain; charset=utf-8'\'' always;\
        add_header '\''Content-Length'\'' 0 always;\
        return 204;\
    }\
' /etc/nginx/sites-available/desfollow

# Adicionar proxy_hide_header dentro de location /
sed -i '/proxy_pass http:\/\/127\.0\.0\.1:8000;/a\
        \
        # Esconder headers CORS do backend\
        proxy_hide_header '\''Access-Control-Allow-Origin'\'';\
        proxy_hide_header '\''Access-Control-Allow-Methods'\'';\
        proxy_hide_header '\''Access-Control-Allow-Headers'\'';\
        proxy_hide_header '\''Access-Control-Allow-Credentials'\'';' /etc/nginx/sites-available/desfollow

EOF

# Executar script de modificação
sudo chmod +x /tmp/add_cors.sh
sudo /tmp/add_cors.sh

# Limpar arquivo temporário
sudo rm /tmp/add_cors.sh

# Testar configuração
echo "📋 5. Testando configuração..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuração válida!"
    
    # Iniciar nginx
    echo "📋 6. Iniciando nginx..."
    sudo systemctl start nginx
    
    # Aguardar
    sleep 3
    
    # Teste CORS
    echo "📋 7. Testando CORS..."
    
    echo "Teste OPTIONS:"
    curl -X OPTIONS \
         -H "Origin: https://www.desfollow.com.br" \
         -H "Access-Control-Request-Method: POST" \
         -H "Access-Control-Request-Headers: Content-Type" \
         -I \
         https://api.desfollow.com.br/api/scan 2>/dev/null | grep -E "(HTTP/|Access-Control)"
    
    echo ""
    echo "Teste GET:"
    curl -H "Origin: https://www.desfollow.com.br" \
         -I \
         https://api.desfollow.com.br/api/status 2>/dev/null | grep -E "(HTTP/|Access-Control)"
    
    echo ""
    echo "✅ CORS ADICIONADO COM SUCESSO!"
    echo "============================="
    echo "🔗 Frontend: https://desfollow.com.br"
    echo "🔗 API: https://api.desfollow.com.br"
    echo ""
    echo "Teste agora o scan no frontend!"
    
else
    echo "❌ Erro na configuração nginx"
    sudo nginx -t
    
    echo ""
    echo "📋 Restaurando backup..."
    sudo cp /etc/nginx/sites-available/desfollow.backup.* /etc/nginx/sites-available/desfollow 2>/dev/null || echo "Backup não encontrado"
    sudo systemctl start nginx
fi

echo ""
echo "📋 8. Para debug, visualizar configuração final:"
echo "sudo cat /etc/nginx/sites-available/desfollow"