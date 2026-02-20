# FIX WACPRODDC02 CONNECTIVITY AND COMPLETE FSMO TRANSFER
# Run this script ON WACPRODDC02 to fix ADWS connectivity
# Then run the transfer commands from WACPRODDC01

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WACPRODDC02 CONNECTIVITY FIX" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check current ADWS status
Write-Host "Step 1: Checking ADWS service status..." -ForegroundColor Yellow
try {
    $adws = Get-Service ADWS -ErrorAction Stop
    Write-Host "  ADWS Service Found" -ForegroundColor Green
    Write-Host "  Status: $($adws.Status)" -ForegroundColor $(if ($adws.Status -eq "Running") { "Green" } else { "Red" })
    Write-Host "  StartType: $($adws.StartType)" -ForegroundColor White
} catch {
    Write-Host "  ERROR: ADWS service not found!" -ForegroundColor Red
    Write-Host "  This may be Server Core without ADWS installed" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Checking if RSAT-AD-PowerShell is installed..." -ForegroundColor Yellow
    
    $feature = Get-WindowsFeature RSAT-AD-PowerShell
    if ($feature.Installed) {
        Write-Host "  RSAT-AD-PowerShell is installed" -ForegroundColor Green
    } else {
        Write-Host "  RSAT-AD-PowerShell is NOT installed" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Installing RSAT-AD-PowerShell (includes ADWS)..." -ForegroundColor Yellow
        Install-WindowsFeature RSAT-AD-PowerShell -IncludeManagementTools
        Write-Host "  Installation complete!" -ForegroundColor Green
    }
    
    # Check again after install
    $adws = Get-Service ADWS -ErrorAction SilentlyContinue
}

Write-Host ""

# Step 2: Start ADWS if not running
if ($adws) {
    if ($adws.Status -ne "Running") {
        Write-Host "Step 2: Starting ADWS service..." -ForegroundColor Yellow
        try {
            Start-Service ADWS -ErrorAction Stop
            Start-Sleep -Seconds 3
            $adws = Get-Service ADWS
            Write-Host "  ADWS started successfully!" -ForegroundColor Green
            Write-Host "  Status: $($adws.Status)" -ForegroundColor Green
        } catch {
            Write-Host "  ERROR: Failed to start ADWS: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Step 2: ADWS is already running" -ForegroundColor Green
    }
} else {
    Write-Host "Step 2: ADWS service still not available after install attempt" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 3: Set ADWS to start automatically
Write-Host "Step 3: Setting ADWS to start automatically..." -ForegroundColor Yellow
try {
    Set-Service ADWS -StartupType Automatic -ErrorAction Stop
    Write-Host "  ADWS set to Automatic startup" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Could not set startup type: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# Step 4: Check Windows Firewall rules for ADWS (port 9389)
Write-Host "Step 4: Checking Windows Firewall for ADWS (port 9389)..." -ForegroundColor Yellow
try {
    $firewallRules = Get-NetFirewallRule | Where-Object {
        $_.DisplayName -like "*Active Directory Web Services*" -or
        $_.DisplayName -like "*ADWS*"
    }
    
    if ($firewallRules) {
        Write-Host "  Found ADWS firewall rules:" -ForegroundColor Green
        foreach ($rule in $firewallRules) {
            Write-Host "    - $($rule.DisplayName): $($rule.Enabled)" -ForegroundColor White
        }
    } else {
        Write-Host "  No specific ADWS firewall rules found" -ForegroundColor Yellow
        Write-Host "  Checking if port 9389 is allowed..." -ForegroundColor Yellow
        
        # Check if there's a rule for port 9389
        $port9389Rules = Get-NetFirewallPortFilter | Where-Object { $_.LocalPort -eq 9389 }
        if ($port9389Rules) {
            Write-Host "  Found rules for port 9389" -ForegroundColor Green
        } else {
            Write-Host "  No rules found for port 9389" -ForegroundColor Yellow
            Write-Host "  Creating firewall rule for ADWS..." -ForegroundColor Yellow
            
            try {
                New-NetFirewallRule -DisplayName "Active Directory Web Services (TCP-In)" `
                    -Direction Inbound `
                    -Protocol TCP `
                    -LocalPort 9389 `
                    -Action Allow `
                    -Profile Domain `
                    -ErrorAction Stop
                Write-Host "  Firewall rule created successfully!" -ForegroundColor Green
            } catch {
                Write-Host "  WARNING: Could not create firewall rule: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
} catch {
    Write-Host "  WARNING: Could not check firewall: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# Step 5: Test local ADWS connectivity
Write-Host "Step 5: Testing local ADWS connectivity..." -ForegroundColor Yellow
try {
    $testConnection = Test-NetConnection -ComputerName localhost -Port 9389 -WarningAction SilentlyContinue
    if ($testConnection.TcpTestSucceeded) {
        Write-Host "  Port 9389 is accessible locally!" -ForegroundColor Green
    } else {
        Write-Host "  Port 9389 is NOT accessible locally" -ForegroundColor Red
    }
} catch {
    Write-Host "  Could not test connection: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# Step 6: Display network information
Write-Host "Step 6: Network Information..." -ForegroundColor Yellow
$ipConfig = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.IPAddress -notlike "127.*" }
foreach ($ip in $ipConfig) {
    Write-Host "  IP Address: $($ip.IPAddress)" -ForegroundColor White
    Write-Host "  Interface: $($ip.InterfaceAlias)" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WACPRODDC02 FIX COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. From WACPRODDC01, test connectivity:" -ForegroundColor White
Write-Host "   Test-NetConnection 10.70.11.10 -Port 9389" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. If test succeeds, transfer the remaining FSMO roles:" -ForegroundColor White
Write-Host "   Move-ADDirectoryServerOperationMasterRole -Identity WACPRODDC02 -OperationMasterRole RIDMaster,InfrastructureMaster -Force" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Verify final FSMO state:" -ForegroundColor White
Write-Host "   netdom query fsmo" -ForegroundColor Cyan
Write-Host ""
