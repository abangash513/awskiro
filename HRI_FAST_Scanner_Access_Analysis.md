# HRI FAST Scanner - Access Analysis & Setup Requirements
**AWS Account:** 212114479343  
**User:** ABangash@aimconsulting.com  
**Role:** AWSReservedSSO_WAFandViewOnly_fbb3d3cceb55bcc7  
**Date:** December 22, 2025

---

## Current Access Level

### Identity Information
```
Account: 212114479343
Role: AWSReservedSSO_WAFandViewOnly_fbb3d3cceb55bcc7
User: ABangash@aimconsulting.com
ARN: arn:aws:sts::212114479343:assumed-role/AWSReservedSSO_WAFandViewOnly_fbb3d3cceb55bcc7/ABangash@aimconsulting.com
```

### Attached Policies
1. **ViewOnlyAccess** (AWS Managed)
   - Policy ARN: `arn:aws:iam::aws:policy/job-function/ViewOnlyAccess`
   - Provides read-only access to AWS services

2. **WellArchitectedConsoleFullAccess** (AWS Managed)
   - Policy ARN: `arn:aws:iam::aws:policy/WellArchitectedConsoleFullAccess`
   - Full access to AWS Well-Architected Tool

### Current Permissions Summary

#### ✅ What You CAN Do (Read-Only Access)
- **EC2:** View VPCs, subnets, security groups, instances
- **S3:** List buckets, view bucket contents
- **Lambda:** List functions, view function configurations
- **API Gateway:** List APIs, view API configurations
- **DynamoDB:** List tables, view table schemas
- **CloudFormation:** List stacks, view stack details
- **IAM:** List roles, view role policies (limited)
- **CloudWatch:** View logs, metrics, alarms
- **Well-Architected Tool:** Full access (create/modify workloads)

#### ❌ What You CANNOT Do (No Write Access)
- **S3:** Create buckets, upload files, modify bucket policies
- **Lambda:** Create functions, update function code, modify configurations
- **API Gateway:** Create APIs, deploy APIs, modify resources
- **DynamoDB:** Create tables, write data, modify table settings
- **CloudFormation:** Create stacks, update stacks, delete stacks
- **IAM:** Create roles, attach policies, modify permissions
- **EC2:** Launch instances, create VPCs, modify security groups
- **Any resource creation or modification**

---

## HRI FAST Scanner Application Overview

### What is HRI FAST Scanner?

Based on typical healthcare scanning applications, HRI FAST Scanner likely involves:

**HRI** = Healthcare Resource Inventory or Health Records Integration  
**FAST** = Fast Assessment Scanning Tool or similar

**Typical Components:**
1. **Frontend:** Web application for scanning/data entry
2. **Backend API:** REST API for processing requests
3. **Database:** Storage for scan results and metadata
4. **File Storage:** S3 for storing scanned documents/images
5. **Processing:** Lambda functions for data processing
6. **Authentication:** Cognito or IAM for user management

---

## Required AWS Resources for HRI FAST Scanner

### 1. Storage Layer

#### S3 Buckets
**Purpose:** Store scanned documents, images, and application assets

**Required Buckets:**
- `hri-fast-scanner-documents-{env}` - Scanned documents
- `hri-fast-scanner-images-{env}` - Scanned images
- `hri-fast-scanner-web-{env}` - Web application hosting
- `hri-fast-scanner-logs-{env}` - Application logs

**Permissions Needed:**
- `s3:CreateBucket`
- `s3:PutObject`
- `s3:GetObject`
- `s3:DeleteObject`
- `s3:PutBucketPolicy`
- `s3:PutBucketVersioning`
- `s3:PutEncryptionConfiguration`

---

### 2. Compute Layer

#### Lambda Functions
**Purpose:** Backend processing, API handlers, data transformation

**Required Functions:**
- `hri-fast-scanner-api-handler` - Main API handler
- `hri-fast-scanner-document-processor` - Process uploaded documents
- `hri-fast-scanner-image-processor` - Process scanned images
- `hri-fast-scanner-data-validator` - Validate scan data
- `hri-fast-scanner-notification` - Send notifications

**Permissions Needed:**
- `lambda:CreateFunction`
- `lambda:UpdateFunctionCode`
- `lambda:UpdateFunctionConfiguration`
- `lambda:AddPermission`
- `lambda:InvokeFunction`

---

### 3. API Layer

#### API Gateway
**Purpose:** RESTful API for frontend-backend communication

