"""
Reliability HRI Checks

Implements 6 reliability checks across Config, CloudWatch, Backup, RDS, VPC, and Auto Scaling.

Requirements:
- 4.1: Verify AWS Config is enabled
- 4.2: Check for absence of CloudWatch alarms on critical resources
- 4.3: Verify backup solutions are enabled for critical resources
- 4.4: Identify single-AZ RDS instances
- 4.5: Verify VPC Flow Logs are enabled
- 4.6: Identify Auto Scaling Groups without health checks or scaling policies
"""

import logging
from typing import Dict, Any, List
from datetime import datetime
from botocore.exceptions import ClientError

logger = logging.getLogger()


def check_config_enabled(scanner_session, region: str, account_id: str,
                        execution_id: str) -> List[Dict[str, Any]]:
    """
    Verify AWS Config is enabled
    
    Requirement 4.1: Verify AWS Config is enabled
    """
    findings = []
    
    try:
        config_client = scanner_session.get_client('config', region=region)
        
        # Check for configuration recorders
        recorders_response = config_client.describe_configuration_recorders()
        recorders = recorders_response.get('ConfigurationRecorders', [])
        
        if len(recorders) == 0:
            findings.append({
                'account_id': account_id,
                'check_id': 'Reliability#Config_Not_Enabled',
                'pillar': 'Reliability',
                'check_name': 'AWS Config Not Enabled',
                'hri': True,
                'evidence': f'AWS Config not enabled in {region}',
                'region': region,
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'execution_id': execution_id
            })
        else:
            # Check if recorder is recording
            status_response = config_client.describe_configuration_recorder_status()
            statuses = status_response.get('ConfigurationRecordersStatus', [])
            
            recording = any(status.get('recording', False) for status in statuses)
            
            if not recording:
                findings.append({
                    'account_id': account_id,
                    'check_id': 'Reliability#Config_Not_Recording',
                    'pillar': 'Reliability',
                    'check_name': 'AWS Config Not Recording',
                    'hri': True,
                    'evidence': f'AWS Config exists but not recording in {region}',
                    'region': region,
                    'timestamp': datetime.utcnow().isoformat() + 'Z',
                    'execution_id': execution_id
                })
                
    except ClientError as e:
        logger.error(f"Error checking AWS Config in {region}: {e}")
    
    return findings


def check_cloudwatch_alarms(scanner_session, region: str, account_id: str,
                            execution_id: str) -> List[Dict[str, Any]]:
    """
    Check for absence of CloudWatch alarms on critical resources
    
    Requirement 4.2: Check for absence of CloudWatch alarms on critical resources
    """
    findings = []
    
    try:
        cloudwatch_client = scanner_session.get_client('cloudwatch', region=region)
        ec2_client = scanner_session.get_client('ec2', region=region)
        rds_client = scanner_session.get_client('rds', region=region)
        
        # Get all alarms
        alarms_response = cloudwatch_client.describe_alarms()
        alarms = alarms_response.get('MetricAlarms', [])
        
        # Get EC2 instances
        ec2_response = ec2_client.describe_instances(
            Filters=[{'Name': 'instance-state-name', 'Values': ['running']}]
        )
        
        instance_ids = []
        for reservation in ec2_response.get('Reservations', []):
            for instance in reservation.get('Instances', []):
                instance_ids.append(instance['InstanceId'])
        
        # Check if EC2 instances have alarms
        alarmed_instances = set()
        for alarm in alarms:
            for dimension in alarm.get('Dimensions', []):
                if dimension.get('Name') == 'InstanceId':
                    alarmed_instances.add(dimension.get('Value'))
        
        # Find instances without alarms
        for instance_id in instance_ids:
            if instance_id not in alarmed_instances:
                findings.append({
                    'account_id': account_id,
                    'check_id': 'Reliability#EC2_No_Alarms',
                    'pillar': 'Reliability',
                    'check_name': 'EC2 Instance Without CloudWatch Alarms',
                    'hri': True,
                    'evidence': f'arn:aws:ec2:{region}:{account_id}:instance/{instance_id}',
                    'region': region,
                    'timestamp': datetime.utcnow().isoformat() + 'Z',
                    'execution_id': execution_id
                })
        
        # Check RDS instances for alarms
        rds_response = rds_client.describe_db_instances()
        
        alarmed_db_instances = set()
        for alarm in alarms:
            for dimension in alarm.get('Dimensions', []):
                if dimension.get('Name') == 'DBInstanceIdentifier':
                    alarmed_db_instances.add(dimension.get('Value'))
        
        for db_instance in rds_response.get('DBInstances', []):
            db_id = db_instance['DBInstanceIdentifier']
            if db_id not in alarmed_db_instances:
                findings.append({
                    'account_id': account_id,
                    'check_id': 'Reliability#RDS_No_Alarms',
                    'pillar': 'Reliability',
                    'check_name': 'RDS Instance Without CloudWatch Alarms',
                    'hri': True,
                    'evidence': db_instance['DBInstanceArn'],
                    'region': region,
                    'timestamp': datetime.utcnow().isoformat() + 'Z',
                    'execution_id': execution_id
                })
                
    except ClientError as e:
        logger.error(f"Error checking CloudWatch alarms in {region}: {e}")
    
    return findings


