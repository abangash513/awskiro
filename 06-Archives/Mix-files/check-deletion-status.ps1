# Quick Status Check Script
# Run this anytime to check if the stack deletion is complete

$STACK_NAME = "concierge-medicine-stack"
$REGION = "us-east-1"

Write-Host "Checking CloudFormation stack status..." -ForegroundColor Cyan
Write-Host ""

try {
    $STATUS = aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].StackStatus' --output text 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Stack Status: $STATUS" -ForegroundColor Yellow
        
        if ($STATUS -eq "DELETE_IN_PROGRESS") {
            Write-Host ""
            Write-Host "Deletion is still in progress. Recent events:" -ForegroundColor Cyan
            aws cloudformation describe-stack-events --stack-name $STACK_NAME --region $REGION --max-items 5 --query 'StackEvents[*].[Timestamp,ResourceStatus,LogicalResourceId]' --output table
        }
    } else {
        Write-Host "✓ Stack has been completely deleted!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Verifying no resources remain..." -ForegroundColor Cyan
        
        # Check for S3 buckets
        Write-Host ""
        Write-Host "Checking for S3 buckets..."
        $buckets = aws s3 ls | Select-String "concierge-medicine"
        if ($buckets) {
            Write-Host "⚠ Found S3 buckets: $buckets" -ForegroundColor Yellow
        } else {
            Write-Host "✓ No S3 buckets found" -ForegroundColor Green
        }
        
        # Check for RDS instances
        Write-Host ""
        Write-Host "Checking for RDS instances..."
        $rds = aws rds describe-db-instances --region $REGION --query 'DBInstances[?contains(DBInstanceIdentifier, `concierge`)].DBInstanceIdentifier' --output text
        if ($rds) {
            Write-Host "⚠ Found RDS instances: $rds" -ForegroundColor Yellow
        } else {
            Write-Host "✓ No RDS instances found" -ForegroundColor Green
        }
        
        # Check for ECS clusters
        Write-Host ""
        Write-Host "Checking for ECS clusters..."
        $ecs = aws ecs list-clusters --region $REGION | Select-String "concierge-medicine"
        if ($ecs) {
            Write-Host "⚠ Found ECS clusters: $ecs" -ForegroundColor Yellow
        } else {
            Write-Host "✓ No ECS clusters found" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Deletion verification complete!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
    }
} catch {
    Write-Host "✓ Stack has been completely deleted!" -ForegroundColor Green
    Write-Host "(Stack not found in CloudFormation)" -ForegroundColor Gray
}
