#!/bin/bash
# CloudOptima AI - Deploy via WSL to Azure VM

set -e

# VM Details
VM_HOST="cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com"
VM_USER="azureuser"
VM_PASS="zJsjfxP80cmn!WeU"
VM_PATH="/opt/cloudoptima"

echo "=== CloudOptima AI - WSL Deployment ==="
echo ""

# Check if sshpass is installed
if ! command -v sshpass &> /dev/null; then
    echo "⚠️  sshpass is not installed"
    echo "Please run: sudo apt-get update && sudo apt-get install -y sshpass rsync"
    echo "Then run this script again"
    exit 1
fi

# Check if rsync is installed
if ! command -v rsync &> /dev/null; then
    echo "⚠️  rsync is not installed"
    echo "Please run: sudo apt-get update && sudo apt-get install -y rsync"
    echo "Then run this script again"
    exit 1
fi

echo "✅ Prerequisites installed"
echo ""

# Create .env file
echo "Creating .env file..."
cat > .env << 'EOF'
# CloudOptima AI - Environment Variables

# Azure Authentication
AZURE_TENANT_ID=d2449d27-d175-4648-90c3-04288acd1837
AZURE_CLIENT_ID=b3aa0768-ba45-4fb8-bae9-e5af46a60d35
AZURE_CLIENT_SECRET=ZmA8Q~PjdbSYKOs7rGjgzSwOKwuEfu0DBH_Gnbb-
AZURE_SUBSCRIPTION_ID=3a6cc9a1-adf7-49fe-a02f-f6db16ced2a1

# Database
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
SECRET_KEY=$(openssl rand -hex 32)
API_KEY=co_$(openssl rand -hex 16)
AUTH_ENABLED=false
CORS_ORIGINS=["http://localhost:3000","http://cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com:3000","http://cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com:8000"]

# Cost Analysis Settings
COST_LOOKBACK_DAYS=30
BUDGET_ALERT_THRESHOLD=0.8

# Logging
LOG_LEVEL=INFO
EOF

echo "✅ .env file created"
echo ""

# Test SSH connection
echo "Testing SSH connection..."
sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 $VM_USER@$VM_HOST "echo 'SSH connection successful'" || {
    echo "❌ SSH connection failed"
    exit 1
}

echo "✅ SSH connection successful"
echo ""

# Create directory on VM
echo "Creating directory on VM..."
sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no $VM_USER@$VM_HOST "sudo mkdir -p $VM_PATH && sudo chown $VM_USER:$VM_USER $VM_PATH"

echo "✅ Directory created"
echo ""

# Sync files to VM
echo "Syncing files to VM (this may take 2-3 minutes)..."
sshpass -p "$VM_PASS" rsync -avz --progress \
    --exclude='node_modules' \
    --exclude='__pycache__' \
    --exclude='.git' \
    --exclude='*.pyc' \
    --exclude='terraform' \
    --exclude='infrastructure' \
    --exclude='*.md' \
    --exclude='frontend/node_modules' \
    --exclude='backend/__pycache__' \
    -e "ssh -o StrictHostKeyChecking=no" \
    ./ $VM_USER@$VM_HOST:$VM_PATH/

echo ""
echo "✅ Files synced to VM"
echo ""

# Deploy on VM
echo "Deploying application on VM..."
sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no $VM_USER@$VM_HOST << 'ENDSSH'
cd /opt/cloudoptima

echo "Stopping any existing containers..."
docker-compose down 2>/dev/null || true

echo "Starting services..."
docker-compose up -d

echo "Waiting for services to start..."
sleep 15

echo ""
echo "=== Service Status ==="
docker-compose ps

echo ""
echo "=== Health Check ==="
curl -f http://localhost:8000/health 2>/dev/null && echo "✅ Backend is healthy" || echo "⚠️  Backend not ready yet (may need more time)"

echo ""
echo "=== Deployment Complete ==="
ENDSSH

echo ""
echo "=== 🎉 Deployment Successful! ==="
echo ""
echo "Access URLs:"
echo "  Frontend:  http://$VM_HOST:3000"
echo "  Backend:   http://$VM_HOST:8000"
echo "  API Docs:  http://$VM_HOST:8000/docs"
echo ""
echo "View logs:"
echo "  ssh $VM_USER@$VM_HOST 'cd /opt/cloudoptima && docker-compose logs -f'"
echo ""
