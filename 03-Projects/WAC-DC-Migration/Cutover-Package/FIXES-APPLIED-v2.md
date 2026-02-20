# Cutover Script Fixes - Version 2
**Date:** February 8, 2026 09:30 AM
**Previous Attempt:** Partial success (1 of 5 roles transferred)

## Issues Found in Latest Cutover (09:19:39)

### Results:
- ✅ PDC Emulator: Successfully transferred to WACPRODDC01
- ❌ Schema Master: Failed - Access denied (not in Schema Admins)
- ❌ Domain Naming Master: Failed - Verification logic bug
- ❌ RID Pool Manager: Failed - Cannot contact WACPRODDC02
- ❌ Infrastructure Master: Failed - Cannot contact WACPRODDC02

## Fixes Applied to 2-EXECUTE-CUTOVER.ps1

### 1. Fixed FSMO Role Verification Logic
**Problem:** Verification was using wrong method, causing false failures
**Fix:** 
- Added proper verification for each role type
- Domain roles use `Get-ADDomain`
- Forest roles use `Get-ADForest`
- Now shows current holder in logs

### 2. Made Schema Admins Membership Required
**Problem:** Script only warned about missing Schema Admins, then failed during transfer
**Fix:**
- Changed from WARNING to ERROR
- Script now exits if user is not in Schema Admins
- Provides clear instructions on how to fix

### 3. Improved ADWS Check on WACPRODDC02
**Problem:** Simple check failed, but didn't try alternatives
**Fix:**
- Added fallback check using AD cmdlets
- Tries to start ADWS if stopped
- Better error messages with fix instructions
- Exits if WACPRODDC02 is not reachable

## Prerequisites Before Next Run

### 1. Add User to Schema Admins (REQUIRED)
```powershell
# Run on any DC as Domain Admin
Add-ADGroupMember -Identity "Schema Admins" -Members "arifb"
```

### 2. Fix ADWS on WACPRODDC02 (REQUIRED)
Option A - If ADWS service exists:
```powershell
# On WACPRODDC02
Get-Service ADWS
Start-Service ADWS
Set-Service ADWS -StartupType Automatic
```

Option B - If ADWS doesn't exist (Server Core):
```powershell
# Check if it's installed
Get-WindowsFeature | Where-Object {$_.Name -eq "RSAT-AD-PowerShell"}

# Install if missing
Install-WindowsFeature RSAT-AD-PowerShell -IncludeManagementTools
```

### 3. Log Out and Back In (REQUIRED)
After adding to Schema Admins, the user MUST log out and back in for group membership to take effect.

## Current FSMO State

**After partial cutover:**
- PDC Emulator: WACPRODDC01 ✅ (MOVED)
- Schema Master: AD01 (NOT MOVED)
- Domain Naming Master: AD01 (NOT MOVED)  
- RID Pool Manager: AD02 (NOT MOVED)
- Infrastructure Master: AD02 (NOT MOVED)

**Target state:**
- PDC Emulator: WACPRODDC01 ✅
- Schema Master: WACPRODDC01
- Domain Naming Master: WACPRODDC01
- RID Pool Manager: WACPRODDC02
- Infrastructure Master: WACPRODDC02

## Next Steps

1. **Fix prerequisites** (see above)
2. **Verify fixes:**
   ```powershell
   # Check group membership
   whoami /groups | findstr "Schema Admins"
   
   # Check ADWS on WACPRODDC02
   Get-Service ADWS -ComputerName WACPRODDC02
   ```

3. **Run cutover again:**
   ```powershell
   cd C:\Users\arifb\Desktop\Cutover-Package\Scripts
   .\2-EXECUTE-CUTOVER.ps1
   ```

4. **The script will now:**
   - Verify Schema Admins membership (exit if missing)
   - Verify ADWS on WACPRODDC02 (exit if not working)
   - Skip PDC Emulator (already transferred)
   - Transfer remaining 4 roles
   - Verify each transfer properly

## Rollback Option

If you need to rollback the PDC Emulator transfer:
```powershell
.\4-ROLLBACK.ps1
```

This will move all roles back to AD01/AD02.

---
**Script Version:** 2.0
**Updated By:** Kiro AI Assistant
