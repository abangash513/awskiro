# Cloud Intelligence Dashboards Solution Design for WAC Production Account

## Executive Summary

This document outlines the implementation strategy for deploying AWS Cloud Intelligence Dashboards Framework in the WAC production account. The solution provides comprehensive visibility into cost, usage, operations, and optimization opportunities across the AWS infrastructure.

## Solution Overview

Cloud Intelligence Dashboards is an open-source framework from AWS Enterprise Support that delivers actionable insights through pre-built Amazon QuickSight dashboards. The framework enables financial accountability, cost optimization, usage tracking, and operational excellence at scale.

### Key Benefits

- **Rapid Deployment**: Deploy in under 30 minutes using CloudFormation templates
- **Secure**: Native AWS services, IAM-based access control, no external agents
- **Comprehensive**: Hundreds of pre-built visuals with resource-level granularity
- **Cost-Efficient**: Serverless architecture with pay-per-use pricing
- **Multi-Organization Support**: Supports multi-payer and multi-cloud environments

## Architecture Components

### 1. Data Foundation Layer

#### Cost and Usage Report (CUR)
- **Purpose**: Primary data source for cost and usage analytics
- **Configuration**:
  - Enable hourly granularity with resource IDs
  - Include all available columns
  - Store in dedicated S3 bucket with versioning
  - Enable Athena integration
  - Compression: Parquet format

#### Data Collection Framework
- **AWS Trusted Advisor**: Organizational view for optimization recommendations
- **AWS Compute Optimizer**: Right-sizing recommendations
- **AWS Cost Anomaly Detection**: Anomaly tracking
- **AWS Cost Optimization Hub**: Consolidated optimization recommendations
- **AWS Health Events**: Service health monitoring
- **AWS Budgets**: Budget tracking and alerts

### 2. Processing Layer

#### Amazon Athena
- **Purpose**: Query engine for CUR data
- **Configuration**:
  - Dedicated workgroup for CID queries
  - Query result location in S3
  - Enable query result encryption
  - Set appropriate data scanned limits

#### AWS Glue
- **Purpose**: Data catalog and ETL
- **Configuration**:
  - Automated crawler for CUR data
  - Database for CID tables
  - Partitioning strategy for performance

### 3. Visualization Layer

#### Amazon QuickSight
- **Edition**: Enterprise Edition (required for advanced features)
- **Features**:
  - Row-level security (RLS) for access control
  - SPICE datasets for performance
  - Scheduled refresh for data updates
  - Custom branding and themes

## Recommended Dashboard Suite

### Phase 1: Foundational Dashboards (Week 1)

#### 1. Cost Intelligence Dashboard (CID)
- **Target Audience**: Executives, Finance, Procurement
- **Purpose**: High-level cost management and financial accountability
- **Key Features**:
  - Executive summary views
  - Cost trends and forecasting
  - Service-level cost breakdown
  - Budget vs. actual tracking
  - No technical AWS knowledge required

#### 2. CUDOS Dashboard (Cost and Usage Dashboard Optimized for Sustainability)
- **Target Audience**: FinOps, Product Owners, Engineering Teams
- **Purpose**: Operational insights with optimization recommendations
- **Key Features**:
  - Resource-level granularity
  - Auto-generated cost optimization recommendations
  - Usage spike identification
  - Drill-down capabilities to specific resources
  - Sustainability metrics

#### 3. KPI and Modernization Dashboard
- **Target Audience**: DevOps, FinOps, Engineering Teams
- **Purpose**: Track modernization and optimization goals
- **Key Features**:
  - OnDemand vs. Reserved vs. Spot usage
  - Graviton adoption tracking
  - Modernization KPI monitoring
  - Goal setting and tracking

### Phase 2: Operational Dashboards (Week 2-3)

#### 4. Trusted Advisor Organizational (TAO) Dashboard
- **Target Audience**: DevOps, Engineering, SRE, Security Teams
- **Purpose**: Comprehensive optimization and risk visibility
- **Key Features**:
  - Cost optimization opportunities
  - Idle resource identification
  - Security risks and flagged resources
  - Reliability and performance insights
  - Historical trend tracking

#### 5. Compute Optimizer Dashboard
- **Target Audience**: FinOps, DevOps, Engineering Teams
- **Purpose**: Right-sizing recommendations
- **Key Features**:
  - Over-provisioned resource identification
  - Under-provisioned resource warnings
  - Cost savings opportunities
  - Performance optimization insights

