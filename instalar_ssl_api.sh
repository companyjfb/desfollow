#!/bin/bash

echo "🔒 Instalando SSL para api.desfollow.com.br..."
echo "=============================================="

# Verificar se o certbot está instalado
if ! command -v certbot &> /dev/null; then
    echo "📦 Instalando certbot..."
    apt update
    apt install -y certbot python3-certbot-nginx
fi

# Verificar se o Nginx está rodando
if ! systemctl is-active --quiet nginx; then
    echo "❌ Nginx não está rodando. Iniciando..."
    systemctl start nginx
fi

# Verificar se o domínio está configurado
echo "🔍 Verificando configuração do Nginx..."
if ! grep -q "api.desfollow.com.br" /etc/nginx/sites-enabled/*; then
    echo "❌ Domínio api.desfollow.com.br não encontrado no Nginx"
    echo "Primeiro configure o Nginx com o domínio"
    exit 1
fi

# Obter certificado SSL
echo "🔒 Obtendo certificado SSL para api.desfollow.com.br..."
certbot --nginx -d api.desfollow.com.br --non-interactive --agree-tos --email admin@desfollow.com.br

# Verificar se o certificado foi obtido
if [ $? -eq 0 ]; then
    echo "✅ Certificado SSL instalado com sucesso!"
    
    # Testar configuração do Nginx
    echo "🔍 Testando configuração do Nginx..."
    nginx -t
    
    if [ $? -eq 0 ]; then
        echo "✅ Configuração do Nginx válida!"
        
        # Recarregar Nginx
        echo "🔄 Recarregando Nginx..."
        systemctl reload nginx
        
        echo "✅ SSL configurado e ativo!"
        echo "🌐 Teste: https://api.desfollow.com.br/health"
    else
        echo "❌ Erro na configuração do Nginx"
        exit 1
    fi
else
    echo "❌ Falha ao obter certificado SSL"
    echo "Verifique se:"
    echo "1. O domínio api.desfollow.com.br aponta para este servidor"
    echo "2. A porta 80 está aberta"
    echo "3. O Nginx está configurado corretamente"
    exit 1
fi

echo ""
echo "🔍 Testando HTTPS..."
curl -I https://api.desfollow.com.br/health

echo ""
echo "✅ Instalação SSL concluída!" 