#!/usr/bin/env python3
"""
Detailed AWS Savings Plans and Reserved Instances Analysis
With break-even calculations for presentation
"""

import csv
import glob

# Current costs from analysis
EC2_ANNUAL_ONDEMAND = 297375.72
RDS_ANNUAL_ONDEMAND = 203161.92

# Discount rates
EC2_SP_1YR_NO_UPFRONT = 0.28
EC2_SP_1YR_FULL_UPFRONT = 0.31
EC2_SP_3YR_NO_UPFRONT = 0.42
EC2_SP_3YR_FULL_UPFRONT = 0.50

RDS_RI_1YR_NO_UPFRONT = 0.25
RDS_RI_1YR_FULL_UPFRONT = 0.30
RDS_RI_3YR_NO_UPFRONT = 0.38
RDS_RI_3YR_FULL_UPFRONT = 0.45

def calculate_breakeven(upfront_cost, monthly_savings):
    """Calculate break-even point in months"""
    if monthly_savings <= 0:
        return 0
    return upfront_cost / monthly_savings

def format_currency(amount):
    """Format currency for presentation"""
    return f"${amount:,.0f}"

def print_section_header(title):
    """Print formatted section header"""
    print("\n" + "=" * 100)
    print(f"{title:^100}")
    print("=" * 100)

def print_ec2_analysis():
    """Print EC2 Savings Plans analysis"""
    print_section_header("EC2 SAVINGS PLANS ANALYSIS (127 On-Demand Instances)")
    
    print(f"\nCurrent Annual On-Demand Cost: {format_currency(EC2_ANNUAL_ONDEMAND)}")
    print(f"Current Monthly Cost: {format_currency(EC2_ANNUAL_ONDEMAND/12)}")
    
    # 1-Year Calculations
    print("\n" + "-" * 100)
    print("1-YEAR SAVINGS PLAN")
    print("-" * 100)
    
    # No Upfront
    sp_1yr_no_annual = EC2_ANNUAL_ONDEMAND * (1 - EC2_SP_1YR_NO_UPFRONT)
    sp_1yr_no_monthly = sp_1yr_no_annual / 12
    sp_1yr_no_savings_annual = EC2_ANNUAL_ONDEMAND - sp_1yr_no_annual
    sp_1yr_no_savings_monthly = sp_1yr_no_savings_annual / 12
    
    print("\nNo Upfront Payment:")
    print(f"  Monthly Cost:           {format_currency(sp_1yr_no_monthly)}")
    print(f"  Annual Cost:            {format_currency(sp_1yr_no_annual)}")
    print(f"  Monthly Savings:        {format_currency(sp_1yr_no_savings_monthly)}")
    print(f"  Annual Savings:         {format_currency(sp_1yr_no_savings_annual)}")
    print(f"  Discount:               {EC2_SP_1YR_NO_UPFRONT*100:.0f}%")
    print(f"  Upfront Payment:        $0")
    print(f"  Break-even:             Immediate (no upfront cost)")
    
    # Full Upfront
    sp_1yr_full = EC2_ANNUAL_ONDEMAND * (1 - EC2_SP_1YR_FULL_UPFRONT)
    sp_1yr_full_savings = EC2_ANNUAL_ONDEMAND - sp_1yr_full
    sp_1yr_full_savings_monthly = sp_1yr_full_savings / 12
    # For full upfront, compare upfront cost vs monthly on-demand
    ondemand_monthly = EC2_ANNUAL_ONDEMAND / 12
    breakeven_1yr_full = calculate_breakeven(sp_1yr_full, ondemand_monthly)
    
    print("\nFull Upfront Payment:")
    print(f"  Upfront Cost:           {format_currency(sp_1yr_full)}")
    print(f"  Monthly Cost:           $0 (already paid)")
    print(f"  Total Annual Savings:   {format_currency(sp_1yr_full_savings)}")
    print(f"  Monthly Savings:        {format_currency(sp_1yr_full_savings_monthly)}")
    print(f"  Discount:               {EC2_SP_1YR_FULL_UPFRONT*100:.0f}%")
    print(f"  Break-even:             {breakeven_1yr_full:.1f} months")
    
    # 3-Year Calculations
    print("\n" + "-" * 100)
    print("3-YEAR SAVINGS PLAN")
    print("-" * 100)
    
    # No Upfront
    sp_3yr_no_annual = EC2_ANNUAL_ONDEMAND * (1 - EC2_SP_3YR_NO_UPFRONT)
    sp_3yr_no_monthly = sp_3yr_no_annual / 12
    sp_3yr_no_savings_annual = EC2_ANNUAL_ONDEMAND - sp_3yr_no_annual
    sp_3yr_no_savings_monthly = sp_3yr_no_savings_annual / 12
    sp_3yr_no_savings_total = sp_3yr_no_savings_annual * 3
    
    print("\nNo Upfront Payment:")
    print(f"  Monthly Cost:           {format_currency(sp_3yr_no_monthly)}")
    print(f"  Annual Cost:            {format_currency(sp_3yr_no_annual)}")
    print(f"  Monthly Savings:        {format_currency(sp_3yr_no_savings_monthly)}")
    print(f"  Annual Savings:         {format_currency(sp_3yr_no_savings_annual)}")
    print(f"  Total 3-Year Savings:   {format_currency(sp_3yr_no_savings_total)}")
    print(f"  Discount:               {EC2_SP_3YR_NO_UPFRONT*100:.0f}%")
    print(f"  Upfront Payment:        $0")
    print(f"  Break-even:             Immediate (no upfront cost)")
    
    # Full Upfront
    sp_3yr_full = EC2_ANNUAL_ONDEMAND * 3 * (1 - EC2_SP_3YR_FULL_UPFRONT)
    sp_3yr_full_savings = (EC2_ANNUAL_ONDEMAND * 3) - sp_3yr_full
    sp_3yr_full_savings_monthly = sp_3yr_full_savings / 36
    breakeven_3yr_full = calculate_breakeven(sp_3yr_full, ondemand_monthly)
    
    print("\nFull Upfront Payment:")
    print(f"  Upfront Cost:           {format_currency(sp_3yr_full)}")
    print(f"  Monthly Cost:           $0 (already paid)")
    print(f"  Total 3-Year Savings:   {format_currency(sp_3yr_full_savings)}")
    print(f"  Monthly Savings:        {format_currency(sp_3yr_full_savings_monthly)}")
    print(f"  Discount:               {EC2_SP_3YR_FULL_UPFRONT*100:.0f}%")
    print(f"  Break-even:             {breakeven_3yr_full:.1f} months")

