"""
Reporting Module

Handles S3 report generation and export with encryption and retry logic.

Requirements:
- 9.1: Generate aggregated JSON report
- 9.2: Group findings by pillar and account
- 9.3: Include summary statistics for total HRIs per pillar
- 9.4: Upload to S3 with timestamp-based naming
- 9.5: Enable server-side encryption
- 18.5: Implement retry logic with jitter for S3 throttling
"""

import json
import logging
import time
import random
from typing import Dict, Any, List
from datetime import datetime
from botocore.exceptions import ClientError

logger = logging.getLogger()


def retry_with_jitter(func, max_retries=3, base_delay=0.5):
    """
    Retry function with jitter for S3 throttling
    
    Args:
        func: Function to retry
        max_retries: Maximum number of retry attempts
        base_delay: Base delay in seconds
        
    Returns:
        Function result
        
    Requirement 18.5: Implement retry logic with jitter for S3 throttling
    """
    for attempt in range(max_retries):
        try:
            return func()
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', '')
            
            # Retry on throttling or slow down errors
            if error_code in ['SlowDown', 'RequestTimeout', 'ServiceUnavailable']:
                if attempt == max_retries - 1:
                    raise
                
                # Exponential backoff with jitter
                jitter = random.uniform(0, 0.1 * (2 ** attempt))
                delay = min(base_delay * (2 ** attempt) + jitter, 5.0)
                
                logger.warning(
                    f"S3 throttled, retry {attempt + 1}/{max_retries} after {delay:.2f}s",
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


def generate_account_report(account_id: str, account_name: str, findings: List[Dict[str, Any]],
                           execution_id: str) -> Dict[str, Any]:
    """
    Generate account-specific JSON report
    
    Args:
        account_id: AWS account ID
        account_name: Account name
        findings: List of findings for the account
        execution_id: Unique execution ID
        
    Returns:
        Account report dictionary
        
    Requirements:
    - 9.2: Group findings by pillar and account
    - 9.3: Include summary statistics
    """
    # Group findings by pillar
    findings_by_pillar = {}
    for finding in findings:
        pillar = finding.get('pillar', 'Unknown')
        if pillar not in findings_by_pillar:
            findings_by_pillar[pillar] = []
        findings_by_pillar[pillar].append(finding)
    
    # Calculate summary statistics
    total_checks = len(findings)
    total_hris = sum(1 for f in findings if f.get('hri', False))
    
    summary_by_pillar = {}
    for pillar, pillar_findings in findings_by_pillar.items():
        hri_count = sum(1 for f in pillar_findings if f.get('hri', False))
        summary_by_pillar[pillar] = hri_count
    
    # Build report
    report = {
        "account_id": account_id,
        "account_name": account_name,
        "scan_timestamp": datetime.utcnow().isoformat() + 'Z',
        "execution_id": execution_id,
        "summary": {
            "total_checks": total_checks,
            "total_hris": total_hris,
            "by_pillar": summary_by_pillar
        },
        "findings": []
    }
    
    # Add findings (simplified format for report)
    for finding in findings:
        report["findings"].append({
            "pillar": finding.get('pillar'),
            "check_name": finding.get('check_name'),
            "hri": finding.get('hri'),
            "evidence": finding.get('evidence'),
            "region": finding.get('region'),
            "cost_impact": finding.get('cost_impact', 0)
        })
    
    return report


def upload_report_to_s3(s3_client, bucket: str, report: Dict[str, Any],
                       account_id: str, execution_id: str) -> str:
    """
    Upload account report to S3 with encryption
    
    Args:
        s3_client: Boto3 S3 client
        bucket: S3 bucket name
        report: Report dictionary
        account_id: AWS account ID
        execution_id: Unique execution ID
        
    Returns:
        S3 object key
        
    Requirements:
    - 9.4: Upload to S3 with timestamp-based naming
    - 9.5: Enable server-side encryption
    """
    # Generate S3 key with timestamp
    timestamp = datetime.utcnow().strftime('%Y%m%d-%H%M%S')
    s3_key = f"reports/{execution_id}/accounts/{account_id}-{timestamp}.json"
    
    # Convert report to JSON
    report_json = json.dumps(report, indent=2, default=str)
    
    # Upload to S3 with server-side encryption
    def upload():
        return s3_client.put_object(
            Bucket=bucket,
            Key=s3_key,
            Body=report_json.encode('utf-8'),
            ContentType='application/json',
            ServerSideEncryption='AES256',  # Enable SSE-S3
            Metadata={
                'account_id': account_id,
                'execution_id': execution_id,
                'scan_timestamp': report['scan_timestamp']
            }
        )
    
    retry_with_jitter(upload)
    
    logger.info(
        f"Uploaded report to S3: s3://{bucket}/{s3_key}",
        extra={
            "bucket": bucket,
            "key": s3_key,
            "account_id": account_id,
            "execution_id": execution_id
        }
    )
    
    return s3_key


def generate_and_upload_report(s3_client, bucket: str, account_id: str,
                               account_name: str, findings: List[Dict[str, Any]],
                               execution_id: str) -> Dict[str, Any]:
    """
    Generate account report and upload to S3
    
    Args:
        s3_client: Boto3 S3 client
        bucket: S3 bucket name
        account_id: AWS account ID
        account_name: Account name
        findings: List of findings
        execution_id: Unique execution ID
        
    Returns:
        Result dictionary with S3 key and status
        
    Requirement 9.1: Generate aggregated JSON report
    """
    try:
        # Generate report
        report = generate_account_report(account_id, account_name, findings, execution_id)
        
        # Upload to S3
        s3_key = upload_report_to_s3(s3_client, bucket, report, account_id, execution_id)
        
        return {
            "status": "success",
            "s3_bucket": bucket,
            "s3_key": s3_key,
            "findings_count": len(findings),
            "hri_count": report["summary"]["total_hris"]
        }
        
    except Exception as e:
        logger.error(
            f"Error generating/uploading report: {e}",
            extra={
                "account_id": account_id,
                "execution_id": execution_id,
                "error": str(e)
            },
            exc_info=True
        )
        
        return {
            "status": "failed",
            "error": str(e)
        }