def check_backup_enabled(scanner_session, region: str, account_id: str,
                        execution_id: str) -> List[Dict[str, Any]]:
    """
    Verify backup solutions are enabled for critical resources
    
    Requirement 4.3: Verify backup solutions are enabled for critical resources
    """
    findings = []
    
    try:
        backup_client = scanner_session.get_client('backup', region=region)
        rds_client = scanner_session.get_client('rds', region=region)
        ec2_client = scanner_session.get_client('ec2', region=region)
        
        # Get backup plans
        backup_plans_response = backup_client.list_backup_plans()
        backup_plans = backup_plans_response.get('BackupPlansList', [])
        
        if len(backup_plans) == 0:
            findings.append({
                'account_id': account_id,
                'check_id': 'Reliability#No_Backup_Plans',
                'pillar': 'Reliability',
                'check_name': 'No AWS Backup Plans Configured',
                'hri': True,
                'evidence': f'No backup plans found in {region}',
                'region': region,
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'execution_id': execution_id
            })
        
        # Check RDS instances for automated backups
        rds_response = rds_client.describe_db_instances()
        
        for db_instance in rds_response.get('DBInstances', []):
            backup_retention = db_instance.get('BackupRetentionPeriod', 0)
            if backup_retention == 0:
                findings.append({
                    'account_id': account_id,
                    'check_id': 'Reliability#RDS_No_Backup',
                    'pillar': 'Reliability',
                    'check_name': 'RDS Instance Without Automated Backups',
                    'hri': True,
                    'evidence': db_instance['DBInstanceArn'],
                    'region': region,
                    'timestamp': datetime.utcnow().isoformat() + 'Z',
                    'execution_id': execution_id
                })
        
        # Check EBS volumes for snapshots (sample check)
        volumes_response = ec2_client.describe_volumes(MaxResults=100)
        volume_ids = [vol['VolumeId'] for vol in volumes_response.get('Volumes', [])]
        
        if volume_ids:
            snapshots_response = ec2_client.describe_snapshots(
                OwnerIds=[account_id],
                Filters=[{'Name': 'volume-id', 'Values': volume_ids[:10]}]  # Sample first 10
            )
            
            volumes_with_snapshots = set(
                snap['VolumeId'] for snap in snapshots_response.get('Snapshots', [])
            )
            
            for volume_id in volume_ids[:10]:  # Check first 10 volumes
                if volume_id not in volumes_with_snapshots:
                    findings.append({
                        'account_id': account_id,
                        'check_id': 'Reliability#EBS_No_Snapshot',
                        'pillar': 'Reliability',
                        'check_name': 'EBS Volume Without Recent Snapshots',
                        'hri': False,  # Lower priority
                        'evidence': f'arn:aws:ec2:{region}:{account_id}:volume/{volume_id}',
                        'region': region,
                        'timestamp': datetime.utcnow().isoformat() + 'Z',
                        'execution_id': execution_id
                    })
                    
    except ClientError as e:
        logger.error(f"Error checking backups in {region}: {e}")
    
    return findings


def check_single_az_rds(scanner_session, region: str, account_id: str,
                       execution_id: str) -> List[Dict[str, Any]]:
    """
    Identify single-AZ RDS instances
    
    Requirement 4.4: Identify single-AZ RDS instances
    """
    findings = []
    
    try:
        rds_client = scanner_session.get_client('rds', region=region)
        
        paginator = rds_client.get_paginator('describe_db_instances')
        
        for page in paginator.paginate():
            for db_instance in page.get('DBInstances', []):
                if not db_instance.get('MultiAZ', False):
                    findings.append({
                        'account_id': account_id,
                        'check_id': 'Reliability#RDS_Single_AZ',
                        'pillar': 'Reliability',
                        'check_name': 'RDS Instance in Single Availability Zone',
                        'hri': True,
                        'evidence': db_instance['DBInstanceArn'],
                        'region': region,
                        'timestamp': datetime.utcnow().isoformat() + 'Z',
                        'execution_id': execution_id
                    })
                    
    except ClientError as e:
        logger.error(f"Error checking RDS instances in {region}: {e}")
    
    return findings


