"""
Lambda 1: discover_accounts

Discovers all active member accounts in AWS Organization and invokes scan_account Lambda for each.

Requirements:
- 1.1: Retrieve all active member accounts from AWS Organizations API
- 1.2: Filter out suspended or closed accounts
- 1.3: Store account metadata (account_id, account_name, organizational_unit)
- 1.4: Return list of scannable accounts for processing
- 1.5: Retry with exponential backoff up to 3 attempts
- 11.2: Initiate account discovery when triggered
- 14.1: Log execution start and completion
"""

import json
import os
import logging
import time
import random
from typing import Dict, Any, List, Optional
import boto3
from botocore.exceptions import ClientError

# Configure structured logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Initialize AWS clients
organizations = boto3.client('organizations')
lambda_client = boto3.client('lambda')
sns_client = boto3.client('sns')

# Environment variables
SCAN_LAMBDA_ARN = os.environ.get('SCAN_LAMBDA_ARN')
ERROR_TOPIC_ARN = os.environ.get('ERROR_TOPIC_ARN')


def retry_with_backoff(func, max_retries=3, base_delay=1):
    """
    Retry function with exponential backoff
    
    Args:
        func: Function to retry
        max_retries: Maximum number of retry attempts (default: 3)
        base_delay: Base delay in seconds (default: 1)
        
    Returns:
        Function result
        
    Raises:
        Last exception if all retries fail
    """
    for attempt in range(max_retries):
        try:
            return func()
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', '')
            
            # Only retry on throttling or transient errors
            if error_code in ['ThrottlingException', 'TooManyRequestsException', 'ServiceUnavailable']:
                if attempt == max_retries - 1:
                    raise
                
                # Exponential backoff with jitter
                delay = base_delay * (2 ** attempt) + random.uniform(0, 1)
                logger.warning(
                    f"Retry {attempt + 1}/{max_retries} after {delay:.2f}s",
                    extra={
                        "attempt": attempt + 1,
                        "max_retries": max_retries,
                        "delay_seconds": delay,
                        "error_code": error_code
                    }
                )
                time.sleep(delay)
            else:
                # Don't retry on other errors
                raise


def list_accounts_with_pagination() -> List[Dict[str, Any]]:
    """
    List all accounts in the organization with pagination support
    
    Returns:
        List of account dictionaries
        
    Requirements:
    - 1.1: Retrieve all active member accounts
    - 1.5: Retry with exponential backoff
    """
    accounts = []
    next_token = None
    
    def list_page():
        nonlocal next_token
        if next_token:
            return organizations.list_accounts(NextToken=next_token)
        else:
            return organizations.list_accounts()
    
    while True:
        try:
            response = retry_with_backoff(list_page)
            accounts.extend(response.get('Accounts', []))
            
            next_token = response.get('NextToken')
            if not next_token:
                break
                
        except ClientError as e:
            logger.error(
                "Failed to list accounts",
                extra={
                    "error": str(e),
                    "error_code": e.response.get('Error', {}).get('Code', ''),
                    "accounts_retrieved": len(accounts)
                }
            )
            raise
    
    logger.info(
        f"Retrieved {len(accounts)} total accounts from Organizations API",
        extra={"total_accounts": len(accounts)}
    )
    
    return accounts


