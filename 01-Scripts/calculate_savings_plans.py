#!/usr/bin/env python3
"""
Calculate EC2 Savings Plans and RDS Reserved Instance costs
Analyzes all accounts and calculates 1-year and 3-year commitment savings
"""

import csv
import glob
from datetime import datetime

# AWS Pricing (approximate hourly rates in USD for us-west-2)
# These are On-Demand rates - actual rates may vary slightly
EC2_PRICING = {
    # T2 family
    't2.micro': 0.0116,
    't2.small': 0.023,
    't2.medium': 0.0464,
    't2.large': 0.0928,
    # T3 family
    't3.nano': 0.0052,
    't3.micro': 0.0104,
    't3.small': 0.0208,
    't3.medium': 0.0416,
    't3.large': 0.0832,
    't3.xlarge': 0.1664,
    't3.2xlarge': 0.3328,
    # M3 family (previous generation)
    'm3.medium': 0.067,
    'm3.large': 0.133,
    'm3.xlarge': 0.266,
    # M5 family
    'm5.large': 0.096,
    'm5.xlarge': 0.192,
    'm5.2xlarge': 0.384,
    'm5.4xlarge': 0.768,
    # M7a family
    'm7a.large': 0.1008,
    # C3 family (previous generation)
    'c3.xlarge': 0.210,
    # C4 family (previous generation)
    'c4.2xlarge': 0.398,
    # C5n family
    'c5n.large': 0.108,
    'c5n.2xlarge': 0.432,
    # C6i family
    'c6i.2xlarge': 0.34,
    # C7i-flex family
    'c7i-flex.8xlarge': 1.224,
    # G5 family (GPU)
    'g5.xlarge': 1.006,
    # G6e family (GPU)
    'g6e.4xlarge': 2.176,
}

RDS_PRICING = {
    # T3 family
    'db.t3.micro': 0.017,
    'db.t3.small': 0.034,
    'db.t3.medium': 0.068,
    'db.t3.large': 0.136,
    'db.t3.xlarge': 0.272,
    # T4g family (Graviton)
    'db.t4g.micro': 0.016,
    'db.t4g.small': 0.032,
    'db.t4g.medium': 0.064,
    'db.t4g.large': 0.128,
    # M5 family
    'db.m5.large': 0.188,
    'db.m5.xlarge': 0.376,
    'db.m5.4xlarge': 1.504,
    # M6i family
    'db.m6i.large': 0.192,
    # M7g family (Graviton)
    'db.m7g.xlarge': 0.364,
    # R7g family (Graviton, memory optimized)
    'db.r7g.2xlarge': 0.968,
    # Serverless
    'db.serverless': 0.12,  # Approximate ACU cost
}

# Savings Plan discount rates (approximate)
EC2_SP_1YR_NO_UPFRONT = 0.28  # 28% savings
EC2_SP_1YR_FULL_UPFRONT = 0.31  # 31% savings
EC2_SP_3YR_NO_UPFRONT = 0.42  # 42% savings
EC2_SP_3YR_FULL_UPFRONT = 0.50  # 50% savings

# RDS Reserved Instance discount rates (approximate)
RDS_RI_1YR_NO_UPFRONT = 0.25  # 25% savings
RDS_RI_1YR_FULL_UPFRONT = 0.30  # 30% savings
RDS_RI_3YR_NO_UPFRONT = 0.38  # 38% savings
RDS_RI_3YR_FULL_UPFRONT = 0.45  # 45% savings

