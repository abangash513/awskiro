#!/bin/bash
VM_HOST="cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com"
VM_USER="azureuser"
VM_PASS="zJsjfxP80cmn!WeU"

echo "=== Final Fix: Fresh Start ==="

sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no $VM_USER@$VM_HOST << 'ENDSSH'
cd /opt/cloudoptima

echo "1. Stopping all services..."
docker-compose down -v

echo "2. Removing old database data..."
sudo rm -rf postgres_data/

echo "3. Starting services fresh..."
docker-compose up -d

echo "4. Waiting for database to be ready..."
sleep 15

echo "5. Checking service status..."
docker-compose ps

echo ""
echo "6. Testing backend..."
sleep 5
curl -s http://localhost:8000/health && echo "✅ Backend is healthy!" || echo "⚠️ Backend still starting..."

echo ""
echo "7. Backend logs:"
docker-compose logs --tail=20 backend

ENDSSH

echo ""
echo "=== Done! ==="
