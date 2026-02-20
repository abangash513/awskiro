#!/bin/bash
# Fix database by switching to SQLite

VM_HOST="cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com"
VM_USER="azureuser"
VM_PASS="zJsjfxP80cmn!WeU"

echo "Connecting to VM and fixing database..."

sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no $VM_USER@$VM_HOST << 'ENDSSH'
cd /opt/cloudoptima

echo "Updating .env to use SQLite..."
sed -i 's|DATABASE_URL=postgresql.*|DATABASE_URL=sqlite+aiosqlite:///./cloudoptima.db|' .env

echo "Stopping services..."
docker-compose down

echo "Starting services..."
docker-compose up -d

echo "Waiting for services to start..."
sleep 15

echo ""
echo "=== Service Status ==="
docker-compose ps

echo ""
echo "=== Testing Backend ==="
curl -s http://localhost:8000/health && echo "" || echo "Backend not ready yet"

echo ""
echo "=== Backend Logs (last 10 lines) ==="
docker-compose logs --tail=10 backend

ENDSSH

echo ""
echo "Done! Check the output above."
