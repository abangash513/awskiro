# Cloud Intelligence Dashboards - WAC Production Implementation Plan

## Quick Start Guide

### Week 1: Foundation Setup

#### Day 1-2: Prerequisites and Planning
- [ ] Review solution design document with stakeholders
- [ ] Identify executive sponsor
- [ ] Form implementation team (FinOps lead, AWS admin, QuickSight admin)
- [ ] Verify AWS account access and permissions
- [ ] Document current cost visibility gaps

#### Day 3: Enable Cost and Usage Report
```bash
# Navigate to AWS Billing Console > Cost & Usage Reports
# Create new report with these settings:
Report name: wac-prod-cur
Time granularity: Hourly
Include: Resource IDs
Data integration: Amazon Athena
Compression: Parquet
S3 bucket: wac-prod-cur-data
Report path prefix: cur/
Versioning: Overwrite existing report
```

#### Day 4: QuickSight Setup
- [ ] Subscribe to Amazon QuickSight Enterprise Edition
- [ ] Configure QuickSight IAM role with S3 and Athena access
- [ ] Create user groups: Executives, Finance, FinOps, Engineering
- [ ] Add initial users to appropriate groups

#### Day 5: Deploy First Dashboard
```bash
# Install cid-cmd tool
pip3 install cid-cmd

# Deploy Cost Intelligence Dashboard
cid-cmd deploy --dashboard-id cost-intelligence-dashboard

# Follow prompts to configure:
# - Select CUR S3 bucket
# - Choose QuickSight user
# - Configure refresh schedule
```

### Week 2: Core Dashboards

#### Deploy CUDOS Dashboard
```bash
cid-cmd deploy --dashboard-id cudos
```

#### Deploy KPI Dashboard
```bash
cid-cmd deploy --dashboard-id kpi
```

#### Configure Data Refresh
- [ ] Set daily refresh at 6 AM for all dashboards
- [ ] Verify Athena queries are running successfully
- [ ] Check SPICE dataset refresh status

### Week 3: Operational Dashboards

#### Enable Additional Data Sources
```bash
# Enable Trusted Advisor Organizational View
aws support describe-trusted-advisor-checks --language en

# Enable Compute Optimizer
aws compute-optimizer update-enrollment-status --status Active

# Enable Cost Anomaly Detection
aws ce create-anomaly-monitor --anomaly-monitor file://monitor-config.json
```

#### Deploy Operational Dashboards
```bash
# Trusted Advisor Organizational Dashboard
cid-cmd deploy --dashboard-id tao

# Compute Optimizer Dashboard
cid-cmd deploy --dashboard-id compute-optimizer

# Cost Anomaly Dashboard
cid-cmd deploy --dashboard-id cost-anomaly
```

### Week 4: Access Control and Training

#### Implement Row-Level Security
1. Define organizational structure in CSV:
```csv
UserName,CostCenter,Environment,BusinessUnit
finance-user@wac.com,*,*,*
eng-team-lead@wac.com,CC-1001,prod,Engineering
dev-team@wac.com,CC-1002,dev,Engineering
```

2. Upload RLS dataset to QuickSight
3. Apply RLS rules to dashboards
4. Test access with different user accounts

#### Conduct Training Sessions
- [ ] Executive overview (1 hour) - Focus on CID
- [ ] Finance deep dive (2 hours) - CID, CUDOS, Budgets
- [ ] FinOps workshop (4 hours) - All dashboards, customization
- [ ] Engineering hands-on (3 hours) - CUDOS, TAO, Compute Optimizer

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         STAKEHOLDERS                             │
│  Executives  │  Finance  │  FinOps  │  Engineering  │  DevOps   │
└────────┬─────────────┬──────────┬──────────┬──────────┬─────────┘
         │             │          │          │          │
         └─────────────┴──────────┴──────────┴──────────┘
                              │
                    ┌─────────▼─────────┐
                    │  Amazon QuickSight │
                    │  Enterprise Edition │
                    │  + Row Level Security│
                    └─────────┬─────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
    ┌────▼────┐         ┌────▼────┐         ┌────▼────┐
    │   CID   │         │  CUDOS  │         │   KPI   │
    │Dashboard│         │Dashboard│         │Dashboard│
    └─────────┘         └─────────┘         └─────────┘
         │                    │                    │
    ┌────▼────┐         ┌────▼────┐         ┌────▼────┐
    │   TAO   │         │Compute  │         │ Anomaly │
    │Dashboard│         │Optimizer│         │Dashboard│
    └─────────┘         └─────────┘         └─────────┘
                              │
                    ┌─────────▼─────────┐
                    │  Amazon Athena    │
                    │  Query Engine     │
                    └─────────┬─────────┘
                              │
                    ┌─────────▼─────────┐
                    │   AWS Glue        │
                    │   Data Catalog    │
                    └─────────┬─────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
    ┌────▼────┐         ┌────▼────┐         ┌────▼────┐
    │S3 Bucket│         │S3 Bucket│         │S3 Bucket│
    │CUR Data │         │TA Data  │         │ Athena  │
    └────▲────┘         └────▲────┘         │ Results │
         │                   │               └─────────┘
         │                   │
    ┌────┴────┐         ┌────┴────┐
    │   CUR   │         │ Lambda  │
    │ Service │         │Data Coll│
    └─────────┘         └────▲────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
    ┌────┴────┐         ┌────┴────┐        ┌────┴────┐
    │Trusted  │         │Compute  │        │  Cost   │
    │Advisor  │         │Optimizer│        │ Anomaly │
    └─────────┘         └─────────┘        └─────────┘
