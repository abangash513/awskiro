#!/usr/bin/env python3
"""
AWS Resource Inventory with Rightsizing Recommendations
Generates two CSV files:
1. awsdev_ebs_inventory.csv - All EBS volumes
2. awsdev_compute_inventory.csv - EC2, RDS, and ECS resources with rightsizing
"""

import boto3
import csv
from datetime import datetime, timedelta
from botocore.exceptions import ClientError, EndpointConnectionError
from botocore.config import Config
import time

# Configuration
ACCOUNT_NAME = "AWS Development"
ACCOUNT_ID = "013612877090"
PROFILE_NAME = "srsa-dev"
ENV_HINT = "dev"
EBS_OUTPUT_FILE = "awsdev_ebs_inventory.csv"
COMPUTE_OUTPUT_FILE = "awsdev_compute_inventory.csv"

# Boto3 config with retries
config = Config(
    retries={
        'max_attempts': 10,
        'mode': 'adaptive'
    }
)

# Instance type families for rightsizing
INSTANCE_TYPE_SIZES = {
    't2': ['nano', 'micro', 'small', 'medium', 'large', 'xlarge', '2xlarge'],
    't3': ['nano', 'micro', 'small', 'medium', 'large', 'xlarge', '2xlarge'],
    't3a': ['nano', 'micro', 'small', 'medium', 'large', 'xlarge', '2xlarge'],
    'm5': ['large', 'xlarge', '2xlarge', '4xlarge', '8xlarge', '12xlarge', '16xlarge', '24xlarge'],
    'm5a': ['large', 'xlarge', '2xlarge', '4xlarge', '8xlarge', '12xlarge', '16xlarge', '24xlarge'],
    'm6i': ['large', 'xlarge', '2xlarge', '4xlarge', '8xlarge', '12xlarge', '16xlarge', '24xlarge', '32xlarge'],
    'c5': ['large', 'xlarge', '2xlarge', '4xlarge', '9xlarge', '12xlarge', '18xlarge', '24xlarge'],
    'c6i': ['large', 'xlarge', '2xlarge', '4xlarge', '8xlarge', '12xlarge', '16xlarge', '24xlarge', '32xlarge'],
    'r5': ['large', 'xlarge', '2xlarge', '4xlarge', '8xlarge', '12xlarge', '16xlarge', '24xlarge'],
    'r6i': ['large', 'xlarge', '2xlarge', '4xlarge', '8xlarge', '12xlarge', '16xlarge', '24xlarge', '32xlarge'],
}

# RDS instance class sizes
RDS_CLASS_SIZES = {
    'db.t3': ['micro', 'small', 'medium', 'large', 'xlarge', '2xlarge'],
    'db.t4g': ['micro', 'small', 'medium', 'large', 'xlarge', '2xlarge'],
    'db.m5': ['large', 'xlarge', '2xlarge', '4xlarge', '8xlarge', '12xlarge', '16xlarge', '24xlarge'],
    'db.m6i': ['large', 'xlarge', '2xlarge', '4xlarge', '8xlarge', '12xlarge', '16xlarge', '24xlarge', '32xlarge'],
    'db.r5': ['large', 'xlarge', '2xlarge', '4xlarge', '8xlarge', '12xlarge', '16xlarge', '24xlarge'],
    'db.r6i': ['large', 'xlarge', '2xlarge', '4xlarge', '8xlarge', '12xlarge', '16xlarge', '24xlarge', '32xlarge'],
}

def get_session():
    """Create boto3 session"""
    try:
        return boto3.Session(profile_name=PROFILE_NAME)
    except:
        return boto3.Session()

def get_enabled_regions(session):
    """Get all enabled AWS regions"""
    ec2_client = session.client('ec2', region_name='us-east-1', config=config)
    try:
        regions = ec2_client.describe_regions(
            Filters=[{'Name': 'opt-in-status', 'Values': ['opt-in-not-required', 'opted-in']}]
        )
        return [region['RegionName'] for region in regions['Regions']]
    except Exception as e:
        print(f"Error getting regions: {e}")
        return ['us-east-1', 'us-east-2', 'us-west-1', 'us-west-2']

def get_tag_value(tags, key):
    """Extract tag value from tags list"""
    if not tags:
        return ""
    for tag in tags:
        if tag.get('Key') == key:
            return tag.get('Value', '')
    return ""

