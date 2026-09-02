# 📝 Comandos Úteis - Docker Compose

## 🚀 Início Rápido

### Configuração Inicial
```powershell
# 1. Copiar arquivo de ambiente
copy .env.example .env

# 2. Editar variáveis (se necessário)
notepad .env

# 3. Build das imagens
docker-compose build

# 4. Iniciar serviços
docker-compose up -d

# 5. Verificar status
docker-compose ps
```

## 🔨 Build e Deploy

### Build
```powershell
# Build normal
docker-compose build

# Build sem cache
docker-compose build --no-cache

# Build de um serviço específico
docker-compose build api

# Build com output detalhado
docker-compose build --progress=plain
```

### Iniciar Serviços
```powershell
# Produção (detached)
docker-compose up -d

# Desenvolvimento
docker-compose -f docker-compose.dev.yml up -d

# Com logs no terminal (foreground)
docker-compose up

# Recriar containers
docker-compose up -d --force-recreate
```

## 📊 Monitoramento

### Status e Logs
```powershell
# Ver status dos containers
docker-compose ps

# Logs de todos os serviços
docker-compose logs

# Logs em tempo real
docker-compose logs -f

# Logs de um serviço específico
docker-compose logs -f api
docker-compose logs -f postgres
docker-compose logs -f redis

# Últimas 100 linhas
docker-compose logs --tail=100

# Logs com timestamp
docker-compose logs -t
```

### Health Check
```powershell
# Via PowerShell
Invoke-RestMethod http://localhost:3000/health | ConvertTo-Json

# Via curl (se instalado)
curl http://localhost:3000/health

# Via navegador
start http://localhost:3000/health
```

### Estatísticas de Recursos
```powershell
# Ver uso de CPU/Memória
docker stats

# Stats de containers específicos
docker stats nodejs_api postgres_db redis_cache
```

## 🔧 Gerenciamento

### Parar e Remover
```powershell
# Parar serviços
docker-compose stop

# Parar um serviço específico
docker-compose stop api

# Parar e remover containers
docker-compose down

# Parar e remover volumes
docker-compose down -v

# Parar e remover imagens
docker-compose down --rmi all

# Limpar tudo
docker-compose down -v --rmi all --remove-orphans
```

### Reiniciar
```powershell
# Reiniciar todos os serviços
docker-compose restart

# Reiniciar serviço específico
docker-compose restart api

# Parar e iniciar novamente
docker-compose stop
docker-compose start
```

## 🐚 Acesso aos Containers

### Shell/Terminal
```powershell
# Acessar container da API
docker exec -it nodejs_api sh

# Acessar como root
docker exec -it -u root nodejs_api sh

# Executar comando único
docker exec nodejs_api node -v
```

### PostgreSQL
```powershell
# Acessar psql
docker exec -it postgres_db psql -U nodejs_user -d nodejs_db

# Executar query direta
docker exec postgres_db psql -U nodejs_user -d nodejs_db -c "SELECT version();"

# Dump do banco
docker exec postgres_db pg_dump -U nodejs_user nodejs_db > backup.sql

# Restaurar backup
Get-Content backup.sql | docker exec -i postgres_db psql -U nodejs_user -d nodejs_db
```

### Redis
```powershell
# Acessar Redis CLI
docker exec -it redis_cache redis-cli

# Executar comando direto
docker exec redis_cache redis-cli ping
docker exec redis_cache redis-cli info
docker exec redis_cache redis-cli keys "*"

# Ver todas as chaves
docker exec redis_cache redis-cli --scan

# Flush database (cuidado!)
docker exec redis_cache redis-cli flushdb
```

## 📦 Volumes e Dados

### Gerenciar Volumes
```powershell
# Listar volumes
docker volume ls

# Inspecionar volume
docker volume inspect postgres_volume
docker volume inspect redis_volume

# Remover volume (quando parado)
docker volume rm postgres_volume

# Backup de volume PostgreSQL
docker run --rm -v postgres_volume:/data -v ${PWD}:/backup alpine tar czf /backup/postgres-backup.tar.gz -C /data .

# Restaurar backup
docker run --rm -v postgres_volume:/data -v ${PWD}:/backup alpine tar xzf /backup/postgres-backup.tar.gz -C /data
```

## 🔍 Debugging

### Inspecionar
```powershell
# Inspecionar container
docker inspect nodejs_api

# Ver configuração de rede
docker inspect nodejs_api | Select-String "NetworkMode|Networks"

# Ver variáveis de ambiente
docker exec nodejs_api env

# Ver processos rodando
docker top nodejs_api
```

### Troubleshooting
```powershell
# Ver eventos do Docker
docker events

# Ver uso de disco
docker system df

# Verificar conectividade entre containers
docker exec nodejs_api ping postgres
docker exec nodejs_api ping redis

# Testar conexão com PostgreSQL
docker exec nodejs_api sh -c "apk add postgresql-client && psql -h postgres -U nodejs_user -d nodejs_db -c 'SELECT 1'"

# Testar conexão com Redis
docker exec nodejs_api sh -c "apk add redis && redis-cli -h redis ping"
```

## 🧹 Limpeza

### Limpar Recursos Não Utilizados
```powershell
# Remover containers parados
docker container prune -f

# Remover imagens não utilizadas
docker image prune -f

# Remover volumes não utilizados
docker volume prune -f

# Remover redes não utilizadas
docker network prune -f

# Limpar tudo (cuidado!)
docker system prune -a --volumes -f
```

## 🔄 Update e Manutenção

### Atualizar Serviços
```powershell
# Pull de novas imagens
docker-compose pull

# Rebuild e restart
docker-compose up -d --build

# Atualizar apenas um serviço
docker-compose up -d --build api
```

### Escalar Serviços
```powershell
# Escalar API (múltiplas instâncias)
docker-compose up -d --scale api=3

# Verificar
docker-compose ps
```

## 📝 Logs e Debugging Avançado

### Exportar Logs
```powershell
# Salvar logs em arquivo
docker-compose logs > logs.txt

# Logs com timestamp
docker-compose logs -t > logs-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt

# Logs de um período
docker-compose logs --since="2024-01-01" --until="2024-01-31"
```

## 🧪 Testes

### Testar API
```powershell
# Health check
Invoke-RestMethod http://localhost:3000/health

# Endpoint raiz
Invoke-RestMethod http://localhost:3000/

# Testar cache (SET)
$body = @{
    value = "Teste Redis"
    ttl = 60
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:3000/cache/minha-chave -Method POST -Body $body -ContentType "application/json"

# Testar cache (GET)
Invoke-RestMethod http://localhost:3000/cache/minha-chave
```

## 🎯 Comandos PowerShell Úteis

```powershell
# Função para checar se serviços estão rodando
function Test-Services {
    $services = @("nodejs_api", "postgres_db", "redis_cache")
    foreach ($service in $services) {
        $status = docker ps --filter "name=$service" --format "{{.Status}}"
        Write-Host "$service : $status"
    }
}

# Executar
Test-Services
```

## 📚 Referências

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker CLI Reference](https://docs.docker.com/engine/reference/commandline/cli/)
- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
- [Redis Docker Hub](https://hub.docker.com/_/redis)
- [Node.js Docker Hub](https://hub.docker.com/_/node)
