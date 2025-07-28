@echo off
REM Script para criar repositório no GitHub manualmente
REM Desfollow - Deploy Automation

echo 🚀 Configurando repositório Git...

REM Verifica se está no diretório correto
if not exist "package.json" (
    echo ❌ Execute este script na raiz do projeto Desfollow
    pause
    exit /b 1
)

echo 📋 Verificando Git...

REM Verifica se Git está instalado
git --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Git não encontrado
    echo.
    echo 📥 Instale o Git:
    echo 1. Acesse: https://git-scm.com/
    echo 2. Baixe e instale para Windows
    echo 3. Reinicie o terminal
    echo.
    pause
    exit /b 1
)

echo ✅ Git encontrado

REM Pergunta o nome do usuário
set /p GITHUB_USER="Digite seu usuário do GitHub: "

REM Verifica se já existe .git
if exist ".git" (
    echo ⚠️ Repositório Git já inicializado
    echo.
    echo 📋 Status atual:
    git status
    echo.
    set /p CONTINUE="Deseja continuar? (s/n): "
    if /i not "%CONTINUE%"=="s" (
        echo ❌ Operação cancelada
        pause
        exit /b 1
    )
) else (
    echo 📁 Inicializando repositório Git...
    git init
)

REM Adiciona todos os arquivos
echo 📦 Adicionando arquivos...
git add .

REM Faz primeiro commit
echo 📝 Fazendo primeiro commit...
git commit -m "Initial commit - Desfollow project"

REM Adiciona remote
echo 🔗 Adicionando remote do GitHub...
git remote add origin https://github.com/%GITHUB_USER%/desfollow.git

REM Configura branch principal
echo 🌿 Configurando branch principal...
git branch -M main

REM Tenta fazer push
echo 📤 Fazendo push para GitHub...
git push -u origin main

if errorlevel 1 (
    echo ❌ Erro ao fazer push
    echo.
    echo 💡 Possíveis soluções:
    echo 1. Crie o repositório manualmente no GitHub:
    echo    https://github.com/new
    echo 2. Nome do repositório: desfollow
    echo 3. Descrição: Desfollow - Encontre quem não te segue de volta no Instagram
    echo 4. Deixe público
    echo 5. NÃO inicialize com README, .gitignore ou license
    echo 6. Execute novamente este script
    echo.
    pause
    exit /b 1
)

echo ✅ Push realizado com sucesso!

REM Verifica se .gitignore existe
if not exist ".gitignore" (
    echo 📝 Criando .gitignore...
    echo # Dependencies > .gitignore
    echo node_modules/ >> .gitignore
    echo .env >> .gitignore
    echo .env.local >> .gitignore
    echo .env.production >> .gitignore
    echo dist/ >> .gitignore
    echo build/ >> .gitignore
    echo .DS_Store >> .gitignore
    echo *.log >> .gitignore
    echo .vscode/ >> .gitignore
    echo .idea/ >> .gitignore
    echo __pycache__/ >> .gitignore
    echo *.pyc >> .gitignore
    echo .pytest_cache/ >> .gitignore
    echo .coverage >> .gitignore
    echo .venv/ >> .gitignore
    echo venv/ >> .gitignore
    echo backend/.env >> .gitignore
    echo backend/__pycache__/ >> .gitignore
    echo backend/*.pyc >> .gitignore
    
    REM Adiciona e commita .gitignore
    git add .gitignore
    git commit -m "Add .gitignore"
    git push
)

echo.
echo 🎉 REPOSITÓRIO CONFIGURADO COM SUCESSO!
echo.
echo 📍 URL do repositório: https://github.com/%GITHUB_USER%/desfollow
echo.
echo 📋 PRÓXIMOS PASSOS:
echo 1. Configure o repositório no script setup_vps.sh
echo 2. Atualize a URL no DEPLOY_SIMPLIFICADO.md
echo 3. Faça deploy seguindo o guia
echo.
echo 🔗 Links úteis:
echo - Repositório: https://github.com/%GITHUB_USER%/desfollow
echo - Issues: https://github.com/%GITHUB_USER%/desfollow/issues
echo - Settings: https://github.com/%GITHUB_USER%/desfollow/settings
echo.
echo 💡 Dica: Para fazer push de mudanças futuras:
echo git add .
echo git commit -m "Descrição da mudança"
echo git push
echo.
pause 