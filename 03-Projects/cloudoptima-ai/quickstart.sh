#!/bin/bash
# CloudOptima AI - Quick Start Script
# Run this locally before deploying to AWS

set -e

echo "=== CloudOptima AI - Quick Start ==="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo "⚠️  Please edit .env file with your Azure credentials before continuing."
    echo ""
    read -p "Press Enter after editing .env file..."
fi

# Generate secure secrets
echo "Generating secure secrets..."
SECRET_KEY=$(openssl rand -hex 32)
DB_PASSWORD=$(openssl rand -hex 16)

# Update .env with generated secrets
if grep -q "SECRET_KEY=change-me" .env; then
    sed -i.bak "s/SECRET_KEY=change-me.*/SECRET_KEY=$SECRET_KEY/" .env
    echo "✅ Generated SECRET_KEY"
fi

if grep -q "POSTGRES_PASSWORD=cloudoptima" .env; then
    sed -i.bak "s/POSTGRES_PASSWORD=cloudoptima/POSTGRES_PASSWORD=$DB_PASSWORD/" .env
    sed -i.bak "s/:cloudoptima@/:$DB_PASSWORD@/" .env
    echo "✅ Generated database password"
fi

rm -f .env.bak

echo ""
echo "Starting services..."
docker compose up -d

echo ""
echo "Waiting for services to be healthy..."
sleep 10

# Check service health
echo ""
echo "Checking service status..."
docker compose ps

echo ""
echo "=== CloudOptima AI is running! ==="
echo ""
echo "Access URLs:"
echo "  🌐 Frontend:  http://localhost:3000"
echo "  🔧 Backend:   http://localhost:8000"
echo "  📚 API Docs:  http://localhost:8000/docs"
echo ""
echo "Default credentials (create via API):"
echo "  Email: admin@example.com"
echo "  Password: (set during registration)"
echo ""
echo "Useful commands:"
echo "  View logs:        docker compose logs -f"
echo "  Stop services:    docker compose down"
echo "  Restart:          docker compose restart"
echo "  Clean up:         docker compose down -v"
echo ""
echo "Next steps:"
echo "1. Open http://localhost:3000 in your browser"
echo "2. Register a new account"
echo "3. Connect your Azure subscription"
echo "4. Wait for cost data ingestion (runs daily or trigger manually)"
echo ""
echo "Ready to deploy to AWS? See AWS-DEPLOYMENT-GUIDE.md"
echo ""
