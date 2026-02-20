#!/bin/bash
# Complete deployment script: test, fix, package, and deploy

set -e

VM_IP="52.179.209.239"
VM_USER="azureuser"
VM_PASS="zJsjfxP80cmn!WeU"

echo "=========================================="
echo "CloudOptima AI - Complete Deployment"
echo "=========================================="

# Step 1: Test models locally
echo ""
echo "Step 1: Testing models locally..."
echo "----------------------------------------"
if python test_models_standalone.py; then
    echo "✓ Model tests passed"
else
    echo "✗ Model tests failed. Aborting deployment."
    exit 1
fi

# Step 2: Fix backend imports
echo ""
echo "Step 2: Fixing backend imports..."
echo "----------------------------------------"
bash fix-backend-models.sh

# Step 3: Test again after fixes
echo ""
echo "Step 3: Re-testing after fixes..."
echo "----------------------------------------"
cd backend
if python -c "from app.models import *; print('✓ Backend models import successfully')"; then
    echo "✓ Backend models validated"
else
    echo "✗ Backend models still have issues"
    cd ..
    exit 1
fi
cd ..

# Step 4: Create deployment package
echo ""
echo "Step 4: Creating deployment package..."
echo "----------------------------------------"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PACKAGE_NAME="cloudoptima-fixed-${TIMESTAMP}.tar.gz"

tar -czf "$PACKAGE_NAME" \
    backend/ \
    docker/ \
    docker-compose.yml \
    .env \
    --exclude='backend/__pycache__' \
    --exclude='backend/**/__pycache__' \
    --exclude='backend/**/*.pyc'

echo "✓ Created package: $PACKAGE_NAME"

# Step 5: Copy to VM
echo ""
echo "Step 5: Copying to VM..."
echo "----------------------------------------"
sshpass -p "$VM_PASS" scp -o StrictHostKeyChecking=no "$PACKAGE_NAME" ${VM_USER}@${VM_IP}:/tmp/

echo "✓ Package copied to VM"

# Step 6: Deploy on VM
echo ""
echo "Step 6: Deploying on VM..."
echo "----------------------------------------"
sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} << 'ENDSSH'
set -e

echo "Extracting package..."
cd /opt/cloudoptima
tar -xzf /tmp/cloudoptima-fixed-*.tar.gz

echo "Stopping containers..."
docker-compose down

echo "Removing old backend image..."
docker rmi cloudoptima-backend:latest || true

echo "Rebuilding backend..."
docker-compose build --no-cache backend

echo "Starting services..."
docker-compose up -d

echo "Waiting for services to start..."
sleep 10

echo "Checking backend status..."
docker-compose ps backend
docker-compose logs --tail=50 backend

echo ""
echo "✓ Deployment complete!"
ENDSSH

# Step 7: Verify deployment
echo ""
echo "Step 7: Verifying deployment..."
echo "----------------------------------------"
sleep 5

if curl -s http://${VM_IP}:8000/health | grep -q "healthy"; then
    echo "✓ Backend is healthy!"
else
    echo "⚠ Backend health check failed. Checking logs..."
    sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} \
        "docker-compose -f /opt/cloudoptima/docker-compose.yml logs --tail=100 backend"
fi

echo ""
echo "=========================================="
echo "Deployment Summary"
echo "=========================================="
echo "Package: $PACKAGE_NAME"
echo "VM: ${VM_IP}"
echo "Frontend: http://${VM_IP}:3000"
echo "Backend: http://${VM_IP}:8000"
echo "Backend Health: http://${VM_IP}:8000/health"
echo "Backend Docs: http://${VM_IP}:8000/docs"
echo ""
echo "To check logs:"
echo "  ssh ${VM_USER}@${VM_IP}"
echo "  cd /opt/cloudoptima"
echo "  docker-compose logs -f backend"
echo "=========================================="
