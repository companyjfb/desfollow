@echo off
REM Script para criar repositório no GitHub via GitHub CLI
REM Desfollow - Deploy Automation

echo 🚀 Criando repositório no GitHub...

REM Verifica se está no diretório correto
if not exist "package.json" (
    echo ❌ Execute este script na raiz do projeto Desfollow
    pause
    exit /b 1
)

echo 📋 Verificando GitHub CLI...

REM Verifica se GitHub CLI está instalado
gh --version >nul 2>&1
if errorlevel 1 (
    echo ❌ GitHub CLI não encontrado
    echo.
    echo 📥 Instale o GitHub CLI:
    echo 1. Acesse: https://cli.github.com/
    echo 2. Baixe e instale para Windows
    echo 3. Execute: gh auth login
    echo.
    pause
    exit /b 1
)

echo ✅ GitHub CLI encontrado

REM Verifica se está logado
gh auth status >nul 2>&1
if errorlevel 1 (
    echo ❌ Não está logado no GitHub
    echo.
    echo 🔐 Faça login:
    echo gh auth login
    echo.
    pause
    exit /b 1
)

echo ✅ Logado no GitHub

REM Pergunta o nome do usuário/organização
set /p GITHUB_USER="Digite seu usuário do GitHub: "

REM Cria o repositório
echo.
echo 🏗️ Criando repositório desfollow...
gh repo create desfollow --public --description "Desfollow - Encontre quem não te segue de volta no Instagram" --homepage "https://desfollow.com.br"

if errorlevel 1 (
    echo ❌ Erro ao criar repositório
    echo.
    echo 💡 Possíveis soluções:
    echo 1. Verifique se já existe um repo chamado 'desfollow'
    echo 2. Use um nome diferente
    echo 3. Verifique suas permissões no GitHub
    echo.
    pause
    exit /b 1
)

echo ✅ Repositório criado com sucesso!

REM Inicializa git local (se não existir)
if not exist ".git" (
    echo 📁 Inicializando Git local...
    git init
    git add .
    git commit -m "Initial commit - Desfollow project"
)

REM Adiciona remote e faz push
echo 📤 Fazendo push para GitHub...
git remote add origin https://github.com/%GITHUB_USER%/desfollow.git
git branch -M main
git push -u origin main

if errorlevel 1 (
    echo ❌ Erro ao fazer push
    echo.
    echo 💡 Possíveis soluções:
    echo 1. Verifique se o repositório foi criado
    echo 2. Verifique suas permissões
    echo 3. Tente novamente
    echo.
    pause
    exit /b 1
)

echo ✅ Push realizado com sucesso!

REM Cria arquivo .gitignore se não existir
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
)

REM Adiciona e commita .gitignore
git add .gitignore
git commit -m "Add .gitignore"
git push

echo.
echo 🎉 REPOSITÓRIO CRIADO COM SUCESSO!
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
echo - Actions: https://github.com/%GITHUB_USER%/desfollow/actions
echo.
pause 