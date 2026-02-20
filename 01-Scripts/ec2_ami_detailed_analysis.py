#!/usr/bin/env python3
"""
Comprehensive EC2 and AMI Analysis Script
Generates detailed CSV report with instance details, AMI information, utilization, and recommendations
"""

import boto3
import csv
import json
from datetime import datetime, timedelta
from typing import Dict, List, Any
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class EC2AMIAnalyzer:
    def __init__(self):
        self.ec2_client = boto3.client('ec2')
        self.cloudwatch = boto3.client('cloudwatch')
        self.sts_client = boto3.client('sts')
        self.account_id = None
        self.regions = self.get_all_regions()
        
    def get_account_id(self):
        """Get current AWS account ID"""
        if not self.account_id:
            response = self.sts_client.get_caller_identity()
            self.account_id = response['Account']
        return self.account_id
    
    def get_all_regions(self):
        """Get all available AWS regions"""
        try:
            response = self.ec2_client.describe_regions()
            return [region['RegionName'] for region in response['Regions']]
        except Exception as e:
            logger.error(f"Error getting regions: {e}")
            # Fallback to common regions
            return ['us-east-1', 'us-west-2', 'eu-west-1', 'ap-southeast-1']
    
    def get_cpu_utilization(self, instance_id: str, region: str) -> float:
        """Get average CPU utilization for the last 7 days"""
        try:
            cloudwatch_regional = boto3.client('cloudwatch', region_name=region)
            
            end_time = datetime.utcnow()
            start_time = end_time - timedelta(days=7)
            
            response = cloudwatch_regional.get_metric_statistics(
                Namespace='AWS/EC2',
                MetricName='CPUUtilization',
                Dimensions=[
                    {
                        'Name': 'InstanceId',
                        'Value': instance_id
                    }
                ],
                StartTime=start_time,
                EndTime=end_time,
                Period=3600,  # 1 hour periods
                Statistics=['Average']
            )
            
            if response['Datapoints']:
                avg_cpu = sum(dp['Average'] for dp in response['Datapoints']) / len(response['Datapoints'])
                return round(avg_cpu, 2)
            else:
                return 0.0
                
        except Exception as e:
            logger.warning(f"Could not get CPU utilization for {instance_id}: {e}")
            return 0.0
    
    def get_instance_recommendation(self, instance_type: str, cpu_utilization: float) -> Dict[str, str]:
        """Generate upgrade/downgrade recommendations based on utilization and instance type"""
        
        # Instance type families and their hierarchy
        instance_families = {
            't2': ['t2.nano', 't2.micro', 't2.small', 't2.medium', 't2.large', 't2.xlarge', 't2.2xlarge'],
            't3': ['t3.nano', 't3.micro', 't3.small', 't3.medium', 't3.large', 't3.xlarge', 't3.2xlarge'],
            't3a': ['t3a.nano', 't3a.micro', 't3a.small', 't3a.medium', 't3a.large', 't3a.xlarge', 't3a.2xlarge'],
            'm5': ['m5.large', 'm5.xlarge', 'm5.2xlarge', 'm5.4xlarge', 'm5.8xlarge', 'm5.12xlarge', 'm5.16xlarge', 'm5.24xlarge'],
            'm6i': ['m6i.large', 'm6i.xlarge', 'm6i.2xlarge', 'm6i.4xlarge', 'm6i.8xlarge', 'm6i.12xlarge', 'm6i.16xlarge', 'm6i.24xlarge'],
            'c5': ['c5.large', 'c5.xlarge', 'c5.2xlarge', 'c5.4xlarge', 'c5.9xlarge', 'c5.12xlarge', 'c5.18xlarge', 'c5.24xlarge'],
            'r5': ['r5.large', 'r5.xlarge', 'r5.2xlarge', 'r5.4xlarge', 'r5.8xlarge', 'r5.12xlarge', 'r5.16xlarge', 'r5.24xlarge']
        }
        
        # Get current family
        family = instance_type.split('.')[0]
        
        recommendation = {
            'action': 'maintain',
            'recommended_type': instance_type,
            'reason': 'Current utilization is optimal'
        }
        
        # High utilization (>80%) - recommend upgrade
        if cpu_utilization > 80:
            if family in instance_families:
                current_types = instance_families[family]
                if instance_type in current_types:
                    current_index = current_types.index(instance_type)
                    if current_index < len(current_types) - 1:
                        recommendation = {
                            'action': 'upgrade',
                            'recommended_type': current_types[current_index + 1],
                            'reason': f'High CPU utilization ({cpu_utilization}%) - upgrade recommended'
                        }
                    else:
                        recommendation = {
                            'action': 'upgrade',
                            'recommended_type': 'Consider next generation family',
                            'reason': f'High CPU utilization ({cpu_utilization}%) - at max size for family'
                        }
        
        # Low utilization (<20%) - recommend downgrade
        elif cpu_utilization < 20 and cpu_utilization > 0:
            if family in instance_families:
                current_types = instance_families[family]
                if instance_type in current_types:
                    current_index = current_types.index(instance_type)
                    if current_index > 0:
                        recommendation = {
                            'action': 'downgrade',
                            'recommended_type': current_types[current_index - 1],
                            'reason': f'Low CPU utilization ({cpu_utilization}%) - downgrade to save costs'
                        }
        
        # Legacy instance types - recommend newer generation
        legacy_families = ['t2', 'm4', 'c4', 'r4', 'm3', 'c3', 'r3']
        if family in legacy_families:
            newer_family_map = {
                't2': 't3a',
                'm4': 'm5',
                'c4': 'c5',
                'r4': 'r5',
                'm3': 'm5',
                'c3': 'c5',
                'r3': 'r5'
            }
            if family in newer_family_map:
                size = instance_type.split('.')[1]
                newer_family = newer_family_map[family]
                recommendation = {
                    'action': 'modernize',
                    'recommended_type': f'{newer_family}.{size}',
                    'reason': f'Legacy instance family - upgrade to {newer_family} for better performance and cost'
                }
        
        return recommendation
    
    def get_ami_details(self, ami_id: str, region: str) -> Dict[str, Any]:
        """Get detailed AMI information"""
        try:
            ec2_regional = boto3.client('ec2', region_name=region)
            response = ec2_regional.describe_images(ImageIds=[ami_id])
            
            if response['Images']:
                ami = response['Images'][0]
                return {
                    'ami_name': ami.get('Name', 'Unknown'),
                    'ami_description': ami.get('Description', 'No description'),
                    'ami_creation_date': ami.get('CreationDate', 'Unknown'),
                    'ami_owner': ami.get('OwnerId', 'Unknown'),
                    'ami_platform': ami.get('Platform', 'Linux/Unix'),
                    'ami_architecture': ami.get('Architecture', 'Unknown'),
                    'ami_virtualization': ami.get('VirtualizationType', 'Unknown'),
                    'ami_state': ami.get('State', 'Unknown')
                }
            else:
                return {
                    'ami_name': 'AMI not found',
                    'ami_description': 'AMI may have been deleted',
                    'ami_creation_date': 'Unknown',
                    'ami_owner': 'Unknown',
                    'ami_platform': 'Unknown',
                    'ami_architecture': 'Unknown',
                    'ami_virtualization': 'Unknown',
                    'ami_state': 'Unknown'
                }
        except Exception as e:
            logger.warning(f"Could not get AMI details for {ami_id}: {e}")
            return {
                'ami_name': 'Error retrieving AMI',
                'ami_description': str(e),
                'ami_creation_date': 'Unknown',
                'ami_owner': 'Unknown',
                'ami_platform': 'Unknown',
                'ami_architecture': 'Unknown',
                'ami_virtualization': 'Unknown',
                'ami_state': 'Unknown'
            }
    
    def extract_application_name(self, instance: Dict[str, Any]) -> str:
        """Extract application name from instance tags"""
        tags = instance.get('Tags', [])
        
        # Common tag keys for application names
        app_tag_keys = ['Application', 'App', 'Name', 'Service', 'Project', 'Environment']
        
        for tag in tags:
            key = tag.get('Key', '')
            value = tag.get('Value', '')
            
            if key in app_tag_keys and value:
                return value
        
        # If no specific app tag found, try to construct from Name tag
        for tag in tags:
            if tag.get('Key') == 'Name':
                return tag.get('Value', 'Unknown Application')
        
        return 'Unknown Application'
    
    def analyze_region(self, region: str) -> List[Dict[str, Any]]:
        """Analyze all EC2 instances in a specific region"""
        logger.info(f"Analyzing region: {region}")
        
        try:
            ec2_regional = boto3.client('ec2', region_name=region)
            
            # Get all instances in the region
            paginator = ec2_regional.get_paginator('describe_instances')
            instances_data = []
            
            for page in paginator.paginate():
                for reservation in page['Reservations']:
                    for instance in reservation['Instances']:
                        
                        # Skip terminated instances
                        if instance['State']['Name'] == 'terminated':
                            continue
                        
                        logger.info(f"Processing instance: {instance['InstanceId']}")
                        
                        # Get CPU utilization
                        cpu_utilization = self.get_cpu_utilization(instance['InstanceId'], region)
                        
                        # Get AMI details
                        ami_details = self.get_ami_details(instance['ImageId'], region)
                        
                        # Get recommendation
                        recommendation = self.get_instance_recommendation(
                            instance['InstanceType'], 
                            cpu_utilization
                        )
                        
                        # Extract application name
                        application_name = self.extract_application_name(instance)
                        
                        # Compile instance data
                        instance_data = {
                            'account_number': self.get_account_id(),
                            'region': region,
                            'instance_id': instance['InstanceId'],
                            'instance_type': instance['InstanceType'],
                            'instance_state': instance['State']['Name'],
                            'launch_time': instance.get('LaunchTime', 'Unknown'),
                            'platform': instance.get('Platform', 'Linux/Unix'),
                            'architecture': instance.get('Architecture', 'Unknown'),
                            'virtualization_type': instance.get('VirtualizationType', 'Unknown'),
                            'cpu_utilization_7d_avg': cpu_utilization,
                            'recommendation_action': recommendation['action'],
                            'recommended_instance_type': recommendation['recommended_type'],
                            'recommendation_reason': recommendation['reason'],
                            'ami_id': instance['ImageId'],
                            'ami_name': ami_details['ami_name'],
                            'ami_description': ami_details['ami_description'],
                            'ami_creation_date': ami_details['ami_creation_date'],
                            'ami_owner': ami_details['ami_owner'],
                            'ami_platform': ami_details['ami_platform'],
                            'ami_architecture': ami_details['ami_architecture'],
                            'ami_virtualization': ami_details['ami_virtualization'],
                            'ami_state': ami_details['ami_state'],
                            'application_name': application_name,
                            'vpc_id': instance.get('VpcId', 'Unknown'),
                            'subnet_id': instance.get('SubnetId', 'Unknown'),
                            'availability_zone': instance.get('Placement', {}).get('AvailabilityZone', 'Unknown'),
                            'security_groups': ', '.join([sg['GroupName'] for sg in instance.get('SecurityGroups', [])]),
                            'key_name': instance.get('KeyName', 'No Key Pair'),
                            'monitoring_state': instance.get('Monitoring', {}).get('State', 'Unknown'),
                            'instance_lifecycle': instance.get('InstanceLifecycle', 'on-demand'),
                            'spot_instance_request_id': instance.get('SpotInstanceRequestId', 'N/A'),
                            'private_ip': instance.get('PrivateIpAddress', 'Unknown'),
                            'public_ip': instance.get('PublicIpAddress', 'No Public IP'),
                            'ebs_optimized': instance.get('EbsOptimized', False),
                            'root_device_type': instance.get('RootDeviceType', 'Unknown'),
                            'root_device_name': instance.get('RootDeviceName', 'Unknown')
                        }
                        
                        instances_data.append(instance_data)
            
            logger.info(f"Found {len(instances_data)} instances in {region}")
            return instances_data
            
        except Exception as e:
            logger.error(f"Error analyzing region {region}: {e}")
            return []
    
    def generate_csv_report(self, all_instances: List[Dict[str, Any]], filename: str):
        """Generate comprehensive CSV report"""
        
        if not all_instances:
            logger.warning("No instances found to report")
            return
        
        # Define CSV headers
        headers = [
            'Account Number',
            'Region',
            'Instance ID',
            'Instance Type',
            'Instance State',
            'Launch Time',
            'Platform',
            'Architecture',
            'Virtualization Type',
            'CPU Utilization (7d avg %)',
            'Recommendation Action',
            'Recommended Instance Type',
            'Recommendation Reason',
            'AMI ID',
            'AMI Name',
            'AMI Description',
            'AMI Creation Date',
            'AMI Owner',
            'AMI Platform',
            'AMI Architecture',
            'AMI Virtualization',
            'AMI State',
            'Application Name',
            'VPC ID',
            'Subnet ID',
            'Availability Zone',
            'Security Groups',
            'Key Pair Name',
            'Monitoring State',
            'Instance Lifecycle',
            'Spot Instance Request ID',
            'Private IP Address',
            'Public IP Address',
            'EBS Optimized',
            'Root Device Type',
            'Root Device Name'
        ]
        
        # Write CSV file
        with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=[h.lower().replace(' ', '_').replace('(', '').replace(')', '').replace('%', 'percent') for h in headers])
            
            # Write headers
            writer.writerow({h.lower().replace(' ', '_').replace('(', '').replace(')', '').replace('%', 'percent'): h for h in headers})
            
            # Write data
            for instance in all_instances:
                row = {
                    'account_number': instance['account_number'],
                    'region': instance['region'],
                    'instance_id': instance['instance_id'],
                    'instance_type': instance['instance_type'],
                    'instance_state': instance['instance_state'],
                    'launch_time': str(instance['launch_time']),
                    'platform': instance['platform'],
                    'architecture': instance['architecture'],
                    'virtualization_type': instance['virtualization_type'],
                    'cpu_utilization_7d_avg_percent': instance['cpu_utilization_7d_avg'],
                    'recommendation_action': instance['recommendation_action'],
                    'recommended_instance_type': instance['recommended_instance_type'],
                    'recommendation_reason': instance['recommendation_reason'],
                    'ami_id': instance['ami_id'],
                    'ami_name': instance['ami_name'],
                    'ami_description': instance['ami_description'],
                    'ami_creation_date': instance['ami_creation_date'],
                    'ami_owner': instance['ami_owner'],
                    'ami_platform': instance['ami_platform'],
                    'ami_architecture': instance['ami_architecture'],
                    'ami_virtualization': instance['ami_virtualization'],
                    'ami_state': instance['ami_state'],
                    'application_name': instance['application_name'],
                    'vpc_id': instance['vpc_id'],
                    'subnet_id': instance['subnet_id'],
                    'availability_zone': instance['availability_zone'],
                    'security_groups': instance['security_groups'],
                    'key_pair_name': instance['key_name'],
                    'monitoring_state': instance['monitoring_state'],
                    'instance_lifecycle': instance['instance_lifecycle'],
                    'spot_instance_request_id': instance['spot_instance_request_id'],
                    'private_ip_address': instance['private_ip'],
                    'public_ip_address': instance['public_ip'],
                    'ebs_optimized': instance['ebs_optimized'],
                    'root_device_type': instance['root_device_type'],
                    'root_device_name': instance['root_device_name']
                }
                writer.writerow(row)
        
        logger.info(f"CSV report generated: {filename}")
    
    def run_analysis(self):
        """Run complete EC2 and AMI analysis across all regions"""
        logger.info("Starting comprehensive EC2 and AMI analysis...")
        
        account_id = self.get_account_id()
        logger.info(f"Analyzing account: {account_id}")
        
        all_instances = []
        
        # Analyze each region
        for region in self.regions:
            try:
                region_instances = self.analyze_region(region)
                all_instances.extend(region_instances)
            except Exception as e:
                logger.error(f"Failed to analyze region {region}: {e}")
                continue
        
        # Generate timestamp for filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"EC2_AMI_Analysis_{account_id}_{timestamp}.csv"
        
        # Generate CSV report
        self.generate_csv_report(all_instances, filename)
        
        # Print summary
        print("\n" + "="*80)
        print("EC2 AND AMI ANALYSIS COMPLETE")
        print("="*80)
        print(f"Account ID: {account_id}")
        print(f"Total Instances Analyzed: {len(all_instances)}")
        print(f"Regions Scanned: {len(self.regions)}")
        print(f"Report Generated: {filename}")
        print("="*80)
        
        # Print summary by state
        states = {}
        for instance in all_instances:
            state = instance['instance_state']
            states[state] = states.get(state, 0) + 1
        
        print("\nInstance States Summary:")
        for state, count in states.items():
            print(f"  {state}: {count}")
        
        # Print recommendation summary
        recommendations = {}
        for instance in all_instances:
            action = instance['recommendation_action']
            recommendations[action] = recommendations.get(action, 0) + 1
        
        print("\nRecommendation Summary:")
        for action, count in recommendations.items():
            print(f"  {action}: {count}")
        
        return filename

def main():
    """Main execution function"""
    try:
        analyzer = EC2AMIAnalyzer()
        report_file = analyzer.run_analysis()
        print(f"\n✅ Analysis complete! Report saved as: {report_file}")
        
    except Exception as e:
        logger.error(f"Analysis failed: {e}")
        print(f"❌ Analysis failed: {e}")

if __name__ == "__main__":
    main()