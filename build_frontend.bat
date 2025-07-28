@echo off
echo 🚀 Build Frontend - Desfollow
echo.

echo 📦 Instalando dependências...
npm install

echo 🔨 Fazendo build de produção...
npm run build

echo ✅ Build concluído!
echo.
echo 📁 Arquivos prontos em: dist/
echo.
echo 📋 PRÓXIMOS PASSOS:
echo 1. Acesse o painel da Hostinger
echo 2. Vá em File Manager > public_html
echo 3. Delete tudo que estiver lá
echo 4. Upload da pasta dist/ (conteúdo da pasta)
echo 5. Configure SSL no painel
echo.
echo 🌐 URL final: https://desfollow.com.br
echo.
pause 