#!/usr/bin/env python3
"""
AWS Resource Discovery and Rightsizing Script
Account: 946447852237
Collects EBS, EC2, and RDS information across all enabled regions
Generates CSV reports with rightsizing recommendations
"""

import boto3
import csv
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Tuple
import sys
from botocore.exceptions import ClientError, BotoCoreError
import time

# Account Configuration
ACCOUNT_ID = "163799539090"
DEFAULT_ENVIRONMENT = "Prod"

# CloudWatch Configuration
CLOUDWATCH_DAYS = 30
CLOUDWATCH_PERIOD = 3600  # 1 hour

# Rightsizing Thresholds
CPU_LOW_THRESHOLD = 25.0
CPU_HIGH_THRESHOLD = 65.0

# Instance Type Families for Rightsizing
INSTANCE_TYPE_HIERARCHY = {
    't3': ['t3.nano', 't3.micro', 't3.small', 't3.medium', 't3.large', 't3.xlarge', 't3.2xlarge'],
    't3a': ['t3a.nano', 't3a.micro', 't3a.small', 't3a.medium', 't3a.large', 't3a.xlarge', 't3a.2xlarge'],
    't2': ['t2.nano', 't2.micro', 't2.small', 't2.medium', 't2.large', 't2.xlarge', 't2.2xlarge'],
    'm5': ['m5.large', 'm5.xlarge', 'm5.2xlarge', 'm5.4xlarge', 'm5.8xlarge', 'm5.12xlarge', 'm5.16xlarge', 'm5.24xlarge'],
    'm6i': ['m6i.large', 'm6i.xlarge', 'm6i.2xlarge', 'm6i.4xlarge', 'm6i.8xlarge', 'm6i.12xlarge', 'm6i.16xlarge', 'm6i.24xlarge', 'm6i.32xlarge'],
    'm4': ['m4.large', 'm4.xlarge', 'm4.2xlarge', 'm4.4xlarge', 'm4.10xlarge', 'm4.16xlarge'],
    'c5': ['c5.large', 'c5.xlarge', 'c5.2xlarge', 'c5.4xlarge', 'c5.9xlarge', 'c5.12xlarge', 'c5.18xlarge', 'c5.24xlarge'],
    'c6i': ['c6i.large', 'c6i.xlarge', 'c6i.2xlarge', 'c6i.4xlarge', 'c6i.8xlarge', 'c6i.12xlarge', 'c6i.16xlarge', 'c6i.24xlarge', 'c6i.32xlarge'],
    'c4': ['c4.large', 'c4.xlarge', 'c4.2xlarge', 'c4.4xlarge', 'c4.8xlarge'],
    'r5': ['r5.large', 'r5.xlarge', 'r5.2xlarge', 'r5.4xlarge', 'r5.8xlarge', 'r5.12xlarge', 'r5.16xlarge', 'r5.24xlarge'],
    'r6i': ['r6i.large', 'r6i.xlarge', 'r6i.2xlarge', 'r6i.4xlarge', 'r6i.8xlarge', 'r6i.12xlarge', 'r6i.16xlarge', 'r6i.24xlarge', 'r6i.32xlarge'],
    'r4': ['r4.large', 'r4.xlarge', 'r4.2xlarge', 'r4.4xlarge', 'r4.8xlarge', 'r4.16xlarge'],
}

