@echo off
REM Script de Configuração Rápida para Produção - Desfollow
REM Domínio: https://desfollow.com.br

echo 🚀 Configurando Desfollow para Produção...
echo.

echo 📋 Verificando configurações...

REM Verifica se está no diretório correto
if not exist "package.json" (
    echo ❌ Execute este script na raiz do projeto Desfollow
    pause
    exit /b 1
)

echo ✅ Diretório correto encontrado

REM ============================================================================
REM CONFIGURAÇÃO DO BACKEND
REM ============================================================================

echo 🔧 Configurando backend...

REM Vai para o diretório do backend
cd backend

REM Copia arquivo de exemplo se não existir
if not exist ".env" (
    echo 📝 Criando arquivo .env...
    copy env.example .env
    echo ✅ Arquivo .env criado
) else (
    echo ✅ Arquivo .env já existe
)

REM Volta para o diretório raiz
cd ..

REM ============================================================================
REM BUILD DO FRONTEND
REM ============================================================================

echo 🔨 Construindo frontend para produção...

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
REM INFORMAÇÕES DE DEPLOY
REM ============================================================================

echo.
echo 🎯 INFORMAÇÕES DE DEPLOY:
echo.
echo 📍 DOMÍNIO PRINCIPAL: https://desfollow.com.br
echo 📍 API BACKEND: https://api.desfollow.com.br
echo.
echo 🔑 CREDENCIAIS CONFIGURADAS:
echo    - RAPIDAPI_KEY: dcbcbd1a45msh9db02af0ee3b5b2p1f2f71jsne81868330f01
echo    - RAPIDAPI_HOST: instagram-premium-api-2023.p.rapidapi.com
echo    - SECRET_KEY: desfollow_secret_key_2024_production_secure_123
echo.
echo 📦 ARQUIVOS PRONTOS:
echo    - Frontend: pasta 'dist' (upload para Hostinger)
echo    - Backend: pasta 'backend' (deploy no VPS)
echo    - Nginx: arquivo 'nginx_desfollow.conf'
echo.
echo 🗄️ PRÓXIMOS PASSOS:
echo    1. Configure o banco Supabase
echo    2. Deploy no Hostinger (frontend)
echo    3. Deploy no VPS (backend)
echo    4. Configure DNS para api.desfollow.com.br
echo.
echo ✅ Configuração concluída!
echo.
pause 