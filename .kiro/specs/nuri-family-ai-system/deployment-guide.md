# Deployment Guide: Nuri Family AI System

## Prerequisites

### Required Tools
- AWS CLI v2.x configured with appropriate permissions
- Node.js 18+ and npm/yarn
- Docker (for local development)
- Git

### AWS Permissions Required
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:*",
        "lambda:*",
        "dynamodb:*",
        "cloudformation:*",
        "s3:*",
        "cloudfront:*",
        "secretsmanager:*",
        "iam:*",
        "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Quick Start Deployment

### 1. Clone and Setup
```bash
git clone <repository-url> nuri-family-ai
cd nuri-family-ai

# Install dependencies
cd backend && npm install
cd ../frontend && npm install
cd ..
```

### 2. Configure Environment
```bash
# Copy environment templates
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env

# Edit configuration files with your AWS settings
```

### 3. Deploy Infrastructure
```bash
# Deploy using CloudFormation
cd infrastructure
aws cloudformation deploy \
  --template-file cloudformation/main.yaml \
  --stack-name nuri-family-ai-prod \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    Environment=production \
    DomainName=your-domain.com
```

### 4. Deploy Application
```bash
# Build and deploy backend
cd backend
npm run build
npm run deploy:prod

# Build and deploy frontend
cd ../frontend
npm run build
aws s3 sync dist/ s3://your-frontend-bucket --delete
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
```

## Detailed Deployment Steps

### Step 1: AWS Account Setup

#### Enable Required Services
```bash
# Enable Bedrock in your region
aws bedrock list-foundation-models --region us-east-1

# Request model access if needed
aws bedrock put-model-invocation-logging-configuration \
  --logging-config cloudWatchConfig='{logGroupName="/aws/bedrock/modelinvocations",roleArn="arn:aws:iam::ACCOUNT:role/BedrockLoggingRole"}'
```

#### Create IAM Roles
```bash
# Create execution role for Lambda functions
aws iam create-role \
  --role-name NuriLambdaExecutionRole \
  --assume-role-policy-document file://iam/lambda-trust-policy.json

aws iam attach-role-policy \
  --role-name NuriLambdaExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam put-role-policy \
  --role-name NuriLambdaExecutionRole \
  --policy-name NuriBedrockAccess \
  --policy-document file://iam/bedrock-policy.json
```

### Step 2: Secrets Management

#### Create JWT Secret
```bash
# Generate and store JWT secret
JWT_SECRET=$(openssl rand -base64 32)
aws secretsmanager create-secret \
  --name "nuri/jwt-secret" \
  --description "JWT signing secret for Nuri Family AI" \
  --secret-string "{\"secret\":\"$JWT_SECRET\"}"
```

#### Store Database Credentials (if using RDS)
```bash
aws secretsmanager create-secret \
  --name "nuri/database-credentials" \
  --description "Database credentials for Nuri Family AI" \
  --secret-string '{"username":"admin","password":"your-secure-password"}'
```

### Step 3: Infrastructure Deployment