# RDS Instance Type Hierarchy
RDS_INSTANCE_HIERARCHY = {
    'db.t3': ['db.t3.micro', 'db.t3.small', 'db.t3.medium', 'db.t3.large', 'db.t3.xlarge', 'db.t3.2xlarge'],
    'db.t2': ['db.t2.micro', 'db.t2.small', 'db.t2.medium', 'db.t2.large', 'db.t2.xlarge', 'db.t2.2xlarge'],
    'db.m5': ['db.m5.large', 'db.m5.xlarge', 'db.m5.2xlarge', 'db.m5.4xlarge', 'db.m5.8xlarge', 'db.m5.12xlarge', 'db.m5.16xlarge', 'db.m5.24xlarge'],
    'db.m4': ['db.m4.large', 'db.m4.xlarge', 'db.m4.2xlarge', 'db.m4.4xlarge', 'db.m4.10xlarge', 'db.m4.16xlarge'],
    'db.r5': ['db.r5.large', 'db.r5.xlarge', 'db.r5.2xlarge', 'db.r5.4xlarge', 'db.r5.8xlarge', 'db.r5.12xlarge', 'db.r5.16xlarge', 'db.r5.24xlarge'],
    'db.r4': ['db.r4.large', 'db.r4.xlarge', 'db.r4.2xlarge', 'db.r4.4xlarge', 'db.r4.8xlarge', 'db.r4.16xlarge'],
}


def get_tag_value(tags: List[Dict], keys: List[str]) -> Optional[str]:
    """Extract tag value from list of tags by checking multiple possible keys."""
    if not tags:
        return None
    for tag in tags:
        if tag.get('Key') in keys:
            return tag.get('Value')
    return None


def determine_environment(tags: List[Dict]) -> str:
    """Determine environment from tags with fallback logic."""
    env_keys = ["Environment", "environment", "Env", "env", "Stage", "stage"]
    env_value = get_tag_value(tags, env_keys)
    
    if not env_value:
        return DEFAULT_ENVIRONMENT
    
    env_lower = env_value.lower()
    if 'prod' in env_lower:
        return 'Prod'
    elif any(x in env_lower for x in ['dev', 'qa', 'test', 'stage', 'stg', 'nonprod']):
        return 'NonProd'
    
    return DEFAULT_ENVIRONMENT


def get_account_id() -> str:
    """Get current AWS account ID."""
    try:
        sts = boto3.client('sts')
        return sts.get_caller_identity()['Account']
    except Exception as e:
        print(f"Warning: Could not retrieve account ID: {e}")
        return ACCOUNT_ID


def get_enabled_regions() -> List[str]:
    """Get list of enabled AWS regions."""
    try:
        ec2 = boto3.client('ec2', region_name='us-east-1')
        response = ec2.describe_regions(AllRegions=False)
        regions = [region['RegionName'] for region in response['Regions']]
        print(f"Found {len(regions)} enabled regions")
        return regions
    except Exception as e:
        print(f"Error getting regions: {e}")
        return ['us-east-1']  # Fallback to us-east-1


def get_cloudwatch_metrics(region: str, namespace: str, metric_name: str, 
                           dimensions: List[Dict], statistic: str = 'Average') -> Tuple[Optional[float], int]:
    """Get CloudWatch metrics for the last 30 days."""
    try:
        cloudwatch = boto3.client('cloudwatch', region_name=region)
        end_time = datetime.now(timezone.utc)
        start_time = end_time - timedelta(days=CLOUDWATCH_DAYS)
        
        response = cloudwatch.get_metric_statistics(
            Namespace=namespace,
            MetricName=metric_name,
            Dimensions=dimensions,
            StartTime=start_time,
            EndTime=end_time,
            Period=CLOUDWATCH_PERIOD,
            Statistics=[statistic]
        )
        
        datapoints = response.get('Datapoints', [])
        if not datapoints:
            return None, 0
        
        values = [dp[statistic] for dp in datapoints]
        avg_value = sum(values) / len(values)
        return avg_value, len(values)
    
    except Exception as e:
        print(f"  Warning: CloudWatch metrics error: {e}")
        return None, 0


