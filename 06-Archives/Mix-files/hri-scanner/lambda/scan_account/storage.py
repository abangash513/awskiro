"""
Storage Module

Handles DynamoDB write operations for HRI findings with retry logic and error handling.

Requirements:
- 8.1: Create finding record with all required fields
- 8.2: Use composite key of account ID and check name
- 8.3: Include HRI boolean flag
- 8.4: Include evidence field with resource ARN or identifier
- 8.5: Update timestamp and evidence for existing findings
- 18.4: Handle DynamoDB throttling with exponential backoff
"""

import logging
import time
import random
from typing import Dict, Any, List
from botocore.exceptions import ClientError

logger = logging.getLogger()


def retry_with_exponential_backoff(func, max_retries=5, base_delay=0.1):
    """
    Retry function with exponential backoff for DynamoDB throttling
    
    Args:
        func: Function to retry
        max_retries: Maximum number of retry attempts
        base_delay: Base delay in seconds
        
    Returns:
        Function result
        
    Requirement 18.4: Handle DynamoDB throttling with exponential backoff
    """
    for attempt in range(max_retries):
        try:
            return func()
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', '')
            
            # Retry on throttling errors
            if error_code in ['ProvisionedThroughputExceededException', 'ThrottlingException']:
                if attempt == max_retries - 1:
                    raise
                
                # Exponential backoff with jitter
                delay = min(base_delay * (2 ** attempt) + random.uniform(0, 0.1), 5.0)
                logger.warning(
                    f"DynamoDB throttled, retry {attempt + 1}/{max_retries} after {delay:.2f}s",
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


def store_finding(dynamodb_table, finding: Dict[str, Any]) -> bool:
    """
    Store a single finding in DynamoDB with idempotent update
    
    Args:
        dynamodb_table: DynamoDB table resource
        finding: Finding dictionary
        
    Returns:
        True if successful, False otherwise
        
    Requirements:
    - 8.1: Create finding record with all required fields
    - 8.2: Use composite key of account ID and check name
    - 8.3: Include HRI boolean flag
    - 8.4: Include evidence field
    - 8.5: Update timestamp and evidence for existing findings
    """
    try:
        # Validate required fields
        required_fields = ['account_id', 'check_id', 'pillar', 'check_name', 
                          'hri', 'evidence', 'timestamp', 'execution_id']
        
        for field in required_fields:
            if field not in finding:
                logger.error(f"Missing required field: {field}")
                return False
        
        # Prepare item for DynamoDB
        item = {
            'account_id': finding['account_id'],
            'check_id': finding['check_id'],
            'pillar': finding['pillar'],
            'check_name': finding['check_name'],
            'hri': finding['hri'],
            'evidence': finding['evidence'],
            'region': finding.get('region', 'global'),
            'timestamp': finding['timestamp'],
            'execution_id': finding['execution_id']
        }
        
        # Add optional fields
        if 'resource_tags' in finding and finding['resource_tags']:
            item['resource_tags'] = finding['resource_tags']
        
        if 'cost_impact' in finding:
            item['cost_impact'] = finding['cost_impact']
        
        # Use put_item with idempotent behavior (overwrites existing items)
        def put_item():
            return dynamodb_table.put_item(Item=item)
        
        retry_with_exponential_backoff(put_item)
        
        return True
        
    except Exception as e:
        logger.error(
            f"Error storing finding: {e}",
            extra={
                "account_id": finding.get('account_id'),
                "check_id": finding.get('check_id'),
                "error": str(e)
            },
            exc_info=True
        )
        return False


def store_findings_batch(dynamodb_table, findings: List[Dict[str, Any]]) -> Dict[str, int]:
    """
    Store multiple findings in DynamoDB
    
    Args:
        dynamodb_table: DynamoDB table resource
        findings: List of finding dictionaries
        
    Returns:
        Dictionary with success and failure counts
    """
    success_count = 0
    failure_count = 0
    
    logger.info(f"Storing {len(findings)} findings to DynamoDB")
    
    for finding in findings:
        if store_finding(dynamodb_table, finding):
            success_count += 1
        else:
            failure_count += 1
    
    logger.info(
        f"DynamoDB storage complete: {success_count} succeeded, {failure_count} failed",
        extra={
            "success_count": success_count,
            "failure_count": failure_count,
            "total_findings": len(findings)
        }
    )
    
    return {
        "success": success_count,
        "failed": failure_count,
        "total": len(findings)
    }
