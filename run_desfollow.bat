@echo off
title Desfollow - Backend + Frontend
echo.
echo ========================================
echo    🚀 DESFOLLOW - INICIANDO SERVIÇOS
echo ========================================
echo.

REM Verifica se Python está instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python não encontrado. Instale Python 3.12+ primeiro.
    pause
    exit /b 1
)

REM Verifica se Node.js está instalado
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.js não encontrado. Instale Node.js 18+ primeiro.
    pause
    exit /b 1
)

echo ✅ Python e Node.js encontrados!
echo.

REM Para processos existentes
echo 🔄 Parando processos existentes...
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im node.exe >nul 2>&1
timeout /t 2 >nul

echo.
echo 📦 Preparando ambiente...

REM Navega para o diretório backend
cd backend

REM Cria ambiente virtual se não existir
if not exist "venv" (
    echo 📦 Criando ambiente virtual Python...
    python -m venv venv
)

REM Ativa o ambiente virtual
call venv\Scripts\activate.bat

REM Instala dependências do backend
echo 📦 Instalando dependências do backend...
pip install -r requirements.txt >nul 2>&1

REM Volta para o diretório raiz
cd ..

REM Instala dependências do frontend se necessário
if not exist "node_modules" (
    echo 📦 Instalando dependências do frontend...
    npm install >nul 2>&1
)

echo.
echo ========================================
echo    🎯 SERVIÇOS PRONTOS PARA INICIAR
echo ========================================
echo.
echo 📱 Frontend: http://localhost:3000
echo 🌐 Backend:  http://localhost:8000
echo 📖 API Docs: http://localhost:8000/docs
echo.
echo ⚠️  Pressione qualquer tecla para iniciar...
pause >nul

echo.
echo 🚀 Iniciando serviços...

echo.
echo 🚀 Iniciando Backend...
start "Desfollow Backend" cmd /k "cd /d %cd%\backend && call venv\Scripts\activate.bat && echo 🚀 Backend iniciando... && python run_local.py"

echo 🚀 Iniciando Frontend...
start "Desfollow Frontend" cmd /k "cd /d %cd% && echo 🚀 Frontend iniciando... && npm run dev"

echo.
echo ⏳ Aguardando serviços inicializarem...
timeout /t 5 >nul

echo.
echo ✅ Serviços iniciados!
echo.
echo 📱 Frontend: http://localhost:3000
echo 🌐 Backend:  http://localhost:8000
echo.
echo 💡 Para parar os serviços, feche as janelas ou use Ctrl+C
echo.
pause 