def get_instance_rightsizing(instance_type: str, avg_cpu: Optional[float]) -> Tuple[str, str, str]:
    """Determine rightsizing recommendation for EC2 instance."""
    if avg_cpu is None:
        return "NoData", instance_type, "Insufficient CloudWatch data"
    
    # Extract family from instance type
    family = instance_type.rsplit('.', 1)[0]
    
    # Find hierarchy for this family
    hierarchy = None
    for fam, types in INSTANCE_TYPE_HIERARCHY.items():
        if family.startswith(fam):
            hierarchy = types
            break
    
    if not hierarchy or instance_type not in hierarchy:
        if avg_cpu < CPU_LOW_THRESHOLD:
            return "Downsize", instance_type, f"Low CPU ({avg_cpu:.1f}%) but no smaller type available"
        elif avg_cpu > CPU_HIGH_THRESHOLD:
            return "Upsize", instance_type, f"High CPU ({avg_cpu:.1f}%) but no larger type available"
        else:
            return "Keep", instance_type, f"CPU utilization optimal ({avg_cpu:.1f}%)"
    
    current_index = hierarchy.index(instance_type)
    
    if avg_cpu < CPU_LOW_THRESHOLD:
        if current_index > 0:
            recommended = hierarchy[current_index - 1]
            return "Downsize", recommended, f"Low CPU utilization ({avg_cpu:.1f}%)"
        else:
            return "Keep", instance_type, f"Low CPU ({avg_cpu:.1f}%) but already smallest type"
    
    elif avg_cpu > CPU_HIGH_THRESHOLD:
        if current_index < len(hierarchy) - 1:
            recommended = hierarchy[current_index + 1]
            return "Upsize", recommended, f"High CPU utilization ({avg_cpu:.1f}%)"
        else:
            return "Keep", instance_type, f"High CPU ({avg_cpu:.1f}%) but already largest type"
    
    else:
        return "Keep", instance_type, f"CPU utilization optimal ({avg_cpu:.1f}%)"


def get_rds_rightsizing(instance_class: str, avg_cpu: Optional[float]) -> Tuple[str, str, str]:
    """Determine rightsizing recommendation for RDS instance."""
    if avg_cpu is None:
        return "NoData", instance_class, "Insufficient CloudWatch data"
    
    # Extract family from instance class
    family = instance_class.rsplit('.', 1)[0]
    
    # Find hierarchy for this family
    hierarchy = None
    for fam, types in RDS_INSTANCE_HIERARCHY.items():
        if family == fam:
            hierarchy = types
            break
    
    if not hierarchy or instance_class not in hierarchy:
        if avg_cpu < CPU_LOW_THRESHOLD:
            return "Downsize", instance_class, f"Low CPU ({avg_cpu:.1f}%) but no smaller type available"
        elif avg_cpu > CPU_HIGH_THRESHOLD:
            return "Upsize", instance_class, f"High CPU ({avg_cpu:.1f}%) but no larger type available"
        else:
            return "Keep", instance_class, f"CPU utilization optimal ({avg_cpu:.1f}%)"
    
    current_index = hierarchy.index(instance_class)
    
    if avg_cpu < CPU_LOW_THRESHOLD:
        if current_index > 0:
            recommended = hierarchy[current_index - 1]
            return "Downsize", recommended, f"Low CPU utilization ({avg_cpu:.1f}%)"
        else:
            return "Keep", instance_class, f"Low CPU ({avg_cpu:.1f}%) but already smallest type"
    
    elif avg_cpu > CPU_HIGH_THRESHOLD:
        if current_index < len(hierarchy) - 1:
            recommended = hierarchy[current_index + 1]
            return "Upsize", recommended, f"High CPU utilization ({avg_cpu:.1f}%)"
        else:
            return "Keep", instance_class, f"High CPU ({avg_cpu:.1f}%) but already largest type"
    
    else:
        return "Keep", instance_class, f"CPU utilization optimal ({avg_cpu:.1f}%)"


