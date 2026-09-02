# Análise do Uso de IA — Aula 02 TF

## Prompt Utilizado

["Crie um docker-compose.yml para uma aplicação Node.js 20 com Express que usa PostgreSQL 15 como banco de dados e Redis 7 como cache. Uma API roda na porta 3000. O PostgreSQL precisa de volume nomeado para persistência. Todos os serviços devem estar na mesma rede bridge customizada. Use variáveis ​​de ambiente com interpolação de arquivo .env. Adicione healthchecks, depende_on com condição, e política de reinicialização a menos que seja parado."

Salve a saída original do Kiro]

## Output Original do Kiro

version: '3.8'

services:
  # Serviço da API Node.js com Express
  api:
    build:
      context: .
      dockerfile: Dockerfile
    image: nodejs-express-api:latest
    container_name: nodejs_api
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=${NODE_ENV:-production}
      - PORT=${PORT:-3000}
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=${POSTGRES_DB}
      - DB_USER=${POSTGRES_USER}
      - DB_PASSWORD=${POSTGRES_PASSWORD}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    networks:
      - app_network
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: unless-stopped

  # Serviço PostgreSQL 15
  postgres:
    image: postgres:15-alpine
    container_name: postgres_db
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    ports:
      - "5432:5432"

  # Serviço Redis 7
  redis:
    image: redis:7-alpine
    container_name: redis_cache
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - app_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    ports:
      - "6379:6379"

# Rede bridge customizada
networks:
  app_network:
    driver: bridge
    name: nodejs_app_network

# Volumes nomeados para persistência
volumes:
  postgres_data:
    driver: local
    name: postgres_volume
  redis_data:
    driver: local
    name: redis_volume


## Alterações que Fiz Manualmente

| O que mudei | Por quê |

- Alterei Dockerfile de acordo com o material da aula
- adicionei .dockerignore 
- docker-compose.yml alterei build: pois estava dando erro ao encontrar o arquivo app/package.json
-

## O que o Kiro Acertou

- ela ajudou na praticidade mesmo tendo que fazer algumas alterações, otimizou meu tempo.
- ela fez um REDME.md com exemplos praticos, comentarios e explicações.
- ganhei uma base solida para dar inicio.


## O que o Kiro Errou ou Omitiu

- algumas dependencias nao instaladas 
- ela criou alem do que precisava 
- dockerfile estava tentando copiar arquivos que nao existiam

## Minha Avaliação

- **Tempo economizado usando IA:** [3 horas]
- **Tempo gasto validando/corrigindo:** [40 minutos]
- **Nota para o output da IA (1-10):** [9]
- **Usaria novamente para este tipo de tarefa?** [sim]