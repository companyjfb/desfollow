@echo off
title Desfollow - Verificar Status
echo.
echo ========================================
echo    🔍 DESFOLLOW - VERIFICAR STATUS
echo ========================================
echo.

echo 📊 Verificando serviços...
echo.

REM Verifica Backend (Porta 8000)
echo 🔍 Backend (Porta 8000):
netstat -ano | findstr :8000 >nul 2>&1
if errorlevel 1 (
    echo ❌ Backend NÃO está rodando
) else (
    echo ✅ Backend está rodando
    netstat -ano | findstr :8000
)

echo.

REM Verifica Frontend (Porta 8080)
echo 🔍 Frontend (Porta 8080):
netstat -ano | findstr :8080 >nul 2>&1
if errorlevel 1 (
    echo ❌ Frontend NÃO está rodando
) else (
    echo ✅ Frontend está rodando
    netstat -ano | findstr :8080
)

echo.

REM Verifica processos Python
echo 🔍 Processos Python:
tasklist | findstr python >nul 2>&1
if errorlevel 1 (
    echo ❌ Nenhum processo Python encontrado
) else (
    echo ✅ Processos Python ativos:
    tasklist | findstr python
)

echo.

REM Verifica processos Node.js
echo 🔍 Processos Node.js:
tasklist | findstr node >nul 2>&1
if errorlevel 1 (
    echo ❌ Nenhum processo Node.js encontrado
) else (
    echo ✅ Processos Node.js ativos:
    tasklist | findstr node
)

echo.
echo ========================================
echo    📋 RESUMO
echo ========================================
echo.
echo 🌐 URLs de acesso:
echo    Frontend: http://localhost:8080
echo    Backend:  http://localhost:8000
echo    API Docs: http://localhost:8000/docs
echo.
echo 💡 Para iniciar: run_desfollow.bat
echo 💡 Para parar:   stop_desfollow.bat
echo.
pause 