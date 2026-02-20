#!/bin/bash

# Delete CloudFormation Stack Script
# This script will delete the concierge medicine application from AWS account 750299845580

set -e

STACK_NAME="concierge-medicine-stack"
REGION="us-east-1"
ACCOUNT_ID="750299845580"

echo "=========================================="
echo "CloudFormation Stack Deletion Script"
echo "=========================================="
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo "Account ID: $ACCOUNT_ID"
echo "=========================================="
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Verify AWS credentials
echo "Verifying AWS credentials..."
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")

if [ -z "$CURRENT_ACCOUNT" ]; then
    echo "ERROR: Unable to verify AWS credentials. Please configure AWS CLI."
    exit 1
fi

if [ "$CURRENT_ACCOUNT" != "$ACCOUNT_ID" ]; then
    echo "WARNING: Current AWS account ($CURRENT_ACCOUNT) does not match expected account ($ACCOUNT_ID)"
    read -p "Do you want to continue? (yes/no): " CONTINUE
    if [ "$CONTINUE" != "yes" ]; then
        echo "Aborted."
        exit 1
    fi
fi

echo "AWS credentials verified for account: $CURRENT_ACCOUNT"
echo ""

# Check if stack exists
echo "Checking if stack exists..."
STACK_STATUS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].StackStatus' \
    --output text 2>/dev/null || echo "DOES_NOT_EXIST")

if [ "$STACK_STATUS" == "DOES_NOT_EXIST" ]; then
    echo "Stack '$STACK_NAME' does not exist in region $REGION"
    echo "Nothing to delete."
    exit 0
fi

echo "Stack found with status: $STACK_STATUS"
echo ""

# Warn user about deletion
echo "=========================================="
echo "WARNING: This will DELETE the following:"
echo "=========================================="
echo "- RDS Database (all data will be lost)"
echo "- S3 Buckets and their contents"
echo "- ECS Services and Tasks"
echo "- Load Balancers"
echo "- VPC and networking resources"
echo "- IAM Roles and Policies"
echo "- CloudWatch Logs"
echo "- All other resources in the stack"
echo "=========================================="
echo ""

read -p "Are you sure you want to delete the stack? Type 'DELETE' to confirm: " CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
    echo "Deletion cancelled."
    exit 0
fi

echo ""
echo "Starting stack deletion..."

# Delete the stack
aws cloudformation delete-stack \
    --stack-name $STACK_NAME \
    --region $REGION

echo "Stack deletion initiated."
echo ""
echo "Waiting for stack deletion to complete..."
echo "(This may take 10-20 minutes)"
echo ""

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete \
    --stack-name $STACK_NAME \
    --region $REGION

echo ""
echo "=========================================="
echo "Stack deletion completed successfully!"
echo "=========================================="
echo ""
echo "All resources have been removed from your AWS account."
echo ""

# Check for any remaining resources (S3 buckets with deletion protection)
echo "Checking for any remaining S3 buckets..."
BUCKETS=$(aws s3 ls | grep concierge-medicine || echo "")

if [ -n "$BUCKETS" ]; then
    echo ""
    echo "WARNING: The following S3 buckets may still exist:"
    echo "$BUCKETS"
    echo ""
    echo "If buckets remain, you may need to manually delete them:"
    echo "1. Empty the bucket: aws s3 rm s3://bucket-name --recursive"
    echo "2. Delete the bucket: aws s3 rb s3://bucket-name"
fi

echo ""
echo "Cleanup complete!"
