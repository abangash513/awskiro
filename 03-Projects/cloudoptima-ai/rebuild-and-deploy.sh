#!/bin/bash
VM_HOST="cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com"
VM_USER="azureuser"
VM_PASS="zJsjfxP80cmn!WeU"

echo "=== Rebuilding Backend with Fixed Models ==="
echo ""

sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no $VM_USER@$VM_HOST << 'ENDSSH'
cd /opt/cloudoptima

echo "1. Stopping all services..."
docker-compose down -v

echo ""
echo "2. Removing Python cache files..."
find app -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
find app -type f -name "*.pyc" -delete 2>/dev/null || true

echo ""
echo "3. Rebuilding backend image..."
docker-compose build --no-cache backend

echo ""
echo "4. Starting all services..."
docker-compose up -d

echo ""
echo "5. Waiting for services to start..."
sleep 30

echo ""
echo "=== Service Status ==="
docker-compose ps

echo ""
echo "=== Testing Backend Health ==="
for i in {1..10}; do
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo "✅ Backend is healthy!"
        echo ""
        curl -s http://localhost:8000/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8000/health
        echo ""
        break
    else
        echo "Attempt $i/10: Backend not ready yet, waiting 5 seconds..."
        sleep 5
    fi
done

echo ""
echo "=== Backend Logs (last 40 lines) ==="
docker-compose logs --tail=40 backend

echo ""
echo "=== All Services Logs (last 10 lines each) ==="
docker-compose logs --tail=10

ENDSSH

echo ""
echo "=== Deployment Complete! ==="
echo ""
echo "Access your application:"
echo "  Frontend: http://cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com:3000"
echo "  Backend:  http://cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com:8000"
echo "  API Docs: http://cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com:8000/docs"
echo ""