```

## Dashboard Deployment Checklist

### Foundational Dashboards (Priority 1)
- [ ] Cost Intelligence Dashboard (CID)
  - Target: Executives, Finance
  - Data: CUR only
  - Deploy time: 15 minutes
  
- [ ] CUDOS Dashboard
  - Target: FinOps, Engineering
  - Data: CUR only
  - Deploy time: 20 minutes
  
- [ ] KPI Dashboard
  - Target: All teams
  - Data: CUR only
  - Deploy time: 15 minutes

### Operational Dashboards (Priority 2)
- [ ] Trusted Advisor Organizational (TAO)
  - Target: DevOps, Security, FinOps
  - Data: Trusted Advisor API
  - Deploy time: 30 minutes
  
- [ ] Compute Optimizer Dashboard
  - Target: Engineering, FinOps
  - Data: Compute Optimizer API
  - Deploy time: 25 minutes
  
- [ ] Cost Anomaly Dashboard
  - Target: FinOps, Finance
  - Data: Cost Anomaly Detection
  - Deploy time: 20 minutes

### Advanced Dashboards (Priority 3)
- [ ] Graviton Savings Dashboard
- [ ] Health Events Dashboard
- [ ] AWS Budgets Dashboard
- [ ] Extended Support Cost Projection
- [ ] Data Collection Monitor

## Configuration Templates

### CUR Configuration (JSON)
```json
{
  "ReportName": "wac-prod-cur",
  "TimeUnit": "HOURLY",
  "Format": "Parquet",
  "Compression": "Parquet",
  "AdditionalSchemaElements": [
    "RESOURCES"
  ],
  "S3Bucket": "wac-prod-cur-data",
  "S3Prefix": "cur/",
  "S3Region": "us-east-1",
  "AdditionalArtifacts": [
    "ATHENA"
  ],
  "RefreshClosedReports": true,
  "ReportVersioning": "OVERWRITE_REPORT"
}
```

### QuickSight Permissions (IAM Policy)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::wac-prod-cur-data/*",
        "arn:aws:s3:::wac-prod-cur-data"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "athena:BatchGetQueryExecution",
        "athena:GetQueryExecution",
        "athena:GetQueryResults",
        "athena:GetWorkGroup",
        "athena:StartQueryExecution"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "glue:GetDatabase",
        "glue:GetTable",
        "glue:GetPartitions"
      ],
      "Resource": "*"
    }
  ]
}
```

### Lambda Data Collection (Python)
```python
import boto3
import json
from datetime import datetime

def lambda_handler(event, context):
    """
    Collect data from AWS services for CID dashboards
    """
    
    # Initialize clients
    ta_client = boto3.client('support', region_name='us-east-1')
    co_client = boto3.client('compute-optimizer')
    ce_client = boto3.client('ce')
    s3_client = boto3.client('s3')
    
    bucket_name = 'wac-prod-cur-data'
    timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
    
    # Collect Trusted Advisor checks
    try:
        ta_checks = ta_client.describe_trusted_advisor_checks(language='en')
        s3_client.put_object(
            Bucket=bucket_name,
            Key=f'trusted-advisor/{timestamp}/checks.json',
            Body=json.dumps(ta_checks)
        )
    except Exception as e:
        print(f"Error collecting TA data: {e}")
    
    # Collect Compute Optimizer recommendations
    try:
        co_recs = co_client.get_ec2_instance_recommendations()
        s3_client.put_object(
            Bucket=bucket_name,
            Key=f'compute-optimizer/{timestamp}/ec2-recommendations.json',
            Body=json.dumps(co_recs)
        )
    except Exception as e:
        print(f"Error collecting CO data: {e}")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Data collection completed')
    }
```

