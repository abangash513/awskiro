#!/usr/bin/env python3
"""
Quick deployment script for HRI Scanner
Target Account: 750299845580
"""

import boto3
import json
import sys
from botocore.exceptions import ClientError

ACCOUNT_ID = "750299845580"
REGION = "us-east-1"
TABLE_NAME = "hri_findings"
BUCKET_NAME = f"hri-exports-{ACCOUNT_ID}-{REGION}"


def check_credentials():
    """Check if AWS credentials are valid"""
    try:
        sts = boto3.client('sts')
        identity = sts.get_caller_identity()
        print(f"✓ Authenticated as: {identity['Arn']}")
        print(f"✓ Account: {identity['Account']}")
        return identity['Account'] == ACCOUNT_ID
    except ClientError as e:
        print(f"✗ Credential error: {e}")
        return False


def create_dynamodb_table():
    """Create DynamoDB table for findings"""
    print("\n" + "=" * 80)
    print("Creating DynamoDB Table")
    print("=" * 80)
    
    dynamodb = boto3.client('dynamodb', region_name=REGION)
    
    try:
        # Check if table exists
        dynamodb.describe_table(TableName=TABLE_NAME)
        print(f"✓ Table '{TABLE_NAME}' already exists")
        return True
    except ClientError as e:
        if e.response['Error']['Code'] != 'ResourceNotFoundException':
            print(f"✗ Error checking table: {e}")
            return False
    
    # Create table
    try:
        response = dynamodb.create_table(
            TableName=TABLE_NAME,
            KeySchema=[
                {'AttributeName': 'account_id', 'KeyType': 'HASH'},
                {'AttributeName': 'check_id', 'KeyType': 'RANGE'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'account_id', 'AttributeType': 'S'},
                {'AttributeName': 'check_id', 'AttributeType': 'S'},
                {'AttributeName': 'pillar', 'AttributeType': 'S'},
                {'AttributeName': 'timestamp', 'AttributeType': 'S'},
                {'AttributeName': 'execution_id', 'AttributeType': 'S'}
            ],
            BillingMode='PAY_PER_REQUEST',
            GlobalSecondaryIndexes=[
                {
                    'IndexName': 'pillar-timestamp-index',
                    'KeySchema': [
                        {'AttributeName': 'pillar', 'KeyType': 'HASH'},
                        {'AttributeName': 'timestamp', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'execution-timestamp-index',
                    'KeySchema': [
                        {'AttributeName': 'execution_id', 'KeyType': 'HASH'},
                        {'AttributeName': 'timestamp', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                }
            ]
        )
        print(f"✓ Table '{TABLE_NAME}' created successfully")
        print("  Waiting for table to become active...")
        
        waiter = dynamodb.get_waiter('table_exists')
        waiter.wait(TableName=TABLE_NAME)
        print("✓ Table is now active")
        return True
        
    except ClientError as e:
        print(f"✗ Failed to create table: {e}")
        return False


def create_s3_bucket():
    """Create S3 bucket for reports"""
    print("\n" + "=" * 80)
    print("Creating S3 Bucket")
    print("=" * 80)
    
    s3 = boto3.client('s3', region_name=REGION)
    
    try:
        # Check if bucket exists
        s3.head_bucket(Bucket=BUCKET_NAME)
        print(f"✓ Bucket '{BUCKET_NAME}' already exists")
        return True
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code != '404':
            print(f"✗ Error checking bucket: {e}")
            return False
    
    # Create bucket
    try:
        if REGION == 'us-east-1':
            s3.create_bucket(Bucket=BUCKET_NAME)
        else:
            s3.create_bucket(
                Bucket=BUCKET_NAME,
                CreateBucketConfiguration={'LocationConstraint': REGION}
            )
        print(f"✓ Bucket '{BUCKET_NAME}' created successfully")
        
        # Enable encryption
        s3.put_bucket_encryption(
            Bucket=BUCKET_NAME,
            ServerSideEncryptionConfiguration={
                'Rules': [{
                    'ApplyServerSideEncryptionByDefault': {
                        'SSEAlgorithm': 'AES256'
                    }
                }]
            }
        )
        print("✓ Encryption enabled")
        
        # Enable versioning
        s3.put_bucket_versioning(
            Bucket=BUCKET_NAME,
            VersioningConfiguration={'Status': 'Enabled'}
        )
        print("✓ Versioning enabled")
        
        return True
        
    except ClientError as e:
        print(f"✗ Failed to create bucket: {e}")
        return False


def main():
    """Main deployment function"""
    print("=" * 80)
    print("HRI Scanner Deployment")
    print(f"Target Account: {ACCOUNT_ID}")
    print(f"Region: {REGION}")
    print("=" * 80)
    
    # Step 1: Check credentials
    print("\nStep 1: Checking AWS credentials...")
    if not check_credentials():
        print("\n✗ Deployment failed: Invalid or expired credentials")
        print("\nPlease run: aws sso login")
        return False
    
    # Step 2: Create DynamoDB table
    print("\nStep 2: Creating DynamoDB table...")
    if not create_dynamodb_table():
        print("\n✗ Deployment failed: Could not create DynamoDB table")
        return False
    
    # Step 3: Create S3 bucket
    print("\nStep 3: Creating S3 bucket...")
    if not create_s3_bucket():
        print("\n✗ Deployment failed: Could not create S3 bucket")
        return False
    
    # Summary
    print("\n" + "=" * 80)
    print("Deployment Summary")
    print("=" * 80)
    print(f"✓ DynamoDB Table: {TABLE_NAME}")
    print(f"✓ S3 Bucket: {BUCKET_NAME}")
    print("\nNext Steps:")
    print("1. Deploy Lambda functions (see DEPLOYMENT.md)")
    print("2. Create IAM roles for Lambda execution")
    print("3. Deploy HRI-ScannerRole to member accounts")
    print("4. Test the deployment")
    print("=" * 80)
    
    return True


if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
