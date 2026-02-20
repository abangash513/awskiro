#!/usr/bin/env python3
"""
WAFOps Lambda 1: discover_accounts
Purpose: Discover all active member accounts in AWS Organization
"""

import json
import os
import uuid
import logging
from typing import Dict, List, Any
import boto3
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Initialize AWS clients
organizations_client = boto3.client('organizations')
lambda_client = boto3.client('lambda')


def retry_with_exponential_backoff(func, max_retries=3, base_delay=1):
    """
    Retry function with exponential backoff
    Validates: Requirements 1.5
    """
    import time
    import random
    
    for attempt in range(max_retries):
        try:
            return func()
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', '')
            if error_code in ['ThrottlingException', 'TooManyRequestsException', 'ServiceUnavailable']:
                if attempt == max_retries - 1:
                    raise
                delay = base_delay * (2 ** attempt) + random.uniform(0, 1)
                logger.warning(f"Retry {attempt + 1}/{max_retries} after {delay:.2f}s due to {error_code}")
                time.sleep(delay)
            else:
                raise
    

def list_accounts_with_pagination() -> List[Dict[str, Any]]:
    """
    List all accounts from AWS Organizations with pagination support
    Validates: Requirements 1.1, 10.2
    """
    accounts = []
    next_token = None
    
    logger.info("Starting account discovery from AWS Organizations")
    
    while True:
        try:
            # Call with retry logic
            def list_call():
                params = {}
                if next_token:
                    params['NextToken'] = next_token
                return organizations_client.list_accounts(**params)
            
            response = retry_with_exponential_backoff(list_call)
            
            accounts.extend(response.get('Accounts', []))
            next_token = response.get('NextToken')
            
            if not next_token:
                break
                
        except ClientError as e:
            logger.error(f"Failed to list accounts: {e}")
            raise
    
    logger.info(f"Discovered {len(accounts)} total accounts")
    return accounts


def filter_active_accounts(accounts: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Filter for ACTIVE accounts only, exclude SUSPENDED/CLOSED
    Validates: Requirements 1.2
    """
    active_accounts = [
        acc for acc in accounts 
        if acc.get('Status') == 'ACTIVE'
    ]
    
    filtered_count = len(accounts) - len(active_accounts)
    logger.info(f"Filtered {filtered_count} non-active accounts. {len(active_accounts)} active accounts remain")
    
    return active_accounts


def extract_account_metadata(account: Dict[str, Any]) -> Dict[str, str]:
    """
    Extract and validate account metadata
    Validates: Requirements 1.3
    """
    metadata = {
        'account_id': account.get('Id', ''),
        'account_name': account.get('Name', ''),
        'organizational_unit': account.get('Arn', '').split('/')[-2] if '/' in account.get('Arn', '') else 'root'
    }
    
    # Validate all fields are non-empty
    if not all(metadata.values()):
        logger.warning(f"Incomplete metadata for account {metadata.get('account_id')}: {metadata}")
    
    return metadata


def invoke_scan_lambda(account_metadata: Dict[str, str], execution_id: str) -> bool:
    """
    Invoke scan_account Lambda asynchronously
    Validates: Requirements 1.4
    """
    scan_lambda_arn = os.environ.get('SCAN_LAMBDA_ARN')
    
    if not scan_lambda_arn:
        logger.error("SCAN_LAMBDA_ARN environment variable not set")
        return False
    
    payload = {
        'account_id': account_metadata['account_id'],
        'account_name': account_metadata['account_name'],
        'execution_id': execution_id
    }
    
    try:
        response = lambda_client.invoke(
            FunctionName=scan_lambda_arn,
            InvocationType='Event',  # Asynchronous invocation
            Payload=json.dumps(payload)
        )
        
        status_code = response.get('StatusCode')
        if status_code == 202:  # Accepted for async invocation
            logger.info(f"Successfully invoked scan for account {account_metadata['account_id']}")
            return True
        else:
            logger.error(f"Unexpected status code {status_code} for account {account_metadata['account_id']}")
            return False
            
    except ClientError as e:
        logger.error(f"Failed to invoke scan Lambda for account {account_metadata['account_id']}: {e}")
        return False


def lambda_handler(event, context):
    """
    Main Lambda handler for account discovery
    """
    execution_id = str(uuid.uuid4())
    
    logger.info(f"Starting account discovery execution: {execution_id}")
    logger.debug(f"Event: {json.dumps(event)}")
    
    try:
        # Step 1: List all accounts with pagination
        all_accounts = list_accounts_with_pagination()
        
        # Step 2: Filter for ACTIVE accounts only
        active_accounts = filter_active_accounts(all_accounts)
        
        # Step 3: Extract metadata and invoke scan Lambda for each account
        accounts_scanned = 0
        accounts_failed = 0
        
        for account in active_accounts:
            metadata = extract_account_metadata(account)
            
            # Invoke scan Lambda asynchronously
            success = invoke_scan_lambda(metadata, execution_id)
            
            if success:
                accounts_scanned += 1
            else:
                accounts_failed += 1
        
        # Step 4: Return summary statistics
        result = {
            'accounts_discovered': len(all_accounts),
            'accounts_scanned': accounts_scanned,
            'accounts_failed': accounts_failed,
            'execution_id': execution_id
        }
        
        logger.info(f"Account discovery completed: {json.dumps(result)}")
        
        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }
        
    except Exception as e:
        logger.error(f"Account discovery failed: {e}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'execution_id': execution_id
            })
        }