#### 6. Cost Anomaly Dashboard
- **Target Audience**: FinOps, DevOps, Engineering Teams
- **Purpose**: Track and visualize cost anomalies
- **Key Features**:
  - Anomaly detection findings
  - Root cause analysis
  - Alert integration
  - Historical anomaly tracking

### Phase 3: Advanced Dashboards (Week 4+)

#### 7. Graviton Savings Dashboard
- **Purpose**: Quantify Graviton migration opportunities
- **Services Covered**: EC2, RDS, OpenSearch, ElastiCache
- **Key Metrics**: Potential savings, current adoption rate

#### 8. Health Events Dashboard
- **Purpose**: Track AWS service health events
- **Features**: Past, current, and upcoming events visibility

#### 9. AWS Budgets Dashboard
- **Purpose**: Centralized budget tracking
- **Features**: Organization-wide budget monitoring and alerts

#### 10. Data Collection Monitor Dashboard
- **Purpose**: Monitor data collection framework execution
- **Features**: Execution tracking, error troubleshooting

## Implementation Plan

### Prerequisites

1. **AWS Account Setup**
   - Management account access (for organization-wide deployment)
   - IAM permissions for CloudFormation, QuickSight, Athena, Glue, S3
   - QuickSight Enterprise Edition subscription

2. **Data Sources**
   - Enable AWS Cost and Usage Report (CUR)
   - Enable AWS Organizations (if multi-account)
   - Enable Trusted Advisor (Business or Enterprise Support)
   - Enable Compute Optimizer
   - Enable Cost Anomaly Detection

### Deployment Steps

#### Step 1: Enable Cost and Usage Report (Day 1)
```
1. Navigate to AWS Billing Console
2. Create new CUR with following settings:
   - Report name: wac-prod-cur
   - Time granularity: Hourly
   - Include: Resource IDs
   - Enable: Data integration for Athena
   - Compression: Parquet
   - S3 bucket: wac-prod-cur-data
   - Report path prefix: cur/
   - Versioning: Overwrite existing report
```

#### Step 2: Set Up Amazon QuickSight (Day 1)
```
1. Subscribe to QuickSight Enterprise Edition
2. Configure QuickSight permissions:
   - Grant access to S3 buckets (CUR data)
   - Grant access to Athena
   - Enable IAM role for QuickSight
3. Create QuickSight groups for access control:
   - Executives
   - Finance
   - FinOps
   - Engineering
   - DevOps
```

#### Step 3: Deploy Foundational Dashboards (Day 2-3)
```
Using CloudFormation or cid-cmd tool:

1. Install cid-cmd tool:
   pip3 install cid-cmd

2. Deploy Cost Intelligence Dashboard:
   cid-cmd deploy --dashboard-id cost-intelligence-dashboard

3. Deploy CUDOS Dashboard:
   cid-cmd deploy --dashboard-id cudos

4. Deploy KPI Dashboard:
   cid-cmd deploy --dashboard-id kpi
```

#### Step 4: Configure Data Collection (Day 3-4)
```
1. Deploy Trusted Advisor data collection:
   cid-cmd deploy --dashboard-id tao

2. Deploy Compute Optimizer data collection:
   cid-cmd deploy --dashboard-id compute-optimizer

3. Deploy Cost Anomaly data collection:
   cid-cmd deploy --dashboard-id cost-anomaly

4. Configure Lambda functions for data refresh
5. Set up EventBridge rules for automated collection
```

#### Step 5: Implement Row-Level Security (Day 5)
```
1. Define organizational taxonomy:
   - Business units
   - Cost centers
   - Projects/Applications
   - Environments (Prod, Dev, Test)

2. Create RLS datasets in QuickSight
3. Map users/groups to data access rules
4. Test access controls
```

#### Step 6: Deploy Advanced Dashboards (Week 2-3)
```
Deploy additional dashboards based on priority:
- Graviton Savings Dashboard
- Health Events Dashboard
- AWS Budgets Dashboard
- Extended Support Cost Projection
- Data Collection Monitor
```

### Step 7: Customization and Optimization (Week 3-4)
```
1. Configure organizational tags in dashboards
2. Customize visuals for WAC-specific requirements
3. Set up scheduled refresh intervals
4. Configure email subscriptions for key stakeholders
5. Create custom calculated fields
6. Implement dashboard themes and branding
```

