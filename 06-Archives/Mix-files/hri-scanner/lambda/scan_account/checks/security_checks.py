"""
Security HRI Checks

Implements 11 security checks across S3, EC2, RDS, IAM, Security Hub, GuardDuty, CloudTrail, and KMS.

Requirements:
- 3.1: Check for public S3 buckets
- 3.2: Check for unencrypted EBS volumes
- 3.3: Check for unencrypted RDS instances
- 3.4: Retrieve critical findings from Security Hub
- 3.5: Check if root account has MFA enabled
- 3.6: Identify IAM users without MFA
- 3.7: Identify IAM access keys > 90 days old
- 3.8: Verify CloudTrail is enabled and multi-region
- 3.9: Verify GuardDuty is enabled
- 3.10: Check if S3 Block Public Access is disabled
- 3.11: Identify sensitive workloads without KMS CMK encryption
"""

import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from botocore.exceptions import ClientError

logger = logging.getLogger()


def check_public_s3_buckets(scanner_session, region: str, account_id: str, 
                            execution_id: str) -> List[Dict[str, Any]]:
    """
    Check for public S3 buckets
    
    Requirement 3.1: Check for public S3 buckets using S3 API
    """
    findings = []
    
    try:
        s3_client = scanner_session.get_client('s3', region=region)
        
        # List all buckets (S3 is global, but we check once)
        if region != 'us-east-1':
            return findings
        
        response = s3_client.list_buckets()
        buckets = response.get('Buckets', [])
        
        for bucket in buckets:
            bucket_name = bucket['Name']
            
            try:
                # Check bucket ACL
                acl_response = s3_client.get_bucket_acl(Bucket=bucket_name)
                
                for grant in acl_response.get('Grants', []):
                    grantee = grant.get('Grantee', {})
                    if grantee.get('Type') == 'Group' and \
                       'AllUsers' in grantee.get('URI', ''):
                        findings.append({
                            'account_id': account_id,
                            'check_id': 'Security#Public_S3_Bucket',
                            'pillar': 'Security',
                            'check_name': 'Public S3 Bucket',
                            'hri': True,
                            'evidence': f'arn:aws:s3:::{bucket_name}',
                            'region': 'global',
                            'timestamp': datetime.utcnow().isoformat() + 'Z',
                            'execution_id': execution_id
                        })
                        break
                
                # Check bucket policy
                try:
                    policy_response = s3_client.get_bucket_policy(Bucket=bucket_name)
                    policy = policy_response.get('Policy', '{}')
                    if '"Principal":"*"' in policy or '"Principal":{"AWS":"*"}' in policy:
                        findings.append({
                            'account_id': account_id,
                            'check_id': 'Security#Public_S3_Bucket_Policy',
                            'pillar': 'Security',
                            'check_name': 'Public S3 Bucket Policy',
                            'hri': True,
                            'evidence': f'arn:aws:s3:::{bucket_name}',
                            'region': 'global',
                            'timestamp': datetime.utcnow().isoformat() + 'Z',
                            'execution_id': execution_id
                        })
                except ClientError as e:
                    if e.response['Error']['Code'] != 'NoSuchBucketPolicy':
                        logger.debug(f"Error checking policy for {bucket_name}: {e}")
                        
            except ClientError as e:
                logger.debug(f"Error checking bucket {bucket_name}: {e}")
                
    except ClientError as e:
        logger.error(f"Error listing S3 buckets: {e}")
    
    return findings


def check_unencrypted_ebs_volumes(scanner_session, region: str, account_id: str,
                                  execution_id: str) -> List[Dict[str, Any]]:
    """
    Check for unencrypted EBS volumes
    
    Requirement 3.2: Check for unencrypted EBS volumes using EC2 API
    """
    findings = []
    
    try:
        ec2_client = scanner_session.get_client('ec2', region=region)
        
        paginator = ec2_client.get_paginator('describe_volumes')
        
        for page in paginator.paginate():
            for volume in page.get('Volumes', []):
                if not volume.get('Encrypted', False):
                    findings.append({
                        'account_id': account_id,
                        'check_id': 'Security#Unencrypted_EBS_Volume',
                        'pillar': 'Security',
                        'check_name': 'Unencrypted EBS Volume',
                        'hri': True,
                        'evidence': f"arn:aws:ec2:{region}:{account_id}:volume/{volume['VolumeId']}",
                        'region': region,
                        'timestamp': datetime.utcnow().isoformat() + 'Z',
                        'execution_id': execution_id,
                        'resource_tags': {tag['Key']: tag['Value'] for tag in volume.get('Tags', [])}
                    })
                    
    except ClientError as e:
        logger.error(f"Error checking EBS volumes in {region}: {e}")
    
    return findings


