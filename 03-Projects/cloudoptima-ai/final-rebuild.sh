#!/bin/bash
VM_HOST="cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com"
VM_USER="azureuser"
VM_PASS="zJsjfxP80cmn!WeU"

echo "=== Final Rebuild with Correct Models ==="

sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no $VM_USER@$VM_HOST << 'ENDSSH'
cd /opt/cloudoptima

echo "1. Stopping services..."
docker-compose down -v

echo ""
echo "2. Rebuilding backend with updated models..."
docker-compose build --no-cache backend

echo ""
echo "3. Starting all services..."
docker-compose up -d

echo ""
echo "4. Waiting 30 seconds for startup..."
sleep 30

echo ""
echo "=== Service Status ==="
docker-compose ps

echo ""
echo "=== Testing Backend ==="
for i in {1..5}; do
    result=$(curl -s http://localhost:8000/health)
    if [ $? -eq 0 ]; then
        echo "✅ Backend is healthy!"
        echo "$result"
        break
    else
        echo "Attempt $i/5: Waiting..."
        sleep 5
    fi
done

echo ""
echo "=== Backend Logs (last 30 lines) ==="
docker-compose logs --tail=30 backend

ENDSSH

echo ""
echo "=== 🎉 Deployment Complete! ==="
echo ""
echo "Access your application:"
echo "  Frontend: http://cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com:3000"
echo "  Backend:  http://cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com:8000"
echo "  API Docs: http://cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com:8000/docs"
echo ""
