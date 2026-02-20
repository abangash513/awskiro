#!/bin/bash

# Concierge Medicine Website - CloudFormation Deployment Script
# This script deploys the entire infrastructure to AWS using CloudFormation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_ACCOUNT_ID="750299845580"
AWS_REGION="us-east-1"
STACK_NAME="concierge-medicine-stack"
ENVIRONMENT="test"
APPLICATION_NAME="concierge-medicine"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Concierge Medicine - CloudFormation Deployment            ║${NC}"
echo -e "${BLUE}║  Account: $AWS_ACCOUNT_ID                                  ║${NC}"
echo -e "${BLUE}║  Region: $AWS_REGION                                       ║${NC}"
echo -e "${BLUE}║  Environment: $ENVIRONMENT                                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

# Check prerequisites
echo -e "\n${YELLOW}[1/5] Checking prerequisites...${NC}"

if ! command -v aws &> /dev/null; then
    echo -e "${RED}✗ AWS CLI is not installed${NC}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites check passed${NC}"

# Validate CloudFormation template
echo -e "\n${YELLOW}[2/5] Validating CloudFormation template...${NC}"

aws cloudformation validate-template \
  --template-body file://cloudformation-template.yaml \
  --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓ Template validation passed${NC}"

# Store DB password in Secrets Manager
echo -e "\n${YELLOW}[3/5] Storing secrets in AWS Secrets Manager...${NC}"

# Check if secret already exists
if aws secretsmanager describe-secret \
  --secret-id "${APPLICATION_NAME}/db/password" \
  --region $AWS_REGION 2>/dev/null; then
  echo -e "${YELLOW}  Secret already exists, skipping creation${NC}"
else
  aws secretsmanager create-secret \
    --name "${APPLICATION_NAME}/db/password" \
    --secret-string "ConciergeTest123!@#" \
    --region $AWS_REGION > /dev/null
  echo -e "${GREEN}✓ Secret created${NC}"
fi

# Create or update CloudFormation stack
echo -e "\n${YELLOW}[4/5] Creating/Updating CloudFormation stack...${NC}"

STACK_EXISTS=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --region $AWS_REGION 2>/dev/null || echo "")

if [ -z "$STACK_EXISTS" ]; then
  echo -e "${YELLOW}  Creating new stack...${NC}"
  
  aws cloudformation create-stack \
    --stack-name $STACK_NAME \
    --template-body file://cloudformation-template.yaml \
    --parameters \
      ParameterKey=EnvironmentName,ParameterValue=$ENVIRONMENT \
      ParameterKey=ApplicationName,ParameterValue=$APPLICATION_NAME \
      ParameterKey=DBUsername,ParameterValue=concierge_user \
      ParameterKey=DBPassword,ParameterValue=ConciergeTest123!@# \
      ParameterKey=DBName,ParameterValue=concierge_medicine \
      ParameterKey=JWTSecret,ParameterValue=your_test_jwt_secret_key_min_32_characters_long_12345 \
      ParameterKey=EncryptionKey,ParameterValue=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef \
      ParameterKey=StripeSecretKey,ParameterValue=sk_test_placeholder_key_for_testing \
      ParameterKey=TwilioAccountSID,ParameterValue=AC_test_placeholder \
      ParameterKey=TwilioAuthToken,ParameterValue=test_placeholder_token \
      ParameterKey=TwilioPhoneNumber,ParameterValue=+1234567890 \
      ParameterKey=SendGridAPIKey,ParameterValue=SG.test_placeholder_key \
      ParameterKey=AgoraAppID,ParameterValue=test_agora_app_id \
      ParameterKey=AgoraAppCertificate,ParameterValue=test_agora_certificate \
      ParameterKey=AdminEmail,ParameterValue=admin@concierge-medicine-test.com \
      ParameterKey=SupportEmail,ParameterValue=support@concierge-medicine-test.com \
      ParameterKey=DesiredCount,ParameterValue=1 \
      ParameterKey=TaskCPU,ParameterValue=256 \
      ParameterKey=TaskMemory,ParameterValue=512 \
    --capabilities CAPABILITY_IAM \
    --region $AWS_REGION
  
  STACK_ID=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $AWS_REGION \
    --query 'Stacks[0].StackId' \
    --output text)
  
  echo -e "${GREEN}✓ Stack creation initiated${NC}"
  echo -e "${BLUE}  Stack ID: $STACK_ID${NC}"