def check_unencrypted_rds_instances(scanner_session, region: str, account_id: str,
                                   execution_id: str) -> List[Dict[str, Any]]:
    """
    Check for unencrypted RDS instances
    
    Requirement 3.3: Check for unencrypted RDS instances using RDS API
    """
    findings = []
    
    try:
        rds_client = scanner_session.get_client('rds', region=region)
        
        paginator = rds_client.get_paginator('describe_db_instances')
        
        for page in paginator.paginate():
            for db_instance in page.get('DBInstances', []):
                if not db_instance.get('StorageEncrypted', False):
                    findings.append({
                        'account_id': account_id,
                        'check_id': 'Security#Unencrypted_RDS_Instance',
                        'pillar': 'Security',
                        'check_name': 'Unencrypted RDS Instance',
                        'hri': True,
                        'evidence': db_instance['DBInstanceArn'],
                        'region': region,
                        'timestamp': datetime.utcnow().isoformat() + 'Z',
                        'execution_id': execution_id
                    })
                    
    except ClientError as e:
        logger.error(f"Error checking RDS instances in {region}: {e}")
    
    return findings


def check_security_hub_critical_findings(scanner_session, region: str, account_id: str,
                                        execution_id: str) -> List[Dict[str, Any]]:
    """
    Retrieve critical findings from Security Hub
    
    Requirement 3.4: Retrieve critical findings from Security Hub
    """
    findings = []
    
    try:
        securityhub_client = scanner_session.get_client('securityhub', region=region)
        
        # Check if Security Hub is enabled
        try:
            securityhub_client.describe_hub()
        except ClientError as e:
            if e.response['Error']['Code'] == 'InvalidAccessException':
                logger.debug(f"Security Hub not enabled in {region}")
                return findings
            raise
        
        # Get critical and high severity findings
        paginator = securityhub_client.get_paginator('get_findings')
        
        for page in paginator.paginate(
            Filters={
                'SeverityLabel': [
                    {'Value': 'CRITICAL', 'Comparison': 'EQUALS'}
                ],
                'RecordState': [
                    {'Value': 'ACTIVE', 'Comparison': 'EQUALS'}
                ]
            },
            MaxResults=100
        ):
            for finding in page.get('Findings', []):
                findings.append({
                    'account_id': account_id,
                    'check_id': 'Security#SecurityHub_Critical_Finding',
                    'pillar': 'Security',
                    'check_name': 'Security Hub Critical Finding',
                    'hri': True,
                    'evidence': finding.get('Id', ''),
                    'region': region,
                    'timestamp': datetime.utcnow().isoformat() + 'Z',
                    'execution_id': execution_id
                })
                
    except ClientError as e:
        logger.error(f"Error checking Security Hub in {region}: {e}")
    
    return findings


def check_root_account_mfa(scanner_session, account_id: str, 
                           execution_id: str) -> List[Dict[str, Any]]:
    """
    Check if root account has MFA enabled
    
    Requirement 3.5: Check if root account has MFA enabled using IAM API
    """
    findings = []
    
    try:
        iam_client = scanner_session.get_client('iam')
        
        # Get account summary
        response = iam_client.get_account_summary()
        summary_map = response.get('SummaryMap', {})
        
        # Check if root account has MFA
        if summary_map.get('AccountMFAEnabled', 0) == 0:
            findings.append({
                'account_id': account_id,
                'check_id': 'Security#Root_Account_No_MFA',
                'pillar': 'Security',
                'check_name': 'Root Account Without MFA',
                'hri': True,
                'evidence': f'Root account in {account_id} does not have MFA enabled',
                'region': 'global',
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'execution_id': execution_id
            })
            
    except ClientError as e:
        logger.error(f"Error checking root account MFA: {e}")
    
    return findings


def check_iam_users_without_mfa(scanner_session, account_id: str,
                                execution_id: str) -> List[Dict[str, Any]]:
    """
    Identify IAM users without MFA enabled
    
    Requirement 3.6: Identify IAM users without MFA enabled
    """
    findings = []
    
    try:
        iam_client = scanner_session.get_client('iam')
        
        paginator = iam_client.get_paginator('list_users')
        
        for page in paginator.paginate():
            for user in page.get('Users', []):
                user_name = user['UserName']
                
                # Check MFA devices for user
                mfa_response = iam_client.list_mfa_devices(UserName=user_name)
                
                if len(mfa_response.get('MFADevices', [])) == 0:
                    findings.append({
                        'account_id': account_id,
                        'check_id': 'Security#IAM_User_No_MFA',
                        'pillar': 'Security',
                        'check_name': 'IAM User Without MFA',
                        'hri': True,
                        'evidence': user['Arn'],
                        'region': 'global',
                        'timestamp': datetime.utcnow().isoformat() + 'Z',
                        'execution_id': execution_id
                    })
                    
    except ClientError as e:
        logger.error(f"Error checking IAM users MFA: {e}")
    
    return findings


