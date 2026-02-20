#!/bin/bash
# CloudOptima AI - EC2 Deployment Script
# This script automates the deployment to a single EC2 instance

set -e

echo "=== CloudOptima AI - EC2 Deployment ==="
echo ""

# Configuration
INSTANCE_TYPE="t3.large"
VOLUME_SIZE=50
KEY_NAME=""
SECURITY_GROUP=""
SUBNET_ID=""
REGION="us-east-1"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Get user inputs
read -p "Enter your EC2 Key Pair name: " KEY_NAME
read -p "Enter Security Group ID (or press Enter to create new): " SECURITY_GROUP
read -p "Enter Subnet ID (or press Enter to use default VPC): " SUBNET_ID
read -p "Enter AWS Region [us-east-1]: " INPUT_REGION
REGION=${INPUT_REGION:-$REGION}

echo ""
echo "Configuration:"
echo "  Instance Type: $INSTANCE_TYPE"
echo "  Volume Size: ${VOLUME_SIZE}GB"
echo "  Key Name: $KEY_NAME"
echo "  Region: $REGION"
echo ""

read -p "Proceed with deployment? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Deployment cancelled."
    exit 0
fi

# Create security group if not provided
if [ -z "$SECURITY_GROUP" ]; then
    echo "Creating security group..."
    VPC_ID=$(aws ec2 describe-vpcs --region $REGION --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
    
    SECURITY_GROUP=$(aws ec2 create-security-group \
        --region $REGION \
        --group-name cloudoptima-sg \
        --description "CloudOptima AI Security Group" \
        --vpc-id $VPC_ID \
        --query "GroupId" \
        --output text)
    
    # Add inbound rules
    aws ec2 authorize-security-group-ingress --region $REGION --group-id $SECURITY_GROUP --protocol tcp --port 22 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --region $REGION --group-id $SECURITY_GROUP --protocol tcp --port 80 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --region $REGION --group-id $SECURITY_GROUP --protocol tcp --port 443 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --region $REGION --group-id $SECURITY_GROUP --protocol tcp --port 3000 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --region $REGION --group-id $SECURITY_GROUP --protocol tcp --port 8000 --cidr 0.0.0.0/0
    
    echo "Security group created: $SECURITY_GROUP"
fi

# Get latest Ubuntu 24.04 AMI
echo "Finding latest Ubuntu 24.04 AMI..."
AMI_ID=$(aws ec2 describe-images \
    --region $REGION \
    --owners 099720109477 \
    --filters "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
    --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
    --output text)

echo "Using AMI: $AMI_ID"

# Create user data script
cat > /tmp/cloudoptima-userdata.sh << 'EOF'
#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Install Docker Compose
apt-get install -y docker-compose-plugin

# Install Git
apt-get install -y git

# Create app directory
mkdir -p /opt/cloudoptima
chown ubuntu:ubuntu /opt/cloudoptima

echo "Setup complete. Ready for application deployment."
EOF

# Launch EC2 instance
echo "Launching EC2 instance..."

SUBNET_PARAM=""
if [ -n "$SUBNET_ID" ]; then
    SUBNET_PARAM="--subnet-id $SUBNET_ID"
fi

INSTANCE_ID=$(aws ec2 run-instances \
    --region $REGION \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP \
    $SUBNET_PARAM \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":$VOLUME_SIZE,\"VolumeType\":\"gp3\"}}]" \
    --user-data file:///tmp/cloudoptima-userdata.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=CloudOptima-AI}]" \
    --query "Instances[0].InstanceId" \
    --output text)

echo "Instance launched: $INSTANCE_ID"
echo "Waiting for instance to be running..."

aws ec2 wait instance-running --region $REGION --instance-ids $INSTANCE_ID

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --region $REGION \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Instance ID: $INSTANCE_ID"
echo "Public IP: $PUBLIC_IP"
echo "Security Group: $SECURITY_GROUP"
echo ""
echo "Next steps:"
echo "1. Wait 2-3 minutes for instance initialization"
echo "2. SSH to instance: ssh -i $KEY_NAME.pem ubuntu@$PUBLIC_IP"
echo "3. Clone your repository or upload files to /opt/cloudoptima"
echo "4. Configure .env file with your settings"
echo "5. Run: cd /opt/cloudoptima && docker compose up -d"
echo ""
echo "Access URLs (after deployment):"
echo "  Frontend: http://$PUBLIC_IP:3000"
echo "  Backend API: http://$PUBLIC_IP:8000"
echo "  API Docs: http://$PUBLIC_IP:8000/docs"
echo ""

# Save deployment info
cat > cloudoptima-deployment-info.txt << EOF
CloudOptima AI Deployment Information
======================================

Instance ID: $INSTANCE_ID
Public IP: $PUBLIC_IP
Region: $REGION
Security Group: $SECURITY_GROUP
Key Name: $KEY_NAME

SSH Command:
ssh -i $KEY_NAME.pem ubuntu@$PUBLIC_IP

Deployment Date: $(date)
EOF

echo "Deployment info saved to: cloudoptima-deployment-info.txt"
