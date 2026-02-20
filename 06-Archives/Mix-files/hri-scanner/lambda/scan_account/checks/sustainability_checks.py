"""
Sustainability HRI Checks

Implements 3 sustainability checks across EC2, EBS, and RDS.

Requirements:
- 7.1: Identify old-generation instance families
- 7.2: Identify EBS volumes not using gp3 or Elastic Volume types
- 7.3: Identify outdated RDS instance classes
"""

import logging
from typing import Dict, Any, List
from datetime import datetime
from botocore.exceptions import ClientError

logger = logging.getLogger()

# Old-generation instance families (less energy efficient)
OLD_GENERATION_FAMILIES = [
    't1', 't2', 'm1', 'm2', 'm3', 'c1', 'c3', 'cc2', 'cg1', 'cr1',
    'g2', 'hi1', 'hs1', 'i2', 'r3', 'd2'
]

# Current-generation, energy-efficient instance families
CURRENT_GENERATION_FAMILIES = [
    't3', 't3a', 't4g', 'm5', 'm5a', 'm5n', 'm5zn', 'm6i', 'm6a', 'm6g', 'm7g',
    'c5', 'c5a', 'c5n', 'c6i', 'c6a', 'c6g', 'c7g',
    'r5', 'r5a', 'r5b', 'r5n', 'r6i', 'r6a', 'r6g', 'r7g',
    'x2gd', 'x2idn', 'x2iedn', 'z1d',
    'i3', 'i3en', 'i4i', 'd3', 'd3en',
    'g4dn', 'g5', 'p3', 'p4', 'inf1', 'inf2'
]

# Outdated RDS instance classes (less energy efficient)
OUTDATED_RDS_CLASSES = [
    'db.t2', 'db.m1', 'db.m2', 'db.m3', 'db.m4',
    'db.r3', 'db.r4', 'db.t1'
]

# Current RDS instance classes (more energy efficient)
CURRENT_RDS_CLASSES = [
    'db.t3', 'db.t4g', 'db.m5', 'db.m6i', 'db.m6g', 'db.m7g',
    'db.r5', 'db.r6i', 'db.r6g', 'db.r7g',
    'db.x2g', 'db.x2idn', 'db.x2iedn'
]


