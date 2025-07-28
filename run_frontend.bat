@echo off
echo 🚀 Iniciando Desfollow Frontend...
echo.

REM Verifica se Node.js está instalado
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.js não encontrado. Instale Node.js 18+ primeiro.
    pause
    exit /b 1
)

REM Instala dependências se necessário
if not exist "node_modules" (
    echo 📦 Instalando dependências...
    npm install
)

REM Executa o frontend
echo 🚀 Iniciando aplicação...
npm run dev

pause 