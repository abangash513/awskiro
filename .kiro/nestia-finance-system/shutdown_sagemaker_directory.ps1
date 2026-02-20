# SageMaker and Directory Services Shutdown Script
# This script will identify and shut down SageMaker and Directory Service resources

Write-Host "🛑 SageMaker and Directory Services Shutdown Script" -ForegroundColor Red
Write-Host "=================================================" -ForegroundColor Red

# Function to safely execute AWS commands with error handling
function Invoke-AWSCommand {
    param($Command, $Description)
    Write-Host "`n🔍 $Description..." -ForegroundColor Yellow
    try {
        $result = Invoke-Expression $Command
        return $result
    }
    catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 1. SAGEMAKER CLEANUP
Write-Host "`n🤖 SAGEMAKER RESOURCE CLEANUP" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

# Check and stop notebook instances (all statuses)
$notebooks = Invoke-AWSCommand "aws sagemaker list-notebook-instances --output json | ConvertFrom-Json" "Checking all SageMaker notebook instances"
if ($notebooks -and $notebooks.NotebookInstances.Count -gt 0) {
    Write-Host "📋 Found $($notebooks.NotebookInstances.Count) notebook instances:" -ForegroundColor Yellow
    foreach ($notebook in $notebooks.NotebookInstances) {
        Write-Host "  - $($notebook.NotebookInstanceName) [$($notebook.NotebookInstanceStatus)]" -ForegroundColor White
        
        if ($notebook.NotebookInstanceStatus -eq "InService") {
            Write-Host "    🛑 Stopping notebook instance..." -ForegroundColor Red
            aws sagemaker stop-notebook-instance --notebook-instance-name $notebook.NotebookInstanceName
        }
        elseif ($notebook.NotebookInstanceStatus -eq "Stopped") {
            $response = Read-Host "    ❓ Delete stopped notebook instance $($notebook.NotebookInstanceName)? (y/N)"
            if ($response -eq 'y' -or $response -eq 'Y') {
                Write-Host "    🗑️ Deleting notebook instance..." -ForegroundColor Red
                aws sagemaker delete-notebook-instance --notebook-instance-name $notebook.NotebookInstanceName
            }
        }
    }
} else {
    Write-Host "✅ No notebook instances found" -ForegroundColor Green
}

# Check and delete endpoints
$endpoints = Invoke-AWSCommand "aws sagemaker list-endpoints --output json | ConvertFrom-Json" "Checking SageMaker endpoints"
if ($endpoints -and $endpoints.Endpoints.Count -gt 0) {
    Write-Host "📋 Found $($endpoints.Endpoints.Count) endpoints:" -ForegroundColor Yellow
    foreach ($endpoint in $endpoints.Endpoints) {
        Write-Host "  - $($endpoint.EndpointName) [$($endpoint.EndpointStatus)]" -ForegroundColor White
        
        $response = Read-Host "    ❓ Delete endpoint $($endpoint.EndpointName)? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            Write-Host "    🗑️ Deleting endpoint..." -ForegroundColor Red
            aws sagemaker delete-endpoint --endpoint-name $endpoint.EndpointName
        }
    }
} else {
    Write-Host "✅ No endpoints found" -ForegroundColor Green
}

# Check and stop training jobs
$trainingJobs = Invoke-AWSCommand "aws sagemaker list-training-jobs --status-equals InProgress --output json | ConvertFrom-Json" "Checking active training jobs"
if ($trainingJobs -and $trainingJobs.TrainingJobSummaries.Count -gt 0) {
    Write-Host "📋 Found $($trainingJobs.TrainingJobSummaries.Count) active training jobs:" -ForegroundColor Yellow
    foreach ($job in $trainingJobs.TrainingJobSummaries) {
        Write-Host "  - $($job.TrainingJobName) [$($job.TrainingJobStatus)]" -ForegroundColor White
        
        $response = Read-Host "    ❓ Stop training job $($job.TrainingJobName)? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            Write-Host "    🛑 Stopping training job..." -ForegroundColor Red
            aws sagemaker stop-training-job --training-job-name $job.TrainingJobName
        }
    }
} else {
    Write-Host "✅ No active training jobs found" -ForegroundColor Green
}