def check_old_generation_instances(scanner_session, region: str, account_id: str,
                                   execution_id: str) -> List[Dict[str, Any]]:
    """
    Identify old-generation instance families
    
    Requirement 7.1: Identify old-generation instance families
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
                
                if instance_family in OLD_GENERATION_FAMILIES:
                    # Suggest current-generation alternative
                    suggested_family = None
                    if instance_family.startswith('t'):
                        suggested_family = 't3 or t4g (Graviton)'
                    elif instance_family.startswith('m'):
                        suggested_family = 'm6i, m6g (Graviton), or m7g (Graviton)'
                    elif instance_family.startswith('c'):
                        suggested_family = 'c6i, c6g (Graviton), or c7g (Graviton)'
                    elif instance_family.startswith('r'):
                        suggested_family = 'r6i, r6g (Graviton), or r7g (Graviton)'
                    else:
                        suggested_family = 'current-generation equivalent'
                    
                    findings.append({
                        'account_id': account_id,
                        'check_id': 'Sustainability#Old_Generation_Instance',
                        'pillar': 'Sustainability',
                        'check_name': 'Old-Generation EC2 Instance Family',
                        'hri': True,
                        'evidence': f"arn:aws:ec2:{region}:{account_id}:instance/{instance_id} - Type: {instance_type} (State: {instance_state}), Suggested: {suggested_family}",
                        'region': region,
                        'timestamp': datetime.utcnow().isoformat() + 'Z',
                        'execution_id': execution_id,
                        'resource_tags': {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
                    })
                    
    except ClientError as e:
        logger.error(f"Error checking old-generation instances in {region}: {e}")
    
    return findings


def check_non_gp3_volumes(scanner_session, region: str, account_id: str,
                         execution_id: str) -> List[Dict[str, Any]]:
    """
    Identify EBS volumes not using gp3 or Elastic Volume types
    
    Requirement 7.2: Identify EBS volumes not using gp3 or Elastic Volume types
    """
    findings = []
    
    try:
        ec2_client = scanner_session.get_client('ec2', region=region)
        
        paginator = ec2_client.get_paginator('describe_volumes')
        
        # Sustainable volume types (gp3 is most energy efficient for general purpose)
        sustainable_types = ['gp3', 'io2']  # io2 is more efficient than io1
        
        for page in paginator.paginate():
            for volume in page.get('Volumes', []):
                volume_type = volume.get('VolumeType')
                volume_id = volume['VolumeId']
                size_gb = volume['Size']
                
                # Flag volumes not using sustainable types
                if volume_type not in sustainable_types:
                    suggested_type = None
                    if volume_type == 'gp2':
                        suggested_type = 'gp3 (20% more energy efficient)'
                    elif volume_type == 'io1':
                        suggested_type = 'io2 (more durable and efficient)'
                    elif volume_type in ['st1', 'sc1', 'standard']:
                        suggested_type = 'gp3 (better performance and efficiency)'
                    else:
                        suggested_type = 'gp3 or io2'
                    
                    findings.append({
                        'account_id': account_id,
                        'check_id': 'Sustainability#Non_GP3_Volume',
                        'pillar': 'Sustainability',
                        'check_name': 'EBS Volume Not Using Sustainable Type',
                        'hri': True,
                        'evidence': f"arn:aws:ec2:{region}:{account_id}:volume/{volume_id} - Type: {volume_type}, Size: {size_gb}GB, Suggested: {suggested_type}",
                        'region': region,
                        'timestamp': datetime.utcnow().isoformat() + 'Z',
                        'execution_id': execution_id,
                        'resource_tags': {tag['Key']: tag['Value'] for tag in volume.get('Tags', [])}
                    })
                    
    except ClientError as e:
        logger.error(f"Error checking EBS volumes in {region}: {e}")
    
    return findings


def check_outdated_rds_classes(scanner_session, region: str, account_id: str,
                               execution_id: str) -> List[Dict[str, Any]]:
    """
    Identify outdated RDS instance classes
    
    Requirement 7.3: Identify outdated RDS instance classes
    """
    findings = []
    
    try:
        rds_client = scanner_session.get_client('rds', region=region)
        
        paginator = rds_client.get_paginator('describe_db_instances')
        
        for page in paginator.paginate():
            for db_instance in page.get('DBInstances', []):
                db_instance_class = db_instance['DBInstanceClass']
                db_instance_id = db_instance['DBInstanceIdentifier']
                db_instance_arn = db_instance['DBInstanceArn']
                engine = db_instance.get('Engine', 'unknown')
                
                # Extract instance class family (e.g., 'db.t2' from 'db.t2.micro')
                class_parts = db_instance_class.split('.')
                if len(class_parts) >= 2:
                    class_family = f"{class_parts[0]}.{class_parts[1]}"
                else:
                    class_family = db_instance_class
                
                if class_family in OUTDATED_RDS_CLASSES:
                    # Suggest current-generation alternative
                    suggested_class = None
                    if class_family == 'db.t2':
                        suggested_class = 'db.t3 or db.t4g (Graviton - 40% better price-performance)'
                    elif class_family in ['db.m3', 'db.m4']:
                        suggested_class = 'db.m6i, db.m6g (Graviton), or db.m7g (Graviton)'
                    elif class_family in ['db.r3', 'db.r4']:
                        suggested_class = 'db.r6i, db.r6g (Graviton), or db.r7g (Graviton)'
                    else:
                        suggested_class = 'current-generation equivalent'
                    
                    findings.append({
                        'account_id': account_id,
                        'check_id': 'Sustainability#Outdated_RDS_Class',
                        'pillar': 'Sustainability',
                        'check_name': 'Outdated RDS Instance Class',
                        'hri': True,
                        'evidence': f"{db_instance_arn} - Class: {db_instance_class}, Engine: {engine}, Suggested: {suggested_class}",
                        'region': region,
                        'timestamp': datetime.utcnow().isoformat() + 'Z',
                        'execution_id': execution_id
                    })
                    
    except ClientError as e:
        logger.error(f"Error checking RDS instances in {region}: {e}")
    
    return findings


def run_all_sustainability_checks(scanner_session, regions: List[str], account_id: str,
                                  execution_id: str) -> List[Dict[str, Any]]:
    """
    Run all sustainability HRI checks
    
    Args:
        scanner_session: Scanner session with assumed role
        regions: List of regions to scan
        account_id: AWS account ID
        execution_id: Unique execution ID
        
    Returns:
        List of all sustainability findings
    """
    all_findings = []
    
    logger.info(f"Running sustainability checks for account {account_id}")
    
    # Regional checks
    for region in regions:
        all_findings.extend(check_old_generation_instances(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_non_gp3_volumes(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_outdated_rds_classes(scanner_session, region, account_id, execution_id))
    
    logger.info(f"Sustainability checks completed: {len(all_findings)} findings")
    
    return all_findings
