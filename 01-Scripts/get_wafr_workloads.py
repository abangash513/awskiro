#!/usr/bin/env python3
"""
Script to retrieve AWS Well-Architected Framework workloads and their ARNs
"""
import boto3
import json
import csv
from datetime import datetime

# Initialize the Well-Architected client
wa_client = boto3.client('wellarchitected')

def list_all_workloads():
    """List all Well-Architected workloads in the account"""
    workloads = []
    next_token = None
    
    print("Fetching Well-Architected workloads...")
    
    try:
        while True:
            if next_token:
                response = wa_client.list_workloads(NextToken=next_token)
            else:
                response = wa_client.list_workloads()
            
            workloads.extend(response.get('WorkloadSummaries', []))
            
            next_token = response.get('NextToken')
            if not next_token:
                break
        
        return workloads
    except Exception as e:
        print(f"Error listing workloads: {e}")
        return []

def get_workload_details(workload_id):
    """Get detailed information about a specific workload"""
    try:
        response = wa_client.get_workload(WorkloadId=workload_id)
        return response.get('Workload', {})
    except Exception as e:
        print(f"Error getting workload details for {workload_id}: {e}")
        return {}

def create_csv_for_partner_central(workloads):
    """Create CSV file in the format required by AWS Partner Central"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"wafr_workloads_for_partner_central_{timestamp}.csv"
    
    # CSV headers - adjust based on Partner Central requirements
    headers = ['ARN', 'WorkloadName', 'WorkloadId', 'Environment', 'Industry', 'Owner', 'ReviewDate']
    
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(headers)
        
        for workload in workloads:
            workload_id = workload.get('WorkloadId', '')
            details = get_workload_details(workload_id)
            
            arn = details.get('WorkloadArn', '')
            name = workload.get('WorkloadName', '')
            environment = workload.get('Environment', '')
            industry = workload.get('Industry', '')
            owner = workload.get('Owner', '')
            updated_at = workload.get('UpdatedAt', '')
            
            writer.writerow([arn, name, workload_id, environment, industry, owner, updated_at])
    
    print(f"\nCSV file created: {filename}")
    return filename

def main():
    print("=" * 80)
    print("AWS Well-Architected Framework Workload Retrieval Tool")
    print("=" * 80)
    
    # List all workloads
    workloads = list_all_workloads()
    
    if not workloads:
        print("\nNo workloads found in this account.")
        return
    
    print(f"\nFound {len(workloads)} workload(s):\n")
    
    # Display workload information
    for idx, workload in enumerate(workloads, 1):
        workload_id = workload.get('WorkloadId', 'N/A')
        workload_name = workload.get('WorkloadName', 'N/A')
        
        print(f"{idx}. Workload Name: {workload_name}")
        print(f"   Workload ID: {workload_id}")
        
        # Get full details including ARN
        details = get_workload_details(workload_id)
        arn = details.get('WorkloadArn', 'N/A')
        
        print(f"   ARN: {arn}")
        print(f"   Environment: {workload.get('Environment', 'N/A')}")
        print(f"   Owner: {workload.get('Owner', 'N/A')}")
        print(f"   Updated: {workload.get('UpdatedAt', 'N/A')}")
        print("-" * 80)
    
    # Create CSV file
    csv_filename = create_csv_for_partner_central(workloads)
    
    print("\n" + "=" * 80)
    print("IMPORTANT: ARN Format for Partner Central")
    print("=" * 80)
    print("The ARN should be in this format:")
    print("arn:aws:wellarchitected:Region:AWS_Account_ID:workload/Workload_ID")
    print("\nThis CSV file is ready to be imported into AWS Partner Central.")
    print("=" * 80)

if __name__ == "__main__":
    main()