def collect_ebs_volumes(region: str, account_id: str) -> List[Dict]:
    """Collect EBS volume information for a region."""
    print(f"  Collecting EBS volumes in {region}...")
    volumes_data = []
    
    try:
        ec2 = boto3.client('ec2', region_name=region)
        
        # Get all volumes
        paginator = ec2.get_paginator('describe_volumes')
        for page in paginator.paginate():
            for volume in page['Volumes']:
                volume_id = volume['VolumeId']
                
                # Get volume name from tags
                volume_name = get_tag_value(volume.get('Tags', []), ['Name', 'name'])
                environment = determine_environment(volume.get('Tags', []))
                
                # Attachment information
                attachments = volume.get('Attachments', [])
                is_attached = len(attachments) > 0
                attached_instance_id = attachments[0]['InstanceId'] if is_attached else ''
                attachment_device = attachments[0]['Device'] if is_attached else ''
                
                # Get instance name if attached
                attached_instance_name = ''
                volume_classification = 'Unattached'
                if is_attached:
                    try:
                        instance_response = ec2.describe_instances(InstanceIds=[attached_instance_id])
                        if instance_response['Reservations']:
                            instance = instance_response['Reservations'][0]['Instances'][0]
                            attached_instance_name = get_tag_value(instance.get('Tags', []), ['Name', 'name']) or ''
                            
                            # Determine if root or data volume
                            root_device = instance.get('RootDeviceName', '')
                            if attachment_device == root_device:
                                volume_classification = 'Root/Internal'
                            else:
                                volume_classification = 'Data/External'
                    except Exception as e:
                        print(f"    Warning: Could not get instance details for {attached_instance_id}: {e}")
                
                # Snapshot information
                latest_snapshot_id = ''
                latest_snapshot_time = ''
                days_since_last_snapshot = ''
                
                try:
                    snapshot_response = ec2.describe_snapshots(
                        Filters=[{'Name': 'volume-id', 'Values': [volume_id]}],
                        OwnerIds=[account_id]
                    )
                    snapshots = snapshot_response.get('Snapshots', [])
                    if snapshots:
                        # Sort by start time, most recent first
                        snapshots.sort(key=lambda x: x['StartTime'], reverse=True)
                        latest_snapshot = snapshots[0]
                        latest_snapshot_id = latest_snapshot['SnapshotId']
                        latest_snapshot_time = latest_snapshot['StartTime'].strftime('%Y-%m-%d %H:%M:%S')
                        days_since = (datetime.now(latest_snapshot['StartTime'].tzinfo) - latest_snapshot['StartTime']).days
                        days_since_last_snapshot = str(days_since)
                except Exception as e:
                    print(f"    Warning: Could not get snapshots for {volume_id}: {e}")
                
                # Rightsizing recommendation
                volume_type = volume['VolumeType']
                size_gb = volume['Size']
                iops = volume.get('Iops', 0)
                
                recommendation = 'Keep as is'
                if volume_type == 'gp2':
                    recommendation = 'Convert gp2→gp3'
                elif size_gb >= 100 and volume_type == 'gp2':
                    recommendation = 'Convert gp2→gp3'
                elif not is_attached and days_since_last_snapshot and int(days_since_last_snapshot) > 30:
                    recommendation = 'Delete if unattached > 30 days'
                
                volumes_data.append({
                    'account_id': account_id,
                    'region': region,
                    'volume_id': volume_id,
                    'volume_name': volume_name or '',
                    'environment': environment,
                    'volume_type': volume_type,
                    'size_gb': size_gb,
                    'iops_provisioned': iops,
                    'throughput_mbps': volume.get('Throughput', 0),
                    'state': volume['State'],
                    'is_attached': 'Yes' if is_attached else 'No',
                    'attached_instance_id': attached_instance_id,
                    'attached_instance_name': attached_instance_name,
                    'attachment_device': attachment_device,
                    'volume_classification': volume_classification,
                    'latest_snapshot_id': latest_snapshot_id,
                    'latest_snapshot_time': latest_snapshot_time,
                    'days_since_last_snapshot': days_since_last_snapshot,
                    'encrypted': 'Yes' if volume.get('Encrypted', False) else 'No',
                    'kms_key_id': volume.get('KmsKeyId', ''),
                    'multi_attach_enabled': 'Yes' if volume.get('MultiAttachEnabled', False) else 'No',
                    'rightsizing_recommendation': recommendation
                })
        
        print(f"    Found {len(volumes_data)} EBS volumes")
    
    except Exception as e:
        print(f"    Error collecting EBS volumes in {region}: {e}")
    
    return volumes_data


