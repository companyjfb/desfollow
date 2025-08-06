#!/usr/bin/env python3

import requests
import json

def verificar_assinatura_atual():
    """Verifica o status atual da assinatura"""
    print("🔍 VERIFICANDO ASSINATURA ATUAL")
    print("==============================")
    
    username = "jordanbitencourt"
    url = f"https://api.desfollow.com.br/api/subscription/check/{username}"
    
    try:
        response = requests.get(url, timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            print(f"📋 Dados atuais:")
            print(json.dumps(data, indent=2, default=str))
            
            print(f"\n📊 RESUMO:")
            print(f"✅ Tem assinatura ativa: {data.get('has_active_subscription')}")
            print(f"📅 Status local: {data.get('is_active_local')}")
            print(f"💳 Pagamento atual: {data.get('is_payment_current')}")
            print(f"📅 Dias restantes: {data.get('days_remaining')}")
            print(f"📅 Expira em: {data.get('current_period_end')}")
            print(f"📅 Próxima cobrança: {data.get('next_billing_date')}")
            print(f"💰 Valor mensal: {data.get('monthly_amount')}")
            print(f"🔑 Código PerfectPay: {data.get('perfect_pay_code')}")
            print(f"📧 Email: {data.get('perfect_pay_customer_email', 'N/A')}")
            
        else:
            print(f"❌ Erro ao verificar: {response.status_code}")
            print(f"Resposta: {response.text}")
            
    except Exception as e:
        print(f"❌ Erro: {e}")

def forcar_sync():
    """Força sync com PerfectPay"""
    print("\n🔄 FORÇANDO SYNC COM PERFECTPAY")
    print("==============================")
    
    username = "jordanbitencourt"
    url = f"https://api.desfollow.com.br/api/subscription/sync/{username}"
    
    try:
        response = requests.post(url, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Sync realizado:")
            print(json.dumps(data, indent=2, default=str))
        else:
            print(f"❌ Erro no sync: {response.status_code}")
            print(f"Resposta: {response.text}")
            
    except Exception as e:
        print(f"❌ Erro: {e}")

def testar_novamente_webhook():
    """Reenviar o webhook para forçar atualização"""
    print("\n🔄 REENVIANDO WEBHOOK PARA ATUALIZAR")
    print("===================================")
    
    # Dados do webhook com status APPROVED
    webhook_data = {
        "token": "77d60f5ca571e57fd9ef4dad3c884b4e",
        "code": "PPCPMTB5H09C49",
        "sale_amount": 5,
        "currency_enum": 1,
        "currency_enum_key": "BRL",
        "coupon_code": None,
        "installments": 1,
        "installment_amount": 5,
        "shipping_type_enum": None,
        "shipping_type_enum_key": None,
        "shipping_amount": None,
        "payment_method_enum": 6,
        "payment_method_enum_key": "master",
        "payment_type_enum": 1,
        "payment_type_enum_key": "credit_card",
        "payment_format_enum": 1,
        "payment_format_enum_key": "regular",
        "original_code": None,
        "billet_url": "",
        "billet_number": None,
        "billet_expiration": None,
        "quantity": 1,
        "sale_status_enum": 2,  # FORÇAR APPROVED
        "sale_status_enum_key": "approved",  # FORÇAR APPROVED
        "sale_status_detail": "approved",
        "date_created": "2025-08-06 19:30:00",
        "date_approved": "2025-08-06 19:30:00",
        "tracking": None,
        "url_tracking": None,
        "checkout_type_enum": "regular",
        "academy_access_url": None,
        "product": {
            "code": "PPPBCSMJ",
            "name": "Desfollow",
            "external_reference": None,
            "guarantee": 7
        },
        "plan": {
            "code": "PPLQQN42A",
            "name": "Desfollow - Teste",
            "quantity": 1,
            "tax_code": None
        },
        "plan_itens": [],
        "customer": {
            "customer_type_enum": 1,
            "customer_type_enum_key": "percent",
            "full_name": "Jordan Fernandes Bitencourt",
            "email": "jordanzini@gmail.com",
            "identification_type": "CPF",
            "identification_number": "14166781901",
            "birthday": None,
            "date_birth": None,
            "phone_extension": "55",
            "phone_area_code": "43",
            "phone_number": "998355104",
            "phone_formated": "(43) 99835-5104",
            "phone_formated_ddi": "+55(43) 99835-5104",
            "ip": "103.88.233.223",
            "user_agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1",
            "street_name": "",
            "street_number": "",
            "district": "",
            "complement": "",
            "zip_code": "",
            "city": "",
            "state": "",
            "country": "BR"
        },
        "metadata": {
            "src": "user_jordanbitencourt",
            "sck": None,
            "utm_source": "desfollow",
            "utm_medium": "webapp",
            "utm_campaign": "subscription",
            "utm_content": "jordanbitencourt",
            "utm_term": None,
            "ttclid": None,
            "_fbp": "fb.2.1754505836856.34602788115251841",
            "utm_perfect": "jordanbitencourt",
            "ref": "PPA22P40"
        },
        "subscription": {
            "code": "PPSUB1O91E8CP",
            "charges_made": 1,
            "next_charge_date": "2025-09-05T03:00:00.000000Z",  # DATA ESPECÍFICA
            "subscription_status_enum": 2,
            "status": "active",
            "status_event": "subscription_started"
        },
        "webhook_owner": "PPA22P40",
        "commission": [
            {
                "affiliation_code": "PPA22P40",
                "affiliation_type_enum": 1,
                "affiliation_type_enum_key": "producer",
                "name": "Marcus Vinicius De Almeida",
                "email": "mvimports037@gmail.com",
                "identification_number": "",
                "commission_amount": 3.7,
                "currency_enum": 1,
                "currency_enum_key": "BRL"
            }
        ],
        "url_send_webhook_pay": "https://api.desfollow.com.br/webhook/perfect-pay"
    }
    
    url = "https://api.desfollow.com.br/api/webhook/perfect-pay"
    
    try:
        response = requests.post(
            url,
            json=webhook_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        print(f"📊 Status: {response.status_code}")
        
        if response.text:
            try:
                response_json = response.json()
                print(f"Resposta: {json.dumps(response_json, indent=2)}")
            except:
                print(f"Resposta (texto): {response.text}")
        
        if response.status_code == 200:
            print("✅ Webhook processado! Dados devem estar atualizados")
        else:
            print(f"❌ Erro no webhook: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Erro: {e}")

if __name__ == "__main__":
    verificar_assinatura_atual()
    forcar_sync()
    verificar_assinatura_atual()
    testar_novamente_webhook()
    verificar_assinatura_atual()
    
    print("\n🎯 RESULTADO ESPERADO:")
    print("✅ has_active_subscription: true")
    print("✅ subscription_status: active") 
    print("✅ current_period_end: 2025-09-05")
    print("✅ days_remaining: ~29 dias")