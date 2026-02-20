#!/usr/bin/env python3
"""
Helper script to configure AWS credentials
"""

import os
from pathlib import Path

def configure_credentials():
    """Configure AWS credentials interactively"""
    
    print("=" * 80)
    print("AWS Credentials Configuration Helper")
    print("=" * 80)
    print()
    
    # Get credentials
    print("Please provide your AWS credentials:")
    print("(These will be stored in ~/.aws/credentials)")
    print()
    
    access_key = input("AWS Access Key ID: ").strip()
    secret_key = input("AWS Secret Access Key: ").strip()
    region = input("Default region [us-east-1]: ").strip() or "us-east-1"
    
    # Create .aws directory if it doesn't exist
    aws_dir = Path.home() / '.aws'
    aws_dir.mkdir(exist_ok=True)
    
    # Write credentials file
    credentials_file = aws_dir / 'credentials'
    config_file = aws_dir / 'config'
    
    # Backup existing files
    if credentials_file.exists():
        backup = credentials_file.with_suffix('.credentials.backup')
        credentials_file.rename(backup)
        print(f"✓ Backed up existing credentials to {backup}")
    
    # Write new credentials
    with open(credentials_file, 'w') as f:
        f.write(f"""[default]
aws_access_key_id = {access_key}
aws_secret_access_key = {secret_key}
""")
    
    # Write config
    with open(config_file, 'w') as f:
        f.write(f"""[default]
region = {region}
output = json
""")
    
    print()
    print("✓ Credentials configured successfully!")
    print(f"  Credentials file: {credentials_file}")
    print(f"  Config file: {config_file}")
    print()
    
    # Test credentials
    print("Testing credentials...")
    import boto3
    from botocore.exceptions import ClientError
    
    try:
        sts = boto3.client('sts')
        identity = sts.get_caller_identity()
        
        print("✓ Credentials are valid!")
        print()
        print("Identity:")
        print(f"  Account: {identity['Account']}")
        print(f"  User ARN: {identity['Arn']}")
        print(f"  User ID: {identity['UserId']}")
        print()
        
        return True
        
    except ClientError as e:
        print(f"✗ Credentials test failed: {e}")
        print()
        print("Please verify your access key and secret key are correct.")
        return False


if __name__ == '__main__':
    import sys
    success = configure_credentials()
    sys.exit(0 if success else 1)
