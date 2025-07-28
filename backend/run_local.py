#!/usr/bin/env python3
"""
Script para executar o backend localmente.
Execute: python run_local.py
"""

import uvicorn
import sys
import os

# Adiciona o diretório atual ao PYTHONPATH
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

if __name__ == "__main__":
    print("🚀 Iniciando Desfollow API...")
    print("📖 Documentação: http://localhost:8000/docs")
    print("🔍 Health Check: http://localhost:8000/api/health")
    print("⏹️  Para parar: Ctrl+C")
    print("-" * 50)
    
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    ) 