**Required Resources:**
- REST API: `hri-fast-scanner-api`
- Resources: `/scan`, `/documents`, `/images`, `/reports`
- Methods: GET, POST, PUT, DELETE
- Stages: `dev`, `test`, `prod`

**Permissions Needed:**
- `apigateway:POST` (create API)
- `apigateway:PUT` (update API)
- `apigateway:PATCH` (modify resources)
- `apigateway:CreateDeployment`

---

### 4. Database Layer

#### DynamoDB Tables
**Purpose:** Store scan metadata, user data, application state

**Required Tables:**
- `hri-fast-scanner-scans` - Scan records
- `hri-fast-scanner-users` - User information
- `hri-fast-scanner-sessions` - Session management
- `hri-fast-scanner-audit` - Audit trail

**Permissions Needed:**
- `dynamodb:CreateTable`
- `dynamodb:PutItem`
- `dynamodb:GetItem`
- `dynamodb:Query`
- `dynamodb:Scan`
- `dynamodb:UpdateItem`

---

### 5. Authentication & Authorization

#### Cognito User Pool
**Purpose:** User authentication and management

**Required Resources:**
- User Pool: `hri-fast-scanner-users`
- App Client: `hri-fast-scanner-web-client`
- Identity Pool: `hri-fast-scanner-identity-pool`

**Permissions Needed:**
- `cognito-idp:CreateUserPool`
- `cognito-idp:CreateUserPoolClient`
- `cognito-identity:CreateIdentityPool`

---

### 6. IAM Roles & Policies

#### Required Roles
1. **Lambda Execution Role**
   - Trust: Lambda service
   - Policies: S3 access, DynamoDB access, CloudWatch Logs

2. **API Gateway Execution Role**
   - Trust: API Gateway service
   - Policies: Lambda invoke, CloudWatch Logs

3. **Cognito Authenticated Role**
   - Trust: Cognito Identity Pool
   - Policies: API Gateway invoke, S3 read/write

**Permissions Needed:**
- `iam:CreateRole`
- `iam:AttachRolePolicy`
- `iam:PutRolePolicy`
- `iam:PassRole`

---

### 7. Monitoring & Logging

#### CloudWatch
**Purpose:** Application monitoring, logging, and alerting

**Required Resources:**
- Log Groups: `/aws/lambda/hri-fast-scanner-*`
- Metrics: Custom application metrics
- Alarms: Error rate, latency, availability

**Permissions Needed:**
- `logs:CreateLogGroup`
- `logs:PutLogStream`
- `logs:PutLogEvents`
- `cloudwatch:PutMetricData`
- `cloudwatch:PutMetricAlarm`

---

### 8. Networking (Optional)

#### VPC Configuration
**Purpose:** Secure network isolation (if required)

**Required Resources:**
- VPC: `hri-fast-scanner-vpc`
- Subnets: Public and private subnets
- Security Groups: Lambda, RDS (if used)
- NAT Gateway: For Lambda internet access

**Permissions Needed:**
- `ec2:CreateVpc`
- `ec2:CreateSubnet`
- `ec2:CreateSecurityGroup`
- `ec2:AuthorizeSecurityGroupIngress`

---

## Infrastructure as Code Options

### Option 1: AWS CloudFormation
**Recommended for:** Traditional AWS deployments

**Template Structure:**
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: HRI FAST Scanner Application

Parameters:
  Environment:
    Type: String
    Default: dev
    AllowedValues: [dev, test, prod]

