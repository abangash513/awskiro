# AWS Cost Optimization Plan
**Account ID**: 750299845580  
**Current Monthly Cost**: $294.47  
**Target Reduction**: 30-50% ($88-147 savings)  
**Analysis Date**: January 2, 2025

## 🎯 Priority Optimization Targets

### 1. **SageMaker Optimization** - Potential Savings: $40-60/month
**Current Cost**: $83.28/month (28.3% of total)
**Issue**: ml.t2.large notebook instance running continuously ($88.03/month usage)

#### Immediate Actions:
```bash
# Stop unused SageMaker notebook instances
aws sagemaker list-notebook-instances --status-equals InService
aws sagemaker stop-notebook-instance --notebook-instance-name [INSTANCE_NAME]

# Check for unused endpoints
aws sagemaker list-endpoints --status-equals InService
```

#### Optimization Strategy:
- **Stop/Start Schedule**: Implement automatic start/stop for development notebooks
- **Right-size Instances**: Move from ml.t2.large to ml.t3.medium (50% cost reduction)
- **Spot Instances**: Use SageMaker Spot for training jobs (up to 90% savings)
- **Lifecycle Configurations**: Auto-stop idle notebooks after 1 hour

### 2. **EC2 Compute Optimization** - Potential Savings: $20-35/month
**Current Cost**: $49.07/month (16.7% of total)
**Issue**: m5.large instance running continuously ($9.83/month per instance)

#### Immediate Actions:
```bash
# Identify running instances
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].{InstanceId:InstanceId,InstanceType:InstanceType,LaunchTime:LaunchTime}"

# Check utilization (requires CloudWatch)
aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
  --start-time 2024-12-01T00:00:00Z --end-time 2025-01-01T00:00:00Z \
  --period 86400 --statistics Average
```

#### Optimization Strategy:
- **Reserved Instances**: Purchase 1-year RIs for consistent workloads (30-40% savings)
- **Spot Instances**: Use for development/testing (up to 90% savings)
- **Right-sizing**: Downgrade underutilized instances
- **Scheduled Scaling**: Auto-stop dev instances during off-hours

### 3. **AWS Directory Service Optimization** - Potential Savings: $15-25/month
**Current Cost**: $37.17/month (12.6% of total)

#### Investigation Required:
```bash
# Check directory service usage
aws ds describe-directories
aws ds describe-domain-controllers --directory-id [DIRECTORY_ID]
```

#### Optimization Strategy:
- **Evaluate Necessity**: Determine if Directory Service is actively used
- **Downsize**: Move from Enterprise to Standard edition if applicable
- **Alternative Solutions**: Consider AWS SSO or third-party solutions

### 4. **EKS Cluster Optimization** - Potential Savings: $15-25/month
**Current Cost**: $33.39/month (11.3% of total)

#### Immediate Actions:
```bash
# Check cluster utilization
aws eks list-clusters
aws eks describe-cluster --name [CLUSTER_NAME]
aws eks list-nodegroups --cluster-name [CLUSTER_NAME]
```

#### Optimization Strategy:
- **Node Group Optimization**: Use Spot instances for worker nodes (60-70% savings)
- **Cluster Autoscaler**: Implement to scale down unused nodes
- **Fargate vs EC2**: Evaluate Fargate for intermittent workloads
- **Development Clusters**: Stop/start non-production clusters

### 5. **Lightsail Optimization** - Potential Savings: $8-12/month
**Current Cost**: $15.71/month (5.3% of total)

#### Immediate Actions:
```bash
# Review Lightsail instances
aws lightsail get-instances
aws lightsail get-instance-metric-data --instance-name [INSTANCE_NAME] \
  --metric-name CPUUtilization --period 3600 --unit Percent \
  --start-time 2024-12-01T00:00:00Z --end-time 2025-01-01T00:00:00Z
```

#### Optimization Strategy:
- **Consolidation**: Migrate underutilized Lightsail instances to EC2 t3.micro
- **Rightsizing**: Downgrade oversized instances
- **Elimination**: Remove unused development instances

## 🔧 Implementation Roadmap

