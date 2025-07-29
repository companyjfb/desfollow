#!/usr/bin/env python3
"""
Script para limpar dados zerados/inválidos do banco Supabase
"""

import os
import sys
from datetime import datetime, timedelta
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# Adicionar o path do backend
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))

load_dotenv('backend/.env')

def conectar_banco():
    """Conecta ao banco Supabase"""
    DATABASE_URL = os.getenv("DATABASE_URL")
    if not DATABASE_URL:
        print("❌ DATABASE_URL não encontrado no .env")
        return None
        
    try:
        engine = create_engine(DATABASE_URL)
        return engine
    except Exception as e:
        print(f"❌ Erro ao conectar: {e}")
        return None

def limpar_dados_zerados():
    """Limpa scans com dados zerados ou inválidos"""
    print("🧹 LIMPANDO DADOS ZERADOS DO BANCO")
    print("================================")
    
    engine = conectar_banco()
    if not engine:
        return False
        
    try:
        with engine.connect() as conn:
            # 1. Verificar quantos registros zerados existem
            print("\n📊 Verificando dados zerados...")
            
            result = conn.execute(text("""
                SELECT COUNT(*) as total,
                       COUNT(CASE WHEN profile_info->>'followers_count' = '0' THEN 1 END) as zero_followers,
                       COUNT(CASE WHEN ghosts_count = 0 AND status = 'done' THEN 1 END) as zero_ghosts,
                       COUNT(CASE WHEN followers_count = 0 AND following_count = 0 THEN 1 END) as zero_counts
                FROM scans 
                WHERE created_at >= NOW() - INTERVAL '7 days'
            """))
            
            stats = result.fetchone()
            print(f"📈 Total de scans (7 dias): {stats[0]}")
            print(f"📈 Com followers_count = 0: {stats[1]}")
            print(f"📈 Com ghosts_count = 0: {stats[2]}")
            print(f"📈 Com contadores zerados: {stats[3]}")
            
            # 2. Listar scans problemáticos
            print("\n🔍 Scans com problemas:")
            problem_scans = conn.execute(text("""
                SELECT job_id, username, status, 
                       profile_info->>'followers_count' as followers,
                       ghosts_count, created_at
                FROM scans 
                WHERE (
                    (profile_info->>'followers_count' = '0' AND status = 'done')
                    OR (ghosts_count = 0 AND status = 'done' AND profile_info->>'followers_count' != '0')
                    OR (followers_count = 0 AND following_count = 0 AND status = 'done')
                )
                AND created_at >= NOW() - INTERVAL '24 hours'
                ORDER BY created_at DESC
                LIMIT 10
            """))
            
            for scan in problem_scans:
                print(f"   🚨 {scan[0][:8]}... | {scan[1]} | {scan[2]} | followers:{scan[3]} | ghosts:{scan[4]} | {scan[5]}")
            
            # 3. Perguntar confirmação
            print(f"\n⚠️  AÇÕES A SEREM EXECUTADAS:")
            print(f"   1. Deletar scans com followers_count = 0 (últimas 24h)")
            print(f"   2. Deletar scans com ghosts_count = 0 mas status = 'done' (últimas 24h)")
            print(f"   3. Deletar scans com contadores zerados (últimas 24h)")
            
            confirm = input("\n🤔 Confirma a limpeza? (sim/não): ").lower().strip()
            
            if confirm not in ['sim', 's', 'yes', 'y']:
                print("❌ Operação cancelada pelo usuário")
                return False
            
            # 4. Executar limpeza
            print("\n🧹 Executando limpeza...")
            
            # 4.1. Scans com followers zerados
            result1 = conn.execute(text("""
                DELETE FROM scans 
                WHERE profile_info->>'followers_count' = '0' 
                AND status = 'done'
                AND created_at >= NOW() - INTERVAL '24 hours'
            """))
            print(f"✅ Deletados {result1.rowcount} scans com followers_count = 0")
            
            # 4.2. Scans com ghosts zerados mas status done
            result2 = conn.execute(text("""
                DELETE FROM scans 
                WHERE ghosts_count = 0 
                AND status = 'done'
                AND profile_info->>'followers_count' != '0'
                AND created_at >= NOW() - INTERVAL '24 hours'
            """))
            print(f"✅ Deletados {result2.rowcount} scans com ghosts zerados")
            
            # 4.3. Scans com contadores totalmente zerados
            result3 = conn.execute(text("""
                DELETE FROM scans 
                WHERE followers_count = 0 
                AND following_count = 0 
                AND status = 'done'
                AND created_at >= NOW() - INTERVAL '24 hours'
            """))
            print(f"✅ Deletados {result3.rowcount} scans com contadores zerados")
            
            # 5. Commit das mudanças
            conn.commit()
            
            total_deleted = result1.rowcount + result2.rowcount + result3.rowcount
            print(f"\n🎉 LIMPEZA CONCLUÍDA!")
            print(f"📊 Total de registros deletados: {total_deleted}")
            
            # 6. Verificar estado final
            print("\n📊 Estado após limpeza:")
            final_stats = conn.execute(text("""
                SELECT COUNT(*) as total,
                       COUNT(CASE WHEN profile_info->>'followers_count' = '0' THEN 1 END) as zero_followers,
                       COUNT(CASE WHEN ghosts_count = 0 AND status = 'done' THEN 1 END) as zero_ghosts
                FROM scans 
                WHERE created_at >= NOW() - INTERVAL '7 days'
            """))
            
            final = final_stats.fetchone()
            print(f"📈 Total de scans (7 dias): {final[0]}")
            print(f"📈 Com followers_count = 0: {final[1]}")
            print(f"📈 Com ghosts_count = 0: {final[2]}")
            
            return True
            
    except Exception as e:
        print(f"❌ Erro durante limpeza: {e}")
        return False

def limpar_usuario_especifico(username):
    """Limpa dados de um usuário específico"""
    print(f"🧹 LIMPANDO DADOS PARA: {username}")
    print("=" * 40)
    
    engine = conectar_banco()
    if not engine:
        return False
        
    try:
        with engine.connect() as conn:
            # Verificar dados atuais
            result = conn.execute(text("""
                SELECT job_id, status, profile_info->>'followers_count' as followers,
                       ghosts_count, created_at
                FROM scans 
                WHERE username = :username
                ORDER BY created_at DESC
                LIMIT 5
            """), {"username": username})
            
            print(f"📊 Últimos 5 scans para {username}:")
            scans = result.fetchall()
            for scan in scans:
                print(f"   📋 {scan[0][:8]}... | {scan[1]} | followers:{scan[2]} | ghosts:{scan[3]} | {scan[4]}")
            
            if not scans:
                print(f"ℹ️  Nenhum scan encontrado para {username}")
                return True
            
            # Deletar todos os scans do usuário das últimas 24h
            delete_result = conn.execute(text("""
                DELETE FROM scans 
                WHERE username = :username
                AND created_at >= NOW() - INTERVAL '24 hours'
            """), {"username": username})
            
            conn.commit()
            
            print(f"✅ Deletados {delete_result.rowcount} scans para {username}")
            return True
            
    except Exception as e:
        print(f"❌ Erro ao limpar dados do usuário: {e}")
        return False

if __name__ == "__main__":
    print("🔧 LIMPADOR DE DADOS ZERADOS - SUPABASE")
    print("=====================================")
    
    if len(sys.argv) > 1:
        # Limpar usuário específico
        username = sys.argv[1].lstrip('@')
        limpar_usuario_especifico(username)
    else:
        # Limpeza geral
        limpar_dados_zerados() 