#!/usr/bin/env python3
"""
Correção das funções get_followers_optimized e get_following_optimized
=====================================================================

Corrige o bug onde a API retorna lista direta mas o código espera dict com 'users'
"""

def fix_ig_py():
    """Corrige o arquivo backend/app/ig.py"""
    
    print("🔧 Corrigindo funções de followers e following...")
    
    # Ler arquivo atual
    with open('backend/app/ig.py', 'r') as f:
        content = f.read()
    
    # Correção 1: get_followers_optimized
    old_followers_code = '''            if response.status_code == 200:
                data = response.json()
                users = data.get('users', [])
                
                print(f"📋 Response data: {data}")
                
                if not users:
                    print(f"📭 Nenhum usuário encontrado na página {page}")
                    break'''
    
    new_followers_code = '''            if response.status_code == 200:
                data = response.json()
                
                # API retorna lista direta, não dict com 'users'
                if isinstance(data, list):
                    users = data
                    print(f"📋 Response: lista com {len(users)} usuários")
                else:
                    # Fallback para estrutura dict (caso mude no futuro)
                    users = data.get('users', [])
                    print(f"📋 Response data: {data}")
                
                if not users:
                    print(f"📭 Nenhum usuário encontrado na página {page}")
                    break'''
    
    # Correção 2: get_following_optimized  
    old_following_code = '''            if response.status_code == 200:
                data = response.json()
                users = data.get('users', [])
                
                print(f"📋 Response data: {data}")
                
                if not users:
                    print(f"📭 Nenhum usuário encontrado na página {page}")
                    break'''
    
    new_following_code = '''            if response.status_code == 200:
                data = response.json()
                
                # API retorna lista direta, não dict com 'users'
                if isinstance(data, list):
                    users = data
                    print(f"📋 Response: lista com {len(users)} usuários")
                else:
                    # Fallback para estrutura dict (caso mude no futuro)  
                    users = data.get('users', [])
                    print(f"📋 Response data: {data}")
                
                if not users:
                    print(f"📭 Nenhum usuário encontrado na página {page}")
                    break'''
    
    # Aplicar correções
    content = content.replace(old_followers_code, new_followers_code)
    content = content.replace(old_following_code, new_following_code)
    
    # Correção 3: Ajustar lógica de max_id para usar 'pk' ou 'id'
    old_max_id_code = '''                # Para próxima página, usar o último ID da lista atual
                if users:
                    last_user = users[-1]
                    max_id = last_user.get('id') or last_user.get('pk')
                    print(f"🔑 Próximo max_id: {max_id}")
                else:
                    print(f"📄 Nenhum usuário para continuar paginação")
                    break'''
    
    new_max_id_code = '''                # Para próxima página, usar o último ID da lista atual
                if users:
                    last_user = users[-1]
                    # A API retorna 'pk' e 'id' como campos principais
                    max_id = last_user.get('pk') or last_user.get('id')
                    print(f"🔑 Próximo max_id: {max_id}")
                    
                    if not max_id:
                        print(f"⚠️ Nenhum ID encontrado no último usuário: {last_user}")
                        break
                else:
                    print(f"📄 Nenhum usuário para continuar paginação")
                    break'''
    
    # Aplicar correção de max_id (aparece duas vezes, uma para cada função)
    content = content.replace(old_max_id_code, new_max_id_code)
    
    # Correção 4: Ajustar mapeamento de campos dos usuários
    old_user_mapping = '''                        if db_session:
                            get_or_create_user(db_session, username, {
                                'username': username,
                                'full_name': user.get('full_name', ''),
                                'profile_pic_url': user.get('profile_pic_url', ''),
                                'profile_pic_url_hd': user.get('profile_pic_url_hd', ''),
                                'biography': user.get('biography', ''),
                                'is_private': user.get('is_private', False),
                                'is_verified': user.get('is_verified', False),
                                'followers_count': user.get('edge_followed_by', {}).get('count', 0),
                                'following_count': user.get('edge_follow', {}).get('count', 0),
                                'posts_count': user.get('edge_owner_to_timeline_media', {}).get('count', 0)
                            })'''
    
    new_user_mapping = '''                        if db_session:
                            get_or_create_user(db_session, username, {
                                'username': username,
                                'full_name': user.get('full_name', ''),
                                'profile_pic_url': user.get('profile_pic_url', ''),
                                'profile_pic_url_hd': user.get('profile_pic_url_hd', user.get('profile_pic_url', '')),
                                'biography': user.get('biography', ''),
                                'is_private': user.get('is_private', False),
                                'is_verified': user.get('is_verified', False),
                                # API de followers/following não retorna contadores detalhados
                                'followers_count': 0,
                                'following_count': 0,
                                'posts_count': 0
                            })'''
    
    # Aplicar correção de mapeamento (aparece duas vezes)
    content = content.replace(old_user_mapping, new_user_mapping)
    
    # Salvar arquivo corrigido
    with open('backend/app/ig.py', 'w') as f:
        f.write(content)
    
    print("✅ Arquivo backend/app/ig.py corrigido!")

if __name__ == "__main__":
    import os
    
    print("🔧 CORRIGINDO FUNÇÕES DE FOLLOWERS E FOLLOWING")
    print("=" * 60)
    print()
    
    # Verificar se estamos no diretório correto
    if not os.path.exists('backend/app/ig.py'):
        print("❌ Arquivo backend/app/ig.py não encontrado!")
        print("📂 Certifique-se de estar no diretório /root/desfollow")
        exit(1)
    
    # Fazer backup
    import shutil
    backup_name = 'backend/app/ig.py.backup_before_fix'
    shutil.copy2('backend/app/ig.py', backup_name)
    print(f"📋 Backup criado: {backup_name}")
    
    # Aplicar correções
    try:
        fix_ig_py()
        print()
        print("✅ CORREÇÕES APLICADAS COM SUCESSO!")
        print()
        print("🔧 PRÓXIMOS PASSOS:")
        print("   1. Reiniciar backend: systemctl restart desfollow")
        print("   2. Testar scan novamente: ./executar_teste_scan_completo.sh instagram")
        print("   3. Verificar se followers e following agora funcionam")
        print()
        print("📋 RESUMO DAS CORREÇÕES:")
        print("   ✅ API retorna lista direta (não dict com 'users')")
        print("   ✅ Usar 'pk' como max_id para paginação") 
        print("   ✅ Ajustado mapeamento de campos dos usuários")
        print("   ✅ Fallback para estrutura dict (compatibilidade futura)")
        
    except Exception as e:
        print(f"❌ Erro ao aplicar correções: {e}")
        print(f"🔄 Restaurando backup...")
        shutil.copy2(backup_name, 'backend/app/ig.py')
        print(f"✅ Backup restaurado")
        exit(1) 