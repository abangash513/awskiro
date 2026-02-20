"""
Lambda 2: scan_account

Executes all 30 HRI checks for a single member account.

Requirements:
- 2.1: Assume HRI-ScannerRole using AWS STS
- 2.2: Use temporary credentials for all subsequent API calls
- 2.3: Log failure and continue if role assumption fails
- 2.5: Record account as unscannable if role doesn't exist
- 20.1: Query resources in all enabled regions
- 20.2: Iterate through configured region list
- 20.3: Query global services only once per account
- 20.5: Support region filtering configuration
"""

import json
import os
import logging
import time
import random
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime
import boto3
from botocore.exceptions import ClientError
from botocore.config import Config

# Configure structured logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Environment variables
SCANNER_ROLE_NAME = os.environ.get('SCANNER_ROLE_NAME', 'HRI-ScannerRole')
DYNAMODB_TABLE = os.environ.get('DYNAMODB_TABLE')
S3_BUCKET = os.environ.get('S3_BUCKET')
REGIONS = os.environ.get('REGIONS', 'us-east-1,us-west-2,eu-west-1').split(',')
EXTERNAL_ID = os.environ.get('EXTERNAL_ID')
ERROR_TOPIC_ARN = os.environ.get('ERROR_TOPIC_ARN')

# Initialize AWS clients (management account)
sts_client = boto3.client('sts')
dynamodb = boto3.resource('dynamodb')
s3_client = boto3.client('s3')
sns_client = boto3.client('sns')

# Get DynamoDB table
dynamodb_table = dynamodb.Table(DYNAMODB_TABLE) if DYNAMODB_TABLE else None

# Global services that should only be queried once per account
GLOBAL_SERVICES = ['iam', 'organizations', 'cloudtrail', 'route53']


class ScannerSession:
    """
    Manages cross-account session with temporary credentials
    """
    
    def __init__(self, account_id: str, role_name: str, external_id: str):
        self.account_id = account_id
        self.role_name = role_name
        self.external_id = external_id
        self.credentials = None
        self.session = None
        self.role_arn = f"arn:aws:iam::{account_id}:role/{role_name}"
        
    def assume_role(self) -> bool:
        """
        Assume cross-account role using STS
        
        Returns:
            True if successful, False otherwise
            
        Requirements:
        - 2.1: Assume HRI-ScannerRole using AWS STS
        - 2.2: Use temporary credentials for all subsequent API calls
        """
        try:
            logger.info(
                f"Assuming role {self.role_arn}",
                extra={
                    "account_id": self.account_id,
                    "role_arn": self.role_arn
                }
            )
            
            response = sts_client.assume_role(
                RoleArn=self.role_arn,
                RoleSessionName=f"hri-scanner-{int(time.time())}",
                ExternalId=self.external_id,
                DurationSeconds=3600  # 1 hour
            )
            
            self.credentials = response['Credentials']
            
            # Create boto3 session with temporary credentials
            self.session = boto3.Session(
                aws_access_key_id=self.credentials['AccessKeyId'],
                aws_secret_access_key=self.credentials['SecretAccessKey'],
                aws_session_token=self.credentials['SessionToken']
            )
            
            logger.info(
                f"Successfully assumed role {self.role_arn}",
                extra={
                    "account_id": self.account_id,
                    "expiration": self.credentials['Expiration'].isoformat()
                }
            )
            
            return True
            
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', '')
            error_message = e.response.get('Error', {}).get('Message', '')
            
            logger.error(
                f"Failed to assume role {self.role_arn}",
                extra={
                    "account_id": self.account_id,
                    "role_arn": self.role_arn,
                    "error_code": error_code,
                    "error_message": error_message
                }
            )
            
            return False
    
    def get_client(self, service: str, region: Optional[str] = None):
        """
        Get boto3 client for a service using assumed role credentials
        
        Args:
            service: AWS service name
            region: AWS region (optional)
            
        Returns:
            Boto3 client
        """
        if not self.session:
            raise RuntimeError("Session not initialized. Call assume_role() first.")
        
        config = Config(
            retries={
                'max_attempts': 3,
                'mode': 'adaptive'
            }
        )
        
        if region:
            return self.session.client(service, region_name=region, config=config)
        else:
            return self.session.client(service, config=config)
    
    def is_expired(self) -> bool:
        """
        Check if credentials are expired or about to expire
        
        Returns:
            True if expired or expiring soon (< 5 minutes)
        """
        if not self.credentials:
            return True
        
        expiration = self.credentials['Expiration']
        time_remaining = (expiration - datetime.now(expiration.tzinfo)).total_seconds()
        
        return time_remaining < 300  # Less than 5 minutes


