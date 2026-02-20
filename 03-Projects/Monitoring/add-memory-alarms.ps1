# Add Memory Utilization Alarms
# Run this AFTER installing CloudWatch agent on both DCs

$region = "us-west-2"
$profile = "WACPROD"

# Get SNS topic ARN
$topicArn = (aws sns list-topics --profile $profile --region $region --query "Topics[?contains(TopicArn, 'WACAWSPROD_Monitoring')].TopicArn" --output text)

# Get instance IDs
$dc01 = (aws ec2 describe-instances --filters "Name=tag:Name,Values=WACPRODDC01" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text --profile $profile --region $region)
$dc02 = (aws ec2 describe-instances --filters "Name=tag:Name,Values=WACPRODDC02" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text --profile $profile --region $region)

Write-Host "Creating memory alarms..." -ForegroundColor Cyan

# WACPRODDC01 Memory alarm
aws cloudwatch put-metric-alarm --alarm-name "WACPRODDC01-HighMemory" --alarm-description "Alert when WACPRODDC01 Memory > 70%" --metric-name MemoryUtilization --namespace CWAgent --statistic Average --period 300 --threshold 70 --comparison-operator GreaterThanThreshold --evaluation-periods 2 --dimensions Name=InstanceId,Value=$dc01 --alarm-actions $topicArn --profile $profile --region $region

# WACPRODDC02 Memory alarm
aws cloudwatch put-metric-alarm --alarm-name "WACPRODDC02-HighMemory" --alarm-description "Alert when WACPRODDC02 Memory > 70%" --metric-name MemoryUtilization --namespace CWAgent --statistic Average --period 300 --threshold 70 --comparison-operator GreaterThanThreshold --evaluation-periods 2 --dimensions Name=InstanceId,Value=$dc02 --alarm-actions $topicArn --profile $profile --region $region

Write-Host "Memory alarms created!" -ForegroundColor Green