def print_rds_analysis():
    """Print RDS Reserved Instances analysis"""
    print_section_header("RDS RESERVED INSTANCES ANALYSIS (141 Instances)")
    
    print(f"\nCurrent Annual On-Demand Cost: {format_currency(RDS_ANNUAL_ONDEMAND)}")
    print(f"Current Monthly Cost: {format_currency(RDS_ANNUAL_ONDEMAND/12)}")
    
    # 1-Year Calculations
    print("\n" + "-" * 100)
    print("1-YEAR RESERVED INSTANCES")
    print("-" * 100)
    
    # No Upfront
    ri_1yr_no_annual = RDS_ANNUAL_ONDEMAND * (1 - RDS_RI_1YR_NO_UPFRONT)
    ri_1yr_no_monthly = ri_1yr_no_annual / 12
    ri_1yr_no_savings_annual = RDS_ANNUAL_ONDEMAND - ri_1yr_no_annual
    ri_1yr_no_savings_monthly = ri_1yr_no_savings_annual / 12
    
    print("\nNo Upfront Payment:")
    print(f"  Monthly Cost:           {format_currency(ri_1yr_no_monthly)}")
    print(f"  Annual Cost:            {format_currency(ri_1yr_no_annual)}")
    print(f"  Monthly Savings:        {format_currency(ri_1yr_no_savings_monthly)}")
    print(f"  Annual Savings:         {format_currency(ri_1yr_no_savings_annual)}")
    print(f"  Discount:               {RDS_RI_1YR_NO_UPFRONT*100:.0f}%")
    print(f"  Upfront Payment:        $0")
    print(f"  Break-even:             Immediate (no upfront cost)")
    
    # Full Upfront
    ri_1yr_full = RDS_ANNUAL_ONDEMAND * (1 - RDS_RI_1YR_FULL_UPFRONT)
    ri_1yr_full_savings = RDS_ANNUAL_ONDEMAND - ri_1yr_full
    ri_1yr_full_savings_monthly = ri_1yr_full_savings / 12
    ondemand_monthly = RDS_ANNUAL_ONDEMAND / 12
    breakeven_1yr_full = calculate_breakeven(ri_1yr_full, ondemand_monthly)
    
    print("\nFull Upfront Payment:")
    print(f"  Upfront Cost:           {format_currency(ri_1yr_full)}")
    print(f"  Monthly Cost:           $0 (already paid)")
    print(f"  Total Annual Savings:   {format_currency(ri_1yr_full_savings)}")
    print(f"  Monthly Savings:        {format_currency(ri_1yr_full_savings_monthly)}")
    print(f"  Discount:               {RDS_RI_1YR_FULL_UPFRONT*100:.0f}%")
    print(f"  Break-even:             {breakeven_1yr_full:.1f} months")
    
    # 3-Year Calculations
    print("\n" + "-" * 100)
    print("3-YEAR RESERVED INSTANCES")
    print("-" * 100)
    
    # No Upfront
    ri_3yr_no_annual = RDS_ANNUAL_ONDEMAND * (1 - RDS_RI_3YR_NO_UPFRONT)
    ri_3yr_no_monthly = ri_3yr_no_annual / 12
    ri_3yr_no_savings_annual = RDS_ANNUAL_ONDEMAND - ri_3yr_no_annual
    ri_3yr_no_savings_monthly = ri_3yr_no_savings_annual / 12
    ri_3yr_no_savings_total = ri_3yr_no_savings_annual * 3
    
    print("\nNo Upfront Payment:")
    print(f"  Monthly Cost:           {format_currency(ri_3yr_no_monthly)}")
    print(f"  Annual Cost:            {format_currency(ri_3yr_no_annual)}")
    print(f"  Monthly Savings:        {format_currency(ri_3yr_no_savings_monthly)}")
    print(f"  Annual Savings:         {format_currency(ri_3yr_no_savings_annual)}")
    print(f"  Total 3-Year Savings:   {format_currency(ri_3yr_no_savings_total)}")
    print(f"  Discount:               {RDS_RI_3YR_NO_UPFRONT*100:.0f}%")
    print(f"  Upfront Payment:        $0")
    print(f"  Break-even:             Immediate (no upfront cost)")
    
    # Full Upfront
    ri_3yr_full = RDS_ANNUAL_ONDEMAND * 3 * (1 - RDS_RI_3YR_FULL_UPFRONT)
    ri_3yr_full_savings = (RDS_ANNUAL_ONDEMAND * 3) - ri_3yr_full
    ri_3yr_full_savings_monthly = ri_3yr_full_savings / 36
    breakeven_3yr_full = calculate_breakeven(ri_3yr_full, ondemand_monthly)
    
    print("\nFull Upfront Payment:")
    print(f"  Upfront Cost:           {format_currency(ri_3yr_full)}")
    print(f"  Monthly Cost:           $0 (already paid)")
    print(f"  Total 3-Year Savings:   {format_currency(ri_3yr_full_savings)}")
    print(f"  Monthly Savings:        {format_currency(ri_3yr_full_savings_monthly)}")
    print(f"  Discount:               {RDS_RI_3YR_FULL_UPFRONT*100:.0f}%")
    print(f"  Break-even:             {breakeven_3yr_full:.1f} months")

