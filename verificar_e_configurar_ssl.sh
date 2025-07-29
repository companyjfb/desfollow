#!/bin/bash

echo "🔒 VERIFICANDO E CONFIGURANDO SSL PARA DESFOLLOW"
echo "=============================================="

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Execute como root: sudo $0"
    exit 1
fi

echo "📋 1. Verificando certificados SSL existentes..."
if command -v certbot &> /dev/null; then
    echo "✅ Certbot instalado"
    certbot certificates
else
    echo "❌ Certbot não instalado!"
    echo "📋 Instalando certbot..."
    apt update
    apt install -y certbot python3-certbot-nginx
fi

echo ""
echo "📋 2. Verificando domínios configurados no DNS..."
echo "🔍 Testando resolução DNS:"
for domain in desfollow.com.br www.desfollow.com.br api.desfollow.com.br; do
    ip=$(dig +short $domain)
    if [ -n "$ip" ]; then
        echo "✅ $domain → $ip"
    else
        echo "❌ $domain → NÃO RESOLVE"
    fi
done

echo ""
echo "📋 3. Verificando se Nginx está rodando..."
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx está rodando"
else
    echo "❌ Nginx não está rodando!"
    systemctl start nginx
fi

echo ""
echo "📋 4. Verificando certificados por domínio..."

# Função para verificar certificado
check_cert() {
    local domain=$1
    local cert_path="/etc/letsencrypt/live/$domain/fullchain.pem"
    
    if [ -f "$cert_path" ]; then
        echo "✅ Certificado encontrado para $domain"
        echo "📅 Expiração:"
        openssl x509 -in "$cert_path" -noout -dates | grep notAfter
        return 0
    else
        echo "❌ Certificado NÃO encontrado para $domain"
        return 1
    fi
}

# Verificar certificados
CERT_DESFOLLOW=false
CERT_API=false

if check_cert "desfollow.com.br"; then
    CERT_DESFOLLOW=true
fi

echo ""
if check_cert "api.desfollow.com.br"; then
    CERT_API=true
fi

echo ""
echo "📋 5. Configurando certificados se necessário..."

if [ "$CERT_DESFOLLOW" = false ]; then
    echo "🔧 Configurando certificado para desfollow.com.br e www.desfollow.com.br..."
    certbot certonly --nginx -d desfollow.com.br -d www.desfollow.com.br --non-interactive --agree-tos --email admin@desfollow.com.br
    if [ $? -eq 0 ]; then
        CERT_DESFOLLOW=true
        echo "✅ Certificado criado para desfollow.com.br"
    else
        echo "❌ Falha ao criar certificado para desfollow.com.br"
    fi
fi

if [ "$CERT_API" = false ]; then
    echo "🔧 Configurando certificado para api.desfollow.com.br..."
    certbot certonly --nginx -d api.desfollow.com.br --non-interactive --agree-tos --email admin@desfollow.com.br
    if [ $? -eq 0 ]; then
        CERT_API=true
        echo "✅ Certificado criado para api.desfollow.com.br"
    else
        echo "❌ Falha ao criar certificado para api.desfollow.com.br"
    fi
fi

echo ""
echo "📋 6. Status final dos certificados:"
echo "🌐 desfollow.com.br: $CERT_DESFOLLOW"
echo "🔌 api.desfollow.com.br: $CERT_API"

if [ "$CERT_DESFOLLOW" = true ] && [ "$CERT_API" = true ]; then
    echo ""
    echo "✅ TODOS OS CERTIFICADOS SSL CONFIGURADOS!"
    echo "📋 Agora você pode executar o script Nginx com SSL:"
    echo "   ./corrigir_nginx_frontend_api_com_ssl.sh"
else
    echo ""
    echo "❌ ALGUNS CERTIFICADOS FALHARAM!"
    echo "📋 Possíveis problemas:"
    echo "   1. DNS não aponta para este servidor"
    echo "   2. Firewall bloqueando porta 80/443"
    echo "   3. Nginx não configurado corretamente"
    echo ""
    echo "📋 Para debug:"
    echo "   - Verificar DNS: dig desfollow.com.br"
    echo "   - Verificar firewall: ufw status"
    echo "   - Verificar nginx: nginx -t"
fi

echo ""
echo "📋 7. Verificando renovação automática..."
if crontab -l | grep -q certbot; then
    echo "✅ Renovação automática já configurada"
else
    echo "🔧 Configurando renovação automática..."
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    echo "✅ Renovação automática configurada"
fi

echo ""
echo "📋 Comandos úteis:"
echo "   certbot certificates                    # Listar certificados"
echo "   certbot renew --dry-run                # Testar renovação"
echo "   openssl s_client -connect desfollow.com.br:443 # Testar SSL" 