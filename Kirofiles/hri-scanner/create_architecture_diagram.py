#!/usr/bin/env python3
"""
Create architecture diagram for HRI Fast Scanner
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, ConnectionPatch
import numpy as np

def create_architecture_diagram():
    """Create a comprehensive architecture diagram"""
    
    print("Creating WAFOps Architecture Diagram...")
    
    # Create figure and axis
    fig, ax = plt.subplots(1, 1, figsize=(16, 12))
    ax.set_xlim(0, 16)
    ax.set_ylim(0, 12)
    ax.axis('off')
    
    # Colors
    colors = {
        'aws_orange': '#FF9900',
        'aws_blue': '#232F3E',
        'lambda_orange': '#FF9900',
        'dynamodb_blue': '#3F48CC',
        's3_green': '#569A31',
        'iam_red': '#DD344C',
        'eventbridge_purple': '#7B68EE',
        'cloudwatch_blue': '#2E8B57',
        'organizations_gray': '#6C757D',
        'light_blue': '#E3F2FD',
        'light_orange': '#FFF3E0',
        'light_green': '#E8F5E8'
    }
    
    # Title
    ax.text(8, 11.5, 'WAFOps - AWS Well-Architected Framework', 
            fontsize=20, fontweight='bold', ha='center', va='center')
    ax.text(8, 11, 'Multi-Account Security Assessment Architecture', 
            fontsize=14, ha='center', va='center', style='italic')
    
    # Management Account Box
    mgmt_box = FancyBboxPatch((0.5, 6), 15, 4.5, 
                              boxstyle="round,pad=0.1", 
                              facecolor=colors['light_blue'], 
                              edgecolor=colors['aws_blue'], 
                              linewidth=2)
    ax.add_patch(mgmt_box)
    ax.text(8, 10.2, 'Management Account (750299845580)', 
            fontsize=16, fontweight='bold', ha='center', va='center')
    
    # EventBridge
    eventbridge = FancyBboxPatch((1, 9), 2, 0.8, 
                                 boxstyle="round,pad=0.05", 
                                 facecolor=colors['eventbridge_purple'], 
                                 edgecolor='black', linewidth=1)
    ax.add_patch(eventbridge)
    ax.text(2, 9.4, 'EventBridge\nSchedule', fontsize=10, fontweight='bold', 
            ha='center', va='center', color='white')
    
    # Lambda 1 - discover_accounts
    lambda1 = FancyBboxPatch((4, 9), 2.5, 0.8, 
                             boxstyle="round,pad=0.05", 
                             facecolor=colors['lambda_orange'], 
                             edgecolor='black', linewidth=1)
    ax.add_patch(lambda1)
    ax.text(5.25, 9.4, 'Lambda 1\ndiscover_accounts', fontsize=10, fontweight='bold', 
            ha='center', va='center', color='white')
    
    # Lambda 2 - scan_account
    lambda2 = FancyBboxPatch((7.5, 9), 2.5, 0.8, 
                             boxstyle="round,pad=0.05", 
                             facecolor=colors['lambda_orange'], 
                             edgecolor='black', linewidth=1)
    ax.add_patch(lambda2)
    ax.text(8.75, 9.4, 'Lambda 2\nscan_account', fontsize=10, fontweight='bold', 
            ha='center', va='center', color='white')
    
    # Lambda 3 - partner_sync
    lambda3 = FancyBboxPatch((11, 9), 2.5, 0.8, 
                             boxstyle="round,pad=0.05", 
                             facecolor=colors['lambda_orange'], 
                             edgecolor='black', linewidth=1, linestyle='--')
    ax.add_patch(lambda3)
    ax.text(12.25, 9.4, 'Lambda 3\npartner_sync', fontsize=10, fontweight='bold', 
            ha='center', va='center', color='white')
    ax.text(12.25, 8.7, '(Future)', fontsize=8, ha='center', va='center', style='italic')
    
    # DynamoDB
    dynamodb = FancyBboxPatch((2, 7.5), 3, 0.8, 
                              boxstyle="round,pad=0.05", 
                              facecolor=colors['dynamodb_blue'], 
                              edgecolor='black', linewidth=1)
    ax.add_patch(dynamodb)
    ax.text(3.5, 7.9, 'DynamoDB\nhri_findings', fontsize=10, fontweight='bold', 
            ha='center', va='center', color='white')
    
    # S3 Bucket
    s3 = FancyBboxPatch((6, 7.5), 3, 0.8, 
                        boxstyle="round,pad=0.05", 
                        facecolor=colors['s3_green'], 
                        edgecolor='black', linewidth=1)
    ax.add_patch(s3)
    ax.text(7.5, 7.9, 'S3 Bucket\nhri_exports', fontsize=10, fontweight='bold', 
            ha='center', va='center', color='white')
    
    # Partner Central Export
    partner_s3 = FancyBboxPatch((10, 7.5), 3, 0.8, 
                                boxstyle="round,pad=0.05", 
                                facecolor=colors['s3_green'], 
                                edgecolor='black', linewidth=1, linestyle='--')
    ax.add_patch(partner_s3)
    ax.text(11.5, 7.9, 'S3 Export\nPartner Central', fontsize=10, fontweight='bold', 
            ha='center', va='center', color='white')
    
    # IAM Roles
    iam_mgmt = FancyBboxPatch((1, 6.5), 2.5, 0.6, 
                              boxstyle="round,pad=0.05", 
                              facecolor=colors['iam_red'], 
                              edgecolor='black', linewidth=1)
    ax.add_patch(iam_mgmt)
    ax.text(2.25, 6.8, 'IAM Role\nHRIScannerExecution', fontsize=9, fontweight='bold', 
            ha='center', va='center', color='white')
    
    # CloudWatch
    cloudwatch = FancyBboxPatch((13, 6.5), 2, 0.6, 
                                boxstyle="round,pad=0.05", 
                                facecolor=colors['cloudwatch_blue'], 
                                edgecolor='black', linewidth=1)
    ax.add_patch(cloudwatch)
    ax.text(14, 6.8, 'CloudWatch\nLogs & Metrics', fontsize=9, fontweight='bold', 
            ha='center', va='center', color='white')
    
    # Member Accounts Section
    member_box1 = FancyBboxPatch((0.5, 3), 4.5, 2.5, 
                                 boxstyle="round,pad=0.1", 
                                 facecolor=colors['light_orange'], 
                                 edgecolor=colors['aws_orange'], 
                                 linewidth=2)
    ax.add_patch(member_box1)
    ax.text(2.75, 5.2, 'Member Account 1\n610382284946 (Audit)', 
            fontsize=12, fontweight='bold', ha='center', va='center')
    
    member_box2 = FancyBboxPatch((5.5, 3), 4.5, 2.5, 
                                 boxstyle="round,pad=0.1", 
                                 facecolor=colors['light_green'], 
                                 edgecolor=colors['s3_green'], 
                                 linewidth=2)
    ax.add_patch(member_box2)
    ax.text(7.75, 5.2, 'Member Account 2\n750299845580 (AAIDemo)', 
            fontsize=12, fontweight='bold', ha='center', va='center')
    
    member_box3 = FancyBboxPatch((11, 3), 4.5, 2.5, 
                                 boxstyle="round,pad=0.1", 
                                 facecolor=colors['light_orange'], 
                                 edgecolor=colors['aws_orange'], 
                                 linewidth=2)
    ax.add_patch(member_box3)
    ax.text(13.25, 5.2, 'Member Account 3\n488705985969 (Log Archive)', 
            fontsize=12, fontweight='bold', ha='center', va='center')
    
    # HRI-ScannerRole in member accounts
    for i, x_pos in enumerate([2.75, 7.75, 13.25]):
        scanner_role = FancyBboxPatch((x_pos-1, 4.5), 2, 0.4, 
                                      boxstyle="round,pad=0.05", 
                                      facecolor=colors['iam_red'], 
                                      edgecolor='black', linewidth=1,
                                      linestyle='--' if i != 1 else '-')
        ax.add_patch(scanner_role)
        status = 'Deployed' if i == 1 else 'Missing'
        ax.text(x_pos, 4.7, f'HRI-ScannerRole\n({status})', fontsize=8, fontweight='bold', 
                ha='center', va='center', color='white')
    
    # AWS Services in member accounts
    services = ['S3', 'EC2', 'RDS', 'IAM', 'Security\nHub', 'Config', 'CloudWatch', 
                'GuardDuty', 'CloudTrail', 'Cost\nExplorer']
    
    for account_x in [2.75, 7.75, 13.25]:
        for i, service in enumerate(services[:5]):
            x = account_x - 1.8 + (i * 0.9)
            service_box = FancyBboxPatch((x, 3.8), 0.8, 0.4, 
                                         boxstyle="round,pad=0.02", 
                                         facecolor='lightblue', 
                                         edgecolor='navy', linewidth=0.5)
            ax.add_patch(service_box)
            ax.text(x + 0.4, 4, service, fontsize=6, ha='center', va='center')
        
        for i, service in enumerate(services[5:]):
            x = account_x - 1.8 + (i * 0.9)
            service_box = FancyBboxPatch((x, 3.3), 0.8, 0.4, 
                                         boxstyle="round,pad=0.02", 
                                         facecolor='lightgreen', 
                                         edgecolor='darkgreen', linewidth=0.5)
            ax.add_patch(service_box)
            ax.text(x + 0.4, 3.5, service, fontsize=6, ha='center', va='center')
    
    # Data Flow Arrows
    # EventBridge to Lambda 1
    arrow1 = ConnectionPatch((3, 9.4), (4, 9.4), "data", "data",
                            arrowstyle="->", shrinkA=5, shrinkB=5, 
                            mutation_scale=20, fc=colors['aws_blue'], ec=colors['aws_blue'])
    ax.add_patch(arrow1)
    
    # Lambda 1 to Lambda 2
    arrow2 = ConnectionPatch((6.5, 9.4), (7.5, 9.4), "data", "data",
                            arrowstyle="->", shrinkA=5, shrinkB=5, 
                            mutation_scale=20, fc=colors['aws_blue'], ec=colors['aws_blue'])
    ax.add_patch(arrow2)
    
    # Lambda 2 to DynamoDB
    arrow3 = ConnectionPatch((8.75, 9), (3.5, 8.3), "data", "data",
                            arrowstyle="->", shrinkA=5, shrinkB=5, 
                            mutation_scale=20, fc=colors['aws_blue'], ec=colors['aws_blue'])
    ax.add_patch(arrow3)
    
    # Lambda 2 to S3
    arrow4 = ConnectionPatch((8.75, 9), (7.5, 8.3), "data", "data",
                            arrowstyle="->", shrinkA=5, shrinkB=5, 
                            mutation_scale=20, fc=colors['aws_blue'], ec=colors['aws_blue'])
    ax.add_patch(arrow4)
    
    # Lambda 2 to Member Accounts (AssumeRole)
    for member_x in [2.75, 7.75, 13.25]:
        arrow = ConnectionPatch((8.75, 9), (member_x, 5.5), "data", "data",
                               arrowstyle="->", shrinkA=5, shrinkB=5, 
                               mutation_scale=15, fc='red', ec='red',
                               linestyle='--' if member_x != 7.75 else '-')
        ax.add_patch(arrow)
    
    # Lambda 3 to Partner S3 (future)
    arrow5 = ConnectionPatch((12.25, 9), (11.5, 8.3), "data", "data",
                            arrowstyle="->", shrinkA=5, shrinkB=5, 
                            mutation_scale=20, fc='gray', ec='gray', linestyle='--')
    ax.add_patch(arrow5)
    
    # Legend
    legend_y = 2.5
    ax.text(1, legend_y, 'Legend:', fontsize=12, fontweight='bold')
    
    # Legend items
    legend_items = [
        ('Deployed', 'solid', 'black'),
        ('Planned/Missing', 'dashed', 'gray'),
        ('Data Flow', 'solid', colors['aws_blue']),
        ('AssumeRole (Working)', 'solid', 'red'),
        ('AssumeRole (Failed)', 'dashed', 'red')
    ]
    
    for i, (label, style, color) in enumerate(legend_items):
        y_pos = legend_y - 0.3 - (i * 0.3)
        ax.plot([1, 1.5], [y_pos, y_pos], linestyle=style, color=color, linewidth=2)
        ax.text(1.7, y_pos, label, fontsize=10, va='center')
    
    # Key Features Box
    features_box = FancyBboxPatch((10, 0.5), 5.5, 2, 
                                  boxstyle="round,pad=0.1", 
                                  facecolor='lightyellow', 
                                  edgecolor='orange', 
                                  linewidth=1)
    ax.add_patch(features_box)
    ax.text(12.75, 2.2, 'Key Features', fontsize=12, fontweight='bold', ha='center')
    
    features = [
        '• 30 HRI checks across 6 pillars',
        '• Multi-account scanning',
        '• Cost < $5/month',
        '• Serverless architecture',
        '• Real-time findings storage',
        '• Automated reporting'
    ]
    
    for i, feature in enumerate(features):
        ax.text(10.2, 1.9 - (i * 0.2), feature, fontsize=9, va='center')
    
    # Statistics Box
    stats_box = FancyBboxPatch((4, 0.5), 5.5, 2, 
                               boxstyle="round,pad=0.1", 
                               facecolor='lightcyan', 
                               edgecolor='blue', 
                               linewidth=1)
    ax.add_patch(stats_box)
    ax.text(6.75, 2.2, 'Current Status', fontsize=12, fontweight='bold', ha='center')
    
    stats = [
        '• 3 accounts discovered',
        '• 8 findings identified',
        '• 5 security issues (HIGH)',
        '• 1 account scannable',
        '• 2 accounts need role deployment',
        '• System operational ✓'
    ]
    
    for i, stat in enumerate(stats):
        color = 'red' if 'HIGH' in stat or 'need' in stat else 'green' if '✓' in stat else 'black'
        ax.text(4.2, 1.9 - (i * 0.2), stat, fontsize=9, va='center', color=color)
    
    # Add flow labels
    ax.text(3.5, 9.7, '1. Schedule', fontsize=8, ha='center', color=colors['aws_blue'])
    ax.text(7, 9.7, '2. Discover', fontsize=8, ha='center', color=colors['aws_blue'])
    ax.text(9.5, 8.5, '3. Scan', fontsize=8, ha='center', color=colors['aws_blue'])
    ax.text(5.5, 8.5, '4. Store', fontsize=8, ha='center', color=colors['aws_blue'])
    
    # Add AssumeRole labels
    ax.text(5.5, 6.5, 'AssumeRole\n(STS)', fontsize=8, ha='center', color='red', 
            bbox=dict(boxstyle="round,pad=0.3", facecolor='white', edgecolor='red'))
    
    plt.tight_layout()
    
    # Save the diagram
    from datetime import datetime
    filename = f'WAFOps_Architecture_{datetime.now().strftime("%Y%m%d_%H%M%S")}.png'
    plt.savefig(filename, dpi=300, bbox_inches='tight', facecolor='white', edgecolor='none')
    
    print(f'✓ Architecture diagram created: {filename}')
    print(f'✓ Location: {os.path.abspath(filename)}')
    print(f'✓ Resolution: 300 DPI (high quality)')
    
    plt.show()
    
    return filename

if __name__ == '__main__':
    import os
    import sys
    
    try:
        filename = create_architecture_diagram()
        print('\n' + '=' * 70)
        print('SUCCESS! Architecture diagram created and ready for download.')
        print('=' * 70)
        print(f'\nFile: {filename}')
        print(f'Path: {os.path.abspath(filename)}')
        print('\nThe diagram shows the complete WAFOps architecture')
        print('including all AWS services, data flows, and current status.')
        sys.exit(0)
    except Exception as e:
        print(f'\nError creating architecture diagram: {e}')
        import traceback
        traceback.print_exc()
        sys.exit(1)