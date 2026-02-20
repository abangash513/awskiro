$region = "us-west-2"
$profile = "WACPROD"
$instances = @("i-0745579f46a34da2e", "i-08c78db5cfc6eb412")

# Upload config to Parameter Store
Write-Host "Uploading CloudWatch config to Parameter Store..." -ForegroundColor Cyan
$configContent = Get-Content C:\AWSKiro\cloudwatch-agent-config.json -Raw
aws ssm put-parameter --name "WACPROD-CW-Config" --type String --value $configContent --overwrite --profile $profile --region $region

# Configure and start agent on both DCs
Write-Host "Configuring CloudWatch Agent on both DCs..." -ForegroundColor Cyan
foreach ($instance in $instances) {
    $cmdId = aws ssm send-command --instance-ids $instance --document-name AmazonCloudWatch-ManageAgent --parameters "action=configure,mode=ec2,optionalConfigurationSource=ssm,optionalConfigurationLocation=WACPROD-CW-Config,optionalRestart=yes" --profile $profile --region $region --query Command.CommandId --output text
    Write-Host "  Started on $instance - Command ID: $cmdId"
}

Write-Host "`nCloudWatch Agent configured and started!" -ForegroundColor Green
