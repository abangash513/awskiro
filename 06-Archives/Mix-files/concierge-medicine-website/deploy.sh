#!/bin/bash

# Concierge Medicine Website - AWS Deployment Script
# This script automates the deployment process to AWS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:-}
ECR_REPO_NAME="concierge-medicine-backend"
ECS_CLUSTER_NAME="concierge-medicine-cluster"
ECS_SERVICE_NAME="concierge-medicine-backend"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Concierge Medicine - AWS Deployment${NC}"
echo -e "${GREEN}========================================${NC}"

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed${NC}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed${NC}"
    exit 1
fi

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}AWS_ACCOUNT_ID environment variable is not set${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites check passed${NC}"

# Get AWS Account ID if not provided
if [ -z "$AWS_ACCOUNT_ID" ]; then
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    echo -e "${GREEN}AWS Account ID: $AWS_ACCOUNT_ID${NC}"
fi

# Build Docker image
echo -e "\n${YELLOW}Building Docker image...${NC}"
docker build -t $ECR_REPO_NAME:latest .
echo -e "${GREEN}✓ Docker image built${NC}"

# Login to ECR
echo -e "\n${YELLOW}Logging in to ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
echo -e "${GREEN}✓ ECR login successful${NC}"

# Tag image for ECR
echo -e "\n${YELLOW}Tagging Docker image for ECR...${NC}"
docker tag $ECR_REPO_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:latest
echo -e "${GREEN}✓ Docker image tagged${NC}"

# Push to ECR
echo -e "\n${YELLOW}Pushing Docker image to ECR...${NC}"
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:latest
echo -e "${GREEN}✓ Docker image pushed to ECR${NC}"

# Update ECS service
echo -e "\n${YELLOW}Updating ECS service...${NC}"
aws ecs update-service \
  --cluster $ECS_CLUSTER_NAME \
  --service $ECS_SERVICE_NAME \
  --force-new-deployment \
  --region $AWS_REGION
echo -e "${GREEN}✓ ECS service updated${NC}"

# Wait for service to stabilize
echo -e "\n${YELLOW}Waiting for service to stabilize...${NC}"
aws ecs wait services-stable \
  --cluster $ECS_CLUSTER_NAME \
  --services $ECS_SERVICE_NAME \
  --region $AWS_REGION
echo -e "${GREEN}✓ Service is stable${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"

# Get service details
echo -e "\n${YELLOW}Service Details:${NC}"
aws ecs describe-services \
  --cluster $ECS_CLUSTER_NAME \
  --services $ECS_SERVICE_NAME \
  --region $AWS_REGION \
  --query 'services[0].[serviceName,status,runningCount,desiredCount]' \
  --output table
