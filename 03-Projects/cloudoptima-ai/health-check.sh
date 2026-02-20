#!/bin/bash
# CloudOptima AI - Health Check Script
# Run this to verify all services are working correctly

set -e

echo "=== CloudOptima AI - Health Check ==="
echo ""

# Detect if running locally or on server
if [ -f .env ]; then
    source .env
    BACKEND_URL="http://localhost:8000"
    FRONTEND_URL="http://localhost:3000"
else
    read -p "Enter backend URL (e.g., http://your-domain:8000): " BACKEND_URL
    read -p "Enter frontend URL (e.g., http://your-domain:3000): " FRONTEND_URL
fi

echo "Testing services..."
echo ""

# Check Docker services
if command -v docker &> /dev/null; then
    echo "📦 Docker Services:"
    docker compose ps 2>/dev/null || echo "  ⚠️  Not running via Docker Compose"
    echo ""
fi

# Check backend health
echo "🔧 Backend Health:"
BACKEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" $BACKEND_URL/health || echo "000")
if [ "$BACKEND_HEALTH" = "200" ]; then
    echo "  ✅ Backend is healthy ($BACKEND_URL/health)"
else
    echo "  ❌ Backend is not responding (HTTP $BACKEND_HEALTH)"
fi

# Check API docs
API_DOCS=$(curl -s -o /dev/null -w "%{http_code}" $BACKEND_URL/docs || echo "000")
if [ "$API_DOCS" = "200" ]; then
    echo "  ✅ API docs accessible ($BACKEND_URL/docs)"
else
    echo "  ❌ API docs not accessible (HTTP $API_DOCS)"
fi

echo ""

# Check frontend
echo "🌐 Frontend:"
FRONTEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" $FRONTEND_URL || echo "000")
if [ "$FRONTEND_HEALTH" = "200" ]; then
    echo "  ✅ Frontend is accessible ($FRONTEND_URL)"
else
    echo "  ❌ Frontend is not accessible (HTTP $FRONTEND_HEALTH)"
fi

echo ""

# Check database (if running locally)
if command -v docker &> /dev/null && docker compose ps db &>/dev/null; then
    echo "🗄️  Database:"
    DB_STATUS=$(docker compose exec -T db pg_isready -U cloudoptima 2>&1 || echo "error")
    if [[ "$DB_STATUS" == *"accepting connections"* ]]; then
        echo "  ✅ PostgreSQL is accepting connections"
        
        # Check TimescaleDB extension
        TIMESCALE=$(docker compose exec -T db psql -U cloudoptima -d cloudoptima -tAc "SELECT extname FROM pg_extension WHERE extname='timescaledb';" 2>/dev/null || echo "")
        if [ "$TIMESCALE" = "timescaledb" ]; then
            echo "  ✅ TimescaleDB extension is enabled"
        else
            echo "  ⚠️  TimescaleDB extension not found"
        fi
        
        # Check hypertable
        HYPERTABLE=$(docker compose exec -T db psql -U cloudoptima -d cloudoptima -tAc "SELECT hypertable_name FROM timescaledb_information.hypertables WHERE hypertable_name='cost_data';" 2>/dev/null || echo "")
        if [ "$HYPERTABLE" = "cost_data" ]; then
            echo "  ✅ cost_data hypertable is configured"
        else
            echo "  ⚠️  cost_data hypertable not found"
        fi
    else
        echo "  ❌ PostgreSQL is not responding"
    fi
    echo ""
fi

# Check Redis (if running locally)
if command -v docker &> /dev/null && docker compose ps redis &>/dev/null; then
    echo "📮 Redis:"
    REDIS_STATUS=$(docker compose exec -T redis redis-cli ping 2>&1 || echo "error")
    if [ "$REDIS_STATUS" = "PONG" ]; then
        echo "  ✅ Redis is responding"
    else
        echo "  ❌ Redis is not responding"
    fi
    echo ""
fi

# Check Celery worker (if running locally)
if command -v docker &> /dev/null && docker compose ps celery-worker &>/dev/null; then
    echo "⚙️  Celery Worker:"
    WORKER_STATUS=$(docker compose ps celery-worker --format json 2>/dev/null | grep -o '"State":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    if [ "$WORKER_STATUS" = "running" ]; then
        echo "  ✅ Celery worker is running"
    else
        echo "  ❌ Celery worker is not running (status: $WORKER_STATUS)"
    fi
    echo ""
fi

# Check Celery beat (if running locally)
if command -v docker &> /dev/null && docker compose ps celery-beat &>/dev/null; then
    echo "⏰ Celery Beat:"
    BEAT_STATUS=$(docker compose ps celery-beat --format json 2>/dev/null | grep -o '"State":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    if [ "$BEAT_STATUS" = "running" ]; then
        echo "  ✅ Celery beat is running"
    else
        echo "  ❌ Celery beat is not running (status: $BEAT_STATUS)"
    fi
    echo ""
fi

# Summary
echo "=== Summary ==="
echo ""

ISSUES=0

if [ "$BACKEND_HEALTH" != "200" ]; then
    echo "❌ Backend is not healthy"
    ((ISSUES++))
fi

if [ "$FRONTEND_HEALTH" != "200" ]; then
    echo "❌ Frontend is not accessible"
    ((ISSUES++))
fi

if [ $ISSUES -eq 0 ]; then
    echo "✅ All critical services are healthy!"
    echo ""
    echo "Access URLs:"
    echo "  Frontend:  $FRONTEND_URL"
    echo "  Backend:   $BACKEND_URL"
    echo "  API Docs:  $BACKEND_URL/docs"
    echo ""
    echo "Next steps:"
    echo "1. Register a user account"
    echo "2. Connect your Azure subscription"
    echo "3. Trigger cost data ingestion"
    exit 0
else
    echo "⚠️  Found $ISSUES issue(s)"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check logs: docker compose logs -f"
    echo "2. Verify .env configuration"
    echo "3. Restart services: docker compose restart"
    echo "4. Check AWS-DEPLOYMENT-GUIDE.md for help"
    exit 1
fi