## Access Control Strategy

### User Groups and Permissions

#### Executive Group
- **Access**: Cost Intelligence Dashboard (read-only)
- **Data Scope**: Organization-wide summary
- **Features**: High-level trends, forecasts, budget tracking

#### Finance Group
- **Access**: Cost Intelligence, CUDOS, Budgets Dashboard
- **Data Scope**: All accounts and cost centers
- **Features**: Detailed cost analysis, budget management, forecasting

#### FinOps Group
- **Access**: All cost and optimization dashboards
- **Data Scope**: Organization-wide with drill-down capabilities
- **Features**: Full access to recommendations, anomalies, optimization opportunities

#### Engineering/DevOps Group
- **Access**: CUDOS, TAO, Compute Optimizer, KPI, Health Events
- **Data Scope**: Filtered by team/project tags
- **Features**: Resource-level insights, optimization recommendations, operational metrics

#### Security Group
- **Access**: TAO Dashboard (security pillar)
- **Data Scope**: Security-related findings only
- **Features**: Security risks, compliance status, remediation tracking

## Cost Estimation

### Monthly Costs (Estimated)

#### Amazon QuickSight
- **Enterprise Edition**: $18/user/month (first user) + $5/user/month (additional readers)
- **SPICE Capacity**: $0.25/GB/month
- **Estimated**: 10 authors ($180) + 50 readers ($250) = $430/month

#### Amazon Athena
- **Query Costs**: $5 per TB scanned
- **Estimated**: 100 GB/day × 30 days × $5/TB = $15/month

#### AWS Glue
- **Crawler**: $0.44/DPU-hour
- **Estimated**: 1 crawler × 0.1 hours/day × 30 days = $1.32/month

#### Amazon S3
- **CUR Storage**: $0.023/GB/month
- **Estimated**: 50 GB × $0.023 = $1.15/month

#### AWS Lambda (Data Collection)
- **Invocations**: $0.20 per 1M requests
- **Estimated**: 10,000 invocations/month = $0.002/month

**Total Estimated Monthly Cost**: ~$450-500/month

### Cost Optimization Opportunities
Based on customer case studies, organizations typically achieve:
- **3-10x ROI** within first year
- **$100K-$3M+ annual savings** through identified optimizations
- **20-40% reduction** in idle resources
- **15-30% improvement** in resource utilization

## Success Metrics

### Key Performance Indicators

#### Financial Metrics
- Cost savings identified and realized
- Budget variance reduction
- Forecast accuracy improvement
- Cost allocation accuracy

#### Operational Metrics
- Dashboard adoption rate (active users)
- Time to identify cost anomalies
- Optimization recommendation implementation rate
- Resource utilization improvement

#### Engagement Metrics
- Dashboard views per week
- Average session duration
- Number of custom reports created
- User satisfaction score

### Target Goals (First 90 Days)

1. **Adoption**: 80% of target users actively using dashboards
2. **Savings Identification**: Identify $500K+ in optimization opportunities
3. **Implementation**: Realize 30% of identified savings
4. **Visibility**: 100% cost allocation to business units/projects
5. **Anomaly Detection**: Reduce time to detect anomalies from days to hours

## Governance and Maintenance

### Regular Activities

#### Daily
- Monitor data collection execution
- Review cost anomalies
- Check dashboard refresh status

#### Weekly
- Review new optimization recommendations
- Track savings implementation progress
- Update stakeholder reports

#### Monthly
- Review and update RLS rules
- Analyze dashboard usage metrics
- Conduct user feedback sessions
- Update custom calculations and visuals

#### Quarterly
- Review and optimize SPICE capacity
- Evaluate new dashboard releases
- Conduct training sessions
- Update organizational taxonomy

### Support and Training

#### Initial Training (Week 1-2)
- Executive overview session (1 hour)
- Finance team deep dive (2 hours)
- FinOps practitioner workshop (4 hours)
- Engineering team hands-on lab (3 hours)

#### Ongoing Support
- Weekly office hours for questions
- Slack/Teams channel for support
- Documentation wiki
- Monthly "Tips and Tricks" sessions

## Risk Mitigation

### Potential Risks and Mitigations

#### Risk 1: Data Latency
- **Impact**: CUR data has 24-48 hour delay
- **Mitigation**: Set expectations, use Cost Explorer API for real-time needs