else
  echo -e "${YELLOW}  Updating existing stack...${NC}"
  
  aws cloudformation update-stack \
    --stack-name $STACK_NAME \
    --template-body file://cloudformation-template.yaml \
    --parameters \
      ParameterKey=EnvironmentName,ParameterValue=$ENVIRONMENT \
      ParameterKey=ApplicationName,ParameterValue=$APPLICATION_NAME \
      ParameterKey=DBUsername,ParameterValue=concierge_user \
      ParameterKey=DBPassword,ParameterValue=ConciergeTest123!@# \
      ParameterKey=DBName,ParameterValue=concierge_medicine \
      ParameterKey=JWTSecret,ParameterValue=your_test_jwt_secret_key_min_32_characters_long_12345 \
      ParameterKey=EncryptionKey,ParameterValue=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef \
      ParameterKey=StripeSecretKey,ParameterValue=sk_test_placeholder_key_for_testing \
      ParameterKey=TwilioAccountSID,ParameterValue=AC_test_placeholder \
      ParameterKey=TwilioAuthToken,ParameterValue=test_placeholder_token \
      ParameterKey=TwilioPhoneNumber,ParameterValue=+1234567890 \
      ParameterKey=SendGridAPIKey,ParameterValue=SG.test_placeholder_key \
      ParameterKey=AgoraAppID,ParameterValue=test_agora_app_id \
      ParameterKey=AgoraAppCertificate,ParameterValue=test_agora_certificate \
      ParameterKey=AdminEmail,ParameterValue=admin@concierge-medicine-test.com \
      ParameterKey=SupportEmail,ParameterValue=support@concierge-medicine-test.com \
      ParameterKey=DesiredCount,ParameterValue=1 \
      ParameterKey=TaskCPU,ParameterValue=256 \
      ParameterKey=TaskMemory,ParameterValue=512 \
    --capabilities CAPABILITY_IAM \
    --region $AWS_REGION 2>/dev/null || echo -e "${YELLOW}  No updates to perform${NC}"
  
  echo -e "${GREEN}✓ Stack update initiated${NC}"
fi

# Wait for stack to complete
echo -e "\n${YELLOW}[5/5] Waiting for stack to complete...${NC}"
echo -e "${YELLOW}  This may take 10-15 minutes...${NC}"

aws cloudformation wait stack-create-complete \
  --stack-name $STACK_NAME \
  --region $AWS_REGION 2>/dev/null || \
aws cloudformation wait stack-update-complete \
  --stack-name $STACK_NAME \
  --region $AWS_REGION 2>/dev/null || true

# Get stack status
STACK_STATUS=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --region $AWS_REGION \
  --query 'Stacks[0].StackStatus' \
  --output text)

if [[ $STACK_STATUS == *"COMPLETE"* ]]; then
  echo -e "${GREEN}✓ Stack deployment completed successfully${NC}"
else
  echo -e "${RED}✗ Stack deployment failed with status: $STACK_STATUS${NC}"
  exit 1
fi

# Display stack outputs
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Stack Outputs                                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --region $AWS_REGION \
  --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
  --output table

# Display next steps
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Next Steps                                                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}1. Build and push Docker image to ECR:${NC}"
echo -e "   ${GREEN}aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com${NC}"
echo -e "   ${GREEN}docker build -t $APPLICATION_NAME:latest .${NC}"
echo -e "   ${GREEN}docker tag $APPLICATION_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$APPLICATION_NAME-backend:latest${NC}"
echo -e "   ${GREEN}docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$APPLICATION_NAME-backend:latest${NC}"

echo -e "\n${YELLOW}2. Update ECS service to use the new image:${NC}"
echo -e "   ${GREEN}aws ecs update-service --cluster $APPLICATION_NAME-cluster --service $APPLICATION_NAME-service --force-new-deployment --region $AWS_REGION${NC}"

echo -e "\n${YELLOW}3. Monitor the deployment:${NC}"
echo -e "   ${GREEN}aws ecs describe-services --cluster $APPLICATION_NAME-cluster --services $APPLICATION_NAME-service --region $AWS_REGION${NC}"

echo -e "\n${YELLOW}4. View logs:${NC}"
echo -e "   ${GREEN}aws logs tail /ecs/$APPLICATION_NAME --follow --region $AWS_REGION${NC}"

echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Deployment Complete!                                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
