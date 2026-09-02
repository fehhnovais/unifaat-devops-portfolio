# 🏥 Healthchecks Configurados - Análise Completa

## 📊 Visão Geral

Seu `docker-compose.yml` possui **2 healthchecks ativos** (PostgreSQL e Redis).  
A API **NÃO possui healthcheck** configurado.

---

## 1️⃣ PostgreSQL Healthcheck

### Configuração Atual:
```yaml
postgres:
  image: postgres:15-alpine
  # ... outras configurações
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
    interval: 10s
    timeout: 5s
    retries: 5
    start_period: 10s
```

### Como Funciona:
| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| **test** | `pg_isready -U technova -d technova` | Verifica se PostgreSQL aceita conexões |
| **interval** | 10s | Testa a cada 10 segundos |
| **timeout** | 5s | Máximo 5 segundos para responder |
| **retries** | 5 | 5 tentativas antes de marcar como unhealthy |
| **start_period** | 10s | Aguarda 10s antes de começar os testes |

### Comandos de Teste:
```powershell
# Ver status do healthcheck
docker inspect postgres_db --format='{{.State.Health.Status}}'

# Ver histórico de healthchecks
docker inspect postgres_db --format='{{json .State.Health}}' | ConvertFrom-Json

# Executar healthcheck manualmente
docker exec postgres_db pg_isready -U technova -d technova
```

### Estados Possíveis:
- 🟢 **healthy** - PostgreSQL respondendo corretamente
- 🟡 **starting** - Nos primeiros 10 segundos (start_period)
- 🔴 **unhealthy** - Falhou 5 vezes consecutivas

---

## 2️⃣ Redis Healthcheck

### Configuração Atual:
```yaml
redis:
  image: redis:7-alpine
  # ... outras configurações
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 10s
    timeout: 5s
    retries: 5
    start_period: 10s
```

### Como Funciona:
| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| **test** | `redis-cli ping` | Executa PING no Redis |
| **interval** | 10s | Testa a cada 10 segundos |
| **timeout** | 5s | Máximo 5 segundos para responder |
| **retries** | 5 | 5 tentativas antes de marcar como unhealthy |
| **start_period** | 10s | Aguarda 10s antes de começar os testes |

### Comandos de Teste:
```powershell
# Ver status do healthcheck
docker inspect redis_cache --format='{{.State.Health.Status}}'

# Ver logs de saúde
docker inspect redis_cache --format='{{json .State.Health.Log}}'

# Executar healthcheck manualmente
docker exec redis_cache redis-cli ping
# Resposta esperada: PONG
```

### Resposta Esperada:
```
PONG
```

---

## ⚠️ 3️⃣ API Node.js - SEM HEALTHCHECK

### Problema:
A API **NÃO possui healthcheck** configurado no docker-compose.yml atual.

### Impacto:
- ❌ Não há verificação automática se a API está funcionando
- ❌ Docker não sabe se o container está realmente pronto
- ❌ `depends_on` não pode usar `condition: service_healthy`

---

## ✅ Healthcheck Recomendado para API

### Opção 1: Usando wget (simples)

```yaml
api:
  # ... outras configurações
  healthcheck:
    test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s
```

**Problema:** `wget` não vem instalado na imagem `node:20-alpine` por padrão.

---

### Opção 2: Usando Node.js (recomendado)

```yaml
api:
  # ... outras configurações
  healthcheck:
    test: ["CMD-SHELL", "node -e \"require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})\""]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s
```

**Vantagem:** Usa Node.js nativo, sem dependências extras.

---

### Opção 3: Usando curl (alternativa)

```yaml
api:
  # ... outras configurações
  healthcheck:
    test: ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s
```

**Nota:** Precisa instalar curl no Dockerfile:
```dockerfile
RUN apk add --no-cache curl
```

---

### Opção 4: Script Customizado (mais robusto)

**1. Criar arquivo `healthcheck.sh`:**
```bash
#!/bin/sh
set -e

# Testar endpoint de health
response=$(wget --no-verbose --tries=1 --spider http://localhost:3000/health 2>&1 | grep -c "200 OK" || true)

if [ "$response" -eq 1 ]; then
  echo "API is healthy"
  exit 0
else
  echo "API is unhealthy"
  exit 1
fi
```

**2. Adicionar no Dockerfile:**
```dockerfile
RUN apk add --no-cache wget
COPY healthcheck.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/healthcheck.sh
```