#### Risk 2: QuickSight Costs
- **Impact**: Costs can grow with user adoption
- **Mitigation**: Use reader licenses, implement RLS, monitor usage

#### Risk 3: Data Quality
- **Impact**: Missing tags or incomplete data
- **Mitigation**: Implement tagging strategy, data validation checks

#### Risk 4: User Adoption
- **Impact**: Low engagement reduces ROI
- **Mitigation**: Executive sponsorship, training, regular communication

#### Risk 5: Maintenance Overhead
- **Impact**: Dashboards require ongoing updates
- **Mitigation**: Automated updates via cid-cmd, dedicated FinOps team

## Next Steps

### Immediate Actions (Week 1)

1. **Stakeholder Alignment**
   - Present solution design to leadership
   - Identify executive sponsor
   - Form implementation team

2. **Technical Preparation**
   - Verify IAM permissions
   - Enable CUR in management account
   - Subscribe to QuickSight Enterprise

3. **Planning**
   - Schedule deployment windows
   - Plan training sessions
   - Define success criteria

### Short-term Goals (Month 1)

1. Deploy foundational dashboards (CID, CUDOS, KPI)
2. Configure data collection framework
3. Implement basic RLS
4. Conduct initial training sessions
5. Establish governance processes

### Medium-term Goals (Month 2-3)

1. Deploy advanced dashboards
2. Implement comprehensive RLS
3. Customize dashboards for WAC requirements
4. Track and report on identified savings
5. Expand user adoption

### Long-term Goals (Month 4-6)

1. Achieve 80%+ user adoption
2. Realize $500K+ in cost savings
3. Establish FinOps center of excellence
4. Implement advanced customizations
5. Explore multi-cloud dashboards (if applicable)

## References and Resources

### Official Documentation
- [Cloud Intelligence Dashboards Framework](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/)
- [Well-Architected Labs - CID](https://wellarchitectedlabs.com/cloud-intelligence-dashboards/)
- [AWS Solutions Library - CID](https://aws.amazon.com/solutions/guidance/advanced-cloud-observability-with-cloud-intelligence-dashboards-on-aws/)

### Deployment Tools
- **cid-cmd**: Command-line tool for automated deployment
- **CloudFormation Templates**: Infrastructure as Code deployment
- **GitHub Repository**: [aws-samples/aws-cudos-framework-deployment](https://github.com/aws-samples/aws-cudos-framework-deployment)

### Support Channels
- **Email**: cloud-intelligence-dashboards@amazon.com
- **AWS re:Post**: Community support forum
- **YouTube**: Cloud Intelligence Dashboards channel
- **AWS Account Team**: TAM/SA support

### Customer Success Stories
- Cvent: $3M+ savings in less than two years
- Siemens Energy: Cost-aware culture transformation
- Telenor: Row-level security implementation
- PandaDoc: Comprehensive cost optimization

## Appendix

### A. Required IAM Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cur:DescribeReportDefinitions",
        "cur:PutReportDefinition",
        "s3:CreateBucket",
        "s3:PutBucketPolicy",
        "s3:PutBucketVersioning",
        "athena:*",
        "glue:*",
        "quicksight:*",
        "cloudformation:*",
        "lambda:*",
        "iam:CreateRole",
        "iam:AttachRolePolicy"
      ],
      "Resource": "*"
    }
  ]
}
```

### B. Tagging Strategy

Recommended tags for cost allocation:
- **Environment**: prod, dev, test, staging
- **CostCenter**: Finance code or department
- **Project**: Project or application name
- **Owner**: Team or individual responsible
- **BusinessUnit**: Organizational unit
- **Application**: Application identifier

### C. Dashboard Refresh Schedule

| Dashboard | Refresh Frequency | Data Latency |
|-----------|------------------|--------------|
| Cost Intelligence | Daily at 6 AM | 24-48 hours |
| CUDOS | Daily at 6 AM | 24-48 hours |
| KPI | Daily at 7 AM | 24-48 hours |
| TAO | Daily at 8 AM | Real-time |
| Compute Optimizer | Daily at 8 AM | Real-time |
| Cost Anomaly | Every 6 hours | Near real-time |
| Health Events | Hourly | Real-time |

---

**Document Version**: 1.0  
**Last Updated**: February 16, 2026  
**Author**: Cloud Architecture Team  
**Status**: Draft for Review