def check_old_access_keys(scanner_session, account_id: str,
                          execution_id: str) -> List[Dict[str, Any]]:
    """
    Identify IAM access keys older than 90 days
    
    Requirement 3.7: Identify IAM access keys older than 90 days
    """
    findings = []
    
    try:
        iam_client = scanner_session.get_client('iam')
        
        paginator = iam_client.get_paginator('list_users')
        cutoff_date = datetime.now() - timedelta(days=90)
        
        for page in paginator.paginate():
            for user in page.get('Users', []):
                user_name = user['UserName']
                
                # List access keys for user
                keys_response = iam_client.list_access_keys(UserName=user_name)
                
                for key in keys_response.get('AccessKeyMetadata', []):
                    create_date = key['CreateDate'].replace(tzinfo=None)
                    
                    if create_date < cutoff_date:
                        age_days = (datetime.now() - create_date).days
                        findings.append({
                            'account_id': account_id,
                            'check_id': 'Security#Old_Access_Key',
                            'pillar': 'Security',
                            'check_name': 'IAM Access Key Older Than 90 Days',
                            'hri': True,
                            'evidence': f"{user['Arn']} - Key: {key['AccessKeyId']} ({age_days} days old)",
                            'region': 'global',
                            'timestamp': datetime.utcnow().isoformat() + 'Z',
                            'execution_id': execution_id
                        })
                        
    except ClientError as e:
        logger.error(f"Error checking access keys: {e}")
    
    return findings


def check_cloudtrail_enabled(scanner_session, region: str, account_id: str,
                             execution_id: str) -> List[Dict[str, Any]]:
    """
    Verify CloudTrail is enabled and configured for multi-region
    
    Requirement 3.8: Verify CloudTrail is enabled and configured for multi-region
    """
    findings = []
    
    # Only check in us-east-1 since CloudTrail is global
    if region != 'us-east-1':
        return findings
    
    try:
        cloudtrail_client = scanner_session.get_client('cloudtrail', region=region)
        
        response = cloudtrail_client.describe_trails()
        trails = response.get('trailList', [])
        
        # Check if there's at least one multi-region trail that's logging
        has_multi_region_trail = False
        
        for trail in trails:
            if trail.get('IsMultiRegionTrail', False):
                # Check if trail is logging
                status = cloudtrail_client.get_trail_status(Name=trail['TrailARN'])
                if status.get('IsLogging', False):
                    has_multi_region_trail = True
                    break
        
        if not has_multi_region_trail:
            findings.append({
                'account_id': account_id,
                'check_id': 'Security#CloudTrail_Not_MultiRegion',
                'pillar': 'Security',
                'check_name': 'CloudTrail Not Enabled or Not Multi-Region',
                'hri': True,
                'evidence': f'No active multi-region CloudTrail found in account {account_id}',
                'region': 'global',
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'execution_id': execution_id
            })
            
    except ClientError as e:
        logger.error(f"Error checking CloudTrail: {e}")
    
    return findings


def check_guardduty_enabled(scanner_session, region: str, account_id: str,
                            execution_id: str) -> List[Dict[str, Any]]:
    """
    Verify GuardDuty is enabled
    
    Requirement 3.9: Verify GuardDuty is enabled
    """
    findings = []
    
    try:
        guardduty_client = scanner_session.get_client('guardduty', region=region)
        
        response = guardduty_client.list_detectors()
        detectors = response.get('DetectorIds', [])
        
        if len(detectors) == 0:
            findings.append({
                'account_id': account_id,
                'check_id': 'Security#GuardDuty_Not_Enabled',
                'pillar': 'Security',
                'check_name': 'GuardDuty Not Enabled',
                'hri': True,
                'evidence': f'GuardDuty not enabled in {region}',
                'region': region,
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'execution_id': execution_id
            })
        else:
            # Check if detector is enabled
            for detector_id in detectors:
                detector = guardduty_client.get_detector(DetectorId=detector_id)
                if detector.get('Status') != 'ENABLED':
                    findings.append({
                        'account_id': account_id,
                        'check_id': 'Security#GuardDuty_Disabled',
                        'pillar': 'Security',
                        'check_name': 'GuardDuty Detector Disabled',
                        'hri': True,
                        'evidence': f'GuardDuty detector {detector_id} is disabled in {region}',
                        'region': region,
                        'timestamp': datetime.utcnow().isoformat() + 'Z',
                        'execution_id': execution_id
                    })
                    
    except ClientError as e:
        logger.error(f"Error checking GuardDuty in {region}: {e}")
    
    return findings