#### Deploy Core Infrastructure
```yaml
# infrastructure/cloudformation/main.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Nuri Family AI System - Core Infrastructure'

Parameters:
  Environment:
    Type: String
    Default: production
    AllowedValues: [development, staging, production]
  
  DomainName:
    Type: String
    Description: Domain name for the application

Resources:
  # DynamoDB Tables
  ConversationTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: !Sub 'nuri-conversations-${Environment}'
      BillingMode: PAY_PER_REQUEST
      AttributeDefinitions:
        - AttributeName: sessionId
          AttributeType: S
        - AttributeName: timestamp
          AttributeType: N
      KeySchema:
        - AttributeName: sessionId
          KeyType: HASH
        - AttributeName: timestamp
          KeyType: RANGE
      TimeToLiveSpecification:
        AttributeName: ttl
        Enabled: true
      StreamSpecification:
        StreamViewType: NEW_AND_OLD_IMAGES

  UserMemoryTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: !Sub 'nuri-user-memory-${Environment}'
      BillingMode: PAY_PER_REQUEST
      AttributeDefinitions:
        - AttributeName: userId
          AttributeType: S
      KeySchema:
        - AttributeName: userId
          KeyType: HASH

  # S3 Bucket for Frontend
  FrontendBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'nuri-frontend-${Environment}-${AWS::AccountId}'
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true

  # CloudFront Distribution
  CloudFrontDistribution:
    Type: AWS::CloudFront::Distribution
    Properties:
      DistributionConfig:
        Origins:
          - Id: S3Origin
            DomainName: !GetAtt FrontendBucket.DomainName
            S3OriginConfig:
              OriginAccessIdentity: !Sub 'origin-access-identity/cloudfront/${OriginAccessIdentity}'
        DefaultCacheBehavior:
          TargetOriginId: S3Origin
          ViewerProtocolPolicy: redirect-to-https
          AllowedMethods: [GET, HEAD, OPTIONS]
          CachedMethods: [GET, HEAD]
          CachePolicyId: 658327ea-f89d-4fab-a63d-7e88639e58f6
        Enabled: true
        DefaultRootObject: index.html
        CustomErrorResponses:
          - ErrorCode: 404
            ResponseCode: 200
            ResponsePagePath: /index.html

Outputs:
  ConversationTableName:
    Description: Name of the conversation DynamoDB table
    Value: !Ref ConversationTable
    Export:
      Name: !Sub '${AWS::StackName}-ConversationTable'
  
  UserMemoryTableName:
    Description: Name of the user memory DynamoDB table
    Value: !Ref UserMemoryTable
    Export:
      Name: !Sub '${AWS::StackName}-UserMemoryTable'
  
  FrontendBucketName:
    Description: Name of the frontend S3 bucket
    Value: !Ref FrontendBucket
    Export:
      Name: !Sub '${AWS::StackName}-FrontendBucket'
  
  CloudFrontDistributionId:
    Description: CloudFront distribution ID
    Value: !Ref CloudFrontDistribution
    Export:
      Name: !Sub '${AWS::StackName}-CloudFrontDistribution'
```

#### Deploy Lambda Functions
```bash
# Package and deploy Lambda functions
cd backend
npm run build

# Create deployment package
zip -r deployment.zip dist/ node_modules/

# Deploy chat API function
aws lambda create-function \
  --function-name nuri-chat-api-prod \
  --runtime nodejs18.x \
  --role arn:aws:iam::ACCOUNT:role/NuriLambdaExecutionRole \
  --handler dist/handlers/chat.handler \
  --zip-file fileb://deployment.zip \
  --environment Variables='{
    "BEDROCK_REGION":"us-east-1",
    "DYNAMODB_TABLE":"nuri-conversations-production",
    "JWT_SECRET_ARN":"nuri/jwt-secret"
  }'

# Deploy auth function
aws lambda create-function \
  --function-name nuri-auth-api-prod \
  --runtime nodejs18.x \
  --role arn:aws:iam::ACCOUNT:role/NuriLambdaExecutionRole \
  --handler dist/handlers/auth.handler \
  --zip-file fileb://deployment.zip
```

### Step 4: API Gateway Setup

#### Create REST API
```bash
# Create API Gateway
API_ID=$(aws apigateway create-rest-api \
  --name "nuri-family-ai-prod" \
  --description "Nuri Family AI System API" \
  --query 'id' --output text)

# Get root resource ID
ROOT_ID=$(aws apigateway get-resources \
  --rest-api-id $API_ID \
  --query 'items[0].id' --output text)

# Create /chat resource
CHAT_RESOURCE_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_ID \
  --path-part chat \
  --query 'id' --output text)

# Create POST method for /chat
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $CHAT_RESOURCE_ID \
  --http-method POST \
  --authorization-type NONE

# Integrate with Lambda
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $CHAT_RESOURCE_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:ACCOUNT:function:nuri-chat-api-prod/invocations"

# Deploy API
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod
```

### Step 5: Frontend Deployment

