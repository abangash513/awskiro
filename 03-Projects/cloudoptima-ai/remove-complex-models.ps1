# Remove complex models with foreign keys from backend directory

Write-Host "Removing complex models from backend..." -ForegroundColor Yellow

$modelsToRemove = @(
    "backend/app/models/user.py",
    "backend/app/models/organization.py",
    "backend/app/models/cloud_connection.py",
    "backend/app/models/ai_workload.py",
    "backend/app/models/resource.py",
    "backend/app/models/cost_data.py",
    "backend/app/models/alert.py",
    "backend/app/models/audit_log.py"
)

foreach ($model in $modelsToRemove) {
    if (Test-Path $model) {
        Remove-Item $model -Force
        Write-Host "  Removed: $model" -ForegroundColor Gray
    }
}

Write-Host "OK Complex models removed" -ForegroundColor Green
Write-Host ""
Write-Host "Remaining models:"
Get-ChildItem "backend/app/models/*.py" | ForEach-Object {
    Write-Host "  - $($_.Name)" -ForegroundColor Cyan
}
