#!/usr/bin/env python3
"""
Deploy HRI-ScannerRole to member accounts
This creates the cross-account role that Lambda 2 needs to scan accounts
"""

import boto3
import json

MANAGEMENT_ACCOUNT_ID = "750299845580"
ROLE_NAME = "HRI-ScannerRole"


def create_scanner_role_template():
    """Generate CloudFormation template for HRI-ScannerRole"""
    
    trust_policy = {
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {
                "AWS": f"arn:aws:iam::{MANAGEMENT_ACCOUNT_ID}:role/HRIScannerExecutionRole"
            },
            "Action": "sts:AssumeRole"
        }]
    }
    
    permissions_policy = {
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": [
                # S3
                "s3:GetBucketPublicAccessBlock",
                "s3:GetBucketAcl",
                "s3:GetBucketPolicy",
                "s3:ListAllMyBuckets",
                "s3:GetEncryptionConfiguration",
                # EC2
                "ec2:DescribeVolumes",
                "ec2:DescribeInstances",
                "ec2:DescribeVpcs",
                "ec2:DescribeFlowLogs",
                "ec2:DescribeAddresses",
                # RDS
                "rds:DescribeDBInstances",
                "rds:DescribeDBClusters",
                # IAM
                "iam:GetAccountSummary",
                "iam:ListUsers",
                "iam:ListMFADevices",
                "iam:ListAccessKeys",
                "iam:GetAccountPasswordPolicy",
                "iam:GetCredentialReport",
                "iam:GenerateCredentialReport",
                # Security Hub
                "securityhub:GetFindings",
                "securityhub:DescribeHub",
                # Config
                "config:DescribeConfigurationRecorders",
                "config:DescribeDeliveryChannels",
                # CloudWatch
                "cloudwatch:DescribeAlarms",
                "cloudwatch:GetMetricStatistics",
                # GuardDuty
                "guardduty:ListDetectors",
                "guardduty:GetDetector",
                # CloudTrail
                "cloudtrail:DescribeTrails",
                "cloudtrail:GetTrailStatus",
                # Cost Explorer
                "ce:GetCostAndUsage",
                # Compute Optimizer
                "compute-optimizer:GetEC2InstanceRecommendations",
                # Backup
                "backup:ListBackupPlans",
                "backup:ListProtectedResources",
                # Auto Scaling
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribePolicies",
                # ELB
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeTargetHealth",
                # Lambda
                "lambda:ListFunctions",
                "lambda:GetFunction",
                # KMS
                "kms:ListKeys",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        }]
    }
    
    return trust_policy, permissions_policy


def deploy_role_to_current_account():
    """Deploy HRI-ScannerRole to the current AWS account"""
    
    print("=" * 80)
    print("Deploying HRI-ScannerRole")
    print("=" * 80)
    print()
    
    iam = boto3.client('iam')
    sts = boto3.client('sts')
    
    # Get current account
    identity = sts.get_caller_identity()
    current_account = identity['Account']
    
    print(f"Target Account: {current_account}")
    print(f"Management Account: {MANAGEMENT_ACCOUNT_ID}")
    print()
    
    trust_policy, permissions_policy = create_scanner_role_template()
    
    try:
        # Check if role exists
        iam.get_role(RoleName=ROLE_NAME)
        print(f"✓ Role '{ROLE_NAME}' already exists")
        
        # Update trust policy
        iam.update_assume_role_policy(
            RoleName=ROLE_NAME,
            PolicyDocument=json.dumps(trust_policy)
        )
        print("✓ Updated trust policy")
        
    except iam.exceptions.NoSuchEntityException:
        # Create role
        iam.create_role(
            RoleName=ROLE_NAME,
            AssumeRolePolicyDocument=json.dumps(trust_policy),
            Description='Cross-account role for HRI Scanner',
            MaxSessionDuration=3600
        )
        print(f"✓ Created role '{ROLE_NAME}'")
    
    # Attach/update inline policy
    iam.put_role_policy(
        RoleName=ROLE_NAME,
        PolicyName='HRIScannerPermissions',
        PolicyDocument=json.dumps(permissions_policy)
    )
    print("✓ Attached permissions policy")
    
    role_arn = f"arn:aws:iam::{current_account}:role/{ROLE_NAME}"
    
    print()
    print("=" * 80)
    print("Deployment Complete")
    print("=" * 80)
    print(f"Role ARN: {role_arn}")
    print()
    print("The HRI Scanner can now scan this account!")
    print("=" * 80)
    
    return role_arn


if __name__ == '__main__':
    import sys
    try:
        deploy_role_to_current_account()
        sys.exit(0)
    except Exception as e:
        print(f"\n✗ Deployment failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
