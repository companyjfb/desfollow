#!/bin/bash

echo "🔒 Instalando SSL no api.desfollow.com.br..."
echo "==========================================="

echo "📋 Verificando se certbot está instalado..."
if ! command -v certbot &> /dev/null; then
    echo "❌ certbot não está instalado!"
    echo "🔧 Instalando certbot..."
    apt-get update
    apt-get install -y certbot python3-certbot-nginx
    echo "✅ certbot instalado!"
else
    echo "✅ certbot já está instalado!"
fi

echo ""
echo "🔒 Obtendo certificado SSL para api.desfollow.com.br..."
certbot --nginx -d api.desfollow.com.br --non-interactive --agree-tos --email admin@desfollow.com.br

echo ""
echo "📋 Verificando se o certificado foi instalado..."
certbot certificates

echo ""
echo "🔄 Reiniciando Nginx..."
systemctl reload nginx

echo ""
echo "✅ SSL instalado no api.desfollow.com.br!"
echo ""
echo "📋 Verificando se funcionou..."
echo "   - Teste: curl https://api.desfollow.com.br/api/health"
echo "   - Acesse: https://api.desfollow.com.br"
echo ""
echo "🔍 Agora o frontend pode fazer requisições HTTPS para a API!" 