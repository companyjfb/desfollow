#!/usr/bin/env python3
"""
Sistema de Limpeza Automática de Jobs - Versão 10 Minutos
=========================================================

Sistema otimizado para limpar jobs órfãos em 10 minutos para evitar acúmulo
excessivo de jobs ativos quando múltiplos usuários utilizam simultaneamente.

Melhorias implementadas:
- Jobs ativos por 10 minutos (ao invés de 3)
- Logs detalhados via SSH para acompanhamento
- Monitoramento mais granular
- Melhor contador de progresso (90% em 8 minutos)
- Sistema de alertas aprimorado

Baseado no contexto do aplicativo:
- Frontend polling: 5 segundos de intervalo por até 10 minutos (120 tentativas)
- Scan típico demora: 30-90 segundos  
- Jobs órfãos após 10 minutos indicam falha ou abandono
- Contador deve chegar a 90% em 8 minutos
"""

import os
import time
import json
import psycopg2
import logging
import requests
import subprocess
from datetime import datetime, timedelta
from dotenv import load_dotenv

# Configurar logging mais detalhado
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/desfollow/limpeza_10min.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

# Cache de jobs (mesmo sistema que o backend)
CACHE_FILE = "/tmp/desfollow_jobs.json"

def executar_comando_ssh(comando: str) -> str:
    """Executa comando SSH e retorna a saída"""
    try:
        resultado = subprocess.run(
            comando, 
            shell=True, 
            capture_output=True, 
            text=True, 
            timeout=30
        )
        return resultado.stdout.strip()
    except subprocess.TimeoutExpired:
        logger.error(f"❌ Timeout ao executar comando SSH: {comando}")
        return ""
    except Exception as e:
        logger.error(f"❌ Erro ao executar comando SSH: {e}")
        return ""

def log_ssh_detalhado(mensagem: str, comando: str = None):
    """Log detalhado com opcional execução de comando SSH"""
    logger.info(f"🔍 {mensagem}")
    
    if comando:
        resultado = executar_comando_ssh(comando)
        if resultado:
            logger.info(f"📊 Resultado SSH: {resultado[:200]}...")

def load_jobs():
    """Carrega jobs do arquivo JSON (mesmo sistema do backend)"""
    try:
        if os.path.exists(CACHE_FILE):
            with open(CACHE_FILE, 'r') as f:
                return json.load(f)
    except Exception as e:
        logger.error(f"❌ Erro ao carregar jobs do cache: {e}")
    return {}

def save_jobs(jobs):
    """Salva jobs no arquivo JSON (mesmo sistema do backend)"""
    try:
        with open(CACHE_FILE, 'w') as f:
            json.dump(jobs, f)
    except Exception as e:
        logger.error(f"❌ Erro ao salvar jobs no cache: {e}")

def conectar_supabase():
    """Conecta ao banco Supabase"""
    try:
        load_dotenv('/root/desfollow/backend/.env')  # Caminho absoluto para produção
        DATABASE_URL = os.getenv('DATABASE_URL')
        
        if not DATABASE_URL:
            # Fallback para arquivo local se não encontrar no VPS
            load_dotenv('backend/.env')
            DATABASE_URL = os.getenv('DATABASE_URL')
            
        if not DATABASE_URL:
            logger.error("❌ DATABASE_URL não encontrada!")
            return None
            
        conn = psycopg2.connect(DATABASE_URL)
        return conn
    except Exception as e:
        logger.error(f"❌ Erro ao conectar ao Supabase: {e}")
        return None

def limpar_jobs_cache():
    """Limpa jobs órfãos do cache local (10 minutos)"""
    try:
        jobs = load_jobs()
        jobs_limpos = 0
        current_time = time.time()
        
        # Lista para armazenar jobs a serem removidos
        jobs_para_remover = []
        
        for job_id, job_data in jobs.items():
            if job_data.get("status") == "running":
                start_time = job_data.get("start_time", 0)
                
                # Se job está rodando há mais de 10 minutos (600 segundos)
                if current_time - start_time > 600:
                    job_data["status"] = "error"
                    job_data["error"] = "Job órfão - mais de 10 minutos"
                    jobs_para_remover.append(job_id)
                    jobs_limpos += 1
                    logger.info(f"🧹 Job órfão no cache limpo: {job_id} (rodando há {int(current_time - start_time)}s)")
            
            # Limpar jobs queued há mais de 5 minutos  
            elif job_data.get("status") == "queued":
                start_time = job_data.get("start_time", job_data.get("created_at", 0))
                if current_time - start_time > 300:
                    jobs_para_remover.append(job_id)
                    jobs_limpos += 1
                    logger.info(f"🧹 Job queued expirado no cache: {job_id}")
        
        # Remover jobs órfãos do cache
        for job_id in jobs_para_remover:
            del jobs[job_id]
        
        # Salvar cache atualizado
        save_jobs(jobs)
        
        if jobs_limpos > 0:
            logger.info(f"✅ Cache limpo: {jobs_limpos} jobs órfãos removidos")
            
        return jobs_limpos
        
    except Exception as e:
        logger.error(f"❌ Erro ao limpar cache: {e}")
        return 0

