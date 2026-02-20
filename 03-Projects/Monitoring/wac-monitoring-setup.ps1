# WAC Production DC Monitoring Setup
# Region: us-west-2
# Profile: WACPROD

$region = "us-west-2"
$profile = "WACPROD"
$email = "agbangash@gmail.com"
$phone = "+19723023236"

# Get instance IDs
Write-Host "Fetching instance IDs..." -ForegroundColor Cyan
$dc01 = (aws ec2 describe-instances --filters "Name=tag:Name,Values=WACPRODDC01" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text --profile $profile --region $region)
$dc02 = (aws ec2 describe-instances --filters "Name=tag:Name,Values=WACPRODDC02" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text --profile $profile --region $region)

Write-Host "WACPRODDC01: $dc01" -ForegroundColor Green
Write-Host "WACPRODDC02: $dc02" -ForegroundColor Green

# Create SNS Topic
Write-Host "`nCreating SNS topic..." -ForegroundColor Cyan
$topicArn = (aws sns create-topic --name WACAWSPROD_Monitoring --profile $profile --region $region --query "TopicArn" --output text)
Write-Host "Topic ARN: $topicArn" -ForegroundColor Green

# Subscribe email
Write-Host "`nSubscribing email..." -ForegroundColor Cyan
aws sns subscribe --topic-arn $topicArn --protocol email --notification-endpoint $email --profile $profile --region $region

# Subscribe SMS
Write-Host "Subscribing SMS..." -ForegroundColor Cyan
aws sns subscribe --topic-arn $topicArn --protocol sms --notification-endpoint $phone --profile $profile --region $region

Write-Host "`nCheck your email to confirm subscription!" -ForegroundColor Yellow

# Create alarms for WACPRODDC01
Write-Host "`nCreating alarms for WACPRODDC01..." -ForegroundColor Cyan

# Status check alarm
aws cloudwatch put-metric-alarm --alarm-name "WACPRODDC01-StatusCheck" --alarm-description "Alert when WACPRODDC01 is down" --metric-name StatusCheckFailed --namespace AWS/EC2 --statistic Maximum --period 60 --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold --evaluation-periods 2 --dimensions Name=InstanceId,Value=$dc01 --alarm-actions $topicArn --profile $profile --region $region

# CPU alarm
aws cloudwatch put-metric-alarm --alarm-name "WACPRODDC01-HighCPU" --alarm-description "Alert when WACPRODDC01 CPU > 70%" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 70 --comparison-operator GreaterThanThreshold --evaluation-periods 2 --dimensions Name=InstanceId,Value=$dc01 --alarm-actions $topicArn --profile $profile --region $region

# Create alarms for WACPRODDC02
Write-Host "Creating alarms for WACPRODDC02..." -ForegroundColor Cyan

# Status check alarm
aws cloudwatch put-metric-alarm --alarm-name "WACPRODDC02-StatusCheck" --alarm-description "Alert when WACPRODDC02 is down" --metric-name StatusCheckFailed --namespace AWS/EC2 --statistic Maximum --period 60 --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold --evaluation-periods 2 --dimensions Name=InstanceId,Value=$dc02 --alarm-actions $topicArn --profile $profile --region $region

# CPU alarm
aws cloudwatch put-metric-alarm --alarm-name "WACPRODDC02-HighCPU" --alarm-description "Alert when WACPRODDC02 CPU > 70%" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 70 --comparison-operator GreaterThanThreshold --evaluation-periods 2 --dimensions Name=InstanceId,Value=$dc02 --alarm-actions $topicArn --profile $profile --region $region

Write-Host "`nMonitoring setup complete!" -ForegroundColor Green
Write-Host "Created alarms:" -ForegroundColor Cyan
Write-Host "  - WACPRODDC01-StatusCheck (instance down)" -ForegroundColor White
Write-Host "  - WACPRODDC01-HighCPU (CPU > 70%)" -ForegroundColor White
Write-Host "  - WACPRODDC02-StatusCheck (instance down)" -ForegroundColor White
Write-Host "  - WACPRODDC02-HighCPU (CPU > 70%)" -ForegroundColor White
