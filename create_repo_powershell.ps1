# Script PowerShell para criar repositório no GitHub
# Desfollow - Deploy Automation

Write-Host "🚀 Criando repositório no GitHub..." -ForegroundColor Green

# Verificar se está no diretório correto
if (-not (Test-Path "package.json")) {
    Write-Host "❌ Execute este script na raiz do projeto Desfollow" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

Write-Host "📋 Verificando Git..." -ForegroundColor Yellow

# Verificar se Git está instalado
try {
    $gitVersion = git --version
    Write-Host "✅ Git encontrado: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Git não encontrado" -ForegroundColor Red
    Write-Host "📥 Instale o Git: https://git-scm.com/" -ForegroundColor Yellow
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Perguntar usuário do GitHub
$githubUser = Read-Host "Digite seu usuário do GitHub"

Write-Host "🏗️ Criando repositório desfollow..." -ForegroundColor Yellow

# Criar repositório via GitHub API (sem token, usando apenas Git)
Write-Host "💡 Criando repositório via Git..." -ForegroundColor Cyan

# Verificar se já existe .git
if (Test-Path ".git") {
    Write-Host "⚠️ Repositório Git já inicializado" -ForegroundColor Yellow
    Write-Host "📋 Status atual:" -ForegroundColor Cyan
    git status
    Write-Host ""
    $continue = Read-Host "Deseja continuar? (s/n)"
    if ($continue -ne "s" -and $continue -ne "S") {
        Write-Host "❌ Operação cancelada" -ForegroundColor Red
        Read-Host "Pressione Enter para sair"
        exit 1
    }
} else {
    Write-Host "📁 Inicializando repositório Git..." -ForegroundColor Yellow
    git init
}

# Adicionar todos os arquivos
Write-Host "📦 Adicionando arquivos..." -ForegroundColor Yellow
git add .

# Fazer primeiro commit
Write-Host "📝 Fazendo primeiro commit..." -ForegroundColor Yellow
git commit -m "Initial commit - Desfollow project"

# Adicionar remote
Write-Host "🔗 Adicionando remote do GitHub..." -ForegroundColor Yellow
git remote add origin "https://github.com/$githubUser/desfollow.git"

# Configurar branch principal
Write-Host "🌿 Configurando branch principal..." -ForegroundColor Yellow
git branch -M main

# Tentar fazer push
Write-Host "📤 Fazendo push para GitHub..." -ForegroundColor Yellow
try {
    git push -u origin main
    Write-Host "✅ Push realizado com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro ao fazer push" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Crie o repositório manualmente:" -ForegroundColor Yellow
    Write-Host "1. Acesse: https://github.com/new" -ForegroundColor Cyan
    Write-Host "2. Nome: desfollow" -ForegroundColor Cyan
    Write-Host "3. Descrição: Desfollow - Encontre quem não te segue de volta no Instagram" -ForegroundColor Cyan
    Write-Host "4. Público" -ForegroundColor Cyan
    Write-Host "5. NÃO inicialize com README, .gitignore ou license" -ForegroundColor Cyan
    Write-Host "6. Execute novamente este script" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Verificar se .gitignore existe
if (-not (Test-Path ".gitignore")) {
    Write-Host "📝 Criando .gitignore..." -ForegroundColor Yellow
    
    $gitignoreContent = @"
# Dependencies
node_modules/
.env
.env.local
.env.production
dist/
build/
.DS_Store
*.log
.vscode/
.idea/
__pycache__/
*.pyc
.pytest_cache/
.coverage
.venv/
venv/
backend/.env
backend/__pycache__/
backend/*.pyc
"@
    
    $gitignoreContent | Out-File -FilePath ".gitignore" -Encoding UTF8
    
    # Adicionar e commitar .gitignore
    git add .gitignore
    git commit -m "Add .gitignore"
    git push
}

Write-Host ""
Write-Host "🎉 REPOSITÓRIO CONFIGURADO COM SUCESSO!" -ForegroundColor Green
Write-Host ""
Write-Host "📍 URL do repositório: https://github.com/$githubUser/desfollow" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1. Configure o repositório no script setup_vps.sh" -ForegroundColor White
Write-Host "2. Atualize a URL no DEPLOY_SIMPLIFICADO.md" -ForegroundColor White
Write-Host "3. Faça deploy seguindo o guia" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Links úteis:" -ForegroundColor Yellow
Write-Host "- Repositório: https://github.com/$githubUser/desfollow" -ForegroundColor Cyan
Write-Host "- Issues: https://github.com/$githubUser/desfollow/issues" -ForegroundColor Cyan
Write-Host "- Settings: https://github.com/$githubUser/desfollow/settings" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 Dica: Para fazer push de mudanças futuras:" -ForegroundColor Yellow
Write-Host "git add ." -ForegroundColor White
Write-Host "git commit -m 'Descrição da mudança'" -ForegroundColor White
Write-Host "git push" -ForegroundColor White
Write-Host ""
Read-Host "Pressione Enter para sair" 