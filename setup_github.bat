@echo off
echo 🚀 Configurando GitHub para Desfollow...
echo.

echo 📋 PASSO 1: Criar repositório no GitHub
echo.
echo 1. Abrindo GitHub para criar repositório...
start https://github.com/new
echo.
echo 2. Configure o repositório:
echo    - Nome: desfollow
echo    - Descrição: Desfollow - Encontre quem não te segue de volta no Instagram
echo    - Público (marcado)
echo    - NÃO marque: Add README, Add .gitignore, Choose license
echo.
echo 3. Clique em "Create repository"
echo.
pause

echo.
echo 📋 PASSO 2: Enviar código para GitHub
echo.
echo Enviando código para o repositório...
git push -u origin main

if errorlevel 1 (
    echo ❌ Erro ao fazer push
    echo.
    echo 💡 Verifique se:
    echo 1. O repositório foi criado no GitHub
    echo 2. O nome está correto: desfollow
    echo 3. Você está logado no GitHub
    echo.
    echo Tente novamente:
    echo git push -u origin main
    echo.
    pause
    exit /b 1
)

echo ✅ Código enviado com sucesso!
echo.
echo 🎉 REPOSITÓRIO CONFIGURADO!
echo.
echo 📍 URL: https://github.com/companyjfb/desfollow
echo.
echo 📋 PRÓXIMOS PASSOS:
echo 1. Configure o repositório no script setup_vps.sh
echo 2. Atualize a URL no DEPLOY_SIMPLIFICADO.md
echo 3. Faça deploy seguindo o guia
echo.
pause 