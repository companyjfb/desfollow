#!/usr/bin/env python3
"""
Sistema de Limpeza Automática de Jobs
=====================================

Este script monitora e limpa jobs órfãos automaticamente para evitar acúmulo
quando múltiplos usuários utilizam o aplicativo simultaneamente.
"""

import os
import time
import psycopg2
import logging
from datetime import datetime, timedelta
from dotenv import load_dotenv

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/desfollow/limpeza_automatica.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

def conectar_supabase():
    """Conecta ao banco Supabase"""
    try:
        load_dotenv('backend/.env')
        DATABASE_URL = os.getenv('DATABASE_URL')
        
        if not DATABASE_URL:
            logger.error("DATABASE_URL não encontrada!")
            return None
            
        conn = psycopg2.connect(DATABASE_URL)
        return conn
    except Exception as e:
        logger.error(f"Erro ao conectar ao Supabase: {e}")
        return None

def limpar_jobs_orfos():
    """Limpa jobs órfãos automaticamente"""
    conn = conectar_supabase()
    if not conn:
        return False
    
    try:
        cursor = conn.cursor()
        
        # 1. Limpar jobs running há mais de 30 minutos
        cursor.execute("""
            UPDATE scans 
            SET status = 'error', 
                error_message = 'Job órfão - mais de 30 minutos',
                updated_at = NOW()
            WHERE status = 'running' 
              AND updated_at < NOW() - INTERVAL '30 minutes'
        """)
        jobs_30min = cursor.rowcount
        
        # 2. Limpar jobs queued há mais de 10 minutos
        cursor.execute("""
            UPDATE scans 
            SET status = 'error', 
                error_message = 'Job queued expirado - mais de 10 minutos',
                updated_at = NOW()
            WHERE status = 'queued' 
              AND updated_at < NOW() - INTERVAL '10 minutes'
        """)
        jobs_queued = cursor.rowcount
        
        # 3. Limpar jobs antigos (mais de 24 horas)
        cursor.execute("""
            UPDATE scans 
            SET status = 'error', 
                error_message = 'Job antigo - mais de 24 horas',
                updated_at = NOW()
            WHERE created_at < NOW() - INTERVAL '24 hours' 
              AND status IN ('running', 'queued')
        """)
        jobs_antigos = cursor.rowcount
        
        # 4. Verificar estatísticas
        cursor.execute("""
            SELECT status, COUNT(*) as total 
            FROM scans 
            WHERE status IN ('running', 'queued', 'error')
            GROUP BY status 
            ORDER BY status
        """)
        
        stats = cursor.fetchall()
        
        conn.commit()
        cursor.close()
        conn.close()
        
        # Log das limpezas
        if jobs_30min > 0 or jobs_queued > 0 or jobs_antigos > 0:
            logger.info(f"🧹 Limpeza automática executada:")
            logger.info(f"   - Jobs running > 30min: {jobs_30min}")
            logger.info(f"   - Jobs queued > 10min: {jobs_queued}")
            logger.info(f"   - Jobs antigos > 24h: {jobs_antigos}")
        
        logger.info(f"📊 Estatísticas atuais: {dict(stats)}")
        
        return True
        
    except Exception as e:
        logger.error(f"Erro ao limpar jobs: {e}")
        return False

def monitorar_jobs_ativos():
    """Monitora jobs ativos e alerta se houver muitos"""
    conn = conectar_supabase()
    if not conn:
        return False
    
    try:
        cursor = conn.cursor()
        
        # Contar jobs ativos
        cursor.execute("""
            SELECT COUNT(*) as total 
            FROM scans 
            WHERE status IN ('running', 'queued')
        """)
        
        total_ativos = cursor.fetchone()[0]
        
        # Contar jobs por status
        cursor.execute("""
            SELECT status, COUNT(*) as total 
            FROM scans 
            WHERE status IN ('running', 'queued')
            GROUP BY status
        """)
        
        status_stats = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        # Alertas baseados no número de jobs
        if total_ativos > 50:
            logger.warning(f"⚠️ MUITOS JOBS ATIVOS: {total_ativos}")
            logger.warning(f"   Detalhes: {dict(status_stats)}")
        elif total_ativos > 20:
            logger.info(f"📊 Jobs ativos: {total_ativos}")
            logger.info(f"   Detalhes: {dict(status_stats)}")
        else:
            logger.info(f"✅ Jobs ativos: {total_ativos}")
        
        return True
        
    except Exception as e:
        logger.error(f"Erro ao monitorar jobs: {e}")
        return False

def main():
    """Função principal"""
    logger.info("🚀 Iniciando sistema de limpeza automática...")
    
    # Criar diretório de logs se não existir
    os.makedirs('/var/log/desfollow', exist_ok=True)
    
    while True:
        try:
            # Limpar jobs órfãos
            limpar_jobs_orfos()
            
            # Monitorar jobs ativos
            monitorar_jobs_ativos()
            
            # Aguardar 5 minutos antes da próxima verificação
            logger.info("⏳ Aguardando 5 minutos para próxima verificação...")
            time.sleep(300)
            
        except KeyboardInterrupt:
            logger.info("🛑 Sistema de limpeza interrompido pelo usuário")
            break
        except Exception as e:
            logger.error(f"❌ Erro no sistema de limpeza: {e}")
            time.sleep(60)  # Aguardar 1 minuto antes de tentar novamente

if __name__ == "__main__":
    main() 