#### Build and Deploy React App
```bash
cd frontend

# Install dependencies
npm install

# Build for production
npm run build

# Deploy to S3
aws s3 sync dist/ s3://nuri-frontend-production-ACCOUNT --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

### Step 6: Configure Bedrock Guardrails

#### Create Content Filter
```bash
# Create guardrail configuration
cat > guardrail-config.json << EOF
{
  "name": "nuri-family-safety-guardrail",
  "description": "Content safety guardrail for Nuri Family AI",
  "contentPolicyConfig": {
    "filtersConfig": [
      {
        "type": "SEXUAL",
        "inputStrength": "HIGH",
        "outputStrength": "HIGH"
      },
      {
        "type": "VIOLENCE",
        "inputStrength": "HIGH",
        "outputStrength": "HIGH"
      },
      {
        "type": "HATE",
        "inputStrength": "HIGH",
        "outputStrength": "HIGH"
      },
      {
        "type": "INSULTS",
        "inputStrength": "MEDIUM",
        "outputStrength": "MEDIUM"
      },
      {
        "type": "MISCONDUCT",
        "inputStrength": "HIGH",
        "outputStrength": "HIGH"
      }
    ]
  },
  "topicPolicyConfig": {
    "topicsConfig": [
      {
        "name": "Financial Advice",
        "definition": "Investment advice, financial planning, or specific financial recommendations",
        "examples": ["Should I invest in stocks?", "How should I plan my retirement?"],
        "type": "DENY"
      },
      {
        "name": "Medical Advice",
        "definition": "Specific medical diagnoses, treatment recommendations, or health advice",
        "examples": ["What medication should I take?", "Do I have a medical condition?"],
        "type": "DENY"
      }
    ]
  },
  "wordPolicyConfig": {
    "wordsConfig": [
      {
        "text": "inappropriate-word-1"
      },
      {
        "text": "inappropriate-word-2"
      }
    ],
    "managedWordListsConfig": [
      {
        "type": "PROFANITY"
      }
    ]
  },
  "sensitiveInformationPolicyConfig": {
    "piiEntitiesConfig": [
      {
        "type": "EMAIL",
        "action": "BLOCK"
      },
      {
        "type": "PHONE",
        "action": "BLOCK"
      },
      {
        "type": "ADDRESS",
        "action": "BLOCK"
      }
    ]
  }
}
EOF

# Create the guardrail
aws bedrock create-guardrail \
  --cli-input-json file://guardrail-config.json
```

## Environment-Specific Configurations

### Development Environment
```bash
# Deploy with development settings
aws cloudformation deploy \
  --template-file cloudformation/main.yaml \
  --stack-name nuri-family-ai-dev \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    Environment=development \
    DomainName=dev.your-domain.com
```

### Staging Environment
```bash
# Deploy with staging settings
aws cloudformation deploy \
  --template-file cloudformation/main.yaml \
  --stack-name nuri-family-ai-staging \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    Environment=staging \
    DomainName=staging.your-domain.com
```

## Post-Deployment Verification

### Health Checks
```bash
# Test API endpoints
curl -X POST https://api.your-domain.com/prod/health
curl -X POST https://api.your-domain.com/prod/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test"}'

# Test frontend
curl -I https://your-domain.com
```

### Monitoring Setup
```bash
# Create CloudWatch alarms
aws cloudwatch put-metric-alarm \
  --alarm-name "nuri-api-errors" \
  --alarm-description "High error rate in Nuri API" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=FunctionName,Value=nuri-chat-api-prod \
  --evaluation-periods 2
```

## Troubleshooting

### Common Issues

#### Lambda Function Timeout
```bash
# Increase timeout
aws lambda update-function-configuration \
  --function-name nuri-chat-api-prod \
  --timeout 30
```

#### DynamoDB Throttling
```bash
# Check metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ThrottledRequests \
  --dimensions Name=TableName,Value=nuri-conversations-production \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Sum
```

#### Bedrock Access Issues
```bash
# Check model access
aws bedrock list-foundation-models --region us-east-1

# Test model invocation
aws bedrock-runtime invoke-model \
  --model-id anthropic.claude-3-sonnet-20240229-v1:0 \
  --body '{"anthropic_version":"bedrock-2023-05-31","max_tokens":100,"messages":[{"role":"user","content":"Hello"}]}' \
  --cli-binary-format raw-in-base64-out \
  response.json
```

## Maintenance and Updates

### Regular Maintenance Tasks
1. Update dependencies monthly
2. Review CloudWatch logs weekly
3. Monitor costs and usage
4. Update security patches
5. Review and update guardrails

### Backup Procedures
```bash
# Backup DynamoDB tables
aws dynamodb create-backup \
  --table-name nuri-conversations-production \
  --backup-name "nuri-conversations-$(date +%Y%m%d)"

aws dynamodb create-backup \
  --table-name nuri-user-memory-production \
  --backup-name "nuri-user-memory-$(date +%Y%m%d)"
```

### Rollback Procedures
```bash
# Rollback Lambda function
aws lambda update-function-code \
  --function-name nuri-chat-api-prod \
  --zip-file fileb://previous-deployment.zip

# Rollback frontend
aws s3 sync s3://nuri-frontend-backup/ s3://nuri-frontend-production-ACCOUNT --delete
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
```