#!/usr/bin/env python3
"""
AWS Resource Inventory Collector
Collects EBS, EC2, ECS, and RDS resources across all regions into a single CSV file.
"""

import boto3
import csv
from datetime import datetime
from botocore.exceptions import ClientError, EndpointConnectionError
from botocore.config import Config
import time

# Configuration
ACCOUNT_NAME = "AWS Development"
ACCOUNT_ID = "013612877090"
ENV_HINT = "dev"
PROFILE_NAME = "srsa-dev"
OUTPUT_FILE = "aws_development_inventory.csv"

# Boto3 config with retries
config = Config(
    retries={
        'max_attempts': 10,
        'mode': 'adaptive'
    }
)

def get_session():
    """Create boto3 session with profile or environment credentials"""
    try:
        # Try to use profile first
        return boto3.Session(profile_name=PROFILE_NAME)
    except:
        # Fall back to environment credentials
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

def collect_ebs_volumes(session, region):
    """Collect EBS volume information"""
    print(f"  Collecting EBS volumes in {region}...")
    ec2_client = session.client('ec2', region_name=region, config=config)
    volumes = []
    
    try:
        paginator = ec2_client.get_paginator('describe_volumes')
        for page in paginator.paginate():
            for volume in page['Volumes']:
                is_unattached = len(volume.get('Attachments', [])) == 0
                attached_instance_id = ""
                attached_instance_arn = ""
                attached_instance_name = ""
                attached_instance_type = ""
                
                if not is_unattached:
                    attachment = volume['Attachments'][0]
                    attached_instance_id = attachment.get('InstanceId', '')
                    
                    # Get instance details
                    try:
                        instance_response = ec2_client.describe_instances(InstanceIds=[attached_instance_id])
                        if instance_response['Reservations']:
                            instance = instance_response['Reservations'][0]['Instances'][0]
                            attached_instance_arn = f"arn:aws:ec2:{region}:{ACCOUNT_ID}:instance/{attached_instance_id}"
                            attached_instance_name = get_tag_value(instance.get('Tags'), 'Name')
                            attached_instance_type = instance.get('InstanceType', '')
                    except Exception as e:
                        print(f"    Warning: Could not get instance details for {attached_instance_id}: {e}")
                
                environment = get_tag_value(volume.get('Tags'), 'Environment') or ENV_HINT
                
                volumes.append({
                    'AccountName': ACCOUNT_NAME,
                    'AccountId': ACCOUNT_ID,
                    'Environment': environment,
                    'Region': region,
                    'ResourceType': 'EBS',
                    'VolumeId': volume['VolumeId'],
                    'VolumeType': volume.get('VolumeType', ''),
                    'SizeGiB': volume.get('Size', 0),
                    'State': volume.get('State', ''),
                    'Encrypted': volume.get('Encrypted', False),
                    'Iops': volume.get('Iops', ''),
                    'Throughput': volume.get('Throughput', ''),
                    'IsUnattached': is_unattached,
                    'AttachedInstanceId': attached_instance_id,
                    'AttachedInstanceArn': attached_instance_arn,
                    'AttachedInstanceName': attached_instance_name,
                    'AttachedInstanceType': attached_instance_type
                })
        
        print(f"    Found {len(volumes)} EBS volumes")
    except ClientError as e:
        if e.response['Error']['Code'] == 'UnauthorizedOperation':
            print(f"    No permission to describe volumes in {region}")
        else:
            print(f"    Error collecting EBS volumes: {e}")
    except Exception as e:
        print(f"    Error collecting EBS volumes: {e}")
    
    return volumes

def collect_ec2_instances(session, region):
    """Collect EC2 instance information"""
    print(f"  Collecting EC2 instances in {region}...")
    ec2_client = session.client('ec2', region_name=region, config=config)
    instances = []
    
    try:
        paginator = ec2_client.get_paginator('describe_instances')
        for page in paginator.paginate():
            for reservation in page['Reservations']:
                for instance in reservation['Instances']:
                    instance_id = instance['InstanceId']
                    instance_arn = f"arn:aws:ec2:{region}:{ACCOUNT_ID}:instance/{instance_id}"
                    name = get_tag_value(instance.get('Tags'), 'Name')
                    environment = get_tag_value(instance.get('Tags'), 'Environment') or ENV_HINT
                    
                    # Get root volume ID
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
                        'Name': name,
                        'State': instance['State']['Name'],
                        'InstanceType': instance.get('InstanceType', ''),
                        'LaunchTime': instance.get('LaunchTime', '').isoformat() if instance.get('LaunchTime') else '',
                        'RootVolumeId': root_volume_id,
                        'AllVolumeIds': ','.join(all_volume_ids)
                    })
        
        print(f"    Found {len(instances)} EC2 instances")
    except ClientError as e:
        if e.response['Error']['Code'] == 'UnauthorizedOperation':
            print(f"    No permission to describe instances in {region}")
        else:
            print(f"    Error collecting EC2 instances: {e}")
    except Exception as e:
        print(f"    Error collecting EC2 instances: {e}")
    
    return instances

