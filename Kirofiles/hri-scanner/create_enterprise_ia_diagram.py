#!/usr/bin/env python3
"""
Create Enterprise-Grade Information Architecture Diagram for WAFOps
Based on AIMOPS design principles - workload-centric, pillar-aligned, audit-ready
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, ConnectionPatch, Rectangle
import numpy as np
from datetime import datetime

def create_enterprise_ia_diagram():
    """Create a comprehensive enterprise IA diagram"""
    
    print("Creating WAFOps Enterprise Information Architecture Diagram...")
    
    # Create figure with larger size for detailed IA
    fig, ax = plt.subplots(1, 1, figsize=(20, 16))
    ax.set_xlim(0, 20)
    ax.set_ylim(0, 16)
    ax.axis('off')
    
    # Enterprise color palette
    colors = {
        'primary_blue': '#1E3A8A',      # Executive level
        'secondary_blue': '#3B82F6',    # Management level
        'accent_blue': '#60A5FA',       # Operational level
        'success_green': '#059669',     # Positive indicators
        'warning_orange': '#D97706',    # Attention needed
        'danger_red': '#DC2626',        # Critical issues
        'neutral_gray': '#6B7280',      # Supporting elements
        'light_gray': '#F3F4F6',       # Background
        'white': '#FFFFFF',             # Content areas
        'aws_orange': '#FF9900',        # AWS branding
        'enterprise_purple': '#7C3AED'  # Premium features
    }
    
    # Title and Header
    title_box = FancyBboxPatch((0.5, 14.5), 19, 1.2, 
                               boxstyle="round,pad=0.1", 
                               facecolor=colors['primary_blue'], 
                               edgecolor='none')
    ax.add_patch(title_box)
    
    ax.text(10, 15.1, 'WAFOps Information Architecture', 
            fontsize=24, fontweight='bold', ha='center', va='center', color='white')
    ax.text(10, 14.7, 'Enterprise Well-Architected Framework Operations Platform', 
            fontsize=14, ha='center', va='center', color='white', style='italic')
    
    # Navigation Structure Header
    nav_header = FancyBboxPatch((0.5, 13.5), 19, 0.6, 
                                boxstyle="round,pad=0.05", 
                                facecolor=colors['secondary_blue'], 
                                edgecolor='none')
    ax.add_patch(nav_header)
    ax.text(10, 13.8, 'Top-Level Navigation Structure', 
            fontsize=16, fontweight='bold', ha='center', va='center', color='white')
    
    # Main Navigation Modules
    nav_modules = [
        ('Overview', 'Executive Dashboard', colors['success_green']),
        ('Workloads', 'AWS Workload Registry', colors['aws_orange']),
        ('WA Pillars', '6 Framework Pillars', colors['secondary_blue']),
        ('HRIs', 'High-Risk Issues', colors['danger_red']),
        ('Remediation', 'Action Management', colors['warning_orange']),
        ('Reports', 'Stakeholder Comms', colors['enterprise_purple']),
        ('Governance', 'Risk & Compliance', colors['primary_blue']),
        ('Integrations', 'Enterprise Systems', colors['neutral_gray']),
        ('Administration', 'Platform Management', colors['neutral_gray'])
    ]
    
    # Draw main navigation modules
    module_width = 2.0
    module_height = 0.8
    start_x = 1
    y_pos = 12.5
    
    for i, (name, desc, color) in enumerate(nav_modules):
        x_pos = start_x + (i * 2.1)
        
        module_box = FancyBboxPatch((x_pos, y_pos), module_width, module_height, 
                                    boxstyle="round,pad=0.05", 
                                    facecolor=color, 
                                    edgecolor='white', 
                                    linewidth=2)
        ax.add_patch(module_box)
        
        ax.text(x_pos + module_width/2, y_pos + 0.55, name, 
                fontsize=11, fontweight='bold', ha='center', va='center', color='white')
        ax.text(x_pos + module_width/2, y_pos + 0.25, desc, 
                fontsize=8, ha='center', va='center', color='white')
    
    # Detailed Module Breakdowns
    
    # 1. Overview Module (Executive)
    overview_box = FancyBboxPatch((0.5, 9.5), 4.5, 2.5, 
                                  boxstyle="round,pad=0.1", 
                                  facecolor=colors['light_gray'], 
                                  edgecolor=colors['success_green'], 
                                  linewidth=2)
    ax.add_patch(overview_box)
    
    ax.text(2.75, 11.7, '1. Overview (Executive)', 
            fontsize=14, fontweight='bold', ha='center', va='center', color=colors['primary_blue'])
    
    overview_items = [
        '• Overall WA Score (0-100)',
        '• HRI Count by Severity',
        '• Pillar Health Summary',
        '• Top 5 Action Items',
        '• Trend Indicators',
        '• Executive KPIs'
    ]
    
    for i, item in enumerate(overview_items):
        ax.text(0.8, 11.3 - (i * 0.25), item, fontsize=9, va='center', color=colors['neutral_gray'])
    
    # 2. Workloads Module
    workloads_box = FancyBboxPatch((5.5, 9.5), 4.5, 2.5, 
                                   boxstyle="round,pad=0.1", 
                                   facecolor=colors['light_gray'], 
                                   edgecolor=colors['aws_orange'], 
                                   linewidth=2)
    ax.add_patch(workloads_box)
    
    ax.text(7.75, 11.7, '2. Workloads (Registry)', 
            fontsize=14, fontweight='bold', ha='center', va='center', color=colors['primary_blue'])
    
    workload_items = [
        '• Workload List & Metadata',
        '• Environment Classification',
        '• Account Mapping',
        '• WA Score per Workload',
        '• HRI Distribution',
        '• Scan History & Status'
    ]
    
    for i, item in enumerate(workload_items):
        ax.text(5.8, 11.3 - (i * 0.25), item, fontsize=9, va='center', color=colors['neutral_gray'])
    
    # 3. Well-Architected Pillars
    pillars_box = FancyBboxPatch((10.5, 9.5), 4.5, 2.5, 
                                 boxstyle="round,pad=0.1", 
                                 facecolor=colors['light_gray'], 
                                 edgecolor=colors['secondary_blue'], 
                                 linewidth=2)
    ax.add_patch(pillars_box)
    
    ax.text(12.75, 11.7, '3. WA Pillars (Framework)', 
            fontsize=14, fontweight='bold', ha='center', va='center', color=colors['primary_blue'])
    
    pillar_items = [
        '• Operational Excellence',
        '• Security',
        '• Reliability', 
        '• Performance Efficiency',
        '• Cost Optimization',
        '• Sustainability'
    ]
    
    for i, item in enumerate(pillar_items):
        ax.text(10.8, 11.3 - (i * 0.25), item, fontsize=9, va='center', color=colors['neutral_gray'])
    
    # 4. HRIs Module
    hri_box = FancyBboxPatch((15.5, 9.5), 4, 2.5, 
                             boxstyle="round,pad=0.1", 
                             facecolor=colors['light_gray'], 
                             edgecolor=colors['danger_red'], 
                             linewidth=2)
    ax.add_patch(hri_box)
    
    ax.text(17.5, 11.7, '4. HRIs (Action Hub)', 
            fontsize=14, fontweight='bold', ha='center', va='center', color=colors['primary_blue'])
    
    hri_items = [
        '• HRI Dashboard',
        '• Severity Classification',
        '• Status Tracking',
        '• Ownership Assignment',
        '• Evidence & Impact',
        '• Audit Trail'
    ]
    
    for i, item in enumerate(hri_items):
        ax.text(15.8, 11.3 - (i * 0.25), item, fontsize=9, va='center', color=colors['neutral_gray'])
    
    # Data Flow Architecture
    dataflow_header = FancyBboxPatch((0.5, 8.5), 19, 0.5, 
                                     boxstyle="round,pad=0.05", 
                                     facecolor=colors['neutral_gray'], 
                                     edgecolor='none')
    ax.add_patch(dataflow_header)
    ax.text(10, 8.75, 'Data Flow & Processing Architecture', 
            fontsize=16, fontweight='bold', ha='center', va='center', color='white')
    
    # Data Sources Layer
    sources_y = 7.5
    source_boxes = [
        ('AWS Organizations', 1, colors['aws_orange']),
        ('Well-Architected Tool', 4.5, colors['secondary_blue']),
        ('AWS Config', 8, colors['success_green']),
        ('Security Hub', 11.5, colors['danger_red']),
        ('Cost Explorer', 15, colors['warning_orange']),
        ('CloudWatch', 18, colors['enterprise_purple'])
    ]
    
    for name, x_pos, color in source_boxes:
        source_box = FancyBboxPatch((x_pos, sources_y), 2.5, 0.6, 
                                    boxstyle="round,pad=0.05", 
                                    facecolor=color, 
                                    edgecolor='white', 
                                    linewidth=1)
        ax.add_patch(source_box)
        ax.text(x_pos + 1.25, sources_y + 0.3, name, 
                fontsize=9, fontweight='bold', ha='center', va='center', color='white')
    
    # Processing Layer
    processing_y = 6.2
    processing_box = FancyBboxPatch((2, processing_y), 16, 0.8, 
                                    boxstyle="round,pad=0.1", 
                                    facecolor=colors['primary_blue'], 
                                    edgecolor='white', 
                                    linewidth=2)
    ax.add_patch(processing_box)
    
    ax.text(10, processing_y + 0.4, 'WAFOps Processing Engine', 
            fontsize=14, fontweight='bold', ha='center', va='center', color='white')
    
    processing_components = [
        'Data Ingestion', 'Risk Analysis', 'HRI Generation', 'Scoring Engine', 'Trend Analysis'
    ]
    
    for i, component in enumerate(processing_components):
        x_pos = 3 + (i * 2.8)
        ax.text(x_pos, processing_y + 0.1, component, 
                fontsize=8, ha='center', va='center', color='white')
    
    # Storage & Output Layer
    storage_y = 4.8
    storage_boxes = [
        ('DynamoDB\nFindings', 2, colors['aws_orange']),
        ('S3\nReports', 5.5, colors['success_green']),
        ('CloudWatch\nMetrics', 9, colors['enterprise_purple']),
        ('Partner Central\nExports', 12.5, colors['secondary_blue']),
        ('Audit Logs\nCompliance', 16, colors['neutral_gray'])
    ]
    
    for name, x_pos, color in storage_boxes:
        storage_box = FancyBboxPatch((x_pos, storage_y), 2.5, 0.8, 
                                     boxstyle="round,pad=0.05", 
                                     facecolor=color, 
                                     edgecolor='white', 
                                     linewidth=1)
        ax.add_patch(storage_box)
        ax.text(x_pos + 1.25, storage_y + 0.4, name, 
                fontsize=9, fontweight='bold', ha='center', va='center', color='white')
    
    # Enterprise Integration Layer
    integration_header = FancyBboxPatch((0.5, 3.8), 19, 0.4, 
                                        boxstyle="round,pad=0.05", 
                                        facecolor=colors['enterprise_purple'], 
                                        edgecolor='none')
    ax.add_patch(integration_header)
    ax.text(10, 4, 'Enterprise Integration Layer', 
            fontsize=14, fontweight='bold', ha='center', va='center', color='white')
    
    # Integration boxes
    integration_y = 3
    integrations = [
        ('Jira/ServiceNow', 1.5, 'Ticket Management'),
        ('Slack/Teams', 5, 'Notifications'),
        ('SIEM/SOAR', 8.5, 'Security Ops'),
        ('BI/Analytics', 12, 'Business Intelligence'),
        ('CI/CD Pipeline', 15.5, 'DevOps Integration')
    ]
    
    for name, x_pos, desc in integrations:
        int_box = FancyBboxPatch((x_pos, integration_y), 3, 0.6, 
                                 boxstyle="round,pad=0.05", 
                                 facecolor='white', 
                                 edgecolor=colors['enterprise_purple'], 
                                 linewidth=2)
        ax.add_patch(int_box)
        ax.text(x_pos + 1.5, integration_y + 0.4, name, 
                fontsize=10, fontweight='bold', ha='center', va='center', color=colors['primary_blue'])
        ax.text(x_pos + 1.5, integration_y + 0.15, desc, 
                fontsize=8, ha='center', va='center', color=colors['neutral_gray'])
    
    # Governance & Security Model
    governance_box = FancyBboxPatch((0.5, 1.5), 9, 1.2, 
                                    boxstyle="round,pad=0.1", 
                                    facecolor=colors['light_gray'], 
                                    edgecolor=colors['primary_blue'], 
                                    linewidth=2)
    ax.add_patch(governance_box)
    
    ax.text(5, 2.5, 'Governance & Security Model', 
            fontsize=14, fontweight='bold', ha='center', va='center', color=colors['primary_blue'])
    
    governance_items = [
        '• Multi-tenant isolation',
        '• Role-based access control (RBAC)',
        '• External ID + STS AssumeRole',
        '• Read-only AWS permissions',
        '• Complete audit logging',
        '• Risk acceptance workflows'
    ]
    
    for i, item in enumerate(governance_items):
        ax.text(0.8, 2.2 - (i * 0.15), item, fontsize=9, va='center', color=colors['neutral_gray'])
    
    # Key Metrics & KPIs
    metrics_box = FancyBboxPatch((10.5, 1.5), 9, 1.2, 
                                 boxstyle="round,pad=0.1", 
                                 facecolor=colors['light_gray'], 
                                 edgecolor=colors['success_green'], 
                                 linewidth=2)
    ax.add_patch(metrics_box)
    
    ax.text(15, 2.5, 'Key Performance Indicators', 
            fontsize=14, fontweight='bold', ha='center', va='center', color=colors['primary_blue'])
    
    kpi_items = [
        '• Overall Well-Architected Score',
        '• HRI Resolution Rate',
        '• Mean Time to Remediation (MTTR)',
        '• Cost Optimization Savings',
        '• Security Posture Improvement',
        '• Compliance Coverage %'
    ]
    
    for i, item in enumerate(kpi_items):
        ax.text(10.8, 2.2 - (i * 0.15), item, fontsize=9, va='center', color=colors['neutral_gray'])
    
    # Data Flow Arrows
    # Sources to Processing
    for _, x_pos, _ in source_boxes:
        arrow = ConnectionPatch((x_pos + 1.25, sources_y), (10, processing_y + 0.8), 
                               "data", "data", arrowstyle="->", 
                               shrinkA=5, shrinkB=5, mutation_scale=15, 
                               fc=colors['neutral_gray'], ec=colors['neutral_gray'], alpha=0.6)
        ax.add_patch(arrow)
    
    # Processing to Storage
    for _, x_pos, _ in storage_boxes:
        arrow = ConnectionPatch((10, processing_y), (x_pos + 1.25, storage_y + 0.8), 
                               "data", "data", arrowstyle="->", 
                               shrinkA=5, shrinkB=5, mutation_scale=15, 
                               fc=colors['neutral_gray'], ec=colors['neutral_gray'], alpha=0.6)
        ax.add_patch(arrow)
    
    # Footer with Design Principles
    footer_box = FancyBboxPatch((0.5, 0.2), 19, 0.8, 
                                boxstyle="round,pad=0.05", 
                                facecolor=colors['primary_blue'], 
                                edgecolor='none')
    ax.add_patch(footer_box)
    
    ax.text(10, 0.8, 'Design Principles', 
            fontsize=12, fontweight='bold', ha='center', va='center', color='white')
    
    principles = [
        'Workload-Centric', 'Pillar-Aligned', 'Signal vs Insight Separation', 
        'Progressive Disclosure', 'Audit-Ready by Default'
    ]
    
    for i, principle in enumerate(principles):
        x_pos = 2 + (i * 3.2)
        ax.text(x_pos, 0.4, principle, 
                fontsize=9, ha='center', va='center', color='white')
    
    # Add timestamp and version
    ax.text(19.5, 0.1, f'Generated: {datetime.now().strftime("%Y-%m-%d %H:%M")} | Version: 2.0 Enterprise', 
            fontsize=8, ha='right', va='bottom', color=colors['neutral_gray'])
    
    plt.tight_layout()
    
    # Save the diagram
    filename = f'WAFOps_Enterprise_IA_{datetime.now().strftime("%Y%m%d_%H%M%S")}.png'
    plt.savefig(filename, dpi=300, bbox_inches='tight', facecolor='white', edgecolor='none')
    
    print(f'✓ Enterprise IA diagram created: {filename}')
    print(f'✓ Location: {os.path.abspath(filename)}')
    print(f'✓ Resolution: 300 DPI (presentation quality)')
    
    plt.show()
    
    return filename

if __name__ == '__main__':
    import os
    import sys
    
    try:
        filename = create_enterprise_ia_diagram()
        print('\n' + '=' * 80)
        print('SUCCESS! Enterprise Information Architecture diagram created.')
        print('=' * 80)
        print(f'\nFile: {filename}')
        print(f'Path: {os.path.abspath(filename)}')
        print('\nThis diagram shows:')
        print('• Complete navigation structure')
        print('• Data flow architecture')
        print('• Enterprise integration points')
        print('• Governance & security model')
        print('• Key performance indicators')
        print('\nSuitable for executives, architects, and engineering teams.')
        sys.exit(0)
    except Exception as e:
        print(f'\nError creating enterprise IA diagram: {e}')
        import traceback
        traceback.print_exc()
        sys.exit(1)