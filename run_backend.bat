@echo off
echo 🚀 Iniciando Desfollow Backend...
echo.

REM Verifica se Python está instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python não encontrado. Instale Python 3.12+ primeiro.
    pause
    exit /b 1
)

REM Navega para o diretório backend
cd backend

REM Instala dependências se necessário
if not exist "venv" (
    echo 📦 Criando ambiente virtual...
    python -m venv venv
)

REM Ativa o ambiente virtual
call venv\Scripts\activate.bat

REM Instala dependências
echo 📦 Instalando dependências...
pip install -r requirements.txt

REM Executa o backend
echo 🚀 Iniciando API...
python run_local.py

pause 