### EventBridge Schedule Rule
```json
{
  "Name": "cid-data-collection-daily",
  "Description": "Trigger daily data collection for CID dashboards",
  "ScheduleExpression": "cron(0 6 * * ? *)",
  "State": "ENABLED",
  "Targets": [
    {
      "Arn": "arn:aws:lambda:us-east-1:ACCOUNT_ID:function:cid-data-collection",
      "Id": "1"
    }
  ]
}
```

## Cost Breakdown

### Monthly Recurring Costs

| Service | Component | Estimated Cost |
|---------|-----------|----------------|
| QuickSight | 1 Author | $18/month |
| QuickSight | 10 Authors | $180/month |
| QuickSight | 50 Readers | $250/month |
| QuickSight | SPICE (10 GB) | $2.50/month |
| Athena | Queries (100 GB/day) | $15/month |
| Glue | Crawler (daily) | $1.32/month |
| S3 | Storage (50 GB) | $1.15/month |
| Lambda | Data Collection | $0.10/month |
| **Total** | | **~$468/month** |

### One-Time Setup Costs
- Implementation time: 40 hours @ $150/hour = $6,000
- Training development: 20 hours @ $150/hour = $3,000
- **Total one-time**: $9,000

### Expected ROI
Based on AWS customer case studies:
- **Year 1 Savings**: $500K - $1M (conservative estimate)
- **ROI**: 50x - 100x
- **Payback Period**: < 1 month

## Success Metrics - 90 Day Goals

### Adoption Metrics
- [ ] 80% of target users have accessed dashboards
- [ ] Average 3+ dashboard views per user per week
- [ ] 5+ custom reports created by teams

### Financial Metrics
- [ ] $500K+ optimization opportunities identified
- [ ] $150K+ savings realized (30% implementation rate)
- [ ] 100% cost allocation to business units
- [ ] Budget variance reduced by 20%

### Operational Metrics
- [ ] Anomaly detection time: < 4 hours (from days)
- [ ] 50+ optimization recommendations reviewed
- [ ] 20+ recommendations implemented
- [ ] Resource utilization improved by 15%

### Engagement Metrics
- [ ] 4 training sessions completed
- [ ] User satisfaction score: 4.5/5
- [ ] 10+ feedback items collected and addressed
- [ ] Monthly executive report established

## Troubleshooting Guide

### Issue: CUR data not appearing in Athena
**Solution:**
1. Verify CUR is enabled and generating reports (24-48 hour delay)
2. Check S3 bucket permissions for Athena
3. Run Glue crawler manually to update catalog
4. Verify Athena workgroup configuration

### Issue: QuickSight dashboard shows no data
**Solution:**
1. Check SPICE dataset refresh status
2. Verify Athena queries are completing successfully
3. Review IAM permissions for QuickSight role
4. Check data source connection settings

### Issue: Users cannot access dashboards
**Solution:**
1. Verify user is added to QuickSight
2. Check user group membership
3. Review RLS rules if implemented
4. Verify dashboard sharing settings

### Issue: High Athena costs
**Solution:**
1. Review query patterns and optimize
2. Implement partition pruning
3. Use columnar format (Parquet)
4. Set up query result caching
5. Configure workgroup data scanned limits

## Support Resources

### AWS Documentation
- [CID Official Docs](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/)
- [Well-Architected Labs](https://wellarchitectedlabs.com/cloud-intelligence-dashboards/)
- [QuickSight User Guide](https://docs.aws.amazon.com/quicksight/)

### Community Support
- **Email**: cloud-intelligence-dashboards@amazon.com
- **AWS re:Post**: Tag questions with "cloud-intelligence-dashboards"
- **YouTube**: Cloud Intelligence Dashboards channel
- **GitHub**: aws-samples/aws-cudos-framework-deployment

### Internal Support
- **FinOps Team**: finops@wac.com
- **AWS Account Team**: Contact TAM/SA
- **Slack Channel**: #cloud-intelligence-dashboards
- **Office Hours**: Wednesdays 2-3 PM

## Next Steps

1. **Review and Approve** this implementation plan with stakeholders
2. **Schedule Kickoff** meeting with implementation team
3. **Assign Roles**: Project lead, AWS admin, QuickSight admin, trainers
4. **Set Timeline**: Confirm 4-week implementation schedule
5. **Begin Week 1** activities starting with prerequisites

---

**Document Version**: 1.0  
**Created**: February 16, 2026  
**Owner**: Cloud FinOps Team  
**Status**: Ready for Implementation