def collect_ec2_instances(region: str, account_id: str) -> List[Dict]:
    """Collect EC2 instance information for a region."""
    print(f"  Collecting EC2 instances in {region}...")
    instances_data = []
    
    try:
        ec2 = boto3.client('ec2', region_name=region)
        
        # Get all instances
        paginator = ec2.get_paginator('describe_instances')
        for page in paginator.paginate():
            for reservation in page['Reservations']:
                for instance in reservation['Instances']:
                    instance_id = instance['InstanceId']
                    instance_type = instance['InstanceType']
                    
                    # Get instance name from tags
                    instance_name = get_tag_value(instance.get('Tags', []), ['Name', 'name'])
                    environment = determine_environment(instance.get('Tags', []))
                    
                    # Instance family
                    instance_family = instance_type.rsplit('.', 1)[0]
                    
                    # Launch time
                    launch_time = instance.get('LaunchTime')
                    days_since_launch = ''
                    if launch_time:
                        days_since_launch = (datetime.now(launch_time.tzinfo) - launch_time).days
                    
                    # Root volume information
                    root_device_name = instance.get('RootDeviceName', '')
                    root_volume_size = 0
                    root_volume_type = ''
                    
                    for bdm in instance.get('BlockDeviceMappings', []):
                        if bdm.get('DeviceName') == root_device_name:
                            volume_id = bdm.get('Ebs', {}).get('VolumeId')
                            if volume_id:
                                try:
                                    vol_response = ec2.describe_volumes(VolumeIds=[volume_id])
                                    if vol_response['Volumes']:
                                        vol = vol_response['Volumes'][0]
                                        root_volume_size = vol['Size']
                                        root_volume_type = vol['VolumeType']
                                except Exception as e:
                                    print(f"    Warning: Could not get root volume details: {e}")
                            break
                    
                    # Check for instance store
                    has_instance_store = 'No'
                    for bdm in instance.get('BlockDeviceMappings', []):
                        if 'VirtualName' in bdm:
                            has_instance_store = 'Yes'
                            break
                    
                    # Network information
                    private_ips = ','.join([ni.get('PrivateIpAddress', '') for ni in instance.get('NetworkInterfaces', []) if ni.get('PrivateIpAddress')])
                    public_ip = instance.get('PublicIpAddress', '')
                    subnet_id = instance.get('SubnetId', '')
                    vpc_id = instance.get('VpcId', '')
                    
                    # Security groups - handle both VPC and EC2-Classic formats
                    security_groups = []
                    for sg in instance.get('SecurityGroups', []):
                        if 'GroupId' in sg:
                            security_groups.append(sg['GroupId'])
                        elif 'GroupName' in sg:
                            security_groups.append(sg['GroupName'])
                    security_group_ids = ','.join(security_groups)
                    
                    # Auto Scaling Group
                    asg_name = get_tag_value(instance.get('Tags', []), ['aws:autoscaling:groupName'])
                    
                    # CloudWatch CPU metrics
                    avg_cpu, cpu_datapoints = get_cloudwatch_metrics(
                        region=region,
                        namespace='AWS/EC2',
                        metric_name='CPUUtilization',
                        dimensions=[{'Name': 'InstanceId', 'Value': instance_id}],
                        statistic='Average'
                    )
                    
                    # Purchase option (simplified - would need more logic for actual RI/SP detection)
                    purchase_option = 'OnDemand'
                    if instance.get('InstanceLifecycle') == 'spot':
                        purchase_option = 'Spot'
                    
                    # Rightsizing
                    action, recommended_type, reason = get_instance_rightsizing(instance_type, avg_cpu)
                    
                    instances_data.append({
                        'account_id': account_id,
                        'region': region,
                        'instance_id': instance_id,
                        'instance_name': instance_name or '',
                        'environment': environment,
                        'state': instance['State']['Name'],
                        'platform': instance.get('Platform', 'Linux/Unix'),
                        'instance_type': instance_type,
                        'instance_family': instance_family,
                        'vcpu_count': instance.get('CpuOptions', {}).get('CoreCount', 0) * instance.get('CpuOptions', {}).get('ThreadsPerCore', 1),
                        'cpu_architecture': instance.get('Architecture', ''),
                        'launch_time': launch_time.strftime('%Y-%m-%d %H:%M:%S') if launch_time else '',
                        'days_since_launch': days_since_launch,
                        'root_volume_size_gb': root_volume_size,
                        'root_volume_type': root_volume_type,
                        'has_instance_store': has_instance_store,
                        'private_ips': private_ips,
                        'public_ip': public_ip,
                        'subnet_id': subnet_id,
                        'vpc_id': vpc_id,
                        'security_group_ids': security_group_ids,
                        'autoscaling_group_name': asg_name or '',
                        'avg_cpu_30d': f"{avg_cpu:.2f}" if avg_cpu is not None else '',
                        'cpu_data_points_count_30d': cpu_datapoints,
                        'purchase_option': purchase_option,
                        'rightsizing_action': action,
                        'recommended_instance_type': recommended_type,
                        'recommendation_reason': reason
                    })
        
        print(f"    Found {len(instances_data)} EC2 instances")
    
    except Exception as e:
        print(f"    Error collecting EC2 instances in {region}: {e}")
    
    return instances_data


