@echo off
title Desfollow - Reiniciar Limpo
echo.
echo ========================================
echo    🧹 DESFOLLOW - REINICIAR LIMPO
echo ========================================
echo.

echo 🛑 Parando serviços...
call stop_desfollow.bat

echo.
echo 🧹 Limpando cache...

REM Limpa cache do Vite
if exist "node_modules\.vite" (
    echo 📦 Limpando cache do Vite...
    rmdir /s /q "node_modules\.vite" >nul 2>&1
)

REM Limpa cache do navegador (sugestão)
echo 🌐 Dica: Limpe o cache do navegador (Ctrl+Shift+Del)
echo.

echo ⏳ Aguardando 3 segundos...
timeout /t 3 >nul

echo.
echo 🚀 Reiniciando serviços...
call run_desfollow.bat 