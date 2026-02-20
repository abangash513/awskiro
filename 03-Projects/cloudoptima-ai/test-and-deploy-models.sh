#!/bin/bash
VM_HOST="cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com"
VM_USER="azureuser"
VM_PASS="zJsjfxP80cmn!WeU"

echo "=== Testing and Deploying Updated Models ==="
echo ""

# First, copy the test script
echo "1. Copying test script to VM..."
sshpass -p "$VM_PASS" scp -o StrictHostKeyChecking=no \
    test_models.py \
    $VM_USER@$VM_HOST:/opt/cloudoptima/

echo "✓ Test script copied"
echo ""

# Run the test on the VM
echo "2. Running model tests on VM..."
sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no $VM_USER@$VM_HOST << 'ENDSSH'
cd /opt/cloudoptima
docker-compose exec -T backend python test_models.py
ENDSSH

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Tests passed! Now deploying updated models..."
    echo ""
    
    # Copy the updated models
    echo "3. Copying updated models..."
    sshpass -p "$VM_PASS" scp -o StrictHostKeyChecking=no \
        app/models/*.py \
        $VM_USER@$VM_HOST:/opt/cloudoptima/app/models/
    
    echo "✓ Models copied"
    echo ""
    
    # Restart backend
    echo "4. Restarting backend with new models..."
    sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no $VM_USER@$VM_HOST << 'ENDSSH'
cd /opt/cloudoptima

# Stop services
docker-compose down

# Remove database volume to start fresh
docker volume rm cloudoptima_pgdata 2>/dev/null || true

# Start services
docker-compose up -d

echo ""
echo "Waiting for services to start..."
sleep 20

echo ""
echo "=== Service Status ==="
docker-compose ps

echo ""
echo "=== Testing Backend ==="
curl -s http://localhost:8000/health && echo "✅ Backend is healthy!" || echo "⚠️ Backend not responding yet"

echo ""
echo "=== Backend Logs (last 20 lines) ==="
docker-compose logs --tail=20 backend

ENDSSH
    
    echo ""
    echo "=== Deployment Complete! ==="
    
else
    echo ""
    echo "❌ Tests failed! Not deploying."
    exit 1
fi