def filter_active_accounts(accounts: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Filter for ACTIVE accounts only, excluding SUSPENDED and CLOSED
    
    Args:
        accounts: List of all accounts
        
    Returns:
        List of active accounts only
        
    Requirements:
    - 1.2: Filter out suspended or closed accounts
    """
    active_accounts = [
        account for account in accounts
        if account.get('Status') == 'ACTIVE'
    ]
    
    filtered_count = len(accounts) - len(active_accounts)
    
    logger.info(
        f"Filtered to {len(active_accounts)} ACTIVE accounts (excluded {filtered_count})",
        extra={
            "active_accounts": len(active_accounts),
            "filtered_accounts": filtered_count,
            "total_accounts": len(accounts)
        }
    )
    
    return active_accounts


def get_account_metadata(account: Dict[str, Any]) -> Dict[str, str]:
    """
    Extract account metadata
    
    Args:
        account: Account dictionary from Organizations API
        
    Returns:
        Dictionary with account_id, account_name, organizational_unit
        
    Requirements:
    - 1.3: Store account metadata
    """
    # Get organizational unit (OU) for the account
    account_id = account.get('Id', '')
    
    try:
        # Get parent OU
        parents_response = retry_with_backoff(
            lambda: organizations.list_parents(ChildId=account_id)
        )
        parent_id = parents_response.get('Parents', [{}])[0].get('Id', 'ROOT')
        
        # Get OU name if not root
        if parent_id != 'ROOT' and parent_id.startswith('ou-'):
            ou_response = retry_with_backoff(
                lambda: organizations.describe_organizational_unit(
                    OrganizationalUnitId=parent_id
                )
            )
            ou_name = ou_response.get('OrganizationalUnit', {}).get('Name', parent_id)
        else:
            ou_name = 'ROOT'
            
    except ClientError as e:
        logger.warning(
            f"Failed to get OU for account {account_id}",
            extra={
                "account_id": account_id,
                "error": str(e)
            }
        )
        ou_name = 'UNKNOWN'
    
    return {
        "account_id": account_id,
        "account_name": account.get('Name', ''),
        "organizational_unit": ou_name,
        "email": account.get('Email', ''),
        "status": account.get('Status', '')
    }


def invoke_scan_account(account_metadata: Dict[str, str], execution_id: str) -> bool:
    """
    Invoke scan_account Lambda asynchronously for a single account
    
    Args:
        account_metadata: Account metadata dictionary
        execution_id: Unique execution ID
        
    Returns:
        True if invocation succeeded, False otherwise
        
    Requirements:
    - 1.4: Invoke Lambda 2 for each account
    """
    try:
        payload = {
            "account_id": account_metadata["account_id"],
            "account_name": account_metadata["account_name"],
            "execution_id": execution_id
        }
        
        response = lambda_client.invoke(
            FunctionName=SCAN_LAMBDA_ARN,
            InvocationType='Event',  # Asynchronous invocation
            Payload=json.dumps(payload)
        )
        
        status_code = response.get('StatusCode', 0)
        
        if status_code == 202:  # Accepted for async invocation
            logger.info(
                f"Successfully invoked scan for account {account_metadata['account_id']}",
                extra={
                    "account_id": account_metadata["account_id"],
                    "account_name": account_metadata["account_name"],
                    "execution_id": execution_id
                }
            )
            return True
        else:
            logger.error(
                f"Failed to invoke scan for account {account_metadata['account_id']}",
                extra={
                    "account_id": account_metadata["account_id"],
                    "status_code": status_code
                }
            )
            return False
            
    except ClientError as e:
        logger.error(
            f"Error invoking scan for account {account_metadata['account_id']}",
            extra={
                "account_id": account_metadata["account_id"],
                "error": str(e),
                "error_code": e.response.get('Error', {}).get('Code', '')
            }
        )
        return False


def publish_error_notification(message: str, execution_id: str):
    """
    Publish error notification to SNS topic
    
    Args:
        message: Error message
        execution_id: Unique execution ID
    """
    if not ERROR_TOPIC_ARN:
        return
        
    try:
        sns_client.publish(
            TopicArn=ERROR_TOPIC_ARN,
            Subject='HRI Scanner - Account Discovery Error',
            Message=json.dumps({
                "execution_id": execution_id,
                "component": "discover_accounts",
                "error": message,
                "timestamp": time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
            }, indent=2)
        )
    except Exception as e:
        logger.error(f"Failed to publish error notification: {e}")


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for account discovery
    
    Args:
        event: EventBridge event or manual invocation
        context: Lambda context
        
    Returns:
        Summary of accounts discovered and scanned
        
    Requirements:
    - 1.1, 1.2, 1.3, 1.4, 1.5: Account discovery and invocation
    - 11.2: Initiate account discovery
    - 14.1: Log execution start and completion
    """
    execution_id = context.request_id
    
    # Log execution start
    logger.info(
        "Starting account discovery",
        extra={
            "execution_id": execution_id,
            "event": event,
            "component": "discover_accounts"
        }
    )
    
    try:
        # Step 1: List all accounts with pagination
        all_accounts = list_accounts_with_pagination()
        
        # Step 2: Filter for ACTIVE accounts only
        active_accounts = filter_active_accounts(all_accounts)
        
        # Step 3: Get metadata and invoke scan for each account
        accounts_scanned = 0
        accounts_failed = 0
        
        for account in active_accounts:
            account_metadata = get_account_metadata(account)
            
            # Invoke scan_account Lambda
            if invoke_scan_account(account_metadata, execution_id):
                accounts_scanned += 1
            else:
                accounts_failed += 1
        
        # Log execution completion
        result = {
            "accounts_discovered": len(all_accounts),
            "accounts_active": len(active_accounts),
            "accounts_scanned": accounts_scanned,
            "accounts_failed": accounts_failed,
            "execution_id": execution_id,
            "status": "completed"
        }
        
        logger.info(
            "Account discovery completed",
            extra={
                **result,
                "component": "discover_accounts"
            }
        )
        
        return result
        
    except Exception as e:
        error_message = f"Account discovery failed: {str(e)}"
        logger.error(
            error_message,
            extra={
                "execution_id": execution_id,
                "error": str(e),
                "component": "discover_accounts"
            },
            exc_info=True
        )
        
        # Publish error notification
        publish_error_notification(error_message, execution_id)
        
        # Return error result
        return {
            "accounts_discovered": 0,
            "accounts_active": 0,
            "accounts_scanned": 0,
            "accounts_failed": 0,
            "execution_id": execution_id,
            "status": "failed",
            "error": str(e)
        }
