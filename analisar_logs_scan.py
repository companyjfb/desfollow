#!/usr/bin/env python3
"""
Analisador de Logs de Scan
==========================

Este script analisa os logs detalhados dos scans para entender
o que está acontecendo em cada processo.
"""

import os
import json
import glob
from datetime import datetime
from typing import Dict, List, Any

def analisar_logs_scan():
    """Analisa todos os logs de scan disponíveis"""
    print("🔍 Analisador de Logs de Scan")
    print("=" * 50)
    
    # Verificar se o diretório de logs existe
    log_dir = "/var/log/desfollow"
    if not os.path.exists(log_dir):
        print(f"❌ Diretório de logs não encontrado: {log_dir}")
        return
    
    # Encontrar todos os arquivos de log de scan
    scan_logs = glob.glob(f"{log_dir}/scan_*.json")
    
    if not scan_logs:
        print("📭 Nenhum log de scan encontrado")
        return
    
    print(f"📊 Encontrados {len(scan_logs)} logs de scan")
    print()
    
    # Analisar cada log
    for log_file in scan_logs:
        try:
            with open(log_file, 'r') as f:
                data = json.load(f)
            
            filename = os.path.basename(log_file)
            print(f"📄 {filename}")
            print(f"   User ID: {data.get('user_id', 'N/A')}")
            print(f"   Timestamp: {data.get('timestamp', 'N/A')}")
            
            if 'total_followers' in data:
                print(f"   Seguidores: {data['total_followers']}")
                print(f"   Páginas processadas: {data['pages_processed']}")
                print(f"   Máximo páginas: {data['max_pages']}")
            elif 'total_following' in data:
                print(f"   Seguindo: {data['total_following']}")
                print(f"   Páginas processadas: {data['pages_processed']}")
                print(f"   Máximo páginas: {data['max_pages']}")
            
            print()
            
        except Exception as e:
            print(f"❌ Erro ao ler {log_file}: {e}")
            print()

def analisar_logs_backend():
    """Analisa logs do backend"""
    print("🐍 Analisando Logs do Backend")
    print("=" * 50)
    
    backend_log = "/root/desfollow/backend.log"
    if os.path.exists(backend_log):
        print(f"📄 Lendo: {backend_log}")
        
        # Ler últimas 50 linhas
        with open(backend_log, 'r') as f:
            lines = f.readlines()
        
        print(f"📊 Total de linhas: {len(lines)}")
        
        # Mostrar últimas 20 linhas
        print("\n📋 Últimas 20 linhas:")
        for line in lines[-20:]:
            print(f"   {line.strip()}")
    else:
        print("❌ Log do backend não encontrado")

def analisar_logs_limpeza():
    """Analisa logs do sistema de limpeza"""
    print("🧹 Analisando Logs de Limpeza")
    print("=" * 50)
    
    limpeza_log = "/var/log/desfollow/limpeza_10min.log"
    if os.path.exists(limpeza_log):
        print(f"📄 Lendo: {limpeza_log}")
        
        # Ler últimas 30 linhas
        with open(limpeza_log, 'r') as f:
            lines = f.readlines()
        
        print(f"📊 Total de linhas: {len(lines)}")
        
        # Mostrar últimas 15 linhas
        print("\n📋 Últimas 15 linhas:")
        for line in lines[-15:]:
            print(f"   {line.strip()}")
    else:
        print("❌ Log de limpeza não encontrado")

def verificar_jobs_ativos():
    """Verifica jobs ativos no sistema"""
    print("📊 Verificando Jobs Ativos")
    print("=" * 50)
    
    # Verificar cache de jobs
    cache_file = "/tmp/desfollow_jobs.json"
    if os.path.exists(cache_file):
        try:
            with open(cache_file, 'r') as f:
                jobs = json.load(f)
            
            print(f"📄 Cache de jobs: {len(jobs)} jobs")
            
            for job_id, job_data in jobs.items():
                status = job_data.get('status', 'unknown')
                start_time = job_data.get('start_time', 0)
                
                if start_time:
                    elapsed = datetime.now().timestamp() - start_time
                    elapsed_min = elapsed / 60
                else:
                    elapsed_min = 0
                
                print(f"   Job {job_id[:8]}...: {status} ({elapsed_min:.1f}min)")
        except Exception as e:
            print(f"❌ Erro ao ler cache: {e}")
    else:
        print("📭 Cache de jobs não encontrado")

def main():
    """Função principal"""
    print("🚀 Iniciando análise de logs...")
    print()
    
    # Analisar logs de scan
    analisar_logs_scan()
    print()
    
    # Analisar logs do backend
    analisar_logs_backend()
    print()
    
    # Analisar logs de limpeza
    analisar_logs_limpeza()
    print()
    
    # Verificar jobs ativos
    verificar_jobs_ativos()
    print()
    
    print("✅ Análise concluída!")

if __name__ == "__main__":
    main() 