def collect_rds_instances(region: str, account_id: str) -> List[Dict]:
    """Collect RDS instance information for a region."""
    print(f"  Collecting RDS instances in {region}...")
    instances_data = []
    
    try:
        rds = boto3.client('rds', region_name=region)
        
        # Get all DB instances
        paginator = rds.get_paginator('describe_db_instances')
        for page in paginator.paginate():
            for db_instance in page['DBInstances']:
                db_identifier = db_instance['DBInstanceIdentifier']
                db_instance_class = db_instance['DBInstanceClass']
                
                # Get tags
                try:
                    tags_response = rds.list_tags_for_resource(
                        ResourceName=db_instance['DBInstanceArn']
                    )
                    tags = tags_response.get('TagList', [])
                except Exception as e:
                    print(f"    Warning: Could not get tags for {db_identifier}: {e}")
                    tags = []
                
                environment = determine_environment(tags)
                
                # Application name from tags
                app_keys = ['Application', 'App', 'Service', 'Owner', 'Team', 'application', 'app']
                application_name = get_tag_value(tags, app_keys) or 'Unknown'
                
                # Instance family
                instance_family = db_instance_class.rsplit('.', 1)[0]
                
                # Creation time
                create_time = db_instance.get('InstanceCreateTime')
                days_since_create = ''
                if create_time:
                    days_since_create = (datetime.now(create_time.tzinfo) - create_time).days
                
                # CloudWatch metrics
                avg_cpu, cpu_datapoints = get_cloudwatch_metrics(
                    region=region,
                    namespace='AWS/RDS',
                    metric_name='CPUUtilization',
                    dimensions=[{'Name': 'DBInstanceIdentifier', 'Value': db_identifier}],
                    statistic='Average'
                )
                
                avg_freeable_memory, _ = get_cloudwatch_metrics(
                    region=region,
                    namespace='AWS/RDS',
                    metric_name='FreeableMemory',
                    dimensions=[{'Name': 'DBInstanceIdentifier', 'Value': db_identifier}],
                    statistic='Average'
                )
                
                avg_free_storage, _ = get_cloudwatch_metrics(
                    region=region,
                    namespace='AWS/RDS',
                    metric_name='FreeStorageSpace',
                    dimensions=[{'Name': 'DBInstanceIdentifier', 'Value': db_identifier}],
                    statistic='Average'
                )
                
                # Convert bytes to MB/GB
                avg_freeable_memory_mb = avg_freeable_memory / (1024 * 1024) if avg_freeable_memory else None
                avg_free_storage_gb = avg_free_storage / (1024 * 1024 * 1024) if avg_free_storage else None
                
                # Rightsizing
                action, recommended_class, reason = get_rds_rightsizing(db_instance_class, avg_cpu)
                
                # Storage recommendation
                storage_type = db_instance.get('StorageType', '')
                storage_recommendation = ''
                if storage_type == 'gp2':
                    storage_recommendation = 'Consider converting gp2→gp3'
                
                # Latest restorable time
                latest_restorable = db_instance.get('LatestRestorableTime', '')
                if latest_restorable:
                    latest_restorable = latest_restorable.strftime('%Y-%m-%d %H:%M:%S')
                
                instances_data.append({
                    'account_id': account_id,
                    'region': region,
                    'db_instance_identifier': db_identifier,
                    'db_name': db_instance.get('DBName', ''),
                    'engine': db_instance['Engine'],
                    'engine_version': db_instance['EngineVersion'],
                    'db_instance_class': db_instance_class,
                    'instance_family': instance_family,
                    'multi_az': 'Yes' if db_instance.get('MultiAZ', False) else 'No',
                    'storage_type': storage_type,
                    'allocated_storage_gb': db_instance.get('AllocatedStorage', 0),
                    'max_allocated_storage_gb': db_instance.get('MaxAllocatedStorage', 0),
                    'storage_encrypted': 'Yes' if db_instance.get('StorageEncrypted', False) else 'No',
                    'kms_key_id': db_instance.get('KmsKeyId', ''),
                    'publicly_accessible': 'Yes' if db_instance.get('PubliclyAccessible', False) else 'No',
                    'vpc_id': db_instance.get('DBSubnetGroup', {}).get('VpcId', ''),
                    'subnet_group_name': db_instance.get('DBSubnetGroup', {}).get('DBSubnetGroupName', ''),
                    'environment': environment,
                    'application_name': application_name,
                    'avg_cpu_30d': f"{avg_cpu:.2f}" if avg_cpu is not None else '',
                    'avg_freeable_memory_30d_mb': f"{avg_freeable_memory_mb:.2f}" if avg_freeable_memory_mb is not None else '',
                    'avg_free_storage_gb': f"{avg_free_storage_gb:.2f}" if avg_free_storage_gb is not None else '',
                    'instance_create_time': create_time.strftime('%Y-%m-%d %H:%M:%S') if create_time else '',
                    'days_since_create': days_since_create,
                    'backup_retention_period': db_instance.get('BackupRetentionPeriod', 0),
                    'latest_restorable_time': latest_restorable,
                    'rightsizing_action': action,
                    'recommended_instance_class': recommended_class,
                    'recommendation_reason': reason,
                    'storage_recommendation': storage_recommendation
                })
        
        print(f"    Found {len(instances_data)} RDS instances")
    
    except Exception as e:
        print(f"    Error collecting RDS instances in {region}: {e}")
    
    return instances_data


