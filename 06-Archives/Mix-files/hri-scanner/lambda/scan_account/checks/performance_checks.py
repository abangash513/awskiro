"""
Performance HRI Checks

Implements 4 performance checks across EC2, CloudWatch, Compute Optimizer, and Lambda.

Requirements:
- 5.1: Identify idle EC2 instances using CloudWatch metrics
- 5.2: Identify over-provisioned EC2 instances using Compute Optimizer
- 5.3: Identify Lambda functions with high timeout rates or error rates
- 5.4: Identify legacy instance families (t2, m3, c3)
"""

import logging
from typing import Dict, Any, List
from datetime import datetime, timedelta
from botocore.exceptions import ClientError

logger = logging.getLogger()

# Legacy instance families to flag
LEGACY_INSTANCE_FAMILIES = ['t2', 'm3', 'c3', 'm1', 'm2', 'c1', 'cc2', 'cg1', 'cr1', 'hi1', 'hs1', 't1']


def check_idle_ec2_instances(scanner_session, region: str, account_id: str,
                             execution_id: str) -> List[Dict[str, Any]]:
    """
    Identify idle EC2 instances using CloudWatch metrics
    
    Requirement 5.1: Identify idle EC2 instances using CloudWatch metrics
    """
    findings = []
    
    try:
        ec2_client = scanner_session.get_client('ec2', region=region)
        cloudwatch_client = scanner_session.get_client('cloudwatch', region=region)
        
        # Get running instances
        response = ec2_client.describe_instances(
            Filters=[{'Name': 'instance-state-name', 'Values': ['running']}]
        )
        
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(days=7)  # Check last 7 days
        
        for reservation in response.get('Reservations', []):
            for instance in reservation.get('Instances', []):
                instance_id = instance['InstanceId']
                
                try:
                    # Get CPU utilization metrics
                    cpu_response = cloudwatch_client.get_metric_statistics(
                        Namespace='AWS/EC2',
                        MetricName='CPUUtilization',
                        Dimensions=[{'Name': 'InstanceId', 'Value': instance_id}],
                        StartTime=start_time,
                        EndTime=end_time,
                        Period=86400,  # 1 day
                        Statistics=['Average']
                    )
                    
                    datapoints = cpu_response.get('Datapoints', [])
                    
                    if datapoints:
                        avg_cpu = sum(dp['Average'] for dp in datapoints) / len(datapoints)
                        
                        # Flag instances with < 5% average CPU
                        if avg_cpu < 5.0:
                            findings.append({
                                'account_id': account_id,
                                'check_id': 'Performance#Idle_EC2_Instance',
                                'pillar': 'Performance',
                                'check_name': 'Idle EC2 Instance (Low CPU Utilization)',
                                'hri': True,
                                'evidence': f"arn:aws:ec2:{region}:{account_id}:instance/{instance_id} - Avg CPU: {avg_cpu:.2f}%",
                                'region': region,
                                'timestamp': datetime.utcnow().isoformat() + 'Z',
                                'execution_id': execution_id,
                                'resource_tags': {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
                            })
                            
                except ClientError as e:
                    logger.debug(f"Error getting metrics for instance {instance_id}: {e}")
                    
    except ClientError as e:
        logger.error(f"Error checking idle EC2 instances in {region}: {e}")
    
    return findings


def check_overprovisioned_ec2(scanner_session, region: str, account_id: str,
                              execution_id: str) -> List[Dict[str, Any]]:
    """
    Identify over-provisioned EC2 instances using Compute Optimizer
    
    Requirement 5.2: Identify over-provisioned EC2 instances using Compute Optimizer
    """
    findings = []
    
    try:
        compute_optimizer_client = scanner_session.get_client('compute-optimizer', region=region)
        
        # Check if Compute Optimizer is enabled
        try:
            enrollment_response = compute_optimizer_client.get_enrollment_status()
            status = enrollment_response.get('status', '')
            
            if status != 'Active':
                logger.debug(f"Compute Optimizer not active in {region}")
                return findings
                
        except ClientError as e:
            if e.response['Error']['Code'] == 'OptInRequiredException':
                logger.debug(f"Compute Optimizer not opted-in for {region}")
                return findings
            raise
        
        # Get EC2 instance recommendations
        try:
            paginator = compute_optimizer_client.get_paginator('get_ec2_instance_recommendations')
            
            for page in paginator.paginate():
                for recommendation in page.get('instanceRecommendations', []):
                    finding_reason = recommendation.get('finding', '')
                    
                    # Flag over-provisioned instances
                    if finding_reason in ['Overprovisioned', 'Over-provisioned']:
                        instance_arn = recommendation.get('instanceArn', '')
                        current_type = recommendation.get('currentInstanceType', '')
                        recommended_options = recommendation.get('recommendationOptions', [])
                        
                        recommended_types = [opt.get('instanceType', '') for opt in recommended_options[:3]]
                        
                        findings.append({
                            'account_id': account_id,
                            'check_id': 'Performance#Overprovisioned_EC2',
                            'pillar': 'Performance',
                            'check_name': 'Over-Provisioned EC2 Instance',
                            'hri': True,
                            'evidence': f"{instance_arn} - Current: {current_type}, Recommended: {', '.join(recommended_types)}",
                            'region': region,
                            'timestamp': datetime.utcnow().isoformat() + 'Z',
                            'execution_id': execution_id
                        })
                        
        except ClientError as e:
            if e.response['Error']['Code'] != 'ResourceNotFoundException':
                logger.debug(f"Error getting Compute Optimizer recommendations: {e}")
                
    except ClientError as e:
        logger.error(f"Error checking over-provisioned EC2 in {region}: {e}")
    
    return findings


def check_lambda_errors(scanner_session, region: str, account_id: str,
                       execution_id: str) -> List[Dict[str, Any]]:
    """
    Identify Lambda functions with high timeout rates or error rates
    
    Requirement 5.3: Identify Lambda functions with high timeout rates or error rates
    """
    findings = []
    
    try:
        lambda_client = scanner_session.get_client('lambda', region=region)
        cloudwatch_client = scanner_session.get_client('cloudwatch', region=region)
        
        # Get all Lambda functions
        paginator = lambda_client.get_paginator('list_functions')
        
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(days=7)  # Check last 7 days
        
        for page in paginator.paginate():
            for function in page.get('Functions', []):
                function_name = function['FunctionName']
                function_arn = function['FunctionArn']
                
                try:
                    # Get error metrics
                    errors_response = cloudwatch_client.get_metric_statistics(
                        Namespace='AWS/Lambda',
                        MetricName='Errors',
                        Dimensions=[{'Name': 'FunctionName', 'Value': function_name}],
                        StartTime=start_time,
                        EndTime=end_time,
                        Period=86400,  # 1 day
                        Statistics=['Sum']
                    )
                    
                    # Get invocation metrics
                    invocations_response = cloudwatch_client.get_metric_statistics(
                        Namespace='AWS/Lambda',
                        MetricName='Invocations',
                        Dimensions=[{'Name': 'FunctionName', 'Value': function_name}],
                        StartTime=start_time,
                        EndTime=end_time,
                        Period=86400,
                        Statistics=['Sum']
                    )
                    
                    # Get throttle metrics
                    throttles_response = cloudwatch_client.get_metric_statistics(
                        Namespace='AWS/Lambda',
                        MetricName='Throttles',
                        Dimensions=[{'Name': 'FunctionName', 'Value': function_name}],
                        StartTime=start_time,
                        EndTime=end_time,
                        Period=86400,
                        Statistics=['Sum']
                    )
                    
                    errors_datapoints = errors_response.get('Datapoints', [])
                    invocations_datapoints = invocations_response.get('Datapoints', [])
                    throttles_datapoints = throttles_response.get('Datapoints', [])
                    
                    if invocations_datapoints:
                        total_invocations = sum(dp['Sum'] for dp in invocations_datapoints)
                        total_errors = sum(dp['Sum'] for dp in errors_datapoints)
                        total_throttles = sum(dp['Sum'] for dp in throttles_datapoints)
                        
                        if total_invocations > 0:
                            error_rate = (total_errors / total_invocations) * 100
                            throttle_rate = (total_throttles / total_invocations) * 100
                            
                            # Flag functions with > 5% error rate
                            if error_rate > 5.0:
                                findings.append({
                                    'account_id': account_id,
                                    'check_id': 'Performance#Lambda_High_Error_Rate',
                                    'pillar': 'Performance',
                                    'check_name': 'Lambda Function with High Error Rate',
                                    'hri': True,
                                    'evidence': f"{function_arn} - Error Rate: {error_rate:.2f}%",
                                    'region': region,
                                    'timestamp': datetime.utcnow().isoformat() + 'Z',
                                    'execution_id': execution_id
                                })
                            
                            # Flag functions with > 1% throttle rate
                            if throttle_rate > 1.0:
                                findings.append({
                                    'account_id': account_id,
                                    'check_id': 'Performance#Lambda_High_Throttle_Rate',
                                    'pillar': 'Performance',
                                    'check_name': 'Lambda Function with High Throttle Rate',
                                    'hri': True,
                                    'evidence': f"{function_arn} - Throttle Rate: {throttle_rate:.2f}%",
                                    'region': region,
                                    'timestamp': datetime.utcnow().isoformat() + 'Z',
                                    'execution_id': execution_id
                                })
                                
                except ClientError as e:
                    logger.debug(f"Error getting metrics for Lambda {function_name}: {e}")
                    
    except ClientError as e:
        logger.error(f"Error checking Lambda functions in {region}: {e}")
    
    return findings


def check_legacy_instance_families(scanner_session, region: str, account_id: str,
                                   execution_id: str) -> List[Dict[str, Any]]:
    """
    Identify legacy instance families (t2, m3, c3)
    
    Requirement 5.4: Identify legacy instance families including t2, m3, and c3 types
    """
    findings = []
    
    try:
        ec2_client = scanner_session.get_client('ec2', region=region)
        
        # Get all instances (running and stopped)
        response = ec2_client.describe_instances()
        
        for reservation in response.get('Reservations', []):
            for instance in reservation.get('Instances', []):
                instance_id = instance['InstanceId']
                instance_type = instance['InstanceType']
                instance_state = instance['State']['Name']
                
                # Extract instance family (e.g., 't2' from 't2.micro')
                instance_family = instance_type.split('.')[0]
                
                if instance_family in LEGACY_INSTANCE_FAMILIES:
                    findings.append({
                        'account_id': account_id,
                        'check_id': 'Performance#Legacy_Instance_Family',
                        'pillar': 'Performance',
                        'check_name': 'Legacy EC2 Instance Family',
                        'hri': True,
                        'evidence': f"arn:aws:ec2:{region}:{account_id}:instance/{instance_id} - Type: {instance_type} (State: {instance_state})",
                        'region': region,
                        'timestamp': datetime.utcnow().isoformat() + 'Z',
                        'execution_id': execution_id,
                        'resource_tags': {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
                    })
                    
    except ClientError as e:
        logger.error(f"Error checking instance families in {region}: {e}")
    
    return findings


def run_all_performance_checks(scanner_session, regions: List[str], account_id: str,
                               execution_id: str) -> List[Dict[str, Any]]:
    """
    Run all performance HRI checks
    
    Args:
        scanner_session: Scanner session with assumed role
        regions: List of regions to scan
        account_id: AWS account ID
        execution_id: Unique execution ID
        
    Returns:
        List of all performance findings
    """
    all_findings = []
    
    logger.info(f"Running performance checks for account {account_id}")
    
    # Regional checks
    for region in regions:
        all_findings.extend(check_idle_ec2_instances(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_overprovisioned_ec2(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_lambda_errors(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_legacy_instance_families(scanner_session, region, account_id, execution_id))
    
    logger.info(f"Performance checks completed: {len(all_findings)} findings")
    
    return all_findings
