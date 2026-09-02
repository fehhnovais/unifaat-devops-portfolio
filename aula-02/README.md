# Aplicação Node.js com Docker Compose

Stack completa com Node.js 20, Express, PostgreSQL 15 e Redis 7.

## 📋 Pré-requisitos

- Docker
- Docker Compose

## 🚀 Como usar

### 1. Configure as variáveis de ambiente

Copie o arquivo `.env.example` para `.env`:

```bash
copy .env.example .env
```

Edite o arquivo `.env` com suas configurações.

### 2. Crie a estrutura da aplicação

Crie a pasta `app` e os arquivos necessários:

```bash
mkdir app
```

### 3. Build da imagem Docker

```bash
docker-compose build
```

### 4. Inicie os serviços

**Modo Produção:**
```bash
docker-compose up -d
```

**Modo Desenvolvimento (com hot-reload):**
```bash
docker-compose -f docker-compose.dev.yml up -d
```

### 4. Verifique o status

```bash
docker-compose ps
```

## 📦 Dockerfiles

### Dockerfile (Produção)
- **Multi-stage build** para imagem otimizada
- **Usuário não-root** para segurança
- **npm ci** para instalação determinística
- **Healthcheck** integrado
- Imagem final ~150MB

### Dockerfile.dev (Desenvolvimento)
- Inclui **devDependencies** (nodemon)
- **Volume mounting** para hot-reload
- Ferramentas de desenvolvimento (bash, curl)
- Comando padrão: `npm run dev`

## 🔨 Build e Deploy

### Build manual da imagem
```bash
# Produção
docker build -t nodejs-express-api:latest -f Dockerfile .

# Desenvolvimento
docker build -t nodejs-express-api:dev -f Dockerfile.dev .
```

### Rebuild após mudanças
```bash
docker-compose build --no-cache
docker-compose up -d
```

### 5. Visualize os logs

```bash
docker-compose logs -f
```

## 🏗️ Estrutura

```
.
├── docker-compose.yml    # Configuração dos containers
├── .env                  # Variáveis de ambiente (não versionado)
├── .env.example          # Template das variáveis
├── .gitignore           # Arquivos ignorados pelo Git
└── app/                 # Código da aplicação Node.js
    ├── package.json
    └── index.js
```

## 🔧 Serviços

### API (Node.js)
- **Porta:** 3000
- **Healthcheck:** Endpoint `/health`
- **Restart:** unless-stopped

### PostgreSQL
- **Porta:** 5432
- **Volume:** `postgres_data` (persistente)
- **Healthcheck:** pg_isready

### Redis
- **Porta:** 6379
- **Volume:** `redis_data` (persistente)
- **Healthcheck:** redis-cli ping

## 🌐 Rede

Todos os serviços estão na rede bridge customizada `nodejs_app_network`.

## 💾 Volumes

- `postgres_volume`: Dados do PostgreSQL
- `redis_volume`: Dados do Redis

## 🛑 Parar os serviços

```bash
docker-compose down
```

Para remover também os volumes:

```bash
docker-compose down -v
```

## 🚀 Scripts de Automação

### PowerShell (Windows)
```powershell
# Ver comandos disponíveis
.\scripts.ps1

# Iniciar em produção
.\scripts.ps1 prod

# Iniciar em desenvolvimento
.\scripts.ps1 dev

# Ver logs
.\scripts.ps1 logs

# Verificar health
.\scripts.ps1 health

# Parar serviços
.\scripts.ps1 down
```

### Makefile (Linux/Mac)
```bash
# Ver comandos disponíveis
make help

# Build e iniciar
make prod

# Modo desenvolvimento
make dev

# Ver logs
make logs
```

## 📊 Comandos úteis

### Ferramentas de Monitoramento (Opcional)
```bash
# Iniciar com ferramentas de monitoramento
docker-compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d

# Acessar interfaces:
# - Adminer (PostgreSQL): http://localhost:8080
# - Redis Commander: http://localhost:8081
```

### Acessar o container da API
```bash
docker exec -it nodejs_api sh
```

### Acessar o PostgreSQL
```bash
docker exec -it postgres_db psql -U nodejs_user -d nodejs_db
```

### Acessar o Redis CLI
```bash
docker exec -it redis_cache redis-cli
```

### Ver logs de um serviço específico
```bash
docker-compose logs -f api
docker-compose logs -f postgres
docker-compose logs -f redis
```
