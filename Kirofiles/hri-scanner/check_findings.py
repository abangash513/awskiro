#!/usr/bin/env python3
"""
Check HRI findings in DynamoDB
"""

import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
table = dynamodb.Table('hri_findings')

print("=" * 80)
print("HRI Findings in DynamoDB")
print("=" * 80)
print()

try:
    response = table.scan(Limit=10)
    items = response.get('Items', [])
    
    if not items:
        print("No findings found in DynamoDB")
    else:
        print(f"Found {len(items)} findings:\n")
        
        for i, item in enumerate(items, 1):
            print(f"{i}. Account: {item.get('account_id')}")
            print(f"   Check: {item.get('check_name')}")
            print(f"   Pillar: {item.get('pillar')}")
            print(f"   HRI: {item.get('hri')}")
            print(f"   Evidence: {item.get('evidence', 'N/A')[:100]}")
            print(f"   Timestamp: {item.get('timestamp')}")
            print()
    
    print("=" * 80)
    
except Exception as e:
    print(f"Error: {e}")
