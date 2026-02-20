#!/bin/bash
VM_HOST="cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com"
VM_USER="azureuser"
VM_PASS="zJsjfxP80cmn!WeU"

echo "Fixing PostgreSQL database..."

sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no $VM_USER@$VM_HOST << 'ENDSSH'
cd /opt/cloudoptima

echo "Resetting database..."
docker-compose exec -T db psql -U cloudoptima -d cloudoptima -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

echo "Updating .env back to PostgreSQL..."
sed -i 's|DATABASE_URL=sqlite.*|DATABASE_URL=postgresql+asyncpg://cloudoptima:cloudoptima@db:5432/cloudoptima|' .env

echo "Restarting backend..."
docker-compose restart backend

echo "Waiting for backend to start..."
sleep 10

echo ""
echo "=== Service Status ==="
docker-compose ps

echo ""
echo "=== Testing Backend ==="
curl -s http://localhost:8000/health && echo ""

echo ""
echo "=== Backend Logs (last 20 lines) ==="
docker-compose logs --tail=20 backend

ENDSSH

echo ""
echo "Done!"
