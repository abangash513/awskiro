#!/usr/bin/env python3
"""
Enhanced EC2 and AMI Analysis Script
Takes existing EC2 data and adds comprehensive AMI information
"""

import boto3
import csv
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Any
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class EnhancedEC2AMIAnalyzer:
    def __init__(self):
        self.ec2_client = boto3.client('ec2', region_name='us-west-2')  # Primary region
        self.sts_client = boto3.client('sts')
        self.account_id = None
        
    def get_account_id(self):
        """Get current AWS account ID"""
        if not self.account_id:
            response = self.sts_client.get_caller_identity()
            self.account_id = response['Account']
        return self.account_id
    
    def get_comprehensive_ami_details(self, ami_id: str, region: str = 'us-west-2') -> Dict[str, Any]:
        """Get comprehensive AMI information including security and compliance details"""
        try:
            ec2_regional = boto3.client('ec2', region_name=region)
            
            # Get AMI details
            response = ec2_regional.describe_images(ImageIds=[ami_id])
            
            if not response['Images']:
                return self.get_empty_ami_details("AMI not found or deleted")
            
            ami = response['Images'][0]
            
            # Calculate AMI age
            creation_date = ami.get('CreationDate', '')
            ami_age_days = 0
            if creation_date:
                try:
                    creation_dt = datetime.fromisoformat(creation_date.replace('Z', '+00:00'))
                    ami_age_days = (datetime.now(creation_dt.tzinfo) - creation_dt).days
                except:
                    ami_age_days = 0
            
            # Determine AMI category and risk level
            ami_name = ami.get('Name', '').lower()
            ami_description = ami.get('Description', '').lower()
            
            # Categorize AMI
            ami_category = self.categorize_ami(ami_name, ami_description)
            
            # Assess security risk
            security_risk = self.assess_ami_security_risk(ami, ami_age_days)
            
            # Get block device mappings
            block_devices = self.parse_block_device_mappings(ami.get('BlockDeviceMappings', []))
            
            # Check for public AMI
            is_public = ami.get('Public', False)
            
            # Get AMI tags
            ami_tags = self.parse_ami_tags(ami.get('Tags', []))
            
            return {
                'ami_id': ami_id,
                'ami_name': ami.get('Name', 'Unknown'),
                'ami_description': ami.get('Description', 'No description'),
                'ami_creation_date': creation_date,
                'ami_age_days': ami_age_days,
                'ami_owner_id': ami.get('OwnerId', 'Unknown'),
                'ami_owner_alias': ami.get('ImageOwnerAlias', 'Unknown'),
                'ami_platform': ami.get('Platform', 'Linux/Unix'),
                'ami_platform_details': ami.get('PlatformDetails', 'Unknown'),
                'ami_architecture': ami.get('Architecture', 'Unknown'),
                'ami_virtualization_type': ami.get('VirtualizationType', 'Unknown'),
                'ami_hypervisor': ami.get('Hypervisor', 'Unknown'),
                'ami_state': ami.get('State', 'Unknown'),
                'ami_image_type': ami.get('ImageType', 'Unknown'),
                'ami_root_device_type': ami.get('RootDeviceType', 'Unknown'),
                'ami_root_device_name': ami.get('RootDeviceName', 'Unknown'),
                'ami_sriov_net_support': ami.get('SriovNetSupport', 'Unknown'),
                'ami_ena_support': ami.get('EnaSupport', False),
                'ami_tpm_support': ami.get('TpmSupport', 'Unknown'),
                'ami_boot_mode': ami.get('BootMode', 'Unknown'),
                'ami_imds_support': ami.get('ImdsSupport', 'Unknown'),
                'ami_deprecation_time': ami.get('DeprecationTime', 'Not deprecated'),
                'ami_is_public': is_public,
                'ami_category': ami_category,
                'ami_security_risk_level': security_risk['level'],
                'ami_security_risk_reasons': security_risk['reasons'],
                'ami_compliance_status': self.assess_compliance_status(ami, ami_age_days),
                'ami_update_recommendation': self.get_update_recommendation(ami, ami_age_days),
                'ami_block_device_count': len(ami.get('BlockDeviceMappings', [])),
                'ami_block_devices_details': block_devices,
                'ami_tags_count': len(ami.get('Tags', [])),
                'ami_tags_details': ami_tags,
                'ami_usage_operation': ami.get('UsageOperation', 'Unknown'),
                'ami_image_location': ami.get('ImageLocation', 'Unknown')
            }
            
        except Exception as e:
            logger.warning(f"Could not get AMI details for {ami_id}: {e}")
            return self.get_empty_ami_details(f"Error: {str(e)}")
    
    def get_empty_ami_details(self, reason: str) -> Dict[str, Any]:
        """Return empty AMI details structure"""
        return {
            'ami_id': 'Unknown',
            'ami_name': reason,
            'ami_description': reason,
            'ami_creation_date': 'Unknown',
            'ami_age_days': 0,
            'ami_owner_id': 'Unknown',
            'ami_owner_alias': 'Unknown',
            'ami_platform': 'Unknown',
            'ami_platform_details': 'Unknown',
            'ami_architecture': 'Unknown',
            'ami_virtualization_type': 'Unknown',
            'ami_hypervisor': 'Unknown',
            'ami_state': 'Unknown',
            'ami_image_type': 'Unknown',
            'ami_root_device_type': 'Unknown',
            'ami_root_device_name': 'Unknown',
            'ami_sriov_net_support': 'Unknown',
            'ami_ena_support': False,
            'ami_tpm_support': 'Unknown',
            'ami_boot_mode': 'Unknown',
            'ami_imds_support': 'Unknown',
            'ami_deprecation_time': 'Unknown',
            'ami_is_public': False,
            'ami_category': 'Unknown',
            'ami_security_risk_level': 'Unknown',
            'ami_security_risk_reasons': reason,
            'ami_compliance_status': 'Unknown',
            'ami_update_recommendation': reason,
            'ami_block_device_count': 0,
            'ami_block_devices_details': 'Unknown',
            'ami_tags_count': 0,
            'ami_tags_details': 'Unknown',
            'ami_usage_operation': 'Unknown',
            'ami_image_location': 'Unknown'
        }
    
    def categorize_ami(self, ami_name: str, ami_description: str) -> str:
        """Categorize AMI based on name and description"""
        text = f"{ami_name} {ami_description}".lower()
        
        if any(keyword in text for keyword in ['ubuntu', 'canonical']):
            return 'Ubuntu Linux'
        elif any(keyword in text for keyword in ['amazon linux', 'amzn', 'al2023']):
            return 'Amazon Linux'
        elif any(keyword in text for keyword in ['windows', 'microsoft']):
            return 'Windows'
        elif any(keyword in text for keyword in ['centos', 'rhel', 'red hat']):
            return 'Red Hat/CentOS'
        elif any(keyword in text for keyword in ['debian']):
            return 'Debian'
        elif any(keyword in text for keyword in ['deep learning', 'ml', 'gpu', 'nvidia']):
            return 'Machine Learning/GPU'
        elif any(keyword in text for keyword in ['docker', 'container']):
            return 'Container Optimized'
        elif any(keyword in text for keyword in ['kubernetes', 'k8s', 'eks']):
            return 'Kubernetes Optimized'
        else:
            return 'Other/Custom'
    
    def assess_ami_security_risk(self, ami: Dict, age_days: int) -> Dict[str, Any]:
        """Assess security risk level of AMI"""
        risk_factors = []
        risk_level = 'Low'
        
        # Age-based risk
        if age_days > 365:
            risk_factors.append(f"AMI is {age_days} days old (>1 year)")
            risk_level = 'High'
        elif age_days > 180:
            risk_factors.append(f"AMI is {age_days} days old (>6 months)")
            risk_level = 'Medium' if risk_level == 'Low' else risk_level
        
        # Public AMI risk
        if ami.get('Public', False):
            risk_factors.append("Public AMI - verify source")
            risk_level = 'Medium' if risk_level == 'Low' else risk_level
        
        # Unknown owner risk
        owner_id = ami.get('OwnerId', '')
        if owner_id not in ['137112412989', '099720109477', '898082745236']:  # AWS, Canonical, AWS Deep Learning
            risk_factors.append(f"Third-party AMI owner: {owner_id}")
            risk_level = 'Medium' if risk_level == 'Low' else risk_level
        
        # Deprecated AMI
        if ami.get('DeprecationTime'):
            risk_factors.append("AMI is deprecated")
            risk_level = 'High'
        
        # Missing modern features
        if not ami.get('EnaSupport', False):
            risk_factors.append("Missing Enhanced Networking (ENA) support")
        
        if ami.get('ImdsSupport') != 'v2.0':
            risk_factors.append("Not using IMDSv2 (Instance Metadata Service v2)")
        
        if not risk_factors:
            risk_factors.append("No significant security risks identified")
        
        return {
            'level': risk_level,
            'reasons': '; '.join(risk_factors)
        }
    
    def assess_compliance_status(self, ami: Dict, age_days: int) -> str:
        """Assess compliance status"""
        if ami.get('DeprecationTime'):
            return 'Non-Compliant: Deprecated AMI'
        elif age_days > 365:
            return 'Non-Compliant: AMI >1 year old'
        elif age_days > 180:
            return 'Warning: AMI >6 months old'
        elif not ami.get('EnaSupport', False):
            return 'Warning: Missing ENA support'
        else:
            return 'Compliant'
    
    def get_update_recommendation(self, ami: Dict, age_days: int) -> str:
        """Get update recommendation"""
        if ami.get('DeprecationTime'):
            return 'URGENT: Replace deprecated AMI immediately'
        elif age_days > 365:
            return 'HIGH PRIORITY: Update AMI (>1 year old)'
        elif age_days > 180:
            return 'MEDIUM PRIORITY: Consider updating AMI (>6 months old)'
        elif age_days > 90:
            return 'LOW PRIORITY: AMI is relatively recent but consider updating'
        else:
            return 'CURRENT: AMI is recent, no immediate update needed'
    
    def parse_block_device_mappings(self, block_devices: List) -> str:
        """Parse block device mappings into readable format"""
        if not block_devices:
            return 'No block devices'
        
        devices = []
        for device in block_devices:
            device_name = device.get('DeviceName', 'Unknown')
            if 'Ebs' in device:
                ebs = device['Ebs']
                volume_size = ebs.get('VolumeSize', 'Unknown')
                volume_type = ebs.get('VolumeType', 'Unknown')
                encrypted = ebs.get('Encrypted', False)
                devices.append(f"{device_name}:{volume_type}:{volume_size}GB:{'Encrypted' if encrypted else 'Unencrypted'}")
            else:
                devices.append(f"{device_name}:Unknown")
        
        return '; '.join(devices)
    
    def parse_ami_tags(self, tags: List) -> str:
        """Parse AMI tags into readable format"""
        if not tags:
            return 'No tags'
        
        tag_pairs = []
        for tag in tags:
            key = tag.get('Key', 'Unknown')
            value = tag.get('Value', 'Unknown')
            tag_pairs.append(f"{key}={value}")
        
        return '; '.join(tag_pairs)
    
    def get_ami_id_from_instance(self, instance_id: str, region: str = 'us-west-2') -> str:
        """Get AMI ID from instance ID"""
        try:
            ec2_regional = boto3.client('ec2', region_name=region)
            response = ec2_regional.describe_instances(InstanceIds=[instance_id])
            
            if response['Reservations']:
                instance = response['Reservations'][0]['Instances'][0]
                return instance.get('ImageId', 'Unknown')
            else:
                return 'Unknown'
                
        except Exception as e:
            logger.warning(f"Could not get AMI ID for instance {instance_id}: {e}")
            return 'Unknown'
    
    def enhance_existing_data(self, input_file: str, output_file: str):
        """Enhance existing EC2 data with comprehensive AMI information"""
        logger.info(f"Reading existing EC2 data from: {input_file}")
        
        # Read existing CSV
        df = pd.read_csv(input_file)
        logger.info(f"Found {len(df)} instances in existing data")
        
        # Add new AMI columns
        ami_columns = [
            'ami_id', 'ami_name', 'ami_description', 'ami_creation_date', 'ami_age_days',
            'ami_owner_id', 'ami_owner_alias', 'ami_platform', 'ami_platform_details',
            'ami_architecture', 'ami_virtualization_type', 'ami_hypervisor', 'ami_state',
            'ami_image_type', 'ami_root_device_type', 'ami_root_device_name',
            'ami_sriov_net_support', 'ami_ena_support', 'ami_tpm_support', 'ami_boot_mode',
            'ami_imds_support', 'ami_deprecation_time', 'ami_is_public', 'ami_category',
            'ami_security_risk_level', 'ami_security_risk_reasons', 'ami_compliance_status',
            'ami_update_recommendation', 'ami_block_device_count', 'ami_block_devices_details',
            'ami_tags_count', 'ami_tags_details', 'ami_usage_operation', 'ami_image_location'
        ]
        
        # Initialize new columns
        for col in ami_columns:
            df[col] = ''
        
        # Process each instance
        for index, row in df.iterrows():
            instance_id = row['instance_id']
            region = row['region']
            
            logger.info(f"Processing instance {instance_id} ({index + 1}/{len(df)})")
            
            # Get AMI ID if not available
            ami_id = self.get_ami_id_from_instance(instance_id, region)
            
            if ami_id and ami_id != 'Unknown':
                # Get comprehensive AMI details
                ami_details = self.get_comprehensive_ami_details(ami_id, region)
                
                # Update dataframe with AMI details
                for col in ami_columns:
                    df.at[index, col] = ami_details.get(col, 'Unknown')
            else:
                # Fill with empty details
                empty_details = self.get_empty_ami_details("Could not retrieve AMI ID")
                for col in ami_columns:
                    df.at[index, col] = empty_details.get(col, 'Unknown')
        
        # Save enhanced data
        df.to_csv(output_file, index=False)
        logger.info(f"Enhanced data saved to: {output_file}")
        
        # Generate summary
        self.generate_summary_report(df, output_file)
        
        return output_file
    
    def generate_summary_report(self, df: pd.DataFrame, output_file: str):
        """Generate summary report of AMI analysis"""
        
        summary_file = output_file.replace('.csv', '_AMI_Summary.md')
        
        with open(summary_file, 'w') as f:
            f.write("# Enhanced EC2 and AMI Analysis Summary\n\n")
            f.write(f"**Analysis Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"**Account ID:** {self.get_account_id()}\n")
            f.write(f"**Total Instances:** {len(df)}\n\n")
            
            # AMI Categories
            f.write("## AMI Categories\n\n")
            ami_categories = df['ami_category'].value_counts()
            for category, count in ami_categories.items():
                f.write(f"- **{category}:** {count} instances\n")
            
            # Security Risk Levels
            f.write("\n## Security Risk Assessment\n\n")
            risk_levels = df['ami_security_risk_level'].value_counts()
            for risk, count in risk_levels.items():
                f.write(f"- **{risk} Risk:** {count} instances\n")
            
            # Compliance Status
            f.write("\n## Compliance Status\n\n")
            compliance_status = df['ami_compliance_status'].value_counts()
            for status, count in compliance_status.items():
                f.write(f"- **{status}:** {count} instances\n")
            
            # AMI Age Analysis
            f.write("\n## AMI Age Analysis\n\n")
            df['ami_age_days'] = pd.to_numeric(df['ami_age_days'], errors='coerce')
            avg_age = df['ami_age_days'].mean()
            max_age = df['ami_age_days'].max()
            min_age = df['ami_age_days'].min()
            
            f.write(f"- **Average AMI Age:** {avg_age:.0f} days\n")
            f.write(f"- **Oldest AMI:** {max_age:.0f} days\n")
            f.write(f"- **Newest AMI:** {min_age:.0f} days\n")
            
            # Update Recommendations
            f.write("\n## Update Recommendations\n\n")
            update_recs = df['ami_update_recommendation'].value_counts()
            for rec, count in update_recs.items():
                f.write(f"- **{rec}:** {count} instances\n")
            
            # High Priority Actions
            f.write("\n## High Priority Actions\n\n")
            high_risk = df[df['ami_security_risk_level'] == 'High']
            if len(high_risk) > 0:
                f.write("### High Risk AMIs (Immediate Action Required)\n")
                for _, row in high_risk.iterrows():
                    f.write(f"- **{row['instance_name']}** ({row['instance_id']}): {row['ami_security_risk_reasons']}\n")
            
            deprecated = df[df['ami_compliance_status'].str.contains('Deprecated', na=False)]
            if len(deprecated) > 0:
                f.write("\n### Deprecated AMIs (Replace Immediately)\n")
                for _, row in deprecated.iterrows():
                    f.write(f"- **{row['instance_name']}** ({row['instance_id']}): {row['ami_name']}\n")
        
        logger.info(f"Summary report saved to: {summary_file}")

def main():
    """Main execution function"""
    try:
        analyzer = EnhancedEC2AMIAnalyzer()
        
        # Input and output files
        account_id = analyzer.get_account_id()
        input_file = f"SRSA_Compute/{account_id}-ec2.csv"
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_file = f"Enhanced_EC2_AMI_Analysis_{account_id}_{timestamp}.csv"
        
        # Enhance the data
        result_file = analyzer.enhance_existing_data(input_file, output_file)
        
        print("\n" + "="*80)
        print("ENHANCED EC2 AND AMI ANALYSIS COMPLETE")
        print("="*80)
        print(f"Input File: {input_file}")
        print(f"Enhanced Report: {result_file}")
        print(f"Summary Report: {result_file.replace('.csv', '_AMI_Summary.md')}")
        print("="*80)
        print("\n✅ Enhanced analysis complete with comprehensive AMI details!")
        
    except Exception as e:
        logger.error(f"Analysis failed: {e}")
        print(f"❌ Analysis failed: {e}")

if __name__ == "__main__":
    main()