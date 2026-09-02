# 📂 Estrutura do Projeto

```
aula-02/
│
├── 🐳 Docker Files
│   ├── Dockerfile                      # Dockerfile de produção (multi-stage)
│   ├── Dockerfile.dev                  # Dockerfile de desenvolvimento
│   ├── .dockerignore                   # Arquivos ignorados no build
│   ├── docker-compose.yml              # Orquestração principal (produção)
│   ├── docker-compose.dev.yml          # Orquestração para desenvolvimento
│   └── docker-compose.monitoring.yml   # Ferramentas de monitoramento (opcional)
│
├── 📱 Application
│   └── app/
│       ├── index.js                    # API Express com PostgreSQL e Redis
│       ├── package.json                # Dependências Node.js
│       └── app.js                      # (arquivo existente)
│
├── ⚙️ Configuration
│   ├── .env.example                    # Template de variáveis de ambiente
│   └── .gitignore                      # Arquivos ignorados pelo Git
│
├── 🔧 Scripts & Tools
│   ├── scripts.ps1                     # Scripts PowerShell (Windows)
│   ├── Makefile                        # Comandos Make (Linux/Mac)
│   └── test-api.ps1                    # Script de testes da API
│
└── 📚 Documentation
    ├── README.md                       # Documentação principal
    ├── COMMANDS.md                     # Referência de comandos
    └── STRUCTURE.md                    # Este arquivo
```

## 🎯 Arquivos Principais

### **Dockerfile** (Produção)
- ✅ Multi-stage build
- ✅ Imagem Alpine (leve)
- ✅ Usuário não-root
- ✅ Healthcheck integrado
- ✅ npm ci (build determinístico)
- 📦 Tamanho: ~150MB

### **Dockerfile.dev** (Desenvolvimento)
- ✅ Inclui devDependencies
- ✅ Hot-reload com nodemon
- ✅ Ferramentas de debug
- ✅ Volume mounting

### **docker-compose.yml** (Produção)
```yaml
Serviços:
├── api (Node.js 20 + Express)
│   ├── Build: Dockerfile
│   ├── Porta: 3000
│   ├── Depends: postgres, redis
│   └── Restart: unless-stopped
│
├── postgres (PostgreSQL 15)
│   ├── Volume: postgres_volume
│   ├── Porta: 5432
│   ├── Healthcheck: pg_isready
│   └── Restart: unless-stopped
│
└── redis (Redis 7)
    ├── Volume: redis_volume
    ├── Porta: 6379
    ├── Healthcheck: redis-cli ping
    └── Restart: unless-stopped

Network: app_network (bridge customizada)
```

### **docker-compose.dev.yml** (Desenvolvimento)
```yaml
Diferenças da Produção:
├── Usa Dockerfile.dev
├── Volume mounting ativo
├── NODE_ENV=development
├── Comando: npm run dev (nodemon)
└── Mesma network e volumes
```

### **docker-compose.monitoring.yml** (Opcional)
```yaml
Ferramentas:
├── Adminer (PostgreSQL UI)
│   └── http://localhost:8080
│
└── Redis Commander (Redis UI)
    └── http://localhost:8081
```

## 🚀 Fluxo de Trabalho

### Desenvolvimento
```powershell
# 1. Configurar ambiente
copy .env.example .env

# 2. Iniciar em modo dev
.\scripts.ps1 dev

# 3. Desenvolver com hot-reload
# Editar arquivos em ./app/

# 4. Testar
.\test-api.ps1

# 5. Ver logs
.\scripts.ps1 logs-api
```

### Produção
```powershell
# 1. Build otimizado
.\scripts.ps1 build

# 2. Iniciar
.\scripts.ps1 up

# 3. Verificar health
.\scripts.ps1 health

# 4. Monitorar
.\scripts.ps1 logs
```

## 🔒 Segurança

### Dockerfile
- ✅ Usuário não-root (nodejs:1001)
- ✅ npm ci (evita package-lock drift)
- ✅ Multi-stage (reduz superfície de ataque)
- ✅ Alpine Linux (menos vulnerabilidades)

### Docker Compose
- ✅ Variáveis de ambiente (.env)
- ✅ Network isolada (bridge custom)
- ✅ Volumes nomeados (persistência)
- ✅ Healthchecks (disponibilidade)
- ✅ Restart policies (resiliência)

### Aplicação
- ✅ Credenciais via variáveis
- ✅ Tratamento de erros
- ✅ Graceful shutdown
- ✅ Health endpoint

## 📊 Endpoints da API

```
GET  /                      # Informações da API
GET  /health                # Status dos serviços
GET  /users                 # Teste PostgreSQL
GET  /cache/:key            # Buscar no Redis
POST /cache/:key            # Salvar no Redis
```

## 🧪 Testes

### Manual
```powershell
# Script automatizado
.\test-api.ps1

# Comando único
Invoke-RestMethod http://localhost:3000/health
```

### Health Check
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "services": {
    "postgres": "connected",
    "redis": "connected"
  }
}
```

## 🔄 Lifecycle dos Containers

```
Build → Create → Start → Running
                    ↓
                 Healthy
                    ↓
              [Working...]
                    ↓
            Stop → Remove
```

## 💾 Persistência de Dados

### Volumes Nomeados
```
postgres_volume/     # Dados do PostgreSQL
└── pgdata/

redis_volume/        # Dados do Redis
└── appendonly.aof
```

### Backup
```powershell
# PostgreSQL
docker exec postgres_db pg_dump -U nodejs_user nodejs_db > backup.sql

# Redis
docker exec redis_cache redis-cli save
```

## 🌐 Network

```
nodejs_app_network (bridge)
│
├── api (nodejs_api)
│   └── 172.18.0.2
│
├── postgres (postgres_db)
│   └── 172.18.0.3
│
└── redis (redis_cache)
    └── 172.18.0.4
```

## 📈 Performance

### Imagens
```
node:20-alpine          ~150MB
postgres:15-alpine      ~230MB
redis:7-alpine          ~30MB
─────────────────────────────
Total:                  ~410MB
```

### Startup Time
```
Redis:      ~2 segundos
PostgreSQL: ~5 segundos
API:        ~8 segundos (total)
```

## 🎓 Boas Práticas Implementadas

✅ Multi-stage builds (otimização)
✅ .dockerignore (build mais rápido)
✅ Healthchecks (observabilidade)
✅ depends_on com condition (ordem)
✅ Restart policies (resiliência)
✅ Volumes nomeados (persistência)
✅ Network customizada (isolamento)
✅ Usuário não-root (segurança)
✅ Variáveis de ambiente (configuração)
✅ Imagens Alpine (tamanho reduzido)
✅ Documentação completa
✅ Scripts de automação

## 📚 Próximos Passos

### Melhorias Sugeridas
- [ ] Adicionar Nginx como reverse proxy
- [ ] Implementar SSL/TLS
- [ ] Adicionar testes automatizados
- [ ] Configurar CI/CD
- [ ] Adicionar Prometheus/Grafana
- [ ] Implementar rate limiting
- [ ] Adicionar backup automático
- [ ] Configurar clustering
- [ ] Adicionar logging centralizado
- [ ] Implementar secrets management

### Escalabilidade
```yaml
# Escalar API
docker-compose up -d --scale api=3

# Load balancer (nginx)
# Health checks distribuídos
# Cache compartilhado (Redis)
# Database read replicas
```

## 🔗 Recursos

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [PostgreSQL Docker](https://hub.docker.com/_/postgres)
- [Redis Docker](https://hub.docker.com/_/redis)
