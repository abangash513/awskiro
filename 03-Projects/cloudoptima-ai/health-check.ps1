# CloudOptima AI - Health Check Script (Windows)
# Run this to verify all services are working correctly

Write-Host "=== CloudOptima AI - Health Check ===" -ForegroundColor Cyan
Write-Host ""

# Configuration
$BackendURL = "http://localhost:8000"
$FrontendURL = "http://localhost:3000"

if (-not (Test-Path .env)) {
    $BackendURL = Read-Host "Enter backend URL (e.g., http://your-domain:8000)"
    $FrontendURL = Read-Host "Enter frontend URL (e.g., http://your-domain:3000)"
}

Write-Host "Testing services..." -ForegroundColor Yellow
Write-Host ""

# Check Docker services
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "📦 Docker Services:" -ForegroundColor Cyan
    try {
        docker compose ps
    } catch {
        Write-Host "  ⚠️  Not running via Docker Compose" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Check backend health
Write-Host "🔧 Backend Health:" -ForegroundColor Cyan
try {
    $BackendHealth = Invoke-WebRequest -Uri "$BackendURL/health" -UseBasicParsing -TimeoutSec 5
    if ($BackendHealth.StatusCode -eq 200) {
        Write-Host "  ✅ Backend is healthy ($BackendURL/health)" -ForegroundColor Green
    }
} catch {
    Write-Host "  ❌ Backend is not responding" -ForegroundColor Red
}

# Check API docs
try {
    $ApiDocs = Invoke-WebRequest -Uri "$BackendURL/docs" -UseBasicParsing -TimeoutSec 5
    if ($ApiDocs.StatusCode -eq 200) {
        Write-Host "  ✅ API docs accessible ($BackendURL/docs)" -ForegroundColor Green
    }
} catch {
    Write-Host "  ❌ API docs not accessible" -ForegroundColor Red
}

Write-Host ""

# Check frontend
Write-Host "🌐 Frontend:" -ForegroundColor Cyan
try {
    $FrontendHealth = Invoke-WebRequest -Uri $FrontendURL -UseBasicParsing -TimeoutSec 5
    if ($FrontendHealth.StatusCode -eq 200) {
        Write-Host "  ✅ Frontend is accessible ($FrontendURL)" -ForegroundColor Green
    }
} catch {
    Write-Host "  ❌ Frontend is not accessible" -ForegroundColor Red
}

Write-Host ""

# Check database (if running locally)
if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        $DbStatus = docker compose ps db --format json 2>$null | ConvertFrom-Json
        if ($DbStatus) {
            Write-Host "🗄️  Database:" -ForegroundColor Cyan
            
            $DbCheck = docker compose exec -T db pg_isready -U cloudoptima 2>&1
            if ($DbCheck -match "accepting connections") {
                Write-Host "  ✅ PostgreSQL is accepting connections" -ForegroundColor Green
                
                # Check TimescaleDB extension
                $Timescale = docker compose exec -T db psql -U cloudoptima -d cloudoptima -tAc "SELECT extname FROM pg_extension WHERE extname='timescaledb';" 2>$null
                if ($Timescale -match "timescaledb") {
                    Write-Host "  ✅ TimescaleDB extension is enabled" -ForegroundColor Green
                } else {
                    Write-Host "  ⚠️  TimescaleDB extension not found" -ForegroundColor Yellow
                }
                
                # Check hypertable
                $Hypertable = docker compose exec -T db psql -U cloudoptima -d cloudoptima -tAc "SELECT hypertable_name FROM timescaledb_information.hypertables WHERE hypertable_name='cost_data';" 2>$null
                if ($Hypertable -match "cost_data") {
                    Write-Host "  ✅ cost_data hypertable is configured" -ForegroundColor Green
                } else {
                    Write-Host "  ⚠️  cost_data hypertable not found" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  ❌ PostgreSQL is not responding" -ForegroundColor Red
            }
            Write-Host ""
        }
    } catch {
        # Database not running locally
    }
}

# Check Redis (if running locally)
if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        $RedisStatus = docker compose ps redis --format json 2>$null | ConvertFrom-Json
        if ($RedisStatus) {
            Write-Host "📮 Redis:" -ForegroundColor Cyan
            
            $RedisCheck = docker compose exec -T redis redis-cli ping 2>&1
            if ($RedisCheck -match "PONG") {
                Write-Host "  ✅ Redis is responding" -ForegroundColor Green
            } else {
                Write-Host "  ❌ Redis is not responding" -ForegroundColor Red
            }
            Write-Host ""
        }
    } catch {
        # Redis not running locally
    }
}

# Check Celery worker (if running locally)
if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        $WorkerStatus = docker compose ps celery-worker --format json 2>$null | ConvertFrom-Json
        if ($WorkerStatus) {
            Write-Host "⚙️  Celery Worker:" -ForegroundColor Cyan
            
            if ($WorkerStatus.State -eq "running") {
                Write-Host "  ✅ Celery worker is running" -ForegroundColor Green
            } else {
                Write-Host "  ❌ Celery worker is not running (status: $($WorkerStatus.State))" -ForegroundColor Red
            }
            Write-Host ""
        }
    } catch {
        # Worker not running locally
    }
}

# Check Celery beat (if running locally)
if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        $BeatStatus = docker compose ps celery-beat --format json 2>$null | ConvertFrom-Json
        if ($BeatStatus) {
            Write-Host "⏰ Celery Beat:" -ForegroundColor Cyan
            
            if ($BeatStatus.State -eq "running") {
                Write-Host "  ✅ Celery beat is running" -ForegroundColor Green
            } else {
                Write-Host "  ❌ Celery beat is not running (status: $($BeatStatus.State))" -ForegroundColor Red
            }
            Write-Host ""
        }
    } catch {
        # Beat not running locally
    }
}

# Summary
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host ""

$Issues = 0

try {
    $BackendTest = Invoke-WebRequest -Uri "$BackendURL/health" -UseBasicParsing -TimeoutSec 5
    if ($BackendTest.StatusCode -ne 200) {
        Write-Host "❌ Backend is not healthy" -ForegroundColor Red
        $Issues++
    }
} catch {
    Write-Host "❌ Backend is not healthy" -ForegroundColor Red
    $Issues++
}

try {
    $FrontendTest = Invoke-WebRequest -Uri $FrontendURL -UseBasicParsing -TimeoutSec 5
    if ($FrontendTest.StatusCode -ne 200) {
        Write-Host "❌ Frontend is not accessible" -ForegroundColor Red
        $Issues++
    }
} catch {
    Write-Host "❌ Frontend is not accessible" -ForegroundColor Red
    $Issues++
}

if ($Issues -eq 0) {
    Write-Host "✅ All critical services are healthy!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access URLs:" -ForegroundColor Cyan
    Write-Host "  Frontend:  $FrontendURL"
    Write-Host "  Backend:   $BackendURL"
    Write-Host "  API Docs:  $BackendURL/docs"
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Register a user account"
    Write-Host "2. Connect your Azure subscription"
    Write-Host "3. Trigger cost data ingestion"
    exit 0
} else {
    Write-Host "⚠️  Found $Issues issue(s)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Cyan
    Write-Host "1. Check logs: docker compose logs -f"
    Write-Host "2. Verify .env configuration"
    Write-Host "3. Restart services: docker compose restart"
    Write-Host "4. Check AWS-DEPLOYMENT-GUIDE.md for help"
    exit 1
}