def write_csv(filename: str, data: List[Dict], fieldnames: List[str]):
    """Write data to CSV file."""
    try:
        with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(data)
        print(f"✓ Written {len(data)} records to {filename}")
    except Exception as e:
        print(f"✗ Error writing {filename}: {e}")


def main():
    """Main execution function."""
    print("=" * 80)
    print("AWS Resource Discovery and Rightsizing Analysis")
    print(f"Account: {ACCOUNT_ID}")
    print(f"Default Environment: {DEFAULT_ENVIRONMENT}")
    print("=" * 80)
    
    # Verify account
    actual_account_id = get_account_id()
    if actual_account_id != ACCOUNT_ID:
        print(f"Warning: Script configured for {ACCOUNT_ID} but running in {actual_account_id}")
        response = input("Continue anyway? (yes/no): ")
        if response.lower() != 'yes':
            print("Exiting...")
            sys.exit(1)
    
    # Get enabled regions
    regions = get_enabled_regions()
    print(f"\nScanning {len(regions)} regions...\n")
    
    # Collect data from all regions
    all_ebs_data = []
    all_ec2_data = []
    all_rds_data = []
    
    for region in regions:
        print(f"\n[{region}]")
        
        # Collect EBS volumes
        ebs_data = collect_ebs_volumes(region, ACCOUNT_ID)
        all_ebs_data.extend(ebs_data)
        
        # Collect EC2 instances
        ec2_data = collect_ec2_instances(region, ACCOUNT_ID)
        all_ec2_data.extend(ec2_data)
        
        # Collect RDS instances
        rds_data = collect_rds_instances(region, ACCOUNT_ID)
        all_rds_data.extend(rds_data)
    
    # Write CSV files
    print("\n" + "=" * 80)
    print("Writing CSV files...")
    print("=" * 80)
    
    # EBS CSV
    ebs_fieldnames = [
        'account_id', 'region', 'volume_id', 'volume_name', 'environment',
        'volume_type', 'size_gb', 'iops_provisioned', 'throughput_mbps',
        'state', 'is_attached', 'attached_instance_id', 'attached_instance_name',
        'attachment_device', 'volume_classification', 'latest_snapshot_id',
        'latest_snapshot_time', 'days_since_last_snapshot', 'encrypted',
        'kms_key_id', 'multi_attach_enabled', 'rightsizing_recommendation'
    ]
    write_csv(f'{ACCOUNT_ID}-ebs.csv', all_ebs_data, ebs_fieldnames)
    
    # EC2 CSV
    ec2_fieldnames = [
        'account_id', 'region', 'instance_id', 'instance_name', 'environment',
        'state', 'platform', 'instance_type', 'instance_family', 'vcpu_count',
        'cpu_architecture', 'launch_time', 'days_since_launch',
        'root_volume_size_gb', 'root_volume_type', 'has_instance_store',
        'private_ips', 'public_ip', 'subnet_id', 'vpc_id', 'security_group_ids',
        'autoscaling_group_name', 'avg_cpu_30d', 'cpu_data_points_count_30d',
        'purchase_option', 'rightsizing_action', 'recommended_instance_type',
        'recommendation_reason'
    ]
    write_csv(f'{ACCOUNT_ID}-ec2.csv', all_ec2_data, ec2_fieldnames)
    
    # RDS CSV
    rds_fieldnames = [
        'account_id', 'region', 'db_instance_identifier', 'db_name', 'engine',
        'engine_version', 'db_instance_class', 'instance_family', 'multi_az',
        'storage_type', 'allocated_storage_gb', 'max_allocated_storage_gb',
        'storage_encrypted', 'kms_key_id', 'publicly_accessible', 'vpc_id',
        'subnet_group_name', 'environment', 'application_name', 'avg_cpu_30d',
        'avg_freeable_memory_30d_mb', 'avg_free_storage_gb', 'instance_create_time',
        'days_since_create', 'backup_retention_period', 'latest_restorable_time',
        'rightsizing_action', 'recommended_instance_class', 'recommendation_reason',
        'storage_recommendation'
    ]
    write_csv(f'{ACCOUNT_ID}-rds.csv', all_rds_data, rds_fieldnames)
    
    # Summary
    print("\n" + "=" * 80)
    print("Summary")
    print("=" * 80)
    print(f"Total EBS Volumes: {len(all_ebs_data)}")
    print(f"Total EC2 Instances: {len(all_ec2_data)}")
    print(f"Total RDS Instances: {len(all_rds_data)}")
    print("\nFiles generated:")
    print(f"  - {ACCOUNT_ID}-ebs.csv")
    print(f"  - {ACCOUNT_ID}-ec2.csv")
    print(f"  - {ACCOUNT_ID}-rds.csv")
    print("\n✓ Discovery complete!")


if __name__ == '__main__':
    main()
