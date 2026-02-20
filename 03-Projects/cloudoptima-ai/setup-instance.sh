#!/bin/bash
# CloudOptima AI - EC2 Instance Setup Script
# Run this script on your EC2 instance after SSH

set -e

echo "=== CloudOptima AI - Instance Setup ==="
echo ""

# Check if running as ubuntu user
if [ "$USER" != "ubuntu" ]; then
    echo "⚠️  This script should be run as ubuntu user"
    echo "Current user: $USER"
    read -p "Continue anyway? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        exit 0
    fi
fi

# Update system
echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker ubuntu
    rm get-docker.sh
    echo "✅ Docker installed"
else
    echo "✅ Docker already installed"
fi

# Install Docker Compose
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo apt-get install -y docker-compose-plugin
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose already installed"
fi

# Install Git
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    sudo apt-get install -y git
    echo "✅ Git installed"
else
    echo "✅ Git already installed"
fi

# Install useful tools
echo "Installing additional tools..."
sudo apt-get install -y htop curl wget nano vim jq

# Create app directory
APP_DIR="/opt/cloudoptima"
if [ ! -d "$APP_DIR" ]; then
    echo "Creating application directory..."
    sudo mkdir -p $APP_DIR
    sudo chown ubuntu:ubuntu $APP_DIR
    echo "✅ Created $APP_DIR"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo ""
echo "1. Upload your application code:"
echo "   From your local machine, run:"
echo "   scp -i your-key.pem -r /path/to/cloudoptima-ai ubuntu@$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):/opt/cloudoptima"
echo ""
echo "   OR clone from Git:"
echo "   cd $APP_DIR"
echo "   git clone https://github.com/your-org/cloudoptima-ai.git ."
echo ""
echo "2. Configure environment:"
echo "   cd $APP_DIR"
echo "   cp .env.example .env"
echo "   nano .env  # Edit with your settings"
echo ""
echo "3. Generate secure secrets:"
echo "   export SECRET_KEY=\$(openssl rand -hex 32)"
echo "   export DB_PASSWORD=\$(openssl rand -hex 16)"
echo "   sed -i \"s/SECRET_KEY=change-me.*/SECRET_KEY=\$SECRET_KEY/\" .env"
echo "   sed -i \"s/POSTGRES_PASSWORD=cloudoptima/POSTGRES_PASSWORD=\$DB_PASSWORD/\" .env"
echo "   sed -i \"s/:cloudoptima@/:\$DB_PASSWORD@/\" .env"
echo ""
echo "4. Start services:"
echo "   docker compose up -d"
echo ""
echo "5. Check status:"
echo "   docker compose ps"
echo "   docker compose logs -f"
echo ""
echo "6. Initialize database:"
echo "   docker compose exec db psql -U cloudoptima -d cloudoptima -c \"CREATE EXTENSION IF NOT EXISTS timescaledb;\""
echo "   docker compose exec db psql -U cloudoptima -d cloudoptima -c \"SELECT create_hypertable('cost_data', 'billing_period_start', if_not_exists => TRUE);\""
echo ""
echo "7. Access application:"
echo "   Frontend:  http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
echo "   Backend:   http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000"
echo "   API Docs:  http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000/docs"
echo ""

# Logout and login to apply docker group
echo "⚠️  IMPORTANT: You need to logout and login again for Docker permissions to take effect"
echo "Run: exit, then SSH back in"
echo ""
