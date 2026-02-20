# Install CloudWatch Agent on WACPRODDC01 and WACPRODDC02
# Run this script ON each DC instance via RDP or SSM

$configFile = "C:\AWSKiro\cloudwatch-agent-config.json"

# Download CloudWatch Agent
Write-Host "Downloading CloudWatch Agent..." -ForegroundColor Cyan
$url = "https://s3.amazonaws.com/amazoncloudwatch-agent/windows/amd64/latest/amazon-cloudwatch-agent.msi"
$output = "$env:TEMP\amazon-cloudwatch-agent.msi"
Invoke-WebRequest -Uri $url -OutFile $output

# Install CloudWatch Agent
Write-Host "Installing CloudWatch Agent..." -ForegroundColor Cyan
Start-Process msiexec.exe -ArgumentList "/i $output /qn" -Wait

# Start CloudWatch Agent with config
Write-Host "Starting CloudWatch Agent..." -ForegroundColor Cyan
& "C:\Program Files\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1" -a fetch-config -m ec2 -s -c file:$configFile

Write-Host "CloudWatch Agent installed and started!" -ForegroundColor Green
