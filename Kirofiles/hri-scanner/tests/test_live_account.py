#!/usr/bin/env python3
"""
Live test script for HRI Scanner against AWS account 750299845580
This script tests the discover_accounts function with real AWS credentials
"""

import json
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'lambda'))

# Set environment variables for testing
os.environ['LOG_LEVEL'] = 'INFO'
os.environ['SCAN_LAMBDA_ARN'] = 'arn:aws:lambda:us-east-1:750299845580:function:scan_account'  # Placeholder

from discover_accounts import (
    list_accounts_with_pagination,
    filter_active_accounts,
    extract_account_metadata
)


def test_account_discovery():
    """Test account discovery against live AWS account"""
    print("=" * 80)
    print("HRI Scanner - Live Account Discovery Test")
    print("Target Account: 750299845580")
    print("=" * 80)
    print()
    
    try:
        # Test 1: List all accounts
        print("Test 1: Listing all accounts from AWS Organizations...")
        accounts = list_accounts_with_pagination()
        print(f"✓ Successfully discovered {len(accounts)} accounts")
        print()
        
        # Test 2: Filter active accounts
        print("Test 2: Filtering for ACTIVE accounts...")
        active_accounts = filter_active_accounts(accounts)
        print(f"✓ Found {len(active_accounts)} active accounts")
        print()
        
        # Test 3: Extract metadata
        print("Test 3: Extracting account metadata...")
        for i, account in enumerate(active_accounts[:5], 1):  # Show first 5
            metadata = extract_account_metadata(account)
            print(f"  Account {i}:")
            print(f"    ID: {metadata['account_id']}")
            print(f"    Name: {metadata['account_name']}")
            print(f"    OU: {metadata['organizational_unit']}")
        
        if len(active_accounts) > 5:
            print(f"  ... and {len(active_accounts) - 5} more accounts")
        print()
        
        # Summary
        print("=" * 80)
        print("Test Summary:")
        print(f"  Total accounts discovered: {len(accounts)}")
        print(f"  Active accounts: {len(active_accounts)}")
        print(f"  Inactive accounts: {len(accounts) - len(active_accounts)}")
        print("=" * 80)
        print()
        print("✓ All tests passed successfully!")
        
        return True
        
    except Exception as e:
        print(f"✗ Test failed: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == '__main__':
    success = test_account_discovery()
    sys.exit(0 if success else 1)
