#!/bin/bash
VM_HOST="cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com"
VM_USER="azureuser"
VM_PASS="zJsjfxP80cmn!WeU"

sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no $VM_USER@$VM_HOST << 'ENDSSH'
cd /opt/cloudoptima

echo "Restarting backend..."
docker-compose restart backend

echo "Waiting 15 seconds..."
sleep 15

echo ""
echo "=== Testing Backend Health ==="
curl -s http://localhost:8000/health && echo "" || echo "Backend not responding"

echo ""
echo "=== Service Status ==="
docker-compose ps

echo ""
echo "=== Backend Logs (last 20 lines) ==="
docker-compose logs --tail=20 backend

ENDSSH