### Week 1: Quick Wins ($30-50 savings)
1. **Stop unused SageMaker notebooks**
2. **Terminate idle EC2 instances**
3. **Remove unused Lightsail instances**
4. **Delete old EBS snapshots**

### Week 2: Infrastructure Review ($20-40 savings)
1. **Evaluate Directory Service necessity**
2. **Right-size running instances**
3. **Implement EKS node optimization**
4. **Set up CloudWatch billing alarms**

### Week 3: Long-term Optimization ($25-45 savings)
1. **Purchase Reserved Instances for consistent workloads**
2. **Implement auto-scaling policies**
3. **Set up scheduled start/stop for dev resources**
4. **Optimize storage classes and lifecycle policies**

## 📊 Cost Optimization Scripts

### 1. SageMaker Notebook Auto-Stop
```bash
#!/bin/bash
# Stop idle SageMaker notebooks
aws sagemaker list-notebook-instances --status-equals InService --query "NotebookInstances[].NotebookInstanceName" --output text | \
while read notebook; do
    echo "Stopping notebook: $notebook"
    aws sagemaker stop-notebook-instance --notebook-instance-name "$notebook"
done
```

### 2. EC2 Instance Scheduler
```bash
#!/bin/bash
# Stop development instances after hours (6 PM - 8 AM)
CURRENT_HOUR=$(date +%H)
if [ $CURRENT_HOUR -ge 18 ] || [ $CURRENT_HOUR -lt 8 ]; then
    aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev" "Name=instance-state-name,Values=running" \
      --query "Reservations[].Instances[].InstanceId" --output text | \
    while read instance; do
        echo "Stopping development instance: $instance"
        aws ec2 stop-instances --instance-ids "$instance"
    done
fi
```

### 3. EBS Volume Cleanup
```bash
#!/bin/bash
# Find and delete old snapshots (older than 30 days)
aws ec2 describe-snapshots --owner-ids self \
  --query "Snapshots[?StartTime<='$(date -d '30 days ago' --iso-8601)'].SnapshotId" --output text | \
while read snapshot; do
    echo "Deleting old snapshot: $snapshot"
    aws ec2 delete-snapshot --snapshot-id "$snapshot"
done
```

## 💰 Expected Savings Summary

| Optimization Area | Current Cost | Optimized Cost | Monthly Savings |
|-------------------|--------------|----------------|-----------------|
| SageMaker | $83.28 | $25-45 | $38-58 |
| EC2 Compute | $49.07 | $30-40 | $9-19 |
| Directory Service | $37.17 | $15-25 | $12-22 |
| EKS | $33.39 | $20-25 | $8-13 |
| Lightsail | $15.71 | $5-10 | $5-10 |
| **TOTAL** | **$218.62** | **$95-145** | **$72-122** |

## 🚨 Monitoring and Alerts

### Set up Cost Alerts
```bash
# Create billing alarm for $200/month
aws cloudwatch put-metric-alarm \
  --alarm-name "Monthly-Billing-Alert" \
  --alarm-description "Alert when monthly bill exceeds $200" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 200 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=Currency,Value=USD \
  --evaluation-periods 1 \
  --alarm-actions arn:aws:sns:us-east-1:750299845580:billing-alerts
```

### Daily Cost Monitoring Script
```bash
#!/bin/bash
# Daily cost check
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "1 day ago" +%Y-%m-%d)

COST=$(aws ce get-cost-and-usage \
  --time-period Start=$YESTERDAY,End=$TODAY \
  --granularity DAILY \
  --metrics BlendedCost \
  --query "ResultsByTime[0].Total.BlendedCost.Amount" --output text)

echo "Yesterday's AWS cost: \$$COST"
if (( $(echo "$COST > 15" | bc -l) )); then
    echo "⚠️  High daily cost detected!"
fi
```

## 🎯 Target Achievement

**Current Monthly Cost**: $294.47  
**Optimized Target**: $150-200  
**Potential Savings**: $95-145 (32-49% reduction)  
**Implementation Timeline**: 3 weeks  

This optimization will free up budget for the Nuri Family AI System deployment while maintaining all essential services.