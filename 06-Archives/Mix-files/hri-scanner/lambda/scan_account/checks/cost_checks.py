"""
Cost Optimization HRI Checks

Implements 6 cost optimization checks across EC2, EBS, Cost Explorer, and ELB.

Requirements:
- 6.1: Identify idle EC2 instances with low CPU utilization
- 6.2: Identify gp2 volumes that should be migrated to gp3
- 6.3: Calculate Savings Plan coverage percentage
- 6.4: Calculate RDS Reserved Instance coverage percentage
- 6.5: Identify unattached EBS volumes
- 6.6: Identify idle Application Load Balancers, Elastic Load Balancers, and Elastic IPs
"""

import logging
from typing import Dict, Any, List
from datetime import datetime, timedelta
from botocore.exceptions import ClientError

logger = logging.getLogger()


def check_idle_ec2_for_cost(scanner_session, region: str, account_id: str,
                            execution_id: str) -> List[Dict[str, Any]]:
    """
    Identify idle EC2 instances with low CPU utilization (cost perspective)
    
    Requirement 6.1: Identify idle EC2 instances with low CPU utilization
    Note: This is similar to performance check but focuses on cost impact
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
        start_time = end_time - timedelta(days=14)  # Check last 14 days for cost
        
        for reservation in response.get('Reservations', []):
            for instance in reservation.get('Instances', []):
                instance_id = instance['InstanceId']
                instance_type = instance['InstanceType']
                
                try:
                    # Get CPU utilization metrics
                    cpu_response = cloudwatch_client.get_metric_statistics(
                        Namespace='AWS/EC2',
                        MetricName='CPUUtilization',
                        Dimensions=[{'Name': 'InstanceId', 'Value': instance_id}],
                        StartTime=start_time,
                        EndTime=end_time,
                        Period=86400,  # 1 day
                        Statistics=['Average', 'Maximum']
                    )
                    
                    datapoints = cpu_response.get('Datapoints', [])
                    
                    if datapoints:
                        avg_cpu = sum(dp['Average'] for dp in datapoints) / len(datapoints)
                        max_cpu = max(dp['Maximum'] for dp in datapoints)
                        
                        # Flag instances with < 10% average CPU and < 20% max CPU
                        if avg_cpu < 10.0 and max_cpu < 20.0:
                            findings.append({
                                'account_id': account_id,
                                'check_id': 'Cost#Idle_EC2_Instance',
                                'pillar': 'Cost',
                                'check_name': 'Idle EC2 Instance (Cost Waste)',
                                'hri': True,
                                'evidence': f"arn:aws:ec2:{region}:{account_id}:instance/{instance_id} - Type: {instance_type}, Avg CPU: {avg_cpu:.2f}%, Max CPU: {max_cpu:.2f}%",
                                'region': region,
                                'timestamp': datetime.utcnow().isoformat() + 'Z',
                                'execution_id': execution_id,
                                'resource_tags': {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])},
                                'cost_impact': 0  # Placeholder - actual cost calculation would require pricing API
                            })
                            
                except ClientError as e:
                    logger.debug(f"Error getting metrics for instance {instance_id}: {e}")
                    
    except ClientError as e:
        logger.error(f"Error checking idle EC2 instances in {region}: {e}")
    
    return findings


def check_gp2_volumes(scanner_session, region: str, account_id: str,
                     execution_id: str) -> List[Dict[str, Any]]:
    """
    Identify gp2 volumes that should be migrated to gp3
    
    Requirement 6.2: Identify gp2 volumes that should be migrated to gp3
    """
    findings = []
    
    try:
        ec2_client = scanner_session.get_client('ec2', region=region)
        
        paginator = ec2_client.get_paginator('describe_volumes')
        
        for page in paginator.paginate():
            for volume in page.get('Volumes', []):
                if volume.get('VolumeType') == 'gp2':
                    volume_id = volume['VolumeId']
                    size_gb = volume['Size']
                    
                    # Estimate cost savings (gp3 is ~20% cheaper than gp2)
                    # gp2: $0.10/GB-month, gp3: $0.08/GB-month
                    estimated_monthly_savings = size_gb * 0.02
                    
                    findings.append({
                        'account_id': account_id,
                        'check_id': 'Cost#GP2_Volume',
                        'pillar': 'Cost',
                        'check_name': 'GP2 Volume Should Migrate to GP3',
                        'hri': True,
                        'evidence': f"arn:aws:ec2:{region}:{account_id}:volume/{volume_id} - Size: {size_gb}GB",
                        'region': region,
                        'timestamp': datetime.utcnow().isoformat() + 'Z',
                        'execution_id': execution_id,
                        'resource_tags': {tag['Key']: tag['Value'] for tag in volume.get('Tags', [])},
                        'cost_impact': round(estimated_monthly_savings, 2)
                    })
                    
    except ClientError as e:
        logger.error(f"Error checking gp2 volumes in {region}: {e}")
    
    return findings


def check_savings_plan_coverage(scanner_session, account_id: str,
                                execution_id: str) -> List[Dict[str, Any]]:
    """
    Calculate Savings Plan coverage percentage
    
    Requirement 6.3: Calculate Savings Plan coverage percentage
    """
    findings = []
    
    try:
        ce_client = scanner_session.get_client('ce', region='us-east-1')  # Cost Explorer is global
        
        # Get last month's data
        end_date = datetime.utcnow().date()
        start_date = end_date - timedelta(days=30)
        
        response = ce_client.get_savings_plans_coverage(
            TimePeriod={
                'Start': start_date.strftime('%Y-%m-%d'),
                'End': end_date.strftime('%Y-%m-%d')
            },
            Granularity='MONTHLY'
        )
        
        coverage_data = response.get('SavingsPlansCoverages', [])
        
        if coverage_data:
            # Get the most recent coverage data
            latest_coverage = coverage_data[-1]
            coverage_pct = float(latest_coverage.get('Coverage', {}).get('CoveragePercentage', '0'))
            
            # Flag if coverage is < 70%
            if coverage_pct < 70.0:
                findings.append({
                    'account_id': account_id,
                    'check_id': 'Cost#Low_Savings_Plan_Coverage',
                    'pillar': 'Cost',
                    'check_name': 'Low Savings Plan Coverage',
                    'hri': True,
                    'evidence': f'Savings Plan coverage is {coverage_pct:.2f}% (target: 70%+)',
                    'region': 'global',
                    'timestamp': datetime.utcnow().isoformat() + 'Z',
                    'execution_id': execution_id,
                    'cost_impact': 0  # Would require detailed cost analysis
                })
                
    except ClientError as e:
        if e.response['Error']['Code'] != 'DataUnavailableException':
            logger.error(f"Error checking Savings Plan coverage: {e}")
    
    return findings


def check_rds_ri_coverage(scanner_session, account_id: str,
                         execution_id: str) -> List[Dict[str, Any]]:
    """
    Calculate RDS Reserved Instance coverage percentage
    
    Requirement 6.4: Calculate RDS Reserved Instance coverage percentage
    """
    findings = []
    
    try:
        ce_client = scanner_session.get_client('ce', region='us-east-1')  # Cost Explorer is global
        
        # Get last month's data
        end_date = datetime.utcnow().date()
        start_date = end_date - timedelta(days=30)
        
        response = ce_client.get_reservation_coverage(
            TimePeriod={
                'Start': start_date.strftime('%Y-%m-%d'),
                'End': end_date.strftime('%Y-%m-%d')
            },
            Granularity='MONTHLY',
            Filter={
                'Dimensions': {
                    'Key': 'SERVICE',
                    'Values': ['Amazon Relational Database Service']
                }
            }
        )
        
        coverage_data = response.get('CoveragesByTime', [])
        
        if coverage_data:
            # Get the most recent coverage data
            latest_coverage = coverage_data[-1]
            coverage_pct = float(latest_coverage.get('Total', {}).get('CoverageHours', {}).get('CoverageHoursPercentage', '0'))
            
            # Flag if coverage is < 70%
            if coverage_pct < 70.0:
                findings.append({
                    'account_id': account_id,
                    'check_id': 'Cost#Low_RDS_RI_Coverage',
                    'pillar': 'Cost',
                    'check_name': 'Low RDS Reserved Instance Coverage',
                    'hri': True,
                    'evidence': f'RDS RI coverage is {coverage_pct:.2f}% (target: 70%+)',
                    'region': 'global',
                    'timestamp': datetime.utcnow().isoformat() + 'Z',
                    'execution_id': execution_id,
                    'cost_impact': 0  # Would require detailed cost analysis
                })
                
    except ClientError as e:
        if e.response['Error']['Code'] != 'DataUnavailableException':
            logger.error(f"Error checking RDS RI coverage: {e}")
    
    return findings


def check_unattached_ebs_volumes(scanner_session, region: str, account_id: str,
                                 execution_id: str) -> List[Dict[str, Any]]:
    """
    Identify unattached EBS volumes
    
    Requirement 6.5: Identify unattached EBS volumes
    """
    findings = []
    
    try:
        ec2_client = scanner_session.get_client('ec2', region=region)
        
        paginator = ec2_client.get_paginator('describe_volumes')
        
        for page in paginator.paginate():
            for volume in page.get('Volumes', []):
                # Check if volume is unattached
                if volume.get('State') == 'available':
                    volume_id = volume['VolumeId']
                    size_gb = volume['Size']
                    volume_type = volume.get('VolumeType', 'standard')
                    
                    # Estimate monthly cost based on volume type
                    cost_per_gb = {
                        'gp2': 0.10,
                        'gp3': 0.08,
                        'io1': 0.125,
                        'io2': 0.125,
                        'st1': 0.045,
                        'sc1': 0.015,
                        'standard': 0.05
                    }
                    
                    monthly_cost = size_gb * cost_per_gb.get(volume_type, 0.10)
                    
                    findings.append({
                        'account_id': account_id,
                        'check_id': 'Cost#Unattached_EBS_Volume',
                        'pillar': 'Cost',
                        'check_name': 'Unattached EBS Volume',
                        'hri': True,
                        'evidence': f"arn:aws:ec2:{region}:{account_id}:volume/{volume_id} - Type: {volume_type}, Size: {size_gb}GB",
                        'region': region,
                        'timestamp': datetime.utcnow().isoformat() + 'Z',
                        'execution_id': execution_id,
                        'resource_tags': {tag['Key']: tag['Value'] for tag in volume.get('Tags', [])},
                        'cost_impact': round(monthly_cost, 2)
                    })
                    
    except ClientError as e:
        logger.error(f"Error checking unattached EBS volumes in {region}: {e}")
    
    return findings


def check_idle_load_balancers_and_eips(scanner_session, region: str, account_id: str,
                                       execution_id: str) -> List[Dict[str, Any]]:
    """
    Identify idle Application Load Balancers, Elastic Load Balancers, and Elastic IPs
    
    Requirement 6.6: Identify idle ALBs, ELBs, and EIPs
    """
    findings = []
    
    try:
        elbv2_client = scanner_session.get_client('elbv2', region=region)
        elb_client = scanner_session.get_client('elb', region=region)
        ec2_client = scanner_session.get_client('ec2', region=region)
        cloudwatch_client = scanner_session.get_client('cloudwatch', region=region)
        
        # Check Application Load Balancers and Network Load Balancers
        alb_response = elbv2_client.describe_load_balancers()
        
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(days=7)
        
        for lb in alb_response.get('LoadBalancers', []):
            lb_arn = lb['LoadBalancerArn']
            lb_name = lb['LoadBalancerName']
            lb_type = lb['Type']  # application or network
            
            # Check target health
            target_groups_response = elbv2_client.describe_target_groups(
                LoadBalancerArn=lb_arn
            )
            
            has_healthy_targets = False
            for tg in target_groups_response.get('TargetGroups', []):
                health_response = elbv2_client.describe_target_health(
                    TargetGroupArn=tg['TargetGroupArn']
                )
                
                for target in health_response.get('TargetHealthDescriptions', []):
                    if target.get('TargetHealth', {}).get('State') == 'healthy':
                        has_healthy_targets = True
                        break
                
                if has_healthy_targets:
                    break
            
            if not has_healthy_targets:
                # Estimate cost: ALB ~$22/month, NLB ~$22/month
                monthly_cost = 22.0
                
                findings.append({
                    'account_id': account_id,
                    'check_id': f'Cost#Idle_{lb_type.upper()}',
                    'pillar': 'Cost',
                    'check_name': f'Idle {lb_type.upper()} Without Healthy Targets',
                    'hri': True,
                    'evidence': f"{lb_arn} - No healthy targets",
                    'region': region,
                    'timestamp': datetime.utcnow().isoformat() + 'Z',
                    'execution_id': execution_id,
                    'cost_impact': monthly_cost
                })
        
        # Check Classic Load Balancers
        clb_response = elb_client.describe_load_balancers()
        
        for lb in clb_response.get('LoadBalancerDescriptions', []):
            lb_name = lb['LoadBalancerName']
            
            # Check instance health
            health_response = elb_client.describe_instance_health(
                LoadBalancerName=lb_name
            )
            
            healthy_instances = [
                inst for inst in health_response.get('InstanceStates', [])
                if inst.get('State') == 'InService'
            ]
            
            if len(healthy_instances) == 0:
                # Estimate cost: CLB ~$18/month
                monthly_cost = 18.0
                
                findings.append({
                    'account_id': account_id,
                    'check_id': 'Cost#Idle_CLB',
                    'pillar': 'Cost',
                    'check_name': 'Idle Classic Load Balancer Without Healthy Instances',
                    'hri': True,
                    'evidence': f"arn:aws:elasticloadbalancing:{region}:{account_id}:loadbalancer/{lb_name} - No healthy instances",
                    'region': region,
                    'timestamp': datetime.utcnow().isoformat() + 'Z',
                    'execution_id': execution_id,
                    'cost_impact': monthly_cost
                })
        
        # Check Elastic IPs
        eip_response = ec2_client.describe_addresses()
        
        for eip in eip_response.get('Addresses', []):
            # Unattached EIPs cost money
            if 'InstanceId' not in eip and 'NetworkInterfaceId' not in eip:
                allocation_id = eip.get('AllocationId', '')
                public_ip = eip.get('PublicIp', '')
                
                # Estimate cost: Unattached EIP ~$3.60/month
                monthly_cost = 3.60
                
                findings.append({
                    'account_id': account_id,
                    'check_id': 'Cost#Unattached_EIP',
                    'pillar': 'Cost',
                    'check_name': 'Unattached Elastic IP',
                    'hri': True,
                    'evidence': f"Elastic IP {public_ip} (AllocationId: {allocation_id}) is not attached",
                    'region': region,
                    'timestamp': datetime.utcnow().isoformat() + 'Z',
                    'execution_id': execution_id,
                    'cost_impact': monthly_cost
                })
                
    except ClientError as e:
        logger.error(f"Error checking idle load balancers and EIPs in {region}: {e}")
    
    return findings


def run_all_cost_checks(scanner_session, regions: List[str], account_id: str,
                       execution_id: str) -> List[Dict[str, Any]]:
    """
    Run all cost optimization HRI checks
    
    Args:
        scanner_session: Scanner session with assumed role
        regions: List of regions to scan
        account_id: AWS account ID
        execution_id: Unique execution ID
        
    Returns:
        List of all cost optimization findings
    """
    all_findings = []
    
    logger.info(f"Running cost optimization checks for account {account_id}")
    
    # Global checks (run once)
    all_findings.extend(check_savings_plan_coverage(scanner_session, account_id, execution_id))
    all_findings.extend(check_rds_ri_coverage(scanner_session, account_id, execution_id))
    
    # Regional checks
    for region in regions:
        all_findings.extend(check_idle_ec2_for_cost(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_gp2_volumes(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_unattached_ebs_volumes(scanner_session, region, account_id, execution_id))
        all_findings.extend(check_idle_load_balancers_and_eips(scanner_session, region, account_id, execution_id))
    
    logger.info(f"Cost optimization checks completed: {len(all_findings)} findings")
    
    return all_findings
