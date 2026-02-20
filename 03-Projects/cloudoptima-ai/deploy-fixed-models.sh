#!/bin/bash
VM_HOST="cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com"
VM_USER="azureuser"
VM_PASS="zJsjfxP80cmn!WeU"

echo "=== Deploying Fixed Models to VM ==="
echo ""

# Copy the updated models
echo "1. Copying updated model files..."
sshpass -p "$VM_PASS" scp -o StrictHostKeyChecking=no \
    /mnt/c/AWSKiro/03-Projects/cloudoptima-ai/app/models/__init__.py \
    /mnt/c/AWSKiro/03-Projects/cloudoptima-ai/app/models/budget.py \
    /mnt/c/AWSKiro/03-Projects/cloudoptima-ai/app/models/cost.py \
    /mnt/c/AWSKiro/03-Projects/cloudoptima-ai/app/models/recommendation.py \
    $VM_USER@$VM_HOST:/opt/cloudoptima/app/models/

echo "✓ Models copied"
echo ""

# Restart with fresh database
echo "2. Restarting services with fresh database..."
sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no $VM_USER@$VM_HOST << 'ENDSSH'
cd /opt/cloudoptima

echo "Stopping services..."
docker-compose down

echo "Removing old database volume..."
docker volume rm cloudoptima_pgdata 2>/dev/null || true

echo "Starting services..."
docker-compose up -d

echo ""
echo "Waiting for services to start..."
sleep 25

echo ""
echo "=== Service Status ==="
docker-compose ps

echo ""
echo "=== Testing Backend Health ==="
for i in {1..5}; do
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo "✅ Backend is healthy!"
        curl -s http://localhost:8000/health
        break
    else
        echo "Attempt $i/5: Backend not ready yet, waiting..."
        sleep 5
    fi
done

echo ""
echo "=== Backend Logs (last 30 lines) ==="
docker-compose logs --tail=30 backend

echo ""
echo "=== Testing API Docs ==="
curl -s http://localhost:8000/docs | head -10

ENDSSH

echo ""
echo "=== Deployment Complete! ==="
echo ""
echo "Test the application:"
echo "  Frontend: http://cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com:3000"
echo "  Backend:  http://cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com:8000"
echo "  API Docs: http://cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com:8000/docs"
echo ""
