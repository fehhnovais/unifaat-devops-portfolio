# Scripts PowerShell para gerenciar Docker Compose

function Show-Help {
    Write-Host "=== Comandos Disponíveis ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Build e Deploy:" -ForegroundColor Yellow
    Write-Host "  .\scripts.ps1 build          - Build das imagens Docker"
    Write-Host "  .\scripts.ps1 up             - Iniciar serviços (produção)"
    Write-Host "  .\scripts.ps1 dev            - Iniciar em modo desenvolvimento"
    Write-Host "  .\scripts.ps1 prod           - Build + iniciar produção"
    Write-Host ""
    Write-Host "Controle:" -ForegroundColor Yellow
    Write-Host "  .\scripts.ps1 down           - Parar todos os serviços"
    Write-Host "  .\scripts.ps1 down-v         - Parar e remover volumes"
    Write-Host "  .\scripts.ps1 restart        - Reiniciar serviços"
    Write-Host "  .\scripts.ps1 rebuild        - Rebuild sem cache"
    Write-Host ""
    Write-Host "Monitoramento:" -ForegroundColor Yellow
    Write-Host "  .\scripts.ps1 ps             - Status dos containers"
    Write-Host "  .\scripts.ps1 logs           - Ver todos os logs"
    Write-Host "  .\scripts.ps1 logs-api       - Ver logs da API"
    Write-Host "  .\scripts.ps1 logs-db        - Ver logs do PostgreSQL"
    Write-Host "  .\scripts.ps1 logs-redis     - Ver logs do Redis"
    Write-Host "  .\scripts.ps1 health         - Verificar health"
    Write-Host ""
    Write-Host "Acesso:" -ForegroundColor Yellow
    Write-Host "  .\scripts.ps1 shell-api      - Acessar shell da API"
    Write-Host "  .\scripts.ps1 shell-db       - Acessar PostgreSQL"
    Write-Host "  .\scripts.ps1 shell-redis    - Acessar Redis CLI"
    Write-Host ""
    Write-Host "Limpeza:" -ForegroundColor Yellow
    Write-Host "  .\scripts.ps1 clean          - Remover tudo"
    Write-Host ""
}

switch ($args[0]) {
    "build" {
        Write-Host "Building Docker images..." -ForegroundColor Green
        docker-compose build
    }
    "up" {
        Write-Host "Starting services (production mode)..." -ForegroundColor Green
        docker-compose up -d
        Write-Host "Services started! Check: http://localhost:3000" -ForegroundColor Cyan
    }
    "dev" {
        Write-Host "Starting services (development mode)..." -ForegroundColor Green
        docker-compose -f docker-compose.dev.yml up -d
        Write-Host "Dev services started! Check: http://localhost:3000" -ForegroundColor Cyan
    }
    "down" {
        Write-Host "Stopping services..." -ForegroundColor Yellow
        docker-compose down
    }
    "down-v" {
        Write-Host "Stopping services and removing volumes..." -ForegroundColor Red
        docker-compose down -v
    }
    "logs" {
        docker-compose logs -f
    }
    "logs-api" {
        docker-compose logs -f api
    }
    "logs-db" {
        docker-compose logs -f postgres
    }
    "logs-redis" {
        docker-compose logs -f redis
    }
    "restart" {
        Write-Host "Restarting services..." -ForegroundColor Yellow
        docker-compose restart
    }
    "ps" {
        docker-compose ps
    }
    "shell-api" {
        docker exec -it nodejs_api sh
    }
    "shell-db" {
        docker exec -it postgres_db psql -U $env:POSTGRES_USER -d $env:POSTGRES_DB
    }
    "shell-redis" {
        docker exec -it redis_cache redis-cli
    }
    "clean" {
        Write-Host "Cleaning up everything..." -ForegroundColor Red
        docker-compose down -v --rmi all
    }
    "rebuild" {
        Write-Host "Rebuilding without cache..." -ForegroundColor Yellow
        docker-compose build --no-cache
        docker-compose up -d
    }
    "prod" {
        Write-Host "Building and starting production..." -ForegroundColor Green
        docker-compose build
        docker-compose up -d
        Write-Host "Production started! Check: http://localhost:3000" -ForegroundColor Cyan
    }
    "health" {
        Write-Host "Checking API health..." -ForegroundColor Cyan
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:3000/health" -Method Get
            Write-Host "Status: $($response.status)" -ForegroundColor Green
            Write-Host "PostgreSQL: $($response.services.postgres)" -ForegroundColor Green
            Write-Host "Redis: $($response.services.redis)" -ForegroundColor Green
        }
        catch {
            Write-Host "API is not responding!" -ForegroundColor Red
        }
    }
    default {
        Show-Help
    }
}