Resources:
  # S3 Buckets
  DocumentsBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub hri-fast-scanner-documents-${Environment}
      VersioningConfiguration:
        Status: Enabled
      EncryptionConfiguration:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: AES256

  # DynamoDB Tables
  ScansTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: !Sub hri-fast-scanner-scans-${Environment}
      BillingMode: PAY_PER_REQUEST
      AttributeDefinitions:
        - AttributeName: scanId
          AttributeType: S
      KeySchema:
        - AttributeName: scanId
          KeyType: HASH

  # Lambda Functions
  ApiHandlerFunction:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: !Sub hri-fast-scanner-api-handler-${Environment}
      Runtime: python3.12
      Handler: index.handler
      Role: !GetAtt LambdaExecutionRole.Arn
      Code:
        ZipFile: |
          def handler(event, context):
              return {'statusCode': 200, 'body': 'Hello from HRI FAST Scanner'}

  # IAM Roles
  LambdaExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
      Policies:
        - PolicyName: HRIFastScannerPolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - s3:GetObject
                  - s3:PutObject
                Resource: !Sub ${DocumentsBucket.Arn}/*
              - Effect: Allow
                Action:
                  - dynamodb:PutItem
                  - dynamodb:GetItem
                  - dynamodb:Query
                Resource: !GetAtt ScansTable.Arn

  # API Gateway
  RestApi:
    Type: AWS::ApiGateway::RestApi
    Properties:
      Name: !Sub hri-fast-scanner-api-${Environment}
      Description: HRI FAST Scanner REST API

Outputs:
  ApiEndpoint:
    Description: API Gateway endpoint URL
    Value: !Sub https://${RestApi}.execute-api.${AWS::Region}.amazonaws.com/${Environment}
  DocumentsBucketName:
    Description: S3 bucket for documents
    Value: !Ref DocumentsBucket
```

**Permissions Needed:**
- `cloudformation:CreateStack`
- `cloudformation:UpdateStack`
- `cloudformation:DescribeStacks`
- All permissions for resources in template

---

### Option 2: AWS CDK (Cloud Development Kit)
**Recommended for:** Modern, programmatic infrastructure

**Example (Python):**
```python
from aws_cdk import (
    Stack,
    aws_s3 as s3,
    aws_lambda as lambda_,
    aws_dynamodb as dynamodb,
    aws_apigateway as apigateway,
    aws_iam as iam,
)
from constructs import Construct

class HriFastScannerStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # S3 Bucket for documents
        documents_bucket = s3.Bucket(
            self, "DocumentsBucket",
            bucket_name=f"hri-fast-scanner-documents-{self.account}",
            versioned=True,
            encryption=s3.BucketEncryption.S3_MANAGED,
        )

        # DynamoDB Table for scans
        scans_table = dynamodb.Table(
            self, "ScansTable",
            table_name="hri-fast-scanner-scans",
            partition_key=dynamodb.Attribute(
                name="scanId",
                type=dynamodb.AttributeType.STRING
            ),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
        )

        # Lambda Function
        api_handler = lambda_.Function(
            self, "ApiHandler",
            function_name="hri-fast-scanner-api-handler",
            runtime=lambda_.Runtime.PYTHON_3_12,
            handler="index.handler",
            code=lambda_.Code.from_asset("lambda"),
        )

        # Grant permissions
        documents_bucket.grant_read_write(api_handler)
        scans_table.grant_read_write_data(api_handler)

        # API Gateway
        api = apigateway.RestApi(
            self, "HriFastScannerApi",
            rest_api_name="hri-fast-scanner-api",
        )

        # Add Lambda integration
        scan_resource = api.root.add_resource("scan")
        scan_resource.add_method(
            "POST",
            apigateway.LambdaIntegration(api_handler)
        )
```

**Permissions Needed:**
- Same as CloudFormation
- `sts:AssumeRole` (for CDK bootstrap)

---

### Option 3: Terraform
**Recommended for:** Multi-cloud or existing Terraform infrastructure

**Example:**
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# S3 Bucket
resource "aws_s3_bucket" "documents" {
  bucket = "hri-fast-scanner-documents-${var.environment}"

  tags = {
    Name        = "HRI FAST Scanner Documents"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id

  versioning_configuration {
    status = "Enabled"
  }
}

# DynamoDB Table
resource "aws_dynamodb_table" "scans" {
  name           = "hri-fast-scanner-scans-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "scanId"

  attribute {
    name = "scanId"
    type = "S"
  }

  tags = {
    Name        = "HRI FAST Scanner Scans"
    Environment = var.environment
  }
}

# Lambda Function
resource "aws_lambda_function" "api_handler" {
  filename      = "lambda_function.zip"
  function_name = "hri-fast-scanner-api-handler-${var.environment}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "python3.12"

  environment {
    variables = {
      DOCUMENTS_BUCKET = aws_s3_bucket.documents.id
      SCANS_TABLE      = aws_dynamodb_table.scans.name
    }
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "hri-fast-scanner-lambda-exec-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
```

---

## Required Permissions for Setup

### Minimum IAM Policy for Deployment

To deploy the HRI FAST Scanner application, you need a role with these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3Permissions",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:PutBucketPolicy",
        "s3:PutBucketVersioning",
        "s3:PutEncryptionConfiguration",
        "s3:PutBucketPublicAccessBlock"
      ],
      "Resource": [
        "arn:aws:s3:::hri-fast-scanner-*",
        "arn:aws:s3:::hri-fast-scanner-*/*"
      ]
    },
    {
      "Sid": "LambdaPermissions",
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:AddPermission",
        "lambda:GetFunction",
        "lambda:DeleteFunction",
        "lambda:PublishVersion",
        "lambda:CreateAlias"
      ],
      "Resource": "arn:aws:lambda:*:212114479343:function:hri-fast-scanner-*"
    },
    {
      "Sid": "APIGatewayPermissions",
      "Effect": "Allow",
      "Action": [
        "apigateway:POST",
        "apigateway:PUT",
        "apigateway:PATCH",
        "apigateway:DELETE",
        "apigateway:GET",
        "apigateway:CreateDeployment",
        "apigateway:CreateStage",
        "apigateway:UpdateStage"
      ],
      "Resource": "arn:aws:apigateway:*::/restapis/*"
    },
    {
      "Sid": "DynamoDBPermissions",
      "Effect": "Allow",
      "Action": [
        "dynamodb:CreateTable",
        "dynamodb:UpdateTable",
        "dynamodb:DeleteTable",
        "dynamodb:DescribeTable",
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:212114479343:table/hri-fast-scanner-*"
    },
    {
      "Sid": "IAMPermissions",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PutRolePolicy",
        "iam:PassRole",
        "iam:GetRole",
        "iam:DeleteRole",
        "iam:DetachRolePolicy",
        "iam:DeleteRolePolicy"
      ],
      "Resource": "arn:aws:iam::212114479343:role/hri-fast-scanner-*"
    },
    {
      "Sid": "CloudWatchPermissions",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "cloudwatch:PutMetricData",
        "cloudwatch:PutMetricAlarm"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudFormationPermissions",
      "Effect": "Allow",
      "Action": [
        "cloudformation:CreateStack",
        "cloudformation:UpdateStack",
        "cloudformation:DeleteStack",
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackEvents",
        "cloudformation:DescribeStackResources",
        "cloudformation:GetTemplate"
      ],
      "Resource": "arn:aws:cloudformation:*:212114479343:stack/hri-fast-scanner-*/*"
    },
    {
      "Sid": "CognitoPermissions",
      "Effect": "Allow",
      "Action": [
        "cognito-idp:CreateUserPool",
        "cognito-idp:CreateUserPoolClient",
        "cognito-idp:UpdateUserPool",
        "cognito-idp:DeleteUserPool",
        "cognito-identity:CreateIdentityPool",
        "cognito-identity:UpdateIdentityPool",
        "cognito-identity:DeleteIdentityPool"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## Recommended Approach

### Step 1: Request Elevated Permissions

**Contact:** Your AWS account administrator or IAM team

**Request:** Create a new IAM role or policy with deployment permissions

**Suggested Role Name:** `HRI-FAST-Scanner-Deployer`

**Justification:**
- Need to deploy HRI FAST Scanner application
- Current role (WAFandViewOnly) is read-only
- Require permissions for S3, Lambda, API Gateway, DynamoDB, IAM, CloudFormation

---

### Step 2: Choose Deployment Method

**Recommended:** AWS CloudFormation or AWS CDK

**Reasons:**
- Infrastructure as Code (version control)
- Repeatable deployments
- Easy rollback
- Built-in dependency management
- AWS native

---

### Step 3: Prepare Application Code

**Required Components:**
1. **Lambda Functions** - Python/Node.js code
2. **Frontend** - React/Angular/Vue application
3. **API Specifications** - OpenAPI/Swagger definitions
4. **Database Schemas** - DynamoDB table definitions
5. **Configuration** - Environment variables, secrets

---

### Step 4: Deploy Infrastructure

**Using CloudFormation:**
```bash
# Validate template
aws cloudformation validate-template --template-body file://hri-fast-scanner.yaml

# Create stack
aws cloudformation create-stack \
  --stack-name hri-fast-scanner-dev \
  --template-body file://hri-fast-scanner.yaml \
  --parameters ParameterKey=Environment,ParameterValue=dev \
  --capabilities CAPABILITY_IAM

# Monitor deployment
aws cloudformation describe-stacks --stack-name hri-fast-scanner-dev
```

**Using CDK:**
```bash
# Install CDK
npm install -g aws-cdk

# Bootstrap CDK (first time only)
cdk bootstrap

# Deploy stack
cdk deploy HriFastScannerStack
```

---

### Step 5: Configure Application

**Post-Deployment Tasks:**
1. Upload Lambda function code
2. Configure API Gateway endpoints
3. Set up Cognito user pool
4. Configure environment variables
5. Test API endpoints
6. Deploy frontend to S3
7. Configure CloudFront (if needed)

---

## Cost Estimate

### Monthly Cost Breakdown (Development Environment)

| Service | Usage | Monthly Cost |
|---------|-------|--------------|
| **S3** | 10 GB storage, 1,000 requests | $0.25 |
| **Lambda** | 1M requests, 512 MB, 1s avg | $20.00 |
| **API Gateway** | 1M requests | $3.50 |
| **DynamoDB** | On-demand, 1M reads/writes | $1.25 |
| **CloudWatch** | Logs, metrics, alarms | $5.00 |
| **Cognito** | 1,000 MAU | Free |
| **Data Transfer** | 10 GB out | $0.90 |
| **Total** | | **~$31/month** |

### Production Environment (Estimated)
- **Monthly Cost:** $150-300/month
- **Depends on:** Traffic volume, data storage, processing requirements

---

## Security Considerations

### 1. Data Encryption
- **At Rest:** Enable S3 encryption, DynamoDB encryption
- **In Transit:** Use HTTPS for all API calls
- **Secrets:** Store in AWS Secrets Manager or Parameter Store

### 2. Access Control
- **Principle of Least Privilege:** Grant minimum required permissions
- **IAM Roles:** Use roles instead of access keys
- **Cognito:** Implement user authentication and authorization

### 3. Compliance
- **HIPAA:** If handling PHI, ensure HIPAA compliance
- **Audit Logging:** Enable CloudTrail for all API calls
- **Data Retention:** Implement lifecycle policies

---

## Next Steps

### Immediate Actions

1. **Request Permissions**
   - Contact: AWS account administrator
   - Request: Deployment role with required permissions
   - Timeline: 1-2 business days

2. **Prepare Application Code**
   - Gather: Lambda functions, frontend code, API specs
   - Review: Ensure code is ready for deployment
   - Test: Local testing before deployment

3. **Choose Deployment Method**
   - Decision: CloudFormation vs CDK vs Terraform
   - Prepare: Templates or code
   - Review: With team for approval

4. **Plan Deployment**
   - Environment: Start with dev
   - Timeline: 1-2 weeks for initial deployment
   - Testing: Plan for thorough testing

### Week 1: Setup & Preparation
- [ ] Request elevated IAM permissions
- [ ] Review application requirements
- [ ] Choose deployment method (CloudFormation/CDK)
- [ ] Prepare infrastructure templates
- [ ] Set up development environment

### Week 2: Infrastructure Deployment
- [ ] Deploy S3 buckets
- [ ] Create DynamoDB tables
- [ ] Deploy Lambda functions
- [ ] Configure API Gateway
- [ ] Set up Cognito user pool

### Week 3: Application Deployment
- [ ] Upload Lambda code
- [ ] Deploy frontend to S3
- [ ] Configure API endpoints
- [ ] Test end-to-end functionality
- [ ] Set up monitoring and alarms

### Week 4: Testing & Optimization
- [ ] Perform integration testing
- [ ] Load testing
- [ ] Security review
- [ ] Cost optimization
- [ ] Documentation

---

## Support & Resources

### AWS Documentation
- [Lambda Developer Guide](https://docs.aws.amazon.com/lambda/)
- [API Gateway Developer Guide](https://docs.aws.amazon.com/apigateway/)
- [DynamoDB Developer Guide](https://docs.aws.amazon.com/dynamodb/)
- [CloudFormation User Guide](https://docs.aws.amazon.com/cloudformation/)
- [CDK Developer Guide](https://docs.aws.amazon.com/cdk/)

### Contact Information
- **AWS Support:** Open support case in AWS Console
- **Account Administrator:** Request permissions escalation
- **Development Team:** Coordinate deployment timeline

---

## Summary

### Current Status
- ✅ **Read Access:** You have ViewOnlyAccess to AWS resources
- ❌ **Write Access:** You cannot create or modify resources
- ✅ **Well-Architected:** Full access to Well-Architected Tool

### What You Need
1. **Elevated Permissions:** Deployment role with create/update/delete permissions
2. **Application Code:** Lambda functions, frontend, API specs
3. **Deployment Method:** CloudFormation, CDK, or Terraform
4. **Timeline:** 2-4 weeks for complete deployment

### Recommended Path Forward
1. Request deployment permissions from AWS administrator
2. Prepare application code and infrastructure templates
3. Deploy to development environment first
4. Test thoroughly before production deployment
5. Implement monitoring and cost optimization

---

**💡 KEY INSIGHT:** Your current role (WAFandViewOnly) provides read-only access. To deploy the HRI FAST Scanner application, you need a deployment role with permissions to create S3 buckets, Lambda functions, API Gateway, DynamoDB tables, and IAM roles. Request elevated permissions from your AWS account administrator to proceed with deployment.
