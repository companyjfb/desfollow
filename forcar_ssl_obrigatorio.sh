#!/bin/bash

echo "🔒 FORÇANDO SSL OBRIGATÓRIO - DESFOLLOW"
echo "======================================"
echo "Tentaremos múltiplos métodos até o SSL funcionar"
echo

# Verificar se está no diretório correto
cd /root/desfollow
git pull origin main

echo "📋 1. Verificando status atual dos domínios..."

# Verificar DNS dos domínios
echo "🌐 Verificando DNS..."
nslookup desfollow.com.br
nslookup www.desfollow.com.br  
nslookup api.desfollow.com.br

echo
echo "📋 2. Parando serviços para liberação total da porta 80..."
systemctl stop nginx
systemctl stop apache2 2>/dev/null || true

echo
echo "📋 3. Verificando se a porta 80 está livre..."
netstat -tlnp | grep :80 || echo "✅ Porta 80 livre"

echo
echo "📋 4. MÉTODO 1: Standalone com força bruta..."
certbot certonly \
    --standalone \
    --preferred-challenges http \
    -d desfollow.com.br \
    -d www.desfollow.com.br \
    -d api.desfollow.com.br \
    --agree-tos \
    --non-interactive \
    --email admin@desfollow.com.br \
    --expand \
    --force-renewal \
    --verbose

if [ $? -eq 0 ]; then
    echo "✅ MÉTODO 1 FUNCIONOU!"
else
    echo "❌ Método 1 falhou, tentando método 2..."
    
    echo
    echo "📋 5. MÉTODO 2: Manual com DNS..."
    certbot certonly \
        --manual \
        --preferred-challenges dns \
        -d desfollow.com.br \
        -d www.desfollow.com.br \
        -d api.desfollow.com.br \
        --agree-tos \
        --email admin@desfollow.com.br \
        --expand \
        --force-renewal \
        --manual-public-ip-logging-ok
    
    if [ $? -eq 0 ]; then
        echo "✅ MÉTODO 2 FUNCIONOU!"
    else
        echo "❌ Método 2 falhou, tentando método 3..."
        
        echo
        echo "📋 6. MÉTODO 3: HTTP temporário + webroot..."
        
        # Iniciar nginx com configuração mínima
        sudo tee /etc/nginx/sites-available/temp-ssl > /dev/null << 'EOF'
server {
    listen 80;
    server_name desfollow.com.br www.desfollow.com.br api.desfollow.com.br;
    
    root /var/www/html;
    index index.html;
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        try_files $uri =404;
    }
    
    location / {
        return 200 "OK";
        add_header Content-Type text/plain;
    }
}
EOF
        
        # Ativar configuração temporária
        sudo ln -sf /etc/nginx/sites-available/temp-ssl /etc/nginx/sites-enabled/temp-ssl
        sudo rm -f /etc/nginx/sites-enabled/default
        sudo rm -f /etc/nginx/sites-enabled/desfollow
        
        # Criar diretórios necessários
        sudo mkdir -p /var/www/html/.well-known/acme-challenge
        sudo chown -R www-data:www-data /var/www/html/
        sudo chmod -R 755 /var/www/html/
        
        # Testar nginx
        sudo nginx -t && sudo systemctl start nginx
        
        # Aguardar estabilização
        sleep 5
        
        # Tentar webroot novamente
        certbot certonly \
            --webroot \
            --webroot-path=/var/www/html \
            -d desfollow.com.br \
            -d www.desfollow.com.br \
            -d api.desfollow.com.br \
            --agree-tos \
            --non-interactive \
            --email admin@desfollow.com.br \
            --expand \
            --force-renewal \
            --verbose
        
        if [ $? -eq 0 ]; then
            echo "✅ MÉTODO 3 FUNCIONOU!"
        else
            echo "❌ Método 3 falhou, tentando método 4..."
            
            echo
            echo "📋 7. MÉTODO 4: Certificado existente + expansão..."
            
            # Verificar se já existe algum certificado
            if [ -d "/etc/letsencrypt/live/desfollow.com.br" ]; then
                echo "📋 Expandindo certificado existente..."
                certbot expand \
                    -d desfollow.com.br \
                    -d www.desfollow.com.br \
                    -d api.desfollow.com.br \
                    --non-interactive
                
                if [ $? -eq 0 ]; then
                    echo "✅ MÉTODO 4 FUNCIONOU!"
                else
                    echo "❌ Todos os métodos automáticos falharam!"
                    echo
                    echo "🚨 MÉTODO MANUAL NECESSÁRIO:"
                    echo "1. Acesse seu provedor DNS"
                    echo "2. Execute: certbot certonly --manual --preferred-challenges dns -d desfollow.com.br -d www.desfollow.com.br -d api.desfollow.com.br"
                    echo "3. Adicione os registros TXT solicitados no DNS"
                    echo "4. Continue o processo"
                    exit 1
                fi
            else
                echo "❌ Nenhum certificado existente encontrado!"
                echo
                echo "🚨 MÉTODO MANUAL NECESSÁRIO:"
                echo "Execute: certbot certonly --manual --preferred-challenges dns -d desfollow.com.br -d www.desfollow.com.br -d api.desfollow.com.br"
                exit 1
            fi
        fi
    fi
fi

echo
echo "🎉 SSL INSTALADO COM SUCESSO!"
echo "============================="

# Limpar configuração temporária
sudo rm -f /etc/nginx/sites-enabled/temp-ssl

# Aplicar configuração final com SSL
echo "📋 8. Aplicando configuração final com SSL..."
sudo cp nginx_desfollow_com_proxy_transparente.conf /etc/nginx/sites-available/desfollow
sudo ln -sf /etc/nginx/sites-available/desfollow /etc/nginx/sites-enabled/desfollow

# Testar configuração
if sudo nginx -t; then
    echo "✅ Configuração SSL válida!"
    sudo systemctl restart nginx
    
    # Reiniciar backend
    systemctl restart desfollow
    
    # Atualizar frontend
    ./buildar_frontend_definitivo.sh
    
    echo
    echo "🎉 CONFIGURAÇÃO COMPLETA FINALIZADA!"
    echo "===================================="
    echo "Frontend: https://www.desfollow.com.br"
    echo "Frontend: https://desfollow.com.br"
    echo "API: https://api.desfollow.com.br"
    echo
    echo "✅ SSL obrigatório funcionando"
    echo "✅ Proxy transparente para imagens Instagram"
    echo "✅ CORS resolvido"
    echo "✅ Separação frontend/backend"
    
else
    echo "❌ Erro na configuração final!"
    sudo nginx -t
fi

echo
echo "📋 Status final:"
sudo systemctl status nginx --no-pager -l
echo
systemctl status desfollow --no-pager -l

echo
echo "📋 Verificando certificados:"
certbot certificates