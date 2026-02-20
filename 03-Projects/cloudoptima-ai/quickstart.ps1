# CloudOptima AI - Quick Start Script (Windows)
# Run this locally before deploying to AWS

Write-Host "=== CloudOptima AI - Quick Start ===" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

$dockerInstalled = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerInstalled) {
    Write-Host "❌ Docker is not installed. Please install Docker Desktop first." -ForegroundColor Red
    exit 1
}

$composeInstalled = docker compose version 2>$null
if (-not $composeInstalled) {
    Write-Host "❌ Docker Compose is not available. Please update Docker Desktop." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Docker and Docker Compose are installed" -ForegroundColor Green
Write-Host ""

# Check if .env exists
if (-not (Test-Path .env)) {
    Write-Host "Creating .env file from template..." -ForegroundColor Yellow
    Copy-Item .env.example .env
    Write-Host "⚠️  Please edit .env file with your Azure credentials before continuing." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter after editing .env file"
}

# Generate secure secrets
Write-Host "Generating secure secrets..." -ForegroundColor Yellow

function Get-RandomHex {
    param([int]$Length)
    $bytes = New-Object byte[] $Length
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return ($bytes | ForEach-Object { $_.ToString("x2") }) -join ''
}

$secretKey = Get-RandomHex -Length 32
$dbPassword = Get-RandomHex -Length 16

# Update .env with generated secrets
$envContent = Get-Content .env -Raw

if ($envContent -match "SECRET_KEY=change-me") {
    $envContent = $envContent -replace "SECRET_KEY=change-me.*", "SECRET_KEY=$secretKey"
    Write-Host "✅ Generated SECRET_KEY" -ForegroundColor Green
}

if ($envContent -match "POSTGRES_PASSWORD=cloudoptima") {
    $envContent = $envContent -replace "POSTGRES_PASSWORD=cloudoptima", "POSTGRES_PASSWORD=$dbPassword"
    $envContent = $envContent -replace ":cloudoptima@", ":$dbPassword@"
    Write-Host "✅ Generated database password" -ForegroundColor Green
}

Set-Content .env -Value $envContent

Write-Host ""
Write-Host "Starting services..." -ForegroundColor Yellow
docker compose up -d

Write-Host ""
Write-Host "Waiting for services to be healthy..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Check service health
Write-Host ""
Write-Host "Checking service status..." -ForegroundColor Yellow
docker compose ps

Write-Host ""
Write-Host "=== CloudOptima AI is running! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Cyan
Write-Host "  🌐 Frontend:  http://localhost:3000"
Write-Host "  🔧 Backend:   http://localhost:8000"
Write-Host "  📚 API Docs:  http://localhost:8000/docs"
Write-Host ""
Write-Host "Default credentials (create via API):" -ForegroundColor Cyan
Write-Host "  Email: admin@example.com"
Write-Host "  Password: (set during registration)"
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Cyan
Write-Host "  View logs:        docker compose logs -f"
Write-Host "  Stop services:    docker compose down"
Write-Host "  Restart:          docker compose restart"
Write-Host "  Clean up:         docker compose down -v"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Open http://localhost:3000 in your browser"
Write-Host "2. Register a new account"
Write-Host "3. Connect your Azure subscription"
Write-Host "4. Wait for cost data ingestion (runs daily or trigger manually)"
Write-Host ""
Write-Host "Ready to deploy to AWS? See AWS-DEPLOYMENT-GUIDE.md" -ForegroundColor Cyan
Write-Host ""
