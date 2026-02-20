# Send Test Alert via SNS

$region = "us-west-2"
$profile = "WACPROD"
$email = "agbangash@gmail.com"
$phone = "+19723023236"

# Get SNS topic ARN
$topicArn = (aws sns list-topics --profile $profile --region $region --query "Topics[?contains(TopicArn, 'WACAWSPROD_Monitoring')].TopicArn" --output text)

if ($topicArn) {
    Write-Host "Using existing topic: $topicArn" -ForegroundColor Green
} else {
    Write-Host "Creating SNS topic..." -ForegroundColor Cyan
    $topicArn = (aws sns create-topic --name WAC-Prod-DC-Alerts --profile $profile --region $region --query "TopicArn" --output text)
    
    # Subscribe email
    aws sns subscribe --topic-arn $topicArn --protocol email --notification-endpoint $email --profile $profile --region $region
    
    # Subscribe SMS
    aws sns subscribe --topic-arn $topicArn --protocol sms --notification-endpoint $phone --profile $profile --region $region
    
    Write-Host "Subscriptions created. Check email to confirm!" -ForegroundColor Yellow
    Start-Sleep -Seconds 5
}

# Send test message
$message = "TEST ALERT: WAC Production DC Monitoring is now active. You will receive alerts for instance failures, high CPU/Memory usage, and AD health issues."

Write-Host "`nSending test alert..." -ForegroundColor Cyan
aws sns publish --topic-arn $topicArn --subject "WAC Monitoring Test Alert" --message $message --profile $profile --region $region

Write-Host "Test alert sent to:" -ForegroundColor Green
Write-Host "  Email: $email" -ForegroundColor White
Write-Host "  SMS: $phone" -ForegroundColor White