def limpar_jobs_banco():
    """Limpa jobs órfãos do banco Supabase (10 minutos)"""
    conn = conectar_supabase()
    if not conn:
        return False
    
    try:
        cursor = conn.cursor()
        
        # 1. Limpar jobs running há mais de 10 minutos
        cursor.execute("""
            UPDATE scans 
            SET status = 'error', 
                error_message = 'Job órfão - mais de 10 minutos',
                updated_at = NOW()
            WHERE status = 'running' 
              AND updated_at < NOW() - INTERVAL '10 minutes'
        """)
        jobs_running = cursor.rowcount
        
        # 2. Limpar jobs queued há mais de 5 minutos  
        cursor.execute("""
            UPDATE scans 
            SET status = 'error', 
                error_message = 'Job queued expirado - mais de 5 minutos',
                updated_at = NOW()
            WHERE status = 'queued' 
              AND updated_at < NOW() - INTERVAL '5 minutes'
        """)
        jobs_queued = cursor.rowcount
        
        # 3. Estatísticas detalhadas
        cursor.execute("""
            SELECT status, COUNT(*) as total 
            FROM scans 
            WHERE status IN ('running', 'queued', 'error')
              AND created_at >= NOW() - INTERVAL '1 day'
            GROUP BY status 
            ORDER BY status
        """)
        
        stats = dict(cursor.fetchall())
        
        # 4. Jobs por faixa de tempo
        cursor.execute("""
            SELECT 
                CASE 
                    WHEN updated_at >= NOW() - INTERVAL '5 minutes' THEN '0-5min'
                    WHEN updated_at >= NOW() - INTERVAL '10 minutes' THEN '5-10min'
                    WHEN updated_at >= NOW() - INTERVAL '30 minutes' THEN '10-30min'
                    ELSE '30min+'
                END as time_range,
                COUNT(*) as total
            FROM scans 
            WHERE status IN ('running', 'queued')
            GROUP BY time_range
            ORDER BY time_range
        """)
        
        time_stats = dict(cursor.fetchall())
        
        conn.commit()
        cursor.close()
        conn.close()
        
        # Log das limpezas
        if jobs_running > 0 or jobs_queued > 0:
            logger.info(f"🧹 Limpeza banco executada:")
            logger.info(f"   - Jobs running > 10min: {jobs_running}")
            logger.info(f"   - Jobs queued > 5min: {jobs_queued}")
        
        logger.info(f"📊 Stats banco (24h): {stats}")
        logger.info(f"📊 Stats por tempo: {time_stats}")
        
        return jobs_running + jobs_queued
        
    except Exception as e:
        logger.error(f"❌ Erro ao limpar banco: {e}")
        return 0

def verificar_api_health():
    """Verifica quantos jobs ativos a API reporta"""
    try:
        # Usar HTTP como especificado na memória
        response = requests.get('http://api.desfollow.com.br/api/health', timeout=10)
        if response.status_code == 200:
            data = response.json()
            jobs_active = data.get('jobs_active', 0)
            logger.info(f"📊 API Health: {jobs_active} jobs ativos")
            return jobs_active
        else:
            logger.warning(f"⚠️ API Health falhou: {response.status_code}")
            return -1
    except Exception as e:
        logger.error(f"❌ Erro ao verificar API health: {e}")
        return -1

def verificar_servicos_sistema():
    """Verifica status dos serviços do sistema"""
    logger.info("🔍 Verificando serviços do sistema...")
    
    # Verificar processos Python
    processos_python = executar_comando_ssh("ps aux | grep python | grep -v grep | wc -l")
    logger.info(f"🐍 Processos Python ativos: {processos_python}")
    
    # Verificar uso de memória
    memoria = executar_comando_ssh("free -h | grep Mem")
    logger.info(f"💾 Memória: {memoria}")
    
    # Verificar uso de CPU
    cpu = executar_comando_ssh("top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1")
    logger.info(f"🖥️ CPU: {cpu}%")
    
    # Verificar logs do sistema
    logs_recentes = executar_comando_ssh("tail -n 5 /var/log/desfollow/limpeza_10min.log")
    if logs_recentes:
        logger.info(f"📋 Logs recentes: {logs_recentes}")