def get_cloudwatch_cpu_utilization(session, region, namespace, dimensions, metric_name='CPUUtilization'):
    """Get average CPU utilization from CloudWatch for last 14 days"""
    try:
        cw_client = session.client('cloudwatch', region_name=region, config=config)
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(days=14)
        
        response = cw_client.get_metric_statistics(
            Namespace=namespace,
            MetricName=metric_name,
            Dimensions=dimensions,
            StartTime=start_time,
            EndTime=end_time,
            Period=3600,  # 1 hour
            Statistics=['Average']
        )
        
        if response['Datapoints']:
            avg_cpu = sum(dp['Average'] for dp in response['Datapoints']) / len(response['Datapoints'])
            return round(avg_cpu, 2)
        return 0.0
    except Exception as e:
        return 0.0

def get_rds_free_storage(session, region, db_instance_id):
    """Get free storage space for RDS instance"""
    try:
        cw_client = session.client('cloudwatch', region_name=region, config=config)
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(days=14)
        
        response = cw_client.get_metric_statistics(
            Namespace='AWS/RDS',
            MetricName='FreeStorageSpace',
            Dimensions=[{'Name': 'DBInstanceIdentifier', 'Value': db_instance_id}],
            StartTime=start_time,
            EndTime=end_time,
            Period=3600,
            Statistics=['Average']
        )
        
        if response['Datapoints']:
            avg_free_bytes = sum(dp['Average'] for dp in response['Datapoints']) / len(response['Datapoints'])
            return round(avg_free_bytes / (1024**3), 2)  # Convert to GiB
        return 0.0
    except Exception as e:
        return 0.0

def recommend_instance_size(instance_type, cpu_utilization):
    """Recommend instance size based on CPU utilization"""
    try:
        parts = instance_type.split('.')
        if len(parts) != 2:
            return ""
        
        family = parts[0]
        size = parts[1]
        
        if family not in INSTANCE_TYPE_SIZES:
            return ""
        
        sizes = INSTANCE_TYPE_SIZES[family]
        if size not in sizes:
            return ""
        
        current_index = sizes.index(size)
        
        if cpu_utilization < 20 and current_index > 0:
            # Recommend smaller
            return f"{family}.{sizes[current_index - 1]}"
        elif cpu_utilization > 60 and current_index < len(sizes) - 1:
            # Recommend larger
            return f"{family}.{sizes[current_index + 1]}"
        else:
            return instance_type
    except:
        return ""

def recommend_rds_class(db_class, cpu_utilization, free_storage_gib, allocated_storage_gib):
    """Recommend RDS instance class based on metrics"""
    try:
        # Extract family and size (e.g., db.m5.large -> db.m5, large)
        parts = db_class.rsplit('.', 1)
        if len(parts) != 2:
            return ""
        
        family = parts[0]
        size = parts[1]
        
        if family not in RDS_CLASS_SIZES:
            return ""
        
        sizes = RDS_CLASS_SIZES[family]
        if size not in sizes:
            return ""
        
        current_index = sizes.index(size)
        free_storage_percent = (free_storage_gib / allocated_storage_gib * 100) if allocated_storage_gib > 0 else 0
        
        if cpu_utilization < 20 and free_storage_percent > 30 and current_index > 0:
            # Recommend smaller
            return f"{family}.{sizes[current_index - 1]}"
        elif cpu_utilization > 60 and current_index < len(sizes) - 1:
            # Recommend larger
            return f"{family}.{sizes[current_index + 1]}"
        else:
            return db_class
    except:
        return ""