def check_vpc_flow_logs(scanner_session, region: str, account_id: str,
                       execution_id: str) -> List[Dict[str, Any]]:
    """
    Verify VPC Flow Logs are enabled
    
    Requirement 4.5: Verify VPC Flow Logs are enabled
    """
    findings = []
    
    try:
        ec2_client = scanner_session.get_client('ec2', region=region)
        
        # Get all VPCs
        vpcs_response = ec2_client.describe_vpcs()
        vpcs = vpcs_response.get('Vpcs', [])
        
        # Get all flow logs
        flow_logs_response = ec2_client.describe_flow_logs()
        flow_logs = flow_logs_response.get('FlowLogs', [])
        
        # Get VPCs with flow logs
        vpcs_with_flow_logs = set(
            fl['ResourceId'] for fl in flow_logs 
            if fl.get('ResourceId', '').startswith('vpc-')
        )
        
        # Check each VPC
        for vpc in vpcs:
            vpc_id = vpc['VpcId']
            if vpc_id not in vpcs_with_flow_logs:
                findings.append({
                    'account_id': account_id,
                    'check_id': 'Reliability#VPC_No_Flow_Logs',
                    'pillar': 'Reliability',
                    'check_name': 'VPC Without Flow Logs Enabled',
                    'hri': True,
                    'evidence': f'arn:aws:ec2:{region}:{account_id}:vpc/{vpc_id}',
                    'region': region,
                    'timestamp': datetime.utcnow().isoformat() + 'Z',
                    'execution_id': execution_id,
                    'resource_tags': {tag['Key']: tag['Value'] for tag in vpc.get('Tags', [])}
                })
                
    except ClientError as e:
        logger.error(f"Error checking VPC Flow Logs in {region}: {e}")
    
    return findings


def check_asg_health_checks(scanner_session, region: str, account_id: str,
                            execution_id: str) -> List[Dict[str, Any]]:
    """
    Identify Auto Scaling Groups without health checks or scaling policies
    
    Requirement 4.6: Identify Auto Scaling Groups without health checks or scaling policies
    """
    findings = []
    
    try:
        autoscaling_client = scanner_session.get_client('autoscaling', region=region)
        
        # Get all Auto Scaling Groups
        paginator = autoscaling_client.get_paginator('describe_auto_scaling_groups')
        
        for page in paginator.paginate():
            for asg in page.get('AutoScalingGroups', []):
                asg_name = asg['AutoScalingGroupName']
                asg_arn = asg['AutoScalingGroupARN']
                
                # Check health check type
                health_check_type = asg.get('HealthCheckType', 'EC2')
                if health_check_type == 'EC2':
                    findings.append({
                        'account_id': account_id,
                        'check_id': 'Reliability#ASG_No_ELB_Health_Check',
                        'pillar': 'Reliability',
                        'check_name': 'Auto Scaling Group Without ELB Health Checks',
                        'hri': False,  # Lower priority
                        'evidence': asg_arn,
                        'region': region,
                        'timestamp': datetime.utcnow().isoformat() + 'Z',
                        'execution_id': execution_id
                    })
                
                # Check for scaling policies
                policies_response = autoscaling_client.describe_policies(
                    AutoScalingGroupName=asg_name
                )
                policies = policies_response.get('ScalingPolicies', [])
                
                if len(policies) == 0:
                    findings.append({
                        'account_id': account_id,
                        'check_id': 'Reliability#ASG_No_Scaling_Policy',
                        'pillar': 'Reliability',
                        'check_name': 'Auto Scaling Group Without Scaling Policies',
                        'hri': True,
                        'evidence': asg_arn,
                        'region': region,
                        'timestamp': datetime.utcnow().isoformat() + 'Z',
                        'execution_id': execution_id
                    })
                    
    except ClientError as e:
        logger.error(f"Error checking Auto Scaling Groups in {region}: {e}")
    
    return findings


def run_all_reliability_checks(scanner_session, regions: List[str], account_id: str,
                               execution_id: str) -> List[Dict[str, Any]]:
    """
    Run all reliability HRI checks
    
    Args:
        scanner_session: Scanner session with assumed role
        regions: List of regions to scan
        account_id: AWS account ID
        execution_id: Unique execution ID
        
    Returns:
        List of all reliability findings
    """
    all_findings = []
    
    logger.info(f"Running reliability checks for account {account_id}")
    
    # Regional checks
    for region in regions:
        all_findings.extend(check_config_enabled(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_cloudwatch_alarms(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_backup_enabled(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_single_az_rds(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_vpc_flow_logs(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_asg_health_checks(scanner_session, region, account_id, execution_id))
    
    logger.info(f"Reliability checks completed: {len(all_findings)} findings")
    
    return all_findings