**3. Usar no docker-compose.yml:**
```yaml
healthcheck:
  test: ["CMD", "/usr/local/bin/healthcheck.sh"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

---

## 🔍 Como Adicionar Healthcheck na API (Recomendação)

### Passo 1: Atualizar docker-compose.yml

```yaml
api:
  build:
    context: ./app
    dockerfile: ../Dockerfile
  image: nodejs-express-api:latest
  container_name: nodejs_api
  ports:
    - "3000:3000"
  # ... variáveis de ambiente
  networks:
    - app_network
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy
  restart: unless-stopped
  healthcheck:
    test: ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s
```

### Passo 2: Atualizar Dockerfile

```dockerfile
FROM node:20-alpine

# Instalar wget para healthcheck
RUN apk add --no-cache wget

WORKDIR /app

COPY package*.json ./

RUN npm install --production

COPY . .

EXPOSE 3000

CMD ["node", "app.js"]
```

---

## 📊 Comparação de Healthchecks

| Serviço | Status | Método | Intervalo | Timeout | Retries | Start Period |
|---------|--------|--------|-----------|---------|---------|--------------|
| **PostgreSQL** | ✅ Ativo | `pg_isready` | 10s | 5s | 5 | 10s |
| **Redis** | ✅ Ativo | `redis-cli ping` | 10s | 5s | 5 | 10s |
| **API** | ❌ Ausente | - | - | - | - | - |

---

## 🧪 Testando Healthchecks

### Verificar Status de Todos os Containers
```powershell
docker-compose ps
```

Saída esperada:
```
NAME            STATUS                    HEALTH
nodejs_api      Up 2 minutes             
postgres_db     Up 2 minutes (healthy)   
redis_cache     Up 2 minutes (healthy)
```

### Monitorar Healthchecks em Tempo Real
```powershell
# PostgreSQL
docker inspect postgres_db --format='{{.State.Health.Status}}'

# Redis
docker inspect redis_cache --format='{{.State.Health.Status}}'

# Detalhes completos
docker inspect postgres_db --format='{{json .State.Health}}' | ConvertFrom-Json | ConvertTo-Json
```

### Ver Logs de Healthcheck
```powershell
docker events --filter event=health_status
```

---

## 🚨 Troubleshooting

### PostgreSQL Unhealthy?
```powershell
# 1. Verificar logs
docker logs postgres_db

# 2. Testar comando manualmente
docker exec postgres_db pg_isready -U technova -d technova

# 3. Entrar no container
docker exec -it postgres_db sh

# 4. Testar conexão interna
psql -U technova -d technova -c "SELECT 1"
```

### Redis Unhealthy?
```powershell
# 1. Verificar logs
docker logs redis_cache

# 2. Testar ping manualmente
docker exec redis_cache redis-cli ping

# 3. Ver info do Redis
docker exec redis_cache redis-cli info server
```

### API Sem Resposta?
```powershell
# 1. Verificar se está rodando
docker ps

# 2. Ver logs
docker logs nodejs_api

# 3. Testar endpoint manualmente
Invoke-RestMethod http://localhost:3000/health

# 4. Entrar no container
docker exec -it nodejs_api sh
wget -O- http://localhost:3000/health
```

---

## 📈 Benefícios dos Healthchecks

✅ **Restart Automático**: Docker reinicia containers unhealthy  
✅ **Ordem de Inicialização**: `depends_on` garante ordem correta  
✅ **Monitoramento**: Status visível no `docker ps`  
✅ **Orquestração**: Kubernetes/Swarm usam healthchecks  
✅ **Load Balancers**: Removem containers unhealthy da pool  

---

## 🎯 Próximos Passos

1. ✅ Adicionar healthcheck na API
2. ✅ Testar com `docker-compose up -d`
3. ✅ Monitorar com `docker-compose ps`
4. ✅ Verificar logs com `docker events`
5. ✅ Documentar comportamento esperado

---

## 📚 Referências

- [Docker Healthcheck Documentation](https://docs.docker.com/engine/reference/builder/#healthcheck)
- [Docker Compose Healthcheck](https://docs.docker.com/compose/compose-file/compose-file-v3/#healthcheck)
- [PostgreSQL pg_isready](https://www.postgresql.org/docs/current/app-pg-isready.html)
- [Redis PING Command](https://redis.io/commands/ping/)
