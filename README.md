# Desfollow

Encontre quem não retribui seus follows no Instagram.

## 🚀 Execução Rápida

### Pré-requisitos

- **Python 3.12+** (para o backend)
- **Node.js 18+** (para o frontend)
- **Docker** (opcional, para containerização)

### 1. Execução Completa (Recomendado)

**Windows:**
```bash
# Executa backend + frontend automaticamente
run_desfollow.bat

# Para parar todos os serviços
stop_desfollow.bat

# Verificar status dos serviços
check_status.bat
```

### 2. Execução Individual

**Backend (API):**
```bash
# Windows
run_backend.bat

# Linux/Mac
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

**Frontend:**
```bash
# Windows
run_frontend.bat

# Linux/Mac
npm install
npm run dev
```

### 3. Acessar

- **Frontend**: http://localhost:8080
- **Backend**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **API Health**: http://localhost:8000/api/health

### 4. Testar

```bash
# Testa o backend (crawler + API)
python test_backend.py
```

## 📁 Estrutura do Projeto

```
desfollow/
├── backend/                 # API FastAPI
│   ├── app/
│   │   ├── main.py         # Aplicação principal
│   │   ├── routes.py       # Endpoints da API
│   │   └── ig.py           # Crawler Instagram
│   ├── Dockerfile
│   └── requirements.txt
├── src/                    # Frontend React/TypeScript
│   ├── components/         # Componentes UI
│   ├── pages/             # Páginas da aplicação
│   ├── utils/
│   │   └── ghosts.ts      # Utilitários API
│   └── ...
└── docker-compose.yml
```

## 🔧 Endpoints da API

### POST /api/scan
Inicia um scan para encontrar usuários que não retribuem follows.

**Request:**
```json
{
  "username": "natgeo"
}
```

**Response:**
```json
{
  "job_id": "uuid-do-job"
}
```

### GET /api/scan/{job_id}
Verifica o status de um scan.

**Response:**
```json
{
  "status": "done",
  "count": 15,
  "sample": ["user1", "user2", "user3", "user4", "user5"],
  "all": ["user1", "user2", ...]
}
```

## 🐛 Debug

Para debug, todos os logs aparecem apenas no console do navegador. Não há elementos visuais de debug na interface.

## 📝 Notas

- O backend usa cache em memória (será substituído por Redis em produção)
- Máximo de 5 usuários retornados gratuitamente
- Rate limiting de 2 segundos entre requisições ao Instagram
- CORS configurado para localhost:3000
