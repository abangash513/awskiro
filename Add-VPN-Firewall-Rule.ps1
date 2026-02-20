# Add Windows Firewall rule to allow RDP from VPN clients
# Run this via SSM on the Domain Controllers

$commandId = aws ssm send-command `
    --instance-ids i-0745579f46a34da2e i-08c78db5cfc6eb412 `
    --document-name "AWS-RunPowerShellScript" `
    --parameters '{\"commands\":[\"New-NetFirewallRule -DisplayName \\\"RDP from VPN Clients\\\" -Direction Inbound -Protocol TCP -LocalPort 3389 -RemoteAddress 10.200.0.0/16 -Action Allow -Enabled True\"]}' `
    --region us-west-2 `
    --query 'Command.CommandId' `
    --output text

Write-Host "Command ID: $commandId" -ForegroundColor Green
Write-Host "Waiting for command to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host "`nChecking results for WACPRODDC01..." -ForegroundColor Cyan
aws ssm get-command-invocation `
    --command-id $commandId `
    --instance-id i-0745579f46a34da2e `
    --region us-west-2 `
    --query '[Status,StandardOutputContent,StandardErrorContent]' `
    --output text

Write-Host "`nChecking results for WACPRODDC02..." -ForegroundColor Cyan
aws ssm get-command-invocation `
    --command-id $commandId `
    --instance-id i-08c78db5cfc6eb412 `
    --region us-west-2 `
    --query '[Status,StandardOutputContent,StandardErrorContent]' `
    --output text
