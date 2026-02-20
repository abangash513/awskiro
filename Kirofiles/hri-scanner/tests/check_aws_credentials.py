#!/usr/bin/env python3
"""
Check AWS credentials and configuration
"""

import boto3
from botocore.exceptions import ClientError, NoCredentialsError


def check_credentials():
    """Check if AWS credentials are configured and valid"""
    print("=" * 80)
    print("AWS Credentials Check")
    print("=" * 80)
    print()
    
    try:
        # Try to get caller identity
        sts = boto3.client('sts')
        identity = sts.get_caller_identity()
        
        print("✓ AWS Credentials are configured and valid")
        print()
        print("Current Identity:")
        print(f"  Account: {identity['Account']}")
        print(f"  User ARN: {identity['Arn']}")
        print(f"  User ID: {identity['UserId']}")
        print()
        
        # Check if this is the management account with Organizations access
        try:
            orgs = boto3.client('organizations')
            org_info = orgs.describe_organization()
            
            print("✓ AWS Organizations access confirmed")
            print()
            print("Organization Details:")
            print(f"  Org ID: {org_info['Organization']['Id']}")
            print(f"  Master Account: {org_info['Organization']['MasterAccountId']}")
            print()
            
            return True
            
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', '')
            if error_code == 'AWSOrganizationsNotInUseException':
                print("⚠ This account is not part of an AWS Organization")
                print("  The HRI Scanner requires AWS Organizations to discover member accounts")
            elif error_code == 'AccessDeniedException':
                print("⚠ No permission to access AWS Organizations")
                print("  Ensure the IAM user/role has organizations:DescribeOrganization permission")
            else:
                print(f"⚠ Cannot access AWS Organizations: {e}")
            print()
            return False
            
    except NoCredentialsError:
        print("✗ No AWS credentials found")
        print()
        print("Please configure AWS credentials using one of these methods:")
        print("  1. AWS CLI: aws configure")
        print("  2. Environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY")
        print("  3. AWS credentials file: ~/.aws/credentials")
        print()
        return False
        
    except ClientError as e:
        error_code = e.response.get('Error', {}).get('Code', '')
        if error_code == 'ExpiredToken':
            print("✗ AWS credentials are expired")
            print()
            print("Please refresh your credentials:")
            print("  - If using SSO: aws sso login")
            print("  - If using temporary credentials: generate new credentials")
            print()
        else:
            print(f"✗ Error checking credentials: {e}")
            print()
        return False


if __name__ == '__main__':
    import sys
    success = check_credentials()
    sys.exit(0 if success else 1)