def limpeza_forçada_se_necessario():
    """Se ainda há muitos jobs ativos, força limpeza completa"""
    jobs_ativos = verificar_api_health()
    
    if jobs_ativos > 10:  # Mais agressivo que o original
        logger.warning(f"⚠️ MUITOS JOBS ATIVOS: {jobs_ativos} - Executando limpeza forçada!")
        
        # Log SSH detalhado antes da limpeza
        log_ssh_detalhado("Executando limpeza forçada", "ps aux | grep python | grep desfollow")
        
        conn = conectar_supabase()
        if conn:
            try:
                cursor = conn.cursor()
                
                # Forçar todos os jobs running/queued como erro
                cursor.execute("""
                    UPDATE scans 
                    SET status = 'error', 
                        error_message = 'Limpeza forçada - excesso de jobs ativos',
                        updated_at = NOW()
                    WHERE status IN ('running', 'queued')
                """)
                
                jobs_forçados = cursor.rowcount
                conn.commit()
                cursor.close()
                conn.close()
                
                logger.warning(f"🚨 Limpeza forçada: {jobs_forçados} jobs terminados")
                
                # Limpar cache também
                try:
                    os.remove(CACHE_FILE)
                    logger.info("🧹 Cache forçadamente limpo")
                except:
                    pass
                
                # Log SSH após limpeza
                log_ssh_detalhado("Limpeza forçada concluída", "ps aux | grep python | grep desfollow")
                    
                return jobs_forçados
                
            except Exception as e:
                logger.error(f"❌ Erro na limpeza forçada: {e}")
                
    return 0

def executar_limpeza_completa():
    """Executa limpeza completa - cache e banco"""
    logger.info("🚀 Iniciando limpeza completa...")
    
    # Log SSH inicial
    log_ssh_detalhado("Iniciando limpeza completa", "date")
    
    # 1. Limpar cache local
    jobs_cache = limpar_jobs_cache()
    
    # 2. Limpar banco
    jobs_banco = limpar_jobs_banco()
    
    # 3. Verificar serviços do sistema
    verificar_servicos_sistema()
    
    # 4. Verificar se ainda há muitos jobs e forçar limpeza se necessário
    jobs_forçados = limpeza_forçada_se_necessario()
    
    total_limpo = jobs_cache + jobs_banco + jobs_forçados
    
    if total_limpo > 0:
        logger.info(f"✅ Limpeza executada: {total_limpo} jobs processados")
    else:
        logger.info("✅ Sistema limpo - nenhum job órfão encontrado")
    
    # Log SSH final
    log_ssh_detalhado("Limpeza completa finalizada", "date")
    
    return total_limpo

def main():
    """Função principal - executa a cada 60 segundos"""
    logger.info("🚀 Sistema de Limpeza 10 Minutos iniciado...")
    logger.info("⏱️ Configuração: jobs > 10min serão limpos a cada 60s")
    
    # Criar diretório de logs se não existir
    os.makedirs('/var/log/desfollow', exist_ok=True)
    
    ciclo = 0
    
    while True:
        try:
            ciclo += 1
            logger.info(f"🔄 Ciclo {ciclo} - {datetime.now().strftime('%H:%M:%S')}")
            
            # Executa limpeza completa
            total_limpo = executar_limpeza_completa()
            
            # Log de estatísticas a cada 5 ciclos (5 minutos)
            if ciclo % 5 == 0:
                jobs_ativos = verificar_api_health()
                logger.info(f"📊 Relatório (Ciclo {ciclo}): {jobs_ativos} jobs ativos na API")
                
                # Log SSH detalhado a cada 5 ciclos
                log_ssh_detalhado("Relatório detalhado", "ps aux | grep python | grep -v grep")
            
            # Aguardar 60 segundos (mais frequente que o original de 5 minutos)
            time.sleep(60)
            
        except KeyboardInterrupt:
            logger.info("🛑 Sistema de limpeza interrompido pelo usuário")
            break
        except Exception as e:
            logger.error(f"❌ Erro no ciclo de limpeza: {e}")
            time.sleep(10)  # Aguardar menos tempo em caso de erro

if __name__ == "__main__":
    main() 