def get_enabled_regions(scanner_session: ScannerSession) -> List[str]:
    """
    Get list of enabled regions for the account
    
    Args:
        scanner_session: Scanner session with assumed role
        
    Returns:
        List of enabled region names
        
    Requirements:
    - 20.1: Query resources in all enabled regions
    - 20.2: Iterate through configured region list
    - 20.5: Support region filtering
    """
    try:
        # Use EC2 to get enabled regions
        ec2_client = scanner_session.get_client('ec2', region='us-east-1')
        
        response = ec2_client.describe_regions(
            Filters=[
                {
                    'Name': 'opt-in-status',
                    'Values': ['opt-in-not-required', 'opted-in']
                }
            ]
        )
        
        all_enabled_regions = [region['RegionName'] for region in response['Regions']]
        
        # Filter to configured regions if specified
        if REGIONS and REGIONS[0]:  # Check if REGIONS is not empty
            enabled_regions = [r for r in all_enabled_regions if r in REGIONS]
        else:
            enabled_regions = all_enabled_regions
        
        logger.info(
            f"Scanning {len(enabled_regions)} regions",
            extra={
                "enabled_regions": enabled_regions,
                "configured_regions": REGIONS
            }
        )
        
        return enabled_regions
        
    except ClientError as e:
        logger.warning(
            f"Failed to get enabled regions, using configured list",
            extra={
                "error": str(e),
                "fallback_regions": REGIONS
            }
        )
        return REGIONS


def execute_checks(scanner_session: ScannerSession, regions: List[str], 
                   execution_id: str) -> List[Dict[str, Any]]:
    """
    Execute all HRI checks for the account
    
    Args:
        scanner_session: Scanner session with assumed role
        regions: List of regions to scan
        execution_id: Unique execution ID
        
    Returns:
        List of findings
        
    Requirements:
    - 20.3: Query global services only once per account
    """
    from checks.security_checks import run_all_security_checks
    from checks.reliability_checks import run_all_reliability_checks
    from checks.performance_checks import run_all_performance_checks
    from checks.cost_checks import run_all_cost_checks
    from checks.sustainability_checks import run_all_sustainability_checks
    
    findings = []
    account_id = scanner_session.account_id
    
    logger.info(
        "Executing HRI checks",
        extra={
            "account_id": account_id,
            "regions": regions,
            "execution_id": execution_id
        }
    )
    
    # Run Security checks (11 checks)
    try:
        security_findings = run_all_security_checks(
            scanner_session, regions, account_id, execution_id
        )
        findings.extend(security_findings)
        logger.info(f"Security checks completed: {len(security_findings)} findings")
    except Exception as e:
        logger.error(f"Error running security checks: {e}", exc_info=True)
    
    # Run Reliability checks (6 checks)
    try:
        reliability_findings = run_all_reliability_checks(
            scanner_session, regions, account_id, execution_id
        )
        findings.extend(reliability_findings)
        logger.info(f"Reliability checks completed: {len(reliability_findings)} findings")
    except Exception as e:
        logger.error(f"Error running reliability checks: {e}", exc_info=True)
    
    # Run Performance checks (4 checks)
    try:
        performance_findings = run_all_performance_checks(
            scanner_session, regions, account_id, execution_id
        )
        findings.extend(performance_findings)
        logger.info(f"Performance checks completed: {len(performance_findings)} findings")
    except Exception as e:
        logger.error(f"Error running performance checks: {e}", exc_info=True)
    
    # Run Cost Optimization checks (6 checks)
    try:
        cost_findings = run_all_cost_checks(
            scanner_session, regions, account_id, execution_id
        )
        findings.extend(cost_findings)
        logger.info(f"Cost optimization checks completed: {len(cost_findings)} findings")
    except Exception as e:
        logger.error(f"Error running cost optimization checks: {e}", exc_info=True)
    
    # Run Sustainability checks (3 checks)
    try:
        sustainability_findings = run_all_sustainability_checks(
            scanner_session, regions, account_id, execution_id
        )
        findings.extend(sustainability_findings)
        logger.info(f"Sustainability checks completed: {len(sustainability_findings)} findings")
    except Exception as e:
        logger.error(f"Error running sustainability checks: {e}", exc_info=True)
    
    logger.info(
        f"All HRI checks completed: {len(findings)} total findings",
        extra={
            "account_id": account_id,
            "total_findings": len(findings),
            "execution_id": execution_id
        }
    )
    
    return findings