def read_ec2_inventory():
    """Read all EC2 inventory files"""
    instances = []
    for file in glob.glob('SRSA_Compute/*-ec2.csv'):
        with open(file, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row['state'] == 'running' and row['purchase_option'] == 'OnDemand':
                    instances.append(row)
    return instances

def read_rds_inventory():
    """Read all RDS inventory files"""
    databases = []
    for file in glob.glob('SRSA_RDS/*-rds.csv'):
        with open(file, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                databases.append(row)
    return databases

def calculate_ec2_costs(instances):
    """Calculate EC2 costs for different scenarios"""
    total_hourly_cost = 0
    instance_count = 0
    missing_types = set()
    
    for instance in instances:
        instance_type = instance['instance_type']
        if instance_type in EC2_PRICING:
            total_hourly_cost += EC2_PRICING[instance_type]
            instance_count += 1
        else:
            missing_types.add(instance_type)
    
    # Annual costs
    hours_per_year = 8760
    annual_ondemand = total_hourly_cost * hours_per_year
    
    # 1-Year Savings Plans
    sp_1yr_no_upfront_annual = annual_ondemand * (1 - EC2_SP_1YR_NO_UPFRONT)
    sp_1yr_full_upfront = annual_ondemand * (1 - EC2_SP_1YR_FULL_UPFRONT)
    
    # 3-Year Savings Plans
    sp_3yr_no_upfront_annual = annual_ondemand * (1 - EC2_SP_3YR_NO_UPFRONT)
    sp_3yr_full_upfront_total = annual_ondemand * 3 * (1 - EC2_SP_3YR_FULL_UPFRONT)
    
    return {
        'instance_count': instance_count,
        'missing_types': missing_types,
        'hourly_cost': total_hourly_cost,
        'annual_ondemand': annual_ondemand,
        'sp_1yr_no_upfront_annual': sp_1yr_no_upfront_annual,
        'sp_1yr_full_upfront': sp_1yr_full_upfront,
        'sp_1yr_no_upfront_savings': annual_ondemand - sp_1yr_no_upfront_annual,
        'sp_1yr_full_upfront_savings': annual_ondemand - sp_1yr_full_upfront,
        'sp_3yr_no_upfront_annual': sp_3yr_no_upfront_annual,
        'sp_3yr_full_upfront_total': sp_3yr_full_upfront_total,
        'sp_3yr_no_upfront_savings_annual': annual_ondemand - sp_3yr_no_upfront_annual,
        'sp_3yr_full_upfront_savings_total': (annual_ondemand * 3) - sp_3yr_full_upfront_total,
    }

def calculate_rds_costs(databases):
    """Calculate RDS costs for different scenarios"""
    total_hourly_cost = 0
    instance_count = 0
    missing_types = set()
    
    for db in databases:
        db_class = db['db_instance_class']
        if db_class in RDS_PRICING:
            hourly_cost = RDS_PRICING[db_class]
            # Multi-AZ doubles the cost
            if db['multi_az'] == 'Yes':
                hourly_cost *= 2
            total_hourly_cost += hourly_cost
            instance_count += 1
        else:
            missing_types.add(db_class)
    
    # Annual costs
    hours_per_year = 8760
    annual_ondemand = total_hourly_cost * hours_per_year
    
    # 1-Year Reserved Instances
    ri_1yr_no_upfront_annual = annual_ondemand * (1 - RDS_RI_1YR_NO_UPFRONT)
    ri_1yr_full_upfront = annual_ondemand * (1 - RDS_RI_1YR_FULL_UPFRONT)
    
    # 3-Year Reserved Instances
    ri_3yr_no_upfront_annual = annual_ondemand * (1 - RDS_RI_3YR_NO_UPFRONT)
    ri_3yr_full_upfront_total = annual_ondemand * 3 * (1 - RDS_RI_3YR_FULL_UPFRONT)
    
    return {
        'instance_count': instance_count,
        'missing_types': missing_types,
        'hourly_cost': total_hourly_cost,
        'annual_ondemand': annual_ondemand,
        'ri_1yr_no_upfront_annual': ri_1yr_no_upfront_annual,
        'ri_1yr_full_upfront': ri_1yr_full_upfront,
        'ri_1yr_no_upfront_savings': annual_ondemand - ri_1yr_no_upfront_annual,
        'ri_1yr_full_upfront_savings': annual_ondemand - ri_1yr_full_upfront,
        'ri_3yr_no_upfront_annual': ri_3yr_no_upfront_annual,
        'ri_3yr_full_upfront_total': ri_3yr_full_upfront_total,
        'ri_3yr_no_upfront_savings_annual': annual_ondemand - ri_3yr_no_upfront_annual,
        'ri_3yr_full_upfront_savings_total': (annual_ondemand * 3) - ri_3yr_full_upfront_total,
    }

def main():
    print("=" * 80)
    print("AWS SAVINGS PLANS AND RESERVED INSTANCES COST ANALYSIS")
    print("=" * 80)
    print()
    
    # Read inventory
    print("Reading inventory data...")
    ec2_instances = read_ec2_inventory()
    rds_databases = read_rds_inventory()
    print(f"Found {len(ec2_instances)} running EC2 On-Demand instances")
    print(f"Found {len(rds_databases)} RDS instances")
    print()
    
    # Calculate EC2 costs
    print("=" * 80)
    print("EC2 SAVINGS PLANS ANALYSIS")
    print("=" * 80)
    ec2_costs = calculate_ec2_costs(ec2_instances)
    
    print(f"\nTotal running instances: {len(ec2_instances)}")
    print(f"Instances analyzed (with pricing): {ec2_costs['instance_count']}")
    if ec2_costs['missing_types']:
        print(f"Instances without pricing: {len(ec2_instances) - ec2_costs['instance_count']}")
        print(f"Missing instance types: {', '.join(sorted(ec2_costs['missing_types']))}")
    print(f"\nCurrent hourly cost: ${ec2_costs['hourly_cost']:.2f}")
    print(f"Current annual cost (On-Demand): ${ec2_costs['annual_ondemand']:,.2f}")
    print()
    
    print("1-YEAR SAVINGS PLAN:")
    print(f"  No Upfront Payment:")
    print(f"    Annual cost: ${ec2_costs['sp_1yr_no_upfront_annual']:,.2f}")
    print(f"    Annual savings: ${ec2_costs['sp_1yr_no_upfront_savings']:,.2f} ({EC2_SP_1YR_NO_UPFRONT*100:.0f}% discount)")
    print()
    print(f"  Full Upfront Payment:")
    print(f"    Total cost (paid upfront): ${ec2_costs['sp_1yr_full_upfront']:,.2f}")
    print(f"    Annual savings: ${ec2_costs['sp_1yr_full_upfront_savings']:,.2f} ({EC2_SP_1YR_FULL_UPFRONT*100:.0f}% discount)")
    print()
    
    print("3-YEAR SAVINGS PLAN:")
    print(f"  No Upfront Payment:")
    print(f"    Annual cost: ${ec2_costs['sp_3yr_no_upfront_annual']:,.2f}")
    print(f"    Annual savings: ${ec2_costs['sp_3yr_no_upfront_savings_annual']:,.2f} ({EC2_SP_3YR_NO_UPFRONT*100:.0f}% discount)")
    print(f"    Total 3-year savings: ${ec2_costs['sp_3yr_no_upfront_savings_annual'] * 3:,.2f}")
    print()
    print(f"  Full Upfront Payment:")
    print(f"    Total cost (paid upfront): ${ec2_costs['sp_3yr_full_upfront_total']:,.2f}")
    print(f"    Total 3-year savings: ${ec2_costs['sp_3yr_full_upfront_savings_total']:,.2f} ({EC2_SP_3YR_FULL_UPFRONT*100:.0f}% discount)")
    print()
    
    # Calculate RDS costs
    print("=" * 80)
    print("RDS RESERVED INSTANCES ANALYSIS")
    print("=" * 80)
    rds_costs = calculate_rds_costs(rds_databases)
    
    print(f"\nTotal RDS instances: {len(rds_databases)}")
    print(f"Instances analyzed (with pricing): {rds_costs['instance_count']}")
    if rds_costs['missing_types']:
        print(f"Instances without pricing: {len(rds_databases) - rds_costs['instance_count']}")
        print(f"Missing instance types: {', '.join(sorted(rds_costs['missing_types']))}")
    print(f"\nCurrent hourly cost: ${rds_costs['hourly_cost']:.2f}")
    print(f"Current annual cost (On-Demand): ${rds_costs['annual_ondemand']:,.2f}")
    print()
    
    print("1-YEAR RESERVED INSTANCES:")
    print(f"  No Upfront Payment:")
    print(f"    Annual cost: ${rds_costs['ri_1yr_no_upfront_annual']:,.2f}")
    print(f"    Annual savings: ${rds_costs['ri_1yr_no_upfront_savings']:,.2f} ({RDS_RI_1YR_NO_UPFRONT*100:.0f}% discount)")
    print()
    print(f"  Full Upfront Payment:")
    print(f"    Total cost (paid upfront): ${rds_costs['ri_1yr_full_upfront']:,.2f}")
    print(f"    Annual savings: ${rds_costs['ri_1yr_full_upfront_savings']:,.2f} ({RDS_RI_1YR_FULL_UPFRONT*100:.0f}% discount)")
    print()
    
    print("3-YEAR RESERVED INSTANCES:")
    print(f"  No Upfront Payment:")
    print(f"    Annual cost: ${rds_costs['ri_3yr_no_upfront_annual']:,.2f}")
    print(f"    Annual savings: ${rds_costs['ri_3yr_no_upfront_savings_annual']:,.2f} ({RDS_RI_3YR_NO_UPFRONT*100:.0f}% discount)")
    print(f"    Total 3-year savings: ${rds_costs['ri_3yr_no_upfront_savings_annual'] * 3:,.2f}")
    print()
    print(f"  Full Upfront Payment:")
    print(f"    Total cost (paid upfront): ${rds_costs['ri_3yr_full_upfront_total']:,.2f}")
    print(f"    Total 3-year savings: ${rds_costs['ri_3yr_full_upfront_savings_total']:,.2f} ({RDS_RI_3YR_FULL_UPFRONT*100:.0f}% discount)")
    print()
    
    # Summary
    print("=" * 80)
    print("SUMMARY - RECOMMENDED SAVINGS")
    print("=" * 80)
    print()
    print("EC2 SAVINGS PLANS:")
    print(f"  1-Year Full Upfront: ${ec2_costs['sp_1yr_full_upfront_savings']:,.2f} savings")
    print(f"  3-Year Full Upfront: ${ec2_costs['sp_3yr_full_upfront_savings_total']:,.2f} total savings")
    print()
    print("RDS RESERVED INSTANCES:")
    print(f"  1-Year Full Upfront: ${rds_costs['ri_1yr_full_upfront_savings']:,.2f} savings")
    print(f"  3-Year Full Upfront: ${rds_costs['ri_3yr_full_upfront_savings_total']:,.2f} total savings")
    print()
    print("TOTAL POTENTIAL SAVINGS:")
    print(f"  1-Year (Full Upfront): ${ec2_costs['sp_1yr_full_upfront_savings'] + rds_costs['ri_1yr_full_upfront_savings']:,.2f}")
    print(f"  3-Year (Full Upfront): ${ec2_costs['sp_3yr_full_upfront_savings_total'] + rds_costs['ri_3yr_full_upfront_savings_total']:,.2f}")
    print()

if __name__ == "__main__":
    main()
