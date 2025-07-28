@echo off
REM Script de Deploy para Windows - Desfollow
REM Frontend: Hostinger
REM Backend: VPS Hostinger  
REM Database: Supabase

echo 🚀 Iniciando deploy do Desfollow...

REM Verifica se está no diretório correto
if not exist "package.json" (
    echo ❌ Execute este script na raiz do projeto Desfollow
    pause
    exit /b 1
)

echo 📋 Verificando pré-requisitos...

REM Verifica se Node.js está instalado
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.js não encontrado. Instale o Node.js primeiro.
    pause
    exit /b 1
)

REM Verifica se Python está instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python não encontrado. Instale o Python primeiro.
    pause
    exit /b 1
)

echo ✅ Pré-requisitos verificados

REM ============================================================================
REM FRONTEND BUILD
REM ============================================================================

echo 🔨 Construindo frontend...

REM Instala dependências
call npm install

REM Build para produção
call npm run build

if errorlevel 1 (
    echo ❌ Erro ao construir frontend
    pause
    exit /b 1
) else (
    echo ✅ Frontend construído com sucesso
)

REM ============================================================================
REM BACKEND PREPARATION
REM ============================================================================

echo 🔧 Preparando backend...

REM Vai para o diretório do backend
cd backend

REM Instala dependências Python
pip install -r requirements.txt

REM Verifica se o arquivo .env existe
if not exist ".env" (
    echo ⚠️ Arquivo .env não encontrado. Copiando exemplo...
    copy env.example .env
    echo 📝 Configure as variáveis de ambiente no arquivo .env
)

REM Volta para o diretório raiz
cd ..

REM ============================================================================
REM DEPLOY INSTRUCTIONS
REM ============================================================================

echo 📋 Instruções de Deploy:

echo.
echo 🎯 FRONTEND (Hostinger):
echo 1. Faça upload da pasta 'dist' para o seu domínio
echo 2. Configure o domínio no painel da Hostinger
echo 3. Configure HTTPS no painel da Hostinger
echo.

echo 🔧 BACKEND (VPS Hostinger):
echo 1. Conecte via SSH ao seu VPS
echo 2. Clone o repositório: git clone ^<seu-repo^>
echo 3. Configure as variáveis de ambiente:
echo    - DATABASE_URL (Supabase)
echo    - RAPIDAPI_KEY
echo    - SECRET_KEY
echo    - FRONTEND_URL
echo 4. Execute: pip install -r requirements.txt
echo 5. Execute: gunicorn app.main:app -c gunicorn.conf.py
echo.

echo 🗄️ BANCO DE DADOS (Supabase):
echo 1. Crie um projeto no Supabase
echo 2. Configure as tabelas (users, scans, payments)
echo 3. Obtenha a URL de conexão
echo 4. Configure no arquivo .env
echo.

echo 🔐 CONFIGURAÇÕES DE SEGURANÇA:
echo 1. Gere uma SECRET_KEY forte
echo 2. Configure HTTPS no frontend
echo 3. Configure firewall no VPS
echo 4. Configure rate limiting
echo.

echo ✅ Script de deploy concluído!
echo.
echo 📚 Próximos passos:
echo 1. Configure as variáveis de ambiente
echo 2. Deploy no Hostinger (frontend)
echo 3. Deploy no VPS (backend)
echo 4. Configure o banco Supabase
echo 5. Teste a aplicação
echo.

pause 