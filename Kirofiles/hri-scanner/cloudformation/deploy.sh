#!/bin/bash
#
# HRI Fast Scanner - Automated Deployment Script
# This script automates the deployment of HRI Scanner to AWS
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="hri-scanner-management"
MEMBER_STACK_NAME="hri-scanner-member-role"
REGION="${AWS_REGION:-us-east-1}"
SCANNER_ROLE_NAME="HRI-ScannerRole"
EXTERNAL_ID="hri-scanner-external-id-12345"

# Functions
print_header() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
}

print_info() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install it first."
        exit 1
    fi
    print_info "AWS CLI installed"
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 not found. Please install it first."
        exit 1
    fi
    print_info "Python 3 installed"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi
    print_info "AWS credentials configured"
    
    # Get account ID
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_info "Account ID: $ACCOUNT_ID"
}

package_lambda_code() {
    print_header "Packaging Lambda Functions"
    
    cd ../lambda
    
    # Package discover_accounts
    if [ -f "discover_accounts.py" ]; then
        zip -q discover_accounts.zip discover_accounts.py
        print_info "Packaged discover_accounts.zip"
    else
        print_error "discover_accounts.py not found"
        exit 1
    fi
    
    # Package scan_account
    if [ -f "scan_account.py" ]; then
        zip -q scan_account.zip scan_account.py
        print_info "Packaged scan_account.zip"
    else
        print_error "scan_account.py not found"
        exit 1
    fi
    
    cd ../cloudformation
}

deploy_management_stack() {
    print_header "Deploying Management Account Stack"
    
    # Prompt for email
    read -p "Enter notification email (or press Enter to skip): " NOTIFICATION_EMAIL
    
    # Build parameters
    PARAMS="ParameterKey=ScannerRoleName,ParameterValue=$SCANNER_ROLE_NAME"
    
    if [ ! -z "$NOTIFICATION_EMAIL" ]; then
        PARAMS="$PARAMS ParameterKey=NotificationEmail,ParameterValue=$NOTIFICATION_EMAIL"
    fi
    
    # Deploy stack
    print_info "Creating CloudFormation stack..."
    aws cloudformation create-stack \
        --stack-name $STACK_NAME \
        --template-body file://management-account-stack.yaml \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameters $PARAMS \
        --region $REGION
    
    print_info "Waiting for stack creation to complete..."
    aws cloudformation wait stack-create-complete \
        --stack-name $STACK_NAME \
        --region $REGION
    
    print_info "Management stack deployed successfully"
}

update_lambda_code() {
    print_header "Updating Lambda Function Code"
    
    cd ../lambda
    
    # Update discover_accounts
    print_info "Updating discover_accounts function..."
    aws lambda update-function-code \
        --function-name hri-discover-accounts \
        --zip-file fileb://discover_accounts.zip \
        --region $REGION > /dev/null
    
    # Update scan_account
    print_info "Updating scan_account function..."
    aws lambda update-function-code \
        --function-name hri-scan-account \
        --zip-file fileb://scan_account.zip \
        --region $REGION > /dev/null
    
    print_info "Lambda functions updated successfully"
    
    cd ../cloudformation
}

deploy_member_stack() {
    print_header "Deploying Member Account Stack"
    
    echo "Choose deployment method:"
    echo "1) Deploy to current account (single account)"
    echo "2) Deploy via StackSets (multiple accounts)"
    echo "3) Skip member account deployment"
    read -p "Enter choice [1-3]: " DEPLOY_CHOICE
    
    case $DEPLOY_CHOICE in
        1)
            deploy_single_member_account
            ;;
        2)
            deploy_stacksets
            ;;
        3)
            print_warning "Skipping member account deployment"
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
}

deploy_single_member_account() {
    print_info "Deploying to current account..."
    
    aws cloudformation create-stack \
        --stack-name $MEMBER_STACK_NAME \
        --template-body file://member-account-stack.yaml \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameters \
            ParameterKey=ManagementAccountId,ParameterValue=$ACCOUNT_ID \
            ParameterKey=ScannerRoleName,ParameterValue=$SCANNER_ROLE_NAME \
            ParameterKey=ExternalId,ParameterValue=$EXTERNAL_ID \
        --region $REGION
    
    print_info "Waiting for stack creation to complete..."
    aws cloudformation wait stack-create-complete \
        --stack-name $MEMBER_STACK_NAME \
        --region $REGION
    
    print_info "Member account stack deployed successfully"
}

