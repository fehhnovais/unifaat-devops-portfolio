.PHONY: help build up down logs restart clean dev prod ps shell-api shell-db shell-redis test

help: ## Exibir ajuda
	@echo "Comandos disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build das imagens Docker
	docker-compose build

up: ## Iniciar todos os serviços (produção)
	docker-compose up -d

dev: ## Iniciar em modo desenvolvimento
	docker-compose -f docker-compose.dev.yml up -d

down: ## Parar todos os serviços
	docker-compose down

down-v: ## Parar e remover volumes
	docker-compose down -v

logs: ## Ver logs de todos os serviços
	docker-compose logs -f

logs-api: ## Ver logs da API
	docker-compose logs -f api

logs-db: ## Ver logs do PostgreSQL
	docker-compose logs -f postgres

logs-redis: ## Ver logs do Redis
	docker-compose logs -f redis

restart: ## Reiniciar todos os serviços
	docker-compose restart

ps: ## Listar status dos containers
	docker-compose ps

shell-api: ## Acessar shell do container da API
	docker exec -it nodejs_api sh

shell-db: ## Acessar PostgreSQL
	docker exec -it postgres_db psql -U nodejs_user -d nodejs_db

shell-redis: ## Acessar Redis CLI
	docker exec -it redis_cache redis-cli

clean: ## Limpar containers, volumes e imagens
	docker-compose down -v --rmi all

rebuild: ## Rebuild completo sem cache
	docker-compose build --no-cache
	docker-compose up -d

prod: build up ## Build e iniciar em produção

health: ## Verificar health dos serviços
	@echo "Verificando health da API..."
	@curl -s http://localhost:3000/health | python -m json.tool || echo "API não está respondendo"