def check_s3_block_public_access(scanner_session, account_id: str,
                                 execution_id: str) -> List[Dict[str, Any]]:
    """
    Check if S3 Block Public Access is disabled at account level
    
    Requirement 3.10: Check if S3 Block Public Access is disabled at account level
    """
    findings = []
    
    try:
        s3control_client = scanner_session.get_client('s3control')
        
        response = s3control_client.get_public_access_block(AccountId=account_id)
        config = response.get('PublicAccessBlockConfiguration', {})
        
        # Check if all settings are enabled
        if not all([
            config.get('BlockPublicAcls', False),
            config.get('IgnorePublicAcls', False),
            config.get('BlockPublicPolicy', False),
            config.get('RestrictPublicBuckets', False)
        ]):
            findings.append({
                'account_id': account_id,
                'check_id': 'Security#S3_Block_Public_Access_Disabled',
                'pillar': 'Security',
                'check_name': 'S3 Block Public Access Disabled',
                'hri': True,
                'evidence': f'S3 Block Public Access not fully enabled for account {account_id}',
                'region': 'global',
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'execution_id': execution_id
            })
            
    except ClientError as e:
        if e.response['Error']['Code'] == 'NoSuchPublicAccessBlockConfiguration':
            findings.append({
                'account_id': account_id,
                'check_id': 'Security#S3_Block_Public_Access_Not_Configured',
                'pillar': 'Security',
                'check_name': 'S3 Block Public Access Not Configured',
                'hri': True,
                'evidence': f'S3 Block Public Access not configured for account {account_id}',
                'region': 'global',
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'execution_id': execution_id
            })
        else:
            logger.error(f"Error checking S3 Block Public Access: {e}")
    
    return findings


def check_kms_cmk_usage(scanner_session, region: str, account_id: str,
                        execution_id: str) -> List[Dict[str, Any]]:
    """
    Identify sensitive workloads without KMS CMK encryption
    
    Requirement 3.11: Identify sensitive workloads without KMS CMK encryption
    """
    findings = []
    
    try:
        # Check RDS instances for default encryption
        rds_client = scanner_session.get_client('rds', region=region)
        
        paginator = rds_client.get_paginator('describe_db_instances')
        
        for page in paginator.paginate():
            for db_instance in page.get('DBInstances', []):
                if db_instance.get('StorageEncrypted', False):
                    kms_key_id = db_instance.get('KmsKeyId', '')
                    # Check if using default AWS managed key (contains 'aws/rds')
                    if 'aws/rds' in kms_key_id or not kms_key_id:
                        findings.append({
                            'account_id': account_id,
                            'check_id': 'Security#RDS_No_CMK',
                            'pillar': 'Security',
                            'check_name': 'RDS Instance Without Customer Managed Key',
                            'hri': True,
                            'evidence': db_instance['DBInstanceArn'],
                            'region': region,
                            'timestamp': datetime.utcnow().isoformat() + 'Z',
                            'execution_id': execution_id
                        })
                        
    except ClientError as e:
        logger.error(f"Error checking KMS CMK usage in {region}: {e}")
    
    return findings


def run_all_security_checks(scanner_session, regions: List[str], account_id: str,
                            execution_id: str) -> List[Dict[str, Any]]:
    """
    Run all security HRI checks
    
    Args:
        scanner_session: Scanner session with assumed role
        regions: List of regions to scan
        account_id: AWS account ID
        execution_id: Unique execution ID
        
    Returns:
        List of all security findings
    """
    all_findings = []
    
    logger.info(f"Running security checks for account {account_id}")
    
    # Global checks (run once)
    all_findings.extend(check_root_account_mfa(scanner_session, account_id, execution_id))
    all_findings.extend(check_iam_users_without_mfa(scanner_session, account_id, execution_id))
    all_findings.extend(check_old_access_keys(scanner_session, account_id, execution_id))
    all_findings.extend(check_s3_block_public_access(scanner_session, account_id, execution_id))
    
    # Regional checks
    for region in regions:
        all_findings.extend(check_public_s3_buckets(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_unencrypted_ebs_volumes(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_unencrypted_rds_instances(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_security_hub_critical_findings(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_cloudtrail_enabled(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_guardduty_enabled(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_kms_cmk_usage(scanner_session, region, account_id, execution_id))
    
    logger.info(f"Security checks completed: {len(all_findings)} findings")
    
    return all_findings