def publish_error_notification(message: str, account_id: str, execution_id: str):
    """
    Publish error notification to SNS topic
    
    Args:
        message: Error message
        account_id: AWS account ID
        execution_id: Unique execution ID
    """
    if not ERROR_TOPIC_ARN:
        return
        
    try:
        sns_client.publish(
            TopicArn=ERROR_TOPIC_ARN,
            Subject=f'HRI Scanner - Account Scan Error ({account_id})',
            Message=json.dumps({
                "execution_id": execution_id,
                "account_id": account_id,
                "component": "scan_account",
                "error": message,
                "timestamp": time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
            }, indent=2)
        )
    except Exception as e:
        logger.error(f"Failed to publish error notification: {e}")


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for account scanning
    
    Args:
        event: Account details from discover_accounts Lambda
        context: Lambda context
        
    Returns:
        Summary of findings for the account
        
    Requirements:
    - 2.1, 2.2: Assume role and use temporary credentials
    - 2.3: Log failure and continue
    - 2.5: Record account as unscannable
    - 20.1, 20.2, 20.3, 20.5: Multi-region scanning
    """
    account_id = event.get('account_id')
    account_name = event.get('account_name', 'Unknown')
    execution_id = event.get('execution_id', context.request_id)
    
    start_time = time.time()
    
    # Log execution start
    logger.info(
        "Starting account scan",
        extra={
            "account_id": account_id,
            "account_name": account_name,
            "execution_id": execution_id,
            "component": "scan_account"
        }
    )
    
    try:
        # Step 1: Assume cross-account role
        scanner_session = ScannerSession(account_id, SCANNER_ROLE_NAME, EXTERNAL_ID)
        
        if not scanner_session.assume_role():
            # Requirement 2.3: Log failure and continue
            # Requirement 2.5: Record account as unscannable
            logger.warning(
                f"Account {account_id} is unscannable - role assumption failed",
                extra={
                    "account_id": account_id,
                    "account_name": account_name,
                    "execution_id": execution_id,
                    "status": "unscannable"
                }
            )
            
            return {
                "account_id": account_id,
                "account_name": account_name,
                "findings_count": 0,
                "hri_count": 0,
                "scan_duration_seconds": int(time.time() - start_time),
                "status": "unscannable",
                "error": "Failed to assume HRI-ScannerRole"
            }
        
        # Step 2: Get enabled regions
        regions = get_enabled_regions(scanner_session)
        
        # Step 3: Execute all HRI checks
        findings = execute_checks(scanner_session, regions, execution_id)
        
        # Step 4: Store findings in DynamoDB
        if dynamodb_table and findings:
            from storage import store_findings_batch
            
            storage_result = store_findings_batch(dynamodb_table, findings)
            logger.info(
                f"Stored {storage_result['success']} findings in DynamoDB",
                extra={
                    "account_id": account_id,
                    "execution_id": execution_id,
                    "storage_result": storage_result
                }
            )
        
        # Step 5: Generate and upload S3 report
        if S3_BUCKET and findings:
            from reporting import generate_and_upload_report
            
            report_result = generate_and_upload_report(
                s3_client, S3_BUCKET, account_id, account_name, findings, execution_id
            )
            
            if report_result['status'] == 'success':
                logger.info(
                    f"Uploaded report to S3: {report_result['s3_key']}",
                    extra={
                        "account_id": account_id,
                        "execution_id": execution_id,
                        "s3_key": report_result['s3_key']
                    }
                )
            else:
                logger.warning(
                    f"Failed to upload report to S3: {report_result.get('error')}",
                    extra={
                        "account_id": account_id,
                        "execution_id": execution_id
                    }
                )
        
        # Step 6: Calculate summary
        hri_count = sum(1 for f in findings if f.get('hri', False))
        scan_duration = int(time.time() - start_time)
        
        # Log execution completion
        result = {
            "account_id": account_id,
            "account_name": account_name,
            "findings_count": len(findings),
            "hri_count": hri_count,
            "scan_duration_seconds": scan_duration,
            "status": "completed"
        }
        
        logger.info(
            "Account scan completed",
            extra={
                **result,
                "execution_id": execution_id,
                "component": "scan_account"
            }
        )
        
        return result
        
    except Exception as e:
        error_message = f"Account scan failed for {account_id}: {str(e)}"
        scan_duration = int(time.time() - start_time)
        
        logger.error(
            error_message,
            extra={
                "account_id": account_id,
                "account_name": account_name,
                "execution_id": execution_id,
                "error": str(e),
                "component": "scan_account"
            },
            exc_info=True
        )
        
        # Publish error notification
        publish_error_notification(error_message, account_id, execution_id)
        
        # Return error result
        return {
            "account_id": account_id,
            "account_name": account_name,
            "findings_count": 0,
            "hri_count": 0,
            "scan_duration_seconds": scan_duration,
            "status": "failed",
            "error": str(e)
        }
