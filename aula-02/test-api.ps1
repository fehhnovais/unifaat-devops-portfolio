# Script de teste da API
# Execute: .\test-api.ps1

$baseUrl = "http://localhost:3000"

Write-Host "=== Testando API Node.js + PostgreSQL + Redis ===" -ForegroundColor Cyan
Write-Host ""

# Função auxiliar para testes
function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Method = "GET",
        [object]$Body = $null
    )
    
    Write-Host "Testing: $Name" -ForegroundColor Yellow
    Write-Host "URL: $Url"
    
    try {
        if ($Method -eq "GET") {
            $response = Invoke-RestMethod -Uri $Url -Method $Method
        } else {
            $jsonBody = $Body | ConvertTo-Json
            $response = Invoke-RestMethod -Uri $Url -Method $Method -Body $jsonBody -ContentType "application/json"
        }
        
        Write-Host "✅ Success!" -ForegroundColor Green
        Write-Host "Response:" -ForegroundColor Gray
        $response | ConvertTo-Json -Depth 3
        Write-Host ""
        return $true
    }
    catch {
        Write-Host "❌ Failed!" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        return $false
    }
}

# Aguardar API iniciar
Write-Host "Aguardando API iniciar..." -ForegroundColor Gray
Start-Sleep -Seconds 2

# 1. Testar Health Check
Test-Endpoint -Name "Health Check" -Url "$baseUrl/health"

# 2. Testar Endpoint Raiz
Test-Endpoint -Name "Root Endpoint" -Url "$baseUrl/"

# 3. Testar Conexão PostgreSQL
Test-Endpoint -Name "PostgreSQL Connection" -Url "$baseUrl/users"

# 4. Testar Redis - SET
Write-Host "Testing: Redis SET (Cache)" -ForegroundColor Yellow
$cacheData = @{
    value = @{
        name = "João Silva"
        email = "joao@example.com"
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    ttl = 60
}
Test-Endpoint -Name "Redis SET" -Url "$baseUrl/cache/usuario-teste" -Method "POST" -Body $cacheData

# 5. Testar Redis - GET
Start-Sleep -Seconds 1
Test-Endpoint -Name "Redis GET (Cache)" -Url "$baseUrl/cache/usuario-teste"

# 6. Teste de múltiplas chaves no cache
Write-Host "=== Teste de Performance - Cache ===" -ForegroundColor Cyan
for ($i = 1; $i -le 5; $i++) {
    $data = @{
        value = "Valor $i - $(Get-Date)"
        ttl = 120
    }
    Invoke-RestMethod -Uri "$baseUrl/cache/teste-$i" -Method POST -Body ($data | ConvertTo-Json) -ContentType "application/json" | Out-Null
    Write-Host "✅ Cache key 'teste-$i' criada" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Verificando chaves criadas ===" -ForegroundColor Cyan
for ($i = 1; $i -le 5; $i++) {
    $result = Invoke-RestMethod -Uri "$baseUrl/cache/teste-$i"
    Write-Host "Key: teste-$i | Value: $($result.value)" -ForegroundColor Gray
}

# Resumo
Write-Host ""
Write-Host "=== Teste Concluído ===" -ForegroundColor Cyan
Write-Host "API: $baseUrl" -ForegroundColor Gray
Write-Host "Health: $baseUrl/health" -ForegroundColor Gray
Write-Host ""
Write-Host "Para ver os logs:" -ForegroundColor Yellow
Write-Host "  docker-compose logs -f api" -ForegroundColor Gray
Write-Host ""
Write-Host "Para acessar os serviços:" -ForegroundColor Yellow
Write-Host "  .\scripts.ps1 shell-api    # Node.js" -ForegroundColor Gray
Write-Host "  .\scripts.ps1 shell-db     # PostgreSQL" -ForegroundColor Gray
Write-Host "  .\scripts.ps1 shell-redis  # Redis" -ForegroundColor Gray
