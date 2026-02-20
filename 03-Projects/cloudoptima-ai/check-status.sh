#!/bin/bash
VM_HOST="cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com"
VM_USER="azureuser"
VM_PASS="zJsjfxP80cmn!WeU"

sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no $VM_USER@$VM_HOST << 'ENDSSH'
cd /opt/cloudoptima

echo "=== Service Status ==="
docker-compose ps

echo ""
echo "=== Backend Health Check ==="
curl -s http://localhost:8000/health && echo "" || echo "Backend not responding"

echo ""
echo "=== Frontend Check ==="
curl -s http://localhost:3000 | head -5 || echo "Frontend not responding"

echo ""
echo "=== Backend Logs (last 15 lines) ==="
docker-compose logs --tail=15 backend

ENDSSH
