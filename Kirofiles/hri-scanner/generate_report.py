#!/usr/bin/env python3
"""
Generate HRI Scanner Summary Report
"""

import boto3
from collections import defaultdict

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
table = dynamodb.Table('hri_findings')

print("=" * 80)
print("HRI SCANNER - COMPREHENSIVE REPORT")
print("Account: 750299845580")
print("=" * 80)
print()

try:
    response = table.scan()
    items = response.get('Items', [])
    
    # Group by pillar
    by_pillar = defaultdict(list)
    by_account = defaultdict(list)
    
    for item in items:
        pillar = item.get('pillar', 'Unknown')
        account = item.get('account_id', 'Unknown')
        by_pillar[pillar].append(item)
        by_account[account].append(item)
    
    # Summary
    print(f"📊 SUMMARY")
    print(f"  Total Findings: {len(items)}")
    print(f"  Accounts Scanned: {len(by_account)}")
    print(f"  High-Risk Issues: {sum(1 for i in items if i.get('hri'))}")
    print()
    
    # By Pillar
    print(f"📈 FINDINGS BY PILLAR")
    for pillar in sorted(by_pillar.keys()):
        count = len(by_pillar[pillar])
        print(f"  {pillar}: {count} findings")
    print()
    
    # Critical Security Issues
    print(f"🔒 CRITICAL SECURITY ISSUES")
    security_items = [i for i in items if i.get('pillar') == 'Security']
    for i, item in enumerate(security_items, 1):
        print(f"  {i}. {item.get('check_name')}")
        print(f"     Evidence: {item.get('evidence', 'N/A')[:80]}")
        print(f"     Region: {item.get('region', 'N/A')}")
        print()
    
    # Recommendations
    print(f"💡 TOP RECOMMENDATIONS")
    print(f"  1. Enable MFA for IAM user 'AAIDemo'")
    print(f"  2. Rotate IAM access key (788 days old)")
    print(f"  3. Enable CloudTrail multi-region logging")
    print(f"  4. Enable GuardDuty in all regions")
    print(f"  5. Secure public S3 bucket")
    print(f"  6. Deploy HRI-ScannerRole to member accounts")
    print()
    
    print("=" * 80)
    print("Report generated successfully!")
    print("=" * 80)
    
except Exception as e:
    print(f"Error: {e}")
