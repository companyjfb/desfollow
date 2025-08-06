# 👻 Desfollow

> **Descubra quem não retribui seus follows no Instagram de forma inteligente e eficaz**

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Python](https://img.shields.io/badge/python-3.12+-blue.svg)
![Node.js](https://img.shields.io/badge/node.js-18+-green.svg)
![FastAPI](https://img.shields.io/badge/FastAPI-0.104.1-009688.svg)
![React](https://img.shields.io/badge/React-18.3.1-61dafb.svg)

## 📋 Índice

- [Sobre o Projeto](#-sobre-o-projeto)
- [Funcionalidades](#-funcionalidades)
- [Tecnologias](#-tecnologias)
- [Instalação e Configuração](#-instalação-e-configuração)
- [Uso](#-uso)
- [API Documentation](#-api-documentation)
- [Arquitetura](#-arquitetura)
- [Contribuição](#-contribuição)
- [Deploy](#-deploy)
- [FAQ](#-faq)

## 🎯 Sobre o Projeto

O **Desfollow** é uma plataforma web moderna que permite aos usuários do Instagram identificar quais contas eles seguem mas que não os seguem de volta (os famosos "ghost followers"). O sistema utiliza APIs premium do Instagram para realizar análises completas e precisas.

### ✨ Diferenciais

- **🤖 Análise Inteligente**: Classifica automaticamente perfis famosos/influencers vs. usuários reais
- **⚡ Performance Otimizada**: Sistema de paginação inteligente para contas com muitos seguidores
- **🔒 Seguro e Confiável**: Utiliza APIs oficiais do Instagram via RapidAPI
- **📊 Cache Inteligente**: Evita requisições desnecessárias com sistema de cache avançado
- **🎨 Interface Moderna**: Design responsivo e intuitivo com React + TypeScript

## 🚀 Funcionalidades

### 🔍 Análise de Followers
- Scan completo de followers vs following
- Detecção automática de perfis privados
- Classificação inteligente de ghost followers
- Resultados em tempo real com WebSocket-like polling

### 👥 Classificação de Perfis
- **Ghosts Reais**: Usuários comuns que não seguem de volta
- **Ghosts Famosos**: Influencers, marcas e perfis verificados
- **Filtragem Inteligente**: Remove automaticamente bots e contas suspeitas

### 📈 Dashboard e Relatórios
- Visualização dos resultados em tempo real
- Estatísticas detalhadas do perfil
- Interface responsiva para todos os dispositivos
- Exportação de dados (em desenvolvimento)

## 🛠 Tecnologias

### Backend
- **FastAPI** - Framework web moderno e rápido
- **SQLAlchemy** - ORM para banco de dados
- **Supabase/PostgreSQL** - Banco de dados principal
- **Redis** - Cache e sessões
- **Pydantic** - Validação de dados
- **Gunicorn** - Servidor WSGI para produção

### Frontend
- **React 18** - Biblioteca para interfaces
- **TypeScript** - Tipagem estática
- **Vite** - Bundler e dev server
- **Tailwind CSS** - Framework CSS utilitário
- **Shadcn/ui** - Componentes UI modernos
- **React Query** - Gerenciamento de estado servidor

### DevOps
- **Docker** - Containerização
- **Nginx** - Proxy reverso e servidor web
- **Let's Encrypt** - Certificados SSL automáticos
- **GitHub Actions** - CI/CD (em desenvolvimento)

## 🚀 Instalação e Configuração

### Pré-requisitos

- **Python 3.12+** (para o backend)
- **Node.js 18+** (para o frontend)
- **PostgreSQL** ou conta Supabase
- **RapidAPI Key** para APIs do Instagram
- **Docker** (opcional)

### 1. Clone o Repositório

```bash
git clone https://github.com/seu-usuario/desfollow.git
cd desfollow
```

### 2. Configuração do Backend

```bash
cd backend
pip install -r requirements.txt
```

#### Variáveis de Ambiente

Crie um arquivo `.env` no diretório `backend/`:

```env
# Banco de Dados (Supabase)
DATABASE_URL=postgresql://user:password@host:port/database

# RapidAPI (Instagram APIs)
RAPIDAPI_KEY=your_rapidapi_key_here

# Configurações do App
SECRET_KEY=your_secret_key_here
DEBUG=False
ENVIRONMENT=production

# Redis (opcional)
REDIS_URL=redis://localhost:6379/0
```

### 3. Configuração do Frontend

```bash
npm install
```

### 4. Execução Rápida (Windows)

```bash
# Inicia backend + frontend automaticamente
run_desfollow.bat

# Para parar todos os serviços
stop_desfollow.bat

# Verificar status
check_status.bat
```

### 5. Execução Manual

**Backend:**
```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Frontend:**
```bash
npm run dev
```

### 6. Docker (Opcional)

```bash
# Backend apenas
docker-compose up -d

# Build personalizado
docker build -t desfollow-backend ./backend
docker run -p 8000:8000 desfollow-backend
```

## 🖥 Uso

### Acesso Local
- **Frontend**: http://localhost:5173 (desenvolvimento) ou http://localhost:8080 (produção)
- **Backend API**: http://localhost:8000
- **Documentação API**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

### Fluxo de Uso

1. **Acesse a plataforma** e insira o username do Instagram
2. **Aguarde a análise** - o sistema busca todos os followers e following
3. **Visualize os resultados** - ghosts classificados por tipo
4. **Analise os dados** - estatísticas detalhadas do perfil

## 📚 API Documentation

### Endpoints Principais

#### `POST /api/scan`
Inicia uma análise completa de followers.

**Request:**
```json
{
  "username": "exemplo_usuario"
}
```

**Response:**
```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

#### `GET /api/scan/{job_id}`
Verifica o status de uma análise em andamento.

**Response:**
```json
{
  "status": "done",
  "count": 25,
  "real_ghosts_count": 15,
  "famous_ghosts_count": 10,
  "followers_count": 1250,
  "following_count": 800,
  "sample": ["user1", "user2", "user3", "user4", "user5"],
  "all": [...],
  "profile_info": {
    "username": "exemplo_usuario",
    "full_name": "Usuário Exemplo",
    "followers_count": 1250,
    "following_count": 800,
    "posts_count": 120,
    "is_private": false,
    "is_verified": false
  }
}
```

#### Estados da Análise
- `queued` - Na fila para processamento
- `running` - Em execução
- `done` - Concluído com sucesso
- `error` - Erro durante o processamento

### Autenticação (Futuro)

```bash
# Login
POST /api/auth/login
{
  "email": "user@example.com",
  "password": "senha123"
}

# Registro
POST /api/auth/register
{
  "email": "user@example.com", 
  "password": "senha123",
  "instagram_username": "seu_instagram"
}
```

## 🏗 Arquitetura

### Visão Geral do Sistema

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│    Frontend     │───▶│   Backend API   │───▶│  Instagram APIs │
│   (React/TS)    │    │   (FastAPI)     │    │   (RapidAPI)    │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │                        
         │                        ▼                        
         │               ┌─────────────────┐               
         │               │                 │               
         └──────────────▶│  Supabase DB    │               
                         │  (PostgreSQL)   │               
                         │                 │               
                         └─────────────────┘               
```

### Estrutura de Diretórios

```
desfollow/
├── 📁 backend/                      # API FastAPI
│   ├── 📁 app/
│   │   ├── 📄 main.py              # Aplicação principal
│   │   ├── 📄 routes.py            # Endpoints da API
│   │   ├── 📄 auth_routes.py       # Autenticação
│   │   ├── 📄 database.py          # Modelos e conexão DB
│   │   └── 📄 ig.py                # Lógica de análise Instagram
│   ├── 📄 requirements.txt         # Dependências Python
│   ├── 📄 Dockerfile              # Container backend
│   └── 📄 gunicorn.conf.py        # Configuração produção
├── 📁 src/                         # Frontend React
│   ├── 📁 components/              # Componentes reutilizáveis
│   │   ├── 📄 Header.tsx
│   │   ├── 📄 Benefits.tsx
│   │   └── 📁 ui/                  # Componentes base
│   ├── 📁 pages/                   # Páginas da aplicação
│   │   ├── 📄 Index.tsx           # Landing page
│   │   ├── 📄 Analyzing.tsx       # Página de análise
│   │   └── 📄 Results.tsx         # Resultados
│   ├── 📁 hooks/                   # Custom hooks
│   └── 📁 utils/                   # Utilitários
├── 📄 docker-compose.yml          # Orquestração containers
├── 📄 package.json                # Dependências frontend
└── 📁 deploy/                      # Scripts de deploy
```

### Fluxo de Dados

1. **Input do Usuário**: Username inserido no frontend
2. **Criação do Job**: Backend gera UUID único para tracking
3. **Busca de Dados**: APIs do Instagram via RapidAPI
4. **Processamento**: Classificação inteligente de followers
5. **Armazenamento**: Cache Redis + Banco Supabase
6. **Resposta**: Dados em tempo real via polling

## 🚢 Deploy

### Ambiente de Produção

O sistema está configurado para deploy em VPS com as seguintes especificações:

- **Servidor**: Ubuntu 20.04+ 
- **Proxy**: Nginx com SSL (Let's Encrypt)
- **Domínios**:
  - `desfollow.com.br` (Frontend)
  - `api.desfollow.com.br` (Backend)
  - `www.desfollow.com.br` (Redirect)

### Scripts de Deploy

```bash
# Deploy completo
./deploy.sh

# Deploy apenas backend
./deploy_backend_only.sh

# Atualizar frontend
./buildar_frontend_definitivo.sh

# Configurar SSL
./instalar_ssl_completo.sh
```

### Monitoramento

```bash
# Logs do backend
./monitorar_logs_backend.sh

# Status dos serviços
./verificar_servicos.sh

# Monitorar jobs em tempo real
./monitorar_jobs_tempo_real.sh
```

## 🤝 Contribuição

### Como Contribuir

1. **Fork** o repositório
2. **Clone** sua fork localmente
3. **Crie** uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
4. **Commit** suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
5. **Push** para a branch (`git push origin feature/nova-funcionalidade`)
6. **Abra** um Pull Request

### Padrões de Código

- **Backend**: PEP 8 (Python)
- **Frontend**: ESLint + Prettier (TypeScript/React)
- **Commits**: Conventional Commits
- **Testes**: pytest (backend) + Jest (frontend)

### Roadmap

- [ ] **Sistema de Autenticação Completo**
- [ ] **Plans de Assinatura (Freemium)**
- [ ] **Análises Programadas**
- [ ] **Relatórios Avançados**
- [ ] **API Pública**
- [ ] **App Mobile (React Native)**
- [ ] **Integração com outras redes sociais**

## ❓ FAQ

### Perguntas Frequentes

**Q: O sistema é seguro?**
A: Sim, utilizamos apenas APIs oficiais do Instagram e não solicitamos senhas.

**Q: Funciona com contas privadas?**
A: Não, contas privadas não podem ser analisadas devido às limitações da API.

**Q: Há limite de uso?**
A: Atualmente há rate limiting para proteger as APIs. Plans premium em desenvolvimento.

**Q: Os dados são armazenados?**
A: Sim, para cache e melhor performance, mas podem ser removidos a qualquer momento.

**Q: Como obter uma RapidAPI Key?**
A: Registre-se em [RapidAPI](https://rapidapi.com) e assine as APIs do Instagram utilizadas.

## 📄 Licença

Este projeto está licenciado sob a Licença MIT. Veja o arquivo [LICENSE](LICENSE) para detalhes.

## 📞 Contato

- **Instagram**: [@desfollowbr](https://instagram.com/desfollowbr)
- **Website**: [desfollow.com.br](https://desfollow.com.br)
- **Email**: contato@desfollow.com.br

---

<div align="center">

**[⬆ Voltar ao topo](#-desfollow)**

Feito com ❤️ para a comunidade Instagram brasileira

</div>