def collect_ebs_volumes(session, region):
    """Collect EBS volume information"""
    print(f"  Processing EBS volumes in {region}...")
    ec2_client = session.client('ec2', region_name=region, config=config)
    volumes = []
    
    try:
        paginator = ec2_client.get_paginator('describe_volumes')
        for page in paginator.paginate():
            for volume in page['Volumes']:
                is_unattached = len(volume.get('Attachments', [])) == 0
                attached_instance_id = ""
                attached_instance_type = ""
                attached_instance_arn = ""
                attached_instance_launch_time = ""
                is_root_volume = False
                
                if not is_unattached:
                    attachment = volume['Attachments'][0]
                    attached_instance_id = attachment.get('InstanceId', '')
                    device_name = attachment.get('Device', '')
                    
                    # Get instance details
                    try:
                        instance_response = ec2_client.describe_instances(InstanceIds=[attached_instance_id])
                        if instance_response['Reservations']:
                            instance = instance_response['Reservations'][0]['Instances'][0]
                            attached_instance_arn = f"arn:aws:ec2:{region}:{ACCOUNT_ID}:instance/{attached_instance_id}"
                            attached_instance_type = instance.get('InstanceType', '')
                            launch_time = instance.get('LaunchTime')
                            if launch_time:
                                attached_instance_launch_time = launch_time.isoformat()
                            
                            # Check if root volume
                            root_device = instance.get('RootDeviceName', '')
                            is_root_volume = (device_name == root_device)
                    except Exception as e:
                        pass
                
                environment = get_tag_value(volume.get('Tags'), 'Environment') or ENV_HINT
                
                volumes.append({
                    'AccountName': ACCOUNT_NAME,
                    'AccountId': ACCOUNT_ID,
                    'Environment': environment,
                    'Region': region,
                    'VolumeId': volume['VolumeId'],
                    'VolumeType': volume.get('VolumeType', ''),
                    'SizeGiB': volume.get('Size', 0),
                    'Encrypted': volume.get('Encrypted', False),
                    'Iops': volume.get('Iops', ''),
                    'Throughput': volume.get('Throughput', ''),
                    'State': volume.get('State', ''),
                    'IsUnattached': is_unattached,
                    'AttachedInstanceId': attached_instance_id,
                    'AttachedInstanceType': attached_instance_type,
                    'AttachedInstanceArn': attached_instance_arn,
                    'AttachedInstanceLaunchTime': attached_instance_launch_time,
                    'IsRootVolume': is_root_volume
                })
        
        print(f"    Found {len(volumes)} EBS volumes")
    except ClientError as e:
        if e.response['Error']['Code'] == 'UnauthorizedOperation':
            print(f"    No permission in {region}")
        else:
            print(f"    Error: {e}")
    except Exception as e:
        print(f"    Error: {e}")
    
    return volumes

def collect_ec2_instances(session, region):
    """Collect EC2 instance information with rightsizing"""
    print(f"  Processing EC2 instances in {region}...")
    ec2_client = session.client('ec2', region_name=region, config=config)
    instances = []
    
    try:
        paginator = ec2_client.get_paginator('describe_instances')
        for page in paginator.paginate():
            for reservation in page['Reservations']:
                for instance in reservation['Instances']:
                    instance_id = instance['InstanceId']
                    instance_arn = f"arn:aws:ec2:{region}:{ACCOUNT_ID}:instance/{instance_id}"
                    environment = get_tag_value(instance.get('Tags'), 'Environment') or ENV_HINT
                    instance_type = instance.get('InstanceType', '')
                    launch_time = instance.get('LaunchTime')
                    launch_year = launch_time.year if launch_time else ''
                    
                    # Calculate uptime
                    uptime_days = 0
                    if launch_time:
                        uptime_days = (datetime.now(launch_time.tzinfo) - launch_time).days
                    
                    # Get CPU utilization
                    cpu_utilization = get_cloudwatch_cpu_utilization(
                        session, region, 'AWS/EC2',
                        [{'Name': 'InstanceId', 'Value': instance_id}]
                    )
                    
                    # Rightsizing recommendations
                    recommended_type = recommend_instance_size(instance_type, cpu_utilization)
                    
                    # Purchase option recommendation
                    state = instance['State']['Name']
                    if uptime_days > 30 and state == 'running':
                        recommended_purchase = "SavingsPlan"
                    else:
                        recommended_purchase = "OnDemand"
                    
                    # Get volume information
                    root_volume_id = ""
                    all_volume_ids = []
                    
                    for bdm in instance.get('BlockDeviceMappings', []):
                        if 'Ebs' in bdm:
                            volume_id = bdm['Ebs'].get('VolumeId', '')
                            all_volume_ids.append(volume_id)
                            if bdm.get('DeviceName') == instance.get('RootDeviceName'):
                                root_volume_id = volume_id
                    
                    instances.append({
                        'AccountName': ACCOUNT_NAME,
                        'AccountId': ACCOUNT_ID,
                        'Environment': environment,
                        'Region': region,
                        'ResourceType': 'EC2',
                        'InstanceId': instance_id,
                        'InstanceArn': instance_arn,
                        'InstanceType': instance_type,
                        'LaunchTime': launch_time.isoformat() if launch_time else '',
                        'LaunchYear': launch_year,
                        'UptimeDays': uptime_days,
                        'CPUUtilizationPercent': cpu_utilization,
                        'RootVolumeId': root_volume_id,
                        'AllVolumeIds': ','.join(all_volume_ids),
                        'RecommendedRightSizeType': recommended_type,
                        'RecommendedPurchaseOption': recommended_purchase
                    })
        
        print(f"    Found {len(instances)} EC2 instances")
    except ClientError as e:
        if e.response['Error']['Code'] == 'UnauthorizedOperation':
            print(f"    No permission in {region}")
        else:
            print(f"    Error: {e}")
    except Exception as e:
        print(f"    Error: {e}")
    
    return instances

def collect_rds_instances(session, region):
    """Collect RDS instance information with rightsizing"""
    print(f"  Processing RDS instances in {region}...")
    rds_client = session.client('rds', region_name=region, config=config)
    instances = []
    
    try:
        paginator = rds_client.get_paginator('describe_db_instances')
        for page in paginator.paginate():
            for db_instance in page['DBInstances']:
                db_instance_id = db_instance.get('DBInstanceIdentifier', '')
                environment = ENV_HINT
                
                # Try to get environment from tags
                try:
                    tags_response = rds_client.list_tags_for_resource(
                        ResourceName=db_instance['DBInstanceArn']
                    )
                    for tag in tags_response.get('TagList', []):
                        if tag.get('Key') == 'Environment':
                            environment = tag.get('Value', ENV_HINT)
                except:
                    pass
                
                allocated_storage = db_instance.get('AllocatedStorage', 0)
                db_class = db_instance.get('DBInstanceClass', '')
                
                # Get CPU utilization
                cpu_utilization = get_cloudwatch_cpu_utilization(
                    session, region, 'AWS/RDS',
                    [{'Name': 'DBInstanceIdentifier', 'Value': db_instance_id}]
                )
                
                # Get free storage
                free_storage_gib = get_rds_free_storage(session, region, db_instance_id)
                
                # Rightsizing recommendation
                recommended_class = recommend_rds_class(
                    db_class, cpu_utilization, free_storage_gib, allocated_storage
                )
                
                instances.append({
                    'AccountName': ACCOUNT_NAME,
                    'AccountId': ACCOUNT_ID,
                    'Environment': environment,
                    'Region': region,
                    'ResourceType': 'RDS',
                    'DBInstanceIdentifier': db_instance_id,
                    'DBInstanceArn': db_instance.get('DBInstanceArn', ''),
                    'Engine': db_instance.get('Engine', ''),
                    'EngineVersion': db_instance.get('EngineVersion', ''),
                    'DBInstanceClass': db_class,
                    'AllocatedStorageGiB': allocated_storage,
                    'StorageType': db_instance.get('StorageType', ''),
                    'MultiAZ': db_instance.get('MultiAZ', False),
                    'DBInstanceStatus': db_instance.get('DBInstanceStatus', ''),
                    'RDSCPUUtilizationPercent': cpu_utilization,
                    'FreeStorageSpaceGiB': free_storage_gib,
                    'RecommendedRightSizeClass': recommended_class
                })
        
        print(f"    Found {len(instances)} RDS instances")
    except ClientError as e:
        if e.response['Error']['Code'] in ['AccessDenied', 'UnauthorizedOperation']:
            print(f"    No permission in {region}")
        else:
            print(f"    Error: {e}")
    except Exception as e:
        print(f"    Error: {e}")
    
    return instances

def collect_ecs_services(session, region):
    """Collect ECS service information"""
    print(f"  Processing ECS services in {region}...")
    ecs_client = session.client('ecs', region_name=region, config=config)
    services = []
    
    try:
        clusters_response = ecs_client.list_clusters()
        cluster_arns = clusters_response.get('clusterArns', [])
        
        for cluster_arn in cluster_arns:
            cluster_name = cluster_arn.split('/')[-1]
            
            try:
                services_response = ecs_client.list_services(cluster=cluster_arn)
                service_arns = services_response.get('serviceArns', [])
                
                if service_arns:
                    for i in range(0, len(service_arns), 10):
                        batch = service_arns[i:i+10]
                        described = ecs_client.describe_services(
                            cluster=cluster_arn,
                            services=batch
                        )
                        
                        for service in described.get('services', []):
                            environment = ENV_HINT
                            try:
                                tags_response = ecs_client.list_tags_for_resource(
                                    resourceArn=service['serviceArn']
                                )
                                for tag in tags_response.get('tags', []):
                                    if tag.get('key') == 'Environment':
                                        environment = tag.get('value', ENV_HINT)
                            except:
                                pass
                            
                            services.append({
                                'AccountName': ACCOUNT_NAME,
                                'AccountId': ACCOUNT_ID,
                                'Environment': environment,
                                'Region': region,
                                'ResourceType': 'ECS',
                                'ClusterName': cluster_name,
                                'ServiceName': service.get('serviceName', ''),
                                'LaunchType': service.get('launchType', ''),
                                'DesiredCount': service.get('desiredCount', 0),
                                'RunningCount': service.get('runningCount', 0),
                                'TaskDefinitionArn': service.get('taskDefinition', '')
                            })
            except Exception as e:
                pass
        
        print(f"    Found {len(services)} ECS services")
    except ClientError as e:
        if e.response['Error']['Code'] in ['AccessDeniedException', 'UnauthorizedOperation']:
            print(f"    No permission in {region}")
        else:
            print(f"    Error: {e}")
    except Exception as e:
        print(f"    Error: {e}")
    
    return services

