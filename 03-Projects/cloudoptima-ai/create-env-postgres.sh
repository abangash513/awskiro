#!/bin/bash
VM_HOST="cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com"
VM_USER="azureuser"
VM_PASS="zJsjfxP80cmn!WeU"

echo "Creating new .env file with PostgreSQL..."

sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no $VM_USER@$VM_HOST << 'ENDSSH'
cd /opt/cloudoptima

cat > .env << 'EOF'
# CloudOptima AI - Environment Variables

# Azure Authentication
AZURE_TENANT_ID=d2449d27-d175-4648-90c3-04288acd1837
AZURE_CLIENT_ID=b3aa0768-ba45-4fb8-bae9-e5af46a60d35
AZURE_CLIENT_SECRET=ZmA8Q~PjdbSYKOs7rGjgzSwOKwuEfu0DBH_Gnbb-
AZURE_SUBSCRIPTION_ID=3a6cc9a1-adf7-49fe-a02f-f6db16ced2a1

# Database (PostgreSQL)
DATABASE_URL=postgresql+asyncpg://cloudoptima:cloudoptima@db:5432/cloudoptima
POSTGRES_USER=cloudoptima
POSTGRES_PASSWORD=cloudoptima
POSTGRES_DB=cloudoptima

# Redis
REDIS_URL=redis://redis:6379/0

# API Settings
API_HOST=0.0.0.0
API_PORT=8000
API_DEBUG=false

# Authentication
SECRET_KEY=supersecretkey123456789
API_KEY=co_testapikey123
AUTH_ENABLED=false
CORS_ORIGINS=["http://localhost:3000","http://cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com:3000","http://cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com:8000"]

# Cost Analysis Settings
COST_LOOKBACK_DAYS=30
BUDGET_ALERT_THRESHOLD=0.8

# Logging
LOG_LEVEL=INFO
EOF

echo "✅ .env file created"
cat .env | grep DATABASE_URL

echo ""
echo "Restarting services..."
docker-compose down
docker-compose up -d

echo ""
echo "Waiting for services..."
sleep 20

echo ""
echo "=== Service Status ==="
docker-compose ps

echo ""
echo "=== Testing Backend ==="
curl -s http://localhost:8000/health && echo "✅ Backend is healthy!" || echo "❌ Backend not responding"

ENDSSH

echo ""
echo "Done!"
