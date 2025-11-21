# Script PowerShell para popular banco via API
# Garante que senhas sejam criptografadas corretamente

$apiUrl = "http://localhost:8081/api/seed"

$seedData = @{
    users = @(
        @{
            name = "Joao Silva"
            email = "joao.silva@email.com"
            password = "senha123"
            fone = "11999991111"
            birthDate = "1985-03-15"
            isAdmin = $false
        },
        @{
            name = "Maria Santos"
            email = "maria.santos@email.com"
            password = "senha456"
            fone = "11999992222"
            birthDate = "1990-07-22"
            isAdmin = $false
        },
        @{
            name = "Pedro Oliveira"
            email = "pedro.oliveira@email.com"
            password = "senha789"
            fone = "11999993333"
            birthDate = "1988-11-10"
            isAdmin = $false
        },
        @{
            name = "Ana Costa"
            email = "ana.costa@email.com"
            password = "senha321"
            fone = "11999994444"
            birthDate = "1995-05-30"
            isAdmin = $false
        },
        @{
            name = "Carlos Souza"
            email = "carlos.souza@email.com"
            password = "admin123"
            fone = "11999995555"
            birthDate = "1980-12-01"
            isAdmin = $true
        }
    )
    events = @(
        @{
            creator_id = 1
            event_name = "Workshop de Java"
            is_EAD = $false
            address = "Sao Paulo - SP, Av. Paulista, 1000"
            event_date = "2025-12-15T14:00:00"
            lot_quantity = 100
            quantity = 100
            description = "Workshop hands-on de Java Spring Boot com praticas modernas"
        },
        @{
            creator_id = 1
            event_name = "Conferencia de DevOps"
            is_EAD = $false
            address = "Rio de Janeiro - RJ, Centro de Convencoes"
            event_date = "2026-01-20T09:00:00"
            lot_quantity = 200
            quantity = 200
            description = "Conferencia com os principais especialistas em DevOps do Brasil"
        },
        @{
            creator_id = 1
            event_name = "Hackathon 2025"
            is_EAD = $false
            address = "Belo Horizonte - MG, Campus Universitario"
            event_date = "2025-11-25T08:00:00"
            lot_quantity = 50
            quantity = 50
            description = "24 horas de desenvolvimento intensivo com premios"
        },
        @{
            creator_id = 1
            event_name = "Meetup de Spring Boot"
            is_EAD = $true
            address = "Online"
            event_date = "2025-12-05T19:00:00"
            lot_quantity = 500
            quantity = 500
            description = "Encontro virtual mensal da comunidade Spring Boot Brasil"
        },
        @{
            creator_id = 5
            event_name = "Curso de Docker"
            is_EAD = $false
            address = "Porto Alegre - RS, Tech Hub"
            event_date = "2025-12-10T10:00:00"
            lot_quantity = 30
            quantity = 30
            description = "Curso intensivo de containerizacao com Docker e Kubernetes"
        }
    )
    enrollments = @(
        @{ userId = 2; eventId = 1 },
        @{ userId = 2; eventId = 4 },
        @{ userId = 3; eventId = 1 },
        @{ userId = 3; eventId = 2 },
        @{ userId = 4; eventId = 3 },
        @{ userId = 4; eventId = 4 }
    )
}

$jsonData = $seedData | ConvertTo-Json -Depth 10

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "   POPULANDO BANCO VIA API" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Enviando dados para: $apiUrl" -ForegroundColor Yellow
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $jsonData -ContentType "application/json" -ErrorAction Stop
    
    Write-Host "SUCESSO!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Resumo:" -ForegroundColor Cyan
    Write-Host "   Usuarios criados: $($response.usersCreated)" -ForegroundColor White
    Write-Host "   Eventos criados: $($response.eventsCreated)" -ForegroundColor White
    Write-Host "   Inscricoes criadas: $($response.enrollmentsCreated)" -ForegroundColor White
    
    if ($response.warnings) {
        Write-Host ""
        Write-Host "Avisos:" -ForegroundColor Yellow
        foreach ($warning in $response.warnings) {
            Write-Host "   - $warning" -ForegroundColor Yellow
        }
    }
    
    if ($response.errors) {
        Write-Host ""
        Write-Host "Erros:" -ForegroundColor Red
        foreach ($error in $response.errors) {
            Write-Host "   - $error" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Banco populado! Senhas foram criptografadas." -ForegroundColor Green
    Write-Host "===================================================" -ForegroundColor Cyan
    
} catch {
    Write-Host "ERRO ao popular banco:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Certifique-se de que:" -ForegroundColor Yellow
    Write-Host "  1. O backend esta rodando (docker compose up -d)" -ForegroundColor Yellow
    Write-Host "  2. A porta 8081 esta acessivel" -ForegroundColor Yellow
    Write-Host "  3. O banco de dados esta operacional" -ForegroundColor Yellow
    exit 1
}