def print_summary():
    """Print executive summary"""
    print_section_header("EXECUTIVE SUMMARY - TOTAL SAVINGS ACROSS ALL OPTIONS")
    
    # Calculate all totals
    ec2_1yr_no = EC2_ANNUAL_ONDEMAND * EC2_SP_1YR_NO_UPFRONT
    ec2_1yr_full = EC2_ANNUAL_ONDEMAND * EC2_SP_1YR_FULL_UPFRONT
    ec2_3yr_no = EC2_ANNUAL_ONDEMAND * EC2_SP_3YR_NO_UPFRONT * 3
    ec2_3yr_full = EC2_ANNUAL_ONDEMAND * EC2_SP_3YR_FULL_UPFRONT * 3
    
    rds_1yr_no = RDS_ANNUAL_ONDEMAND * RDS_RI_1YR_NO_UPFRONT
    rds_1yr_full = RDS_ANNUAL_ONDEMAND * RDS_RI_1YR_FULL_UPFRONT
    rds_3yr_no = RDS_ANNUAL_ONDEMAND * RDS_RI_3YR_NO_UPFRONT * 3
    rds_3yr_full = RDS_ANNUAL_ONDEMAND * RDS_RI_3YR_FULL_UPFRONT * 3
    
    print("\n1-YEAR COMMITMENT:")
    print(f"  No Upfront:    EC2 {format_currency(ec2_1yr_no):>12} + RDS {format_currency(rds_1yr_no):>12} = {format_currency(ec2_1yr_no + rds_1yr_no):>12}")
    print(f"  Full Upfront:  EC2 {format_currency(ec2_1yr_full):>12} + RDS {format_currency(rds_1yr_full):>12} = {format_currency(ec2_1yr_full + rds_1yr_full):>12}")
    
    print("\n3-YEAR COMMITMENT:")
    print(f"  No Upfront:    EC2 {format_currency(ec2_3yr_no):>12} + RDS {format_currency(rds_3yr_no):>12} = {format_currency(ec2_3yr_no + rds_3yr_no):>12}")
    print(f"  Full Upfront:  EC2 {format_currency(ec2_3yr_full):>12} + RDS {format_currency(rds_3yr_full):>12} = {format_currency(ec2_3yr_full + rds_3yr_full):>12}")
    
    print("\n" + "=" * 100)
    print(f"MAXIMUM SAVINGS: {format_currency(ec2_3yr_full + rds_3yr_full)} (3-Year Full Upfront)")
    print("=" * 100)

def main():
    print("\n")
    print("*" * 100)
    print("AWS SAVINGS PLANS & RESERVED INSTANCES - DETAILED ANALYSIS")
    print("Prepared for PowerPoint Presentation")
    print("*" * 100)
    
    print_ec2_analysis()
    print("\n\n")
    print_rds_analysis()
    print("\n\n")
    print_summary()
    print("\n")

if __name__ == "__main__":
    main()
