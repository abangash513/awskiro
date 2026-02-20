# PowerShell script to retrieve AWS Well-Architected Framework workloads
# and create a CSV file for AWS Partner Central import

Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("=" * 79) -ForegroundColor Cyan
Write-Host "AWS Well-Architected Framework Workload Retrieval Tool" -ForegroundColor Yellow
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("=" * 79) -ForegroundColor Cyan
Write-Host ""

# Set AWS credentials
Write-Host "Setting AWS credentials..." -ForegroundColor Green
$env:AWS_ACCESS_KEY_ID = "ASIA2TS43GPZJTRMMX4G"
$env:AWS_SECRET_ACCESS_KEY = "cYUumLvf5Gph360Ws0aZGiUmy7l2PLyx0A5f1Z+B"
$env:AWS_SESSION_TOKEN = "IQoJb3JpZ2luX2VjEHYaCXVzLXdlc3QtMiJGMEQCICdwDgB2bNhzvK8mAuWo6LJiOVU6YTDqcZCLUayG8f1XAiAjPLO9ptk6cfJxzrn749UCbJvQ9bkJd5kGb2eS1Az+yiqGAwg+EAQaDDcyOTI2NTQxOTI1MCIMYYRmbKlVmDQHZyh/KuMCLC1Qhl/S1YO63wxLrrny7p0cz4dUsStauxx+zkh/n3jlmfIDPoMKos34lpgr/tR76gqTbKEc76IHYsUUycSl1kz/ZGYGLzLNS21TBG1uul9W6uuG5fP/oop/m5Hra1tJZMDh+DcOohBrH6UNiXjOb8ukjP6XiNDzJL0jnjtrBMeqGGfQqlmAmoOY0cazuBzcTBASnC1dbvAf/+FyN3rAU7vk6aD7zYHYycJZuU+BcBDD06ifxLPAi+H8HiI5LzEkdc90wkJZbuIoG3FnuIVkEnjplvF2WHIQgkJ+WZK1radfxVaOJywGHwgrp0p5krY0INpRMtryjj3U9eVsOBuRTMBDWOnCeiXrcX0jZ4g2dCo1TSWX1TS5dLJA99pZawB6fvOzndXJjXuSuBz9Xc7FVSIdmLxxd+1imhsYOvLCsYIreNl39OOjR3fqUHJeioLWJJlI12VnlpzpbGW+WJo8sQHZjjC/s8TJBjqlAWGnnmQHjiXQnBicqN0uVyGQLkH/+q2eT6wPiEJYRY2sDWArFDswjCVCAorNHCGi1gWt0WRIAH/2pV/1oS+jY9Rfe/8wJE0MKp2rKBMfjhY13TTbi24TE1ZFNplA4ZQzS3iF2iBucQzfU2IAU3gR0VWNrHpyQh8auqsbBvsm247U0KgQMfKE164p7cgERUwWCE7KAmMsWJ9V487Mzp0dBENk40Gb1A=="

Write-Host "Fetching Well-Architected workloads..." -ForegroundColor Green
Write-Host ""

# List all workloads
try {
    $workloadsJson = aws wellarchitected list-workloads --output json 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to list workloads" -ForegroundColor Red
        Write-Host $workloadsJson -ForegroundColor Red
        exit 1
    }
    
    $workloads = ($workloadsJson | ConvertFrom-Json).WorkloadSummaries
    
    if ($workloads.Count -eq 0) {
        Write-Host "No workloads found in this account." -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host "Found $($workloads.Count) workload(s):" -ForegroundColor Green
    Write-Host ""
    
    # Create array to store workload data
    $workloadData = @()
    
    # Process each workload
    $counter = 1
    foreach ($workload in $workloads) {
        Write-Host "$counter. Workload Name: $($workload.WorkloadName)" -ForegroundColor Cyan
        Write-Host "   Workload ID: $($workload.WorkloadId)" -ForegroundColor White
        
        # Get detailed workload information including ARN
        $detailsJson = aws wellarchitected get-workload --workload-id $workload.WorkloadId --output json 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $details = ($detailsJson | ConvertFrom-Json).Workload
            $arn = $details.WorkloadArn
            
            Write-Host "   ARN: $arn" -ForegroundColor Yellow
            Write-Host "   Environment: $($workload.Environment)" -ForegroundColor White
            Write-Host "   Owner: $($workload.Owner)" -ForegroundColor White
            Write-Host "   Updated: $($workload.UpdatedAt)" -ForegroundColor White
            
            # Add to data array
            $workloadData += [PSCustomObject]@{
                ARN = $arn
                WorkloadName = $workload.WorkloadName
                WorkloadId = $workload.WorkloadId
                Environment = $workload.Environment
                Industry = $workload.Industry
                Owner = $workload.Owner
                ReviewDate = $workload.UpdatedAt
            }
        } else {
            Write-Host "   Error getting details for this workload" -ForegroundColor Red
        }
        
        Write-Host ("-" * 80) -ForegroundColor Gray
        $counter++
    }
    
    # Create CSV file
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $csvFilename = "wafr_workloads_for_partner_central_$timestamp.csv"
    
    $workloadData | Export-Csv -Path $csvFilename -NoTypeInformation -Encoding UTF8
    
    Write-Host ""
    Write-Host "=" -NoNewline -ForegroundColor Cyan
    Write-Host ("=" * 79) -ForegroundColor Cyan
    Write-Host "CSV file created: $csvFilename" -ForegroundColor Green
    Write-Host "=" -NoNewline -ForegroundColor Cyan
    Write-Host ("=" * 79) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "IMPORTANT: ARN Format for Partner Central" -ForegroundColor Yellow
    Write-Host "The ARN should be in this format:" -ForegroundColor White
    Write-Host "arn:aws:wellarchitected:Region:AWS_Account_ID:workload/Workload_ID" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This CSV file is ready to be imported into AWS Partner Central." -ForegroundColor Green
    Write-Host "=" -NoNewline -ForegroundColor Cyan
    Write-Host ("=" * 79) -ForegroundColor Cyan
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
