#!/usr/bin/env python3

import requests
import json
from datetime import datetime

# Simular um webhook da PerfectPay para teste
webhook_data = {
    "token": "test_token_123",
    "code": "PP_TEST_001",
    "sale_amount": 29.0,
    "currency_enum": 1,  # BRL
    "coupon_code": None,
    "installments": 1,
    "installment_amount": None,
    "shipping_type_enum": 1,
    "shipping_amount": None,
    "payment_method_enum": 1,  # Cartão
    "payment_type_enum": 1,    # Débito
    "billet_url": None,
    "billet_number": None,
    "billet_expiration": None,
    "quantity": 1,
    "sale_status_enum": 2,  # 2 = approved
    "sale_status_detail": "Pagamento aprovado",
    "date_created": datetime.now().isoformat(),
    "date_approved": datetime.now().isoformat(),
    "product": {
        "name": "Desfollow Premium",
        "description": "Acesso premium ao Desfollow"
    },
    "plan": {
        "name": "Mensal",
        "type": "recurring"
    },
    "plan_itens": [],
    "customer": {
        "email": "jordan@example.com",
        "full_name": "Jordan Test",
        "identification_number": "12345678901"
    },
    "metadata": {
        "username": "jordanbitencourt",
        "utm_perfect": "jordanbitencourt",
        "source": "website"
    },
    "commission": [],
    "marketplaces": None
}

def testar_webhook_local():
    """Testa o webhook localmente"""
    print("🧪 TESTANDO WEBHOOK PERFECT PAY")
    print("==============================")
    
    url = "https://api.desfollow.com.br/api/webhook/perfect-pay"
    
    print(f"📡 URL: {url}")
    print(f"📦 Dados do webhook:")
    print(json.dumps(webhook_data, indent=2, default=str))
    
    try:
        response = requests.post(
            url,
            json=webhook_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        print(f"\n📊 RESPOSTA:")
        print(f"Status: {response.status_code}")
        print(f"Headers: {dict(response.headers)}")
        
        if response.text:
            try:
                response_json = response.json()
                print(f"Corpo (JSON): {json.dumps(response_json, indent=2)}")
            except:
                print(f"Corpo (Text): {response.text}")
        
        if response.status_code == 200:
            print("✅ Webhook funcionando!")
        else:
            print(f"❌ Erro no webhook: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Erro na requisição: {e}")

def verificar_endpoint_exists():
    """Verifica se o endpoint existe"""
    print("\n🔍 VERIFICANDO SE ENDPOINT EXISTE")
    print("==================================")
    
    # Testar com GET primeiro (deve dar 405 - Method Not Allowed)
    try:
        response = requests.get("https://api.desfollow.com.br/api/webhook/perfect-pay", timeout=5)
        print(f"GET Status: {response.status_code}")
        
        if response.status_code == 405:
            print("✅ Endpoint existe mas não aceita GET (correto)")
        elif response.status_code == 404:
            print("❌ Endpoint não encontrado (404)")
        else:
            print(f"🤔 Status inesperado: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Erro ao verificar endpoint: {e}")

def verificar_rotas_disponiveis():
    """Lista rotas disponíveis na API"""
    print("\n📋 VERIFICANDO ROTAS DISPONÍVEIS")
    print("================================")
    
    try:
        # Tentar acessar a documentação automática
        response = requests.get("https://api.desfollow.com.br/docs", timeout=5)
        print(f"Docs status: {response.status_code}")
        
        # Tentar acessar openapi.json
        response = requests.get("https://api.desfollow.com.br/openapi.json", timeout=5)
        if response.status_code == 200:
            openapi = response.json()
            paths = openapi.get("paths", {})
            print("📍 Rotas encontradas:")
            for path in sorted(paths.keys()):
                methods = list(paths[path].keys())
                print(f"  {path} - {', '.join(methods).upper()}")
        else:
            print(f"❌ Não foi possível obter lista de rotas: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Erro ao verificar rotas: {e}")

if __name__ == "__main__":
    verificar_rotas_disponiveis()
    verificar_endpoint_exists()
    testar_webhook_local()
    
    print("\n💡 PRÓXIMOS PASSOS:")
    print("1. Se o endpoint não existe (404), verificar se as rotas estão sendo registradas")
    print("2. Se existe mas retorna erro, verificar logs do servidor")
    print("3. Verificar se o modelo PerfectPayWebhookData está correto")