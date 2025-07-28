@echo off
title Desfollow - Parando Serviços
echo.
echo ========================================
echo    🛑 DESFOLLOW - PARANDO SERVIÇOS
echo ========================================
echo.

echo 🔄 Parando processos Python (Backend)...
taskkill /f /im python.exe >nul 2>&1
if errorlevel 1 (
    echo ✅ Nenhum processo Python encontrado
) else (
    echo ✅ Processos Python finalizados
)

echo.
echo 🔄 Parando processos Node.js (Frontend)...
taskkill /f /im node.exe >nul 2>&1
if errorlevel 1 (
    echo ✅ Nenhum processo Node.js encontrado
) else (
    echo ✅ Processos Node.js finalizados
)

echo.
echo 🔄 Parando processos npm...
taskkill /f /im npm.cmd >nul 2>&1
taskkill /f /im npm.exe >nul 2>&1

echo.
echo 🔄 Parando processos uvicorn...
taskkill /f /im uvicorn.exe >nul 2>&1

echo.
echo ========================================
echo    ✅ TODOS OS SERVIÇOS PARADOS
echo ========================================
echo.
echo 💡 Para reiniciar, execute: run_desfollow.bat
echo.
pause 