def write_ebs_csv(volumes):
    """Write EBS volumes to CSV"""
    if not volumes:
        print("No EBS volumes to write")
        return
    
    fieldnames = [
        'AccountName', 'AccountId', 'Environment', 'Region', 'VolumeId',
        'VolumeType', 'SizeGiB', 'Encrypted', 'Iops', 'Throughput', 'State',
        'IsUnattached', 'AttachedInstanceId', 'AttachedInstanceType',
        'AttachedInstanceArn', 'AttachedInstanceLaunchTime', 'IsRootVolume'
    ]
    
    print(f"\nWriting {len(volumes)} EBS volumes to {EBS_OUTPUT_FILE}...")
    
    with open(EBS_OUTPUT_FILE, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(volumes)
    
    print(f"Successfully wrote {EBS_OUTPUT_FILE}")

def write_compute_csv(resources):
    """Write compute resources to CSV"""
    if not resources:
        print("No compute resources to write")
        return
    
    # Get all unique field names
    fieldnames = set()
    for resource in resources:
        fieldnames.update(resource.keys())
    
    # Ensure common fields are first
    common_fields = ['AccountName', 'AccountId', 'Environment', 'Region', 'ResourceType']
    fieldnames = common_fields + sorted(list(fieldnames - set(common_fields)))
    
    print(f"\nWriting {len(resources)} compute resources to {COMPUTE_OUTPUT_FILE}...")
    
    with open(COMPUTE_OUTPUT_FILE, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(resources)
    
    print(f"Successfully wrote {COMPUTE_OUTPUT_FILE}")

def main():
    """Main execution function"""
    print(f"AWS Resource Inventory with Rightsizing")
    print(f"Account: {ACCOUNT_NAME} ({ACCOUNT_ID})")
    print(f"Profile: {PROFILE_NAME}")
    print("=" * 80)
    
    session = get_session()
    
    # Get enabled regions
    print("\nGetting enabled regions...")
    regions = get_enabled_regions(session)
    print(f"Found {len(regions)} enabled regions")
    
    all_ebs_volumes = []
    all_compute_resources = []
    
    # Collect resources from all regions
    for region in regions:
        print(f"\nProcessing region: {region}")
        
        # Collect EBS volumes
        ebs_volumes = collect_ebs_volumes(session, region)
        all_ebs_volumes.extend(ebs_volumes)
        
        # Collect EC2 instances
        ec2_instances = collect_ec2_instances(session, region)
        all_compute_resources.extend(ec2_instances)
        
        # Collect RDS instances
        rds_instances = collect_rds_instances(session, region)
        all_compute_resources.extend(rds_instances)
        
        # Collect ECS services
        ecs_services = collect_ecs_services(session, region)
        all_compute_resources.extend(ecs_services)
        
        time.sleep(0.5)
    
    # Write CSVs
    print("\n" + "=" * 80)
    write_ebs_csv(all_ebs_volumes)
    write_compute_csv(all_compute_resources)
    
    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"EBS Volumes: {len(all_ebs_volumes)}")
    
    resource_counts = {}
    for resource in all_compute_resources:
        rtype = resource['ResourceType']
        resource_counts[rtype] = resource_counts.get(rtype, 0) + 1
    
    for rtype, count in sorted(resource_counts.items()):
        print(f"{rtype}: {count}")
    
    print(f"\nOutput files:")
    print(f"  - {EBS_OUTPUT_FILE}")
    print(f"  - {COMPUTE_OUTPUT_FILE}")

if __name__ == "__main__":
    main()