deploy_stacksets() {
    print_info "Creating StackSet..."
    
    # Create StackSet
    aws cloudformation create-stack-set \
        --stack-set-name hri-scanner-member-roles \
        --template-body file://member-account-stack.yaml \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameters \
            ParameterKey=ManagementAccountId,ParameterValue=$ACCOUNT_ID \
            ParameterKey=ScannerRoleName,ParameterValue=$SCANNER_ROLE_NAME \
            ParameterKey=ExternalId,ParameterValue=$EXTERNAL_ID \
        --region $REGION
    
    print_info "StackSet created successfully"
    print_warning "Deploy StackSet instances manually using:"
    echo "aws cloudformation create-stack-instances \\"
    echo "  --stack-set-name hri-scanner-member-roles \\"
    echo "  --accounts ACCOUNT_ID_1 ACCOUNT_ID_2 \\"
    echo "  --regions $REGION"
}

verify_deployment() {
    print_header "Verifying Deployment"
    
    # Check stack status
    STACK_STATUS=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --query 'Stacks[0].StackStatus' \
        --output text \
        --region $REGION)
    
    if [ "$STACK_STATUS" == "CREATE_COMPLETE" ]; then
        print_info "Stack status: $STACK_STATUS"
    else
        print_error "Stack status: $STACK_STATUS"
        exit 1
    fi
    
    # Check Lambda functions
    print_info "Verifying Lambda functions..."
    aws lambda get-function --function-name hri-discover-accounts --region $REGION > /dev/null
    aws lambda get-function --function-name hri-scan-account --region $REGION > /dev/null
    print_info "Lambda functions verified"
    
    # Check DynamoDB table
    print_info "Verifying DynamoDB table..."
    TABLE_STATUS=$(aws dynamodb describe-table \
        --table-name hri_findings \
        --query 'Table.TableStatus' \
        --output text \
        --region $REGION)
    print_info "DynamoDB table status: $TABLE_STATUS"
    
    # Check S3 bucket
    print_info "Verifying S3 bucket..."
    BUCKET_NAME="hri-exports-${ACCOUNT_ID}-${REGION}"
    if aws s3 ls "s3://$BUCKET_NAME" &> /dev/null; then
        print_info "S3 bucket verified: $BUCKET_NAME"
    else
        print_error "S3 bucket not found: $BUCKET_NAME"
    fi
}

test_deployment() {
    print_header "Testing Deployment"
    
    read -p "Run test scan? [y/N]: " RUN_TEST
    
    if [ "$RUN_TEST" == "y" ] || [ "$RUN_TEST" == "Y" ]; then
        print_info "Invoking discover_accounts function..."
        
        aws lambda invoke \
            --function-name hri-discover-accounts \
            --payload '{}' \
            --region $REGION \
            response.json > /dev/null
        
        print_info "Response:"
        cat response.json
        echo ""
        
        rm -f response.json
        
        print_info "Check CloudWatch Logs for detailed output:"
        echo "aws logs tail /aws/lambda/hri-discover-accounts --follow"
    else
        print_warning "Skipping test"
    fi
}

print_summary() {
    print_header "Deployment Summary"
    
    # Get stack outputs
    echo "Stack Outputs:"
    aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
        --output table \
        --region $REGION
    
    echo ""
    print_info "Deployment completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Confirm SNS email subscription (if provided)"
    echo "2. Deploy member account roles to other accounts"
    echo "3. Run a test scan: aws lambda invoke --function-name hri-discover-accounts --payload '{}' response.json"
    echo "4. Check findings: aws dynamodb scan --table-name hri_findings --max-items 10"
    echo ""
    echo "Documentation: See DEPLOYMENT_GUIDE.md for detailed instructions"
}

# Main execution
main() {
    print_header "HRI Fast Scanner - Automated Deployment"
    
    check_prerequisites
    package_lambda_code
    deploy_management_stack
    update_lambda_code
    deploy_member_stack
    verify_deployment
    test_deployment
    print_summary
}

# Run main function
main