# Check SageMaker domains and apps
$domains = Invoke-AWSCommand "aws sagemaker list-domains --output json | ConvertFrom-Json" "Checking SageMaker domains"
if ($domains -and $domains.Domains.Count -gt 0) {
    Write-Host "📋 Found $($domains.Domains.Count) SageMaker domains:" -ForegroundColor Yellow
    foreach ($domain in $domains.Domains) {
        Write-Host "  - $($domain.DomainName) [$($domain.Status)]" -ForegroundColor White
        
        # List apps in this domain
        $apps = aws sagemaker list-apps --domain-id-equals $domain.DomainId --output json | ConvertFrom-Json
        if ($apps.Apps.Count -gt 0) {
            Write-Host "    📱 Found $($apps.Apps.Count) apps in domain:" -ForegroundColor Yellow
            foreach ($app in $apps.Apps) {
                if ($app.Status -eq "InService") {
                    Write-Host "      - $($app.AppName) [$($app.Status)] - Deleting..." -ForegroundColor Red
                    aws sagemaker delete-app --domain-id $domain.DomainId --user-profile-name $app.UserProfileName --app-type $app.AppType --app-name $app.AppName
                }
            }
        }
        
        $response = Read-Host "    ❓ Delete domain $($domain.DomainName)? This will delete all user profiles! (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            Write-Host "    🗑️ Deleting domain (this may take several minutes)..." -ForegroundColor Red
            aws sagemaker delete-domain --domain-id $domain.DomainId --retention-policy HomeEfsFileSystem=Delete
        }
    }
} else {
    Write-Host "✅ No SageMaker domains found" -ForegroundColor Green
}

# 2. DIRECTORY SERVICES CLEANUP
Write-Host "`n🏢 DIRECTORY SERVICES CLEANUP" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

$directories = Invoke-AWSCommand "aws ds describe-directories --output json | ConvertFrom-Json" "Checking Directory Services"
if ($directories -and $directories.DirectoryDescriptions.Count -gt 0) {
    Write-Host "📋 Found $($directories.DirectoryDescriptions.Count) directories:" -ForegroundColor Yellow
    foreach ($directory in $directories.DirectoryDescriptions) {
        Write-Host "  - $($directory.Name) [$($directory.Type)] - ID: $($directory.DirectoryId)" -ForegroundColor White
        Write-Host "    Size: $($directory.Size), Stage: $($directory.Stage)" -ForegroundColor Gray
        
        if ($directory.Stage -eq "Active") {
            $response = Read-Host "    ❓ Delete directory $($directory.Name)? This is IRREVERSIBLE! (y/N)"
            if ($response -eq 'y' -or $response -eq 'Y') {
                Write-Host "    🗑️ Deleting directory (this may take 30-40 minutes)..." -ForegroundColor Red
                aws ds delete-directory --directory-id $directory.DirectoryId
                Write-Host "    ⏳ Directory deletion initiated. Check status with: aws ds describe-directories" -ForegroundColor Yellow
            }
        } else {
            Write-Host "    ℹ️ Directory is in $($directory.Stage) stage - cannot delete" -ForegroundColor Blue
        }
    }
} else {
    Write-Host "✅ No active directories found" -ForegroundColor Green
    Write-Host "ℹ️ Note: You may still see Directory Service costs for recently deleted directories" -ForegroundColor Blue
    Write-Host "   These costs will stop appearing in 24-48 hours after deletion" -ForegroundColor Blue
}

# 3. COST IMPACT SUMMARY
Write-Host "`n💰 ESTIMATED COST SAVINGS" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan

Write-Host "Based on your December 2024 usage:" -ForegroundColor White
Write-Host "  🤖 SageMaker: ~`$83.28/month" -ForegroundColor Yellow
Write-Host "  🏢 Directory Service: ~`$37.17/month" -ForegroundColor Yellow
Write-Host "  💵 Total Potential Savings: ~`$120.45/month" -ForegroundColor Green
Write-Host "  📊 Percentage Reduction: ~41% of total AWS costs" -ForegroundColor Green

Write-Host "`n⚠️ IMPORTANT NOTES:" -ForegroundColor Red
Write-Host "- SageMaker notebook instances may take 5-10 minutes to stop" -ForegroundColor Yellow
Write-Host "- Directory Service deletion takes 30-40 minutes and is irreversible" -ForegroundColor Yellow
Write-Host "- Costs may appear for 1-2 billing cycles after resource deletion" -ForegroundColor Yellow
Write-Host "- Always backup important data before deletion" -ForegroundColor Yellow

Write-Host "`n✅ Shutdown script completed!" -ForegroundColor Green
Write-Host "Monitor your costs over the next few days to confirm savings." -ForegroundColor White