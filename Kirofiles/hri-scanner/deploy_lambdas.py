#!/usr/bin/env python3
"""
Deploy Lambda functions to AWS
"""

import boto3
import zipfile
import os
import json
from pathlib import Path
from botocore.exceptions import ClientError

ACCOUNT_ID = "750299845580"
REGION = "us-east-1"


def create_lambda_zip(lambda_name: str) -> str:
    """Create deployment package for Lambda function"""
    print(f"\nCreating deployment package for {lambda_name}...")
    
    lambda_dir = Path('hri-scanner/lambda')
    zip_path = lambda_dir / f'{lambda_name}.zip'
    
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        # Add the Lambda function file
        lambda_file = lambda_dir / f'{lambda_name}.py'
        zipf.write(lambda_file, f'{lambda_name}.py')
    
    print(f"✓ Created {zip_path}")
    return str(zip_path)


def create_lambda_execution_role() -> str:
    """Create IAM role for Lambda execution"""
    print("\nCreating Lambda execution role...")
    
    iam = boto3.client('iam', region_name=REGION)
    role_name = 'HRIScannerExecutionRole'
    
    trust_policy = {
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Service": "lambda.amazonaws.com"},
            "Action": "sts:AssumeRole"
        }]
    }
    
    try:
        # Check if role exists
        iam.get_role(RoleName=role_name)
        print(f"✓ Role '{role_name}' already exists")
        
    except ClientError as e:
        if e.response['Error']['Code'] == 'NoSuchEntity':
            # Create role
            iam.create_role(
                RoleName=role_name,
                AssumeRolePolicyDocument=json.dumps(trust_policy),
                Description='Execution role for HRI Scanner Lambda functions'
            )
            print(f"✓ Created role '{role_name}'")
            
            # Attach policies
            policies = [
                'arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole',
                'arn:aws:iam::aws:policy/AWSOrganizationsReadOnlyAccess'
            ]
            
            for policy_arn in policies:
                iam.attach_role_policy(RoleName=role_name, PolicyArn=policy_arn)
                print(f"✓ Attached policy {policy_arn}")
            
            # Add inline policy for DynamoDB, S3, Lambda, STS
            inline_policy = {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Action": [
                            "dynamodb:PutItem",
                            "dynamodb:UpdateItem",
                            "dynamodb:GetItem",
                            "dynamodb:Query",
                            "dynamodb:Scan"
                        ],
                        "Resource": f"arn:aws:dynamodb:{REGION}:{ACCOUNT_ID}:table/hri_findings"
                    },
                    {
                        "Effect": "Allow",
                        "Action": [
                            "s3:PutObject",
                            "s3:GetObject"
                        ],
                        "Resource": f"arn:aws:s3:::hri-exports-{ACCOUNT_ID}-{REGION}/*"
                    },
                    {
                        "Effect": "Allow",
                        "Action": "lambda:InvokeFunction",
                        "Resource": f"arn:aws:lambda:{REGION}:{ACCOUNT_ID}:function:hri-*"
                    },
                    {
                        "Effect": "Allow",
                        "Action": "sts:AssumeRole",
                        "Resource": "arn:aws:iam::*:role/HRI-ScannerRole"
                    }
                ]
            }
            
            iam.put_role_policy(
                RoleName=role_name,
                PolicyName='HRIScannerPolicy',
                PolicyDocument=json.dumps(inline_policy)
            )
            print("✓ Added inline policy")
            
            # Wait for role to propagate
            print("  Waiting for role to propagate...")
            import time
            time.sleep(10)
        else:
            raise
    
    role_arn = f"arn:aws:iam::{ACCOUNT_ID}:role/{role_name}"
    return role_arn


def deploy_lambda(function_name: str, handler: str, zip_path: str, role_arn: str, 
                  memory: int, timeout: int, env_vars: dict) -> str:
    """Deploy or update Lambda function"""
    print(f"\nDeploying Lambda function: {function_name}...")
    
    lambda_client = boto3.client('lambda', region_name=REGION)
    
    with open(zip_path, 'rb') as f:
        zip_content = f.read()
    
    try:
        # Try to update existing function
        response = lambda_client.update_function_code(
            FunctionName=function_name,
            ZipFile=zip_content
        )
        print(f"✓ Updated function code for {function_name}")
        
        # Update configuration
        lambda_client.update_function_configuration(
            FunctionName=function_name,
            Runtime='python3.12',
            Handler=handler,
            Role=role_arn,
            Timeout=timeout,
            MemorySize=memory,
            Environment={'Variables': env_vars}
        )
        print(f"✓ Updated function configuration for {function_name}")
        
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            # Create new function
            response = lambda_client.create_function(
                FunctionName=function_name,
                Runtime='python3.12',
                Role=role_arn,
                Handler=handler,
                Code={'ZipFile': zip_content},
                Timeout=timeout,
                MemorySize=memory,
                Environment={'Variables': env_vars},
                Description=f'HRI Scanner - {function_name}'
            )
            print(f"✓ Created function {function_name}")
        else:
            raise
    
    function_arn = response['FunctionArn']
    return function_arn


def main():
    """Main deployment function"""
    print("=" * 80)
    print("HRI Scanner - Lambda Deployment")
    print(f"Account: {ACCOUNT_ID}")
    print(f"Region: {REGION}")
    print("=" * 80)
    
    try:
        # Step 1: Create IAM role
        role_arn = create_lambda_execution_role()
        
        # Step 2: Deploy Lambda 1 (discover_accounts)
        zip1 = create_lambda_zip('discover_accounts')
        lambda1_arn = deploy_lambda(
            function_name='hri-discover-accounts',
            handler='discover_accounts.lambda_handler',
            zip_path=zip1,
            role_arn=role_arn,
            memory=256,
            timeout=120,
            env_vars={
                'SCAN_LAMBDA_ARN': f'arn:aws:lambda:{REGION}:{ACCOUNT_ID}:function:hri-scan-account',
                'DYNAMODB_TABLE': 'hri_findings',
                'LOG_LEVEL': 'INFO'
            }
        )
        
        # Step 3: Deploy Lambda 2 (scan_account)
        zip2 = create_lambda_zip('scan_account')
        lambda2_arn = deploy_lambda(
            function_name='hri-scan-account',
            handler='scan_account.lambda_handler',
            zip_path=zip2,
            role_arn=role_arn,
            memory=1024,
            timeout=600,
            env_vars={
                'SCANNER_ROLE_NAME': 'HRI-ScannerRole',
                'DYNAMODB_TABLE': 'hri_findings',
                'S3_BUCKET': f'hri-exports-{ACCOUNT_ID}-{REGION}',
                'REGIONS': 'us-east-1,us-west-2',
                'LOG_LEVEL': 'INFO'
            }
        )
        
        # Summary
        print("\n" + "=" * 80)
        print("Deployment Summary")
        print("=" * 80)
        print(f"✓ IAM Role: {role_arn}")
        print(f"✓ Lambda 1: {lambda1_arn}")
        print(f"✓ Lambda 2: {lambda2_arn}")
        print("\nNext Steps:")
        print("1. Test Lambda 1: aws lambda invoke --function-name hri-discover-accounts response.json")
        print("2. Deploy HRI-ScannerRole to member accounts")
        print("3. Set up EventBridge schedule")
        print("=" * 80)
        
        return True
        
    except Exception as e:
        print(f"\n✗ Deployment failed: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == '__main__':
    import sys
    success = main()
    sys.exit(0 if success else 1)
