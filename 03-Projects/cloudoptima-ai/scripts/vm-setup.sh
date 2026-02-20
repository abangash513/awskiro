#!/bin/bash
# CloudOptima AI - VM Setup Script
# Run this script after SSH into the VM

set -e

echo "========================================="
echo "CloudOptima AI - VM Setup"
echo "========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variables
APP_DIR="/opt/cloudoptima"
REPO_URL="https://github.com/yourusername/cloudoptima-ai.git"  # Update this

echo -e "${YELLOW}Step 1: Creating application directory${NC}"
sudo mkdir -p $APP_DIR
sudo chown azureuser:azureuser $APP_DIR

echo -e "${YELLOW}Step 2: Cloning repository${NC}"
# For now, we'll assume code is uploaded manually
# git clone $REPO_URL $APP_DIR

echo -e "${YELLOW}Step 3: Installing Python dependencies${NC}"
cd $APP_DIR/backend
python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo -e "${YELLOW}Step 4: Starting Redis container${NC}"
docker run -d \
  --name redis \
  --restart unless-stopped \
  -p 6379:6379 \
  -v redis-data:/data \
  redis:7-alpine \
  redis-server --maxmemory 50mb --maxmemory-policy allkeys-lru

echo -e "${YELLOW}Step 5: Creating systemd services${NC}"

# Backend service
sudo tee /etc/systemd/system/backend.service > /dev/null <<EOF
[Unit]
Description=CloudOptima AI Backend API
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=azureuser
WorkingDirectory=$APP_DIR/backend
Environment="PATH=$APP_DIR/backend/venv/bin:/usr/local/bin:/usr/bin:/bin"
EnvironmentFile=/etc/environment
ExecStart=$APP_DIR/backend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Celery Worker service
sudo tee /etc/systemd/system/celery-worker.service > /dev/null <<EOF
[Unit]
Description=CloudOptima AI Celery Worker
After=network.target docker.service backend.service
Requires=docker.service

[Service]
Type=simple
User=azureuser
WorkingDirectory=$APP_DIR/backend
Environment="PATH=$APP_DIR/backend/venv/bin:/usr/local/bin:/usr/bin:/bin"
EnvironmentFile=/etc/environment
ExecStart=$APP_DIR/backend/venv/bin/celery -A app.core.celery_app worker --loglevel=info
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Celery Beat service
sudo tee /etc/systemd/system/celery-beat.service > /dev/null <<EOF
[Unit]
Description=CloudOptima AI Celery Beat Scheduler
After=network.target docker.service backend.service
Requires=docker.service

[Service]
Type=simple
User=azureuser
WorkingDirectory=$APP_DIR/backend
Environment="PATH=$APP_DIR/backend/venv/bin:/usr/local/bin:/usr/bin:/bin"
EnvironmentFile=/etc/environment
ExecStart=$APP_DIR/backend/venv/bin/celery -A app.core.celery_app beat --loglevel=info
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo -e "${YELLOW}Step 6: Reloading systemd${NC}"
sudo systemctl daemon-reload

echo -e "${YELLOW}Step 7: Enabling services${NC}"
sudo systemctl enable backend celery-worker celery-beat

echo -e "${YELLOW}Step 8: Starting services${NC}"
sudo systemctl start backend
sleep 5
sudo systemctl start celery-worker
sudo systemctl start celery-beat

echo -e "${YELLOW}Step 9: Running database migrations${NC}"
cd $APP_DIR/backend
source venv/bin/activate
# If using Alembic:
# alembic upgrade head
# If using init_db:
python -c "import asyncio; from app.core.database import init_db; asyncio.run(init_db())"

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Service Status:"
sudo systemctl status backend --no-pager
sudo systemctl status celery-worker --no-pager
sudo systemctl status celery-beat --no-pager
echo ""
echo "Check logs:"
echo "  sudo journalctl -u backend -f"
echo "  sudo journalctl -u celery-worker -f"
echo "  sudo journalctl -u celery-beat -f"
echo ""
echo "Test backend:"
echo "  curl http://localhost:8000/health"
echo ""
echo "Memory usage:"
free -h