def collect_ecs_services(session, region):
    """Collect ECS service information"""
    print(f"  Collecting ECS services in {region}...")
    ecs_client = session.client('ecs', region_name=region, config=config)
    services = []
    
    try:
        # List all clusters
        clusters_response = ecs_client.list_clusters()
        cluster_arns = clusters_response.get('clusterArns', [])
        
        for cluster_arn in cluster_arns:
            cluster_name = cluster_arn.split('/')[-1]
            
            # List services in cluster
            try:
                services_response = ecs_client.list_services(cluster=cluster_arn)
                service_arns = services_response.get('serviceArns', [])
                
                if service_arns:
                    # Describe services (batch of 10 at a time)
                    for i in range(0, len(service_arns), 10):
                        batch = service_arns[i:i+10]
                        described = ecs_client.describe_services(
                            cluster=cluster_arn,
                            services=batch
                        )
                        
                        for service in described.get('services', []):
                            environment = ENV_HINT
                            # Try to get environment from tags
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
                print(f"    Error processing cluster {cluster_name}: {e}")
        
        print(f"    Found {len(services)} ECS services")
    except ClientError as e:
        if e.response['Error']['Code'] in ['AccessDeniedException', 'UnauthorizedOperation']:
            print(f"    No permission to describe ECS in {region}")
        else:
            print(f"    Error collecting ECS services: {e}")
    except Exception as e:
        print(f"    Error collecting ECS services: {e}")
    
    return services

def collect_rds_instances(session, region):
    """Collect RDS instance information"""
    print(f"  Collecting RDS instances in {region}...")
    rds_client = session.client('rds', region_name=region, config=config)
    instances = []
    
    try:
        paginator = rds_client.get_paginator('describe_db_instances')
        for page in paginator.paginate():
            for db_instance in page['DBInstances']:
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
                
                instances.append({
                    'AccountName': ACCOUNT_NAME,
                    'AccountId': ACCOUNT_ID,
                    'Environment': environment,
                    'Region': region,
                    'ResourceType': 'RDS',
                    'DBInstanceIdentifier': db_instance.get('DBInstanceIdentifier', ''),
                    'DBInstanceArn': db_instance.get('DBInstanceArn', ''),
                    'Engine': db_instance.get('Engine', ''),
                    'EngineVersion': db_instance.get('EngineVersion', ''),
                    'DBInstanceClass': db_instance.get('DBInstanceClass', ''),
                    'AllocatedStorageGiB': db_instance.get('AllocatedStorage', 0),
                    'StorageType': db_instance.get('StorageType', ''),
                    'MultiAZ': db_instance.get('MultiAZ', False),
                    'DBInstanceStatus': db_instance.get('DBInstanceStatus', '')
                })
        
        print(f"    Found {len(instances)} RDS instances")
    except ClientError as e:
        if e.response['Error']['Code'] in ['AccessDenied', 'UnauthorizedOperation']:
            print(f"    No permission to describe RDS in {region}")
        else:
            print(f"    Error collecting RDS instances: {e}")
    except Exception as e:
        print(f"    Error collecting RDS instances: {e}")
    
    return instances

def write_to_csv(all_resources):
    """Write all resources to a single CSV file"""
    if not all_resources:
        print("No resources to write")
        return
    
    # Get all unique field names
    fieldnames = set()
    for resource in all_resources:
        fieldnames.update(resource.keys())
    
    # Ensure common fields are first
    common_fields = ['AccountName', 'AccountId', 'Environment', 'Region', 'ResourceType']
    fieldnames = common_fields + sorted(list(fieldnames - set(common_fields)))
    
    print(f"\nWriting {len(all_resources)} resources to {OUTPUT_FILE}...")
    
    with open(OUTPUT_FILE, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(all_resources)
    
    print(f"Successfully wrote inventory to {OUTPUT_FILE}")

def main():
    """Main execution function"""
    print(f"AWS Resource Inventory Collector")
    print(f"Account: {ACCOUNT_NAME} ({ACCOUNT_ID})")
    print(f"Profile: {PROFILE_NAME}")
    print(f"Output: {OUTPUT_FILE}")
    print("=" * 80)
    
    session = get_session()
    
    # Get enabled regions
    print("\nGetting enabled regions...")
    regions = get_enabled_regions(session)
    print(f"Found {len(regions)} enabled regions: {', '.join(regions)}")
    
    all_resources = []
    
    # Collect resources from all regions
    for region in regions:
        print(f"\nProcessing region: {region}")
        
        # Collect EBS volumes
        ebs_volumes = collect_ebs_volumes(session, region)
        all_resources.extend(ebs_volumes)
        
        # Collect EC2 instances
        ec2_instances = collect_ec2_instances(session, region)
        all_resources.extend(ec2_instances)
        
        # Collect ECS services
        ecs_services = collect_ecs_services(session, region)
        all_resources.extend(ecs_services)
        
        # Collect RDS instances
        rds_instances = collect_rds_instances(session, region)
        all_resources.extend(rds_instances)
        
        # Small delay to avoid throttling
        time.sleep(0.5)
    
    # Write all resources to CSV
    print("\n" + "=" * 80)
    write_to_csv(all_resources)
    
    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    resource_counts = {}
    for resource in all_resources:
        rtype = resource['ResourceType']
        resource_counts[rtype] = resource_counts.get(rtype, 0) + 1
    
    for rtype, count in sorted(resource_counts.items()):
        print(f"{rtype}: {count}")
    print(f"\nTotal resources: {len(all_resources)}")
    print(f"Output file: {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
