@echo off
REM WAC AD CUTOVER - Master Execution Script
REM Run this file as Domain Admin on WACPRODDC01

echo ========================================
echo WAC AD CUTOVER - AUTOMATED EXECUTION
echo ========================================
echo.
echo This script will:
echo 1. Check prerequisites
echo 2. Transfer FSMO roles
echo 3. Verify success
echo.
echo Press CTRL+C to cancel, or
pause

echo.
echo ========================================
echo STEP 1: Pre-Cutover Checks
echo ========================================
powershell.exe -ExecutionPolicy Bypass -File "%~dp01-PRE-CUTOVER-CHECK.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo PRE-CUTOVER CHECKS FAILED
    echo ========================================
    echo DO NOT PROCEED WITH CUTOVER
    pause
    exit /b 1
)

echo.
echo ========================================
echo STEP 2: Execute FSMO Transfer
echo ========================================
echo.
echo WARNING: About to transfer FSMO roles!
echo Press CTRL+C to cancel, or
pause

powershell.exe -ExecutionPolicy Bypass -File "%~dp02-EXECUTE-CUTOVER.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo CUTOVER FAILED
    echo ========================================
    echo Run 4-ROLLBACK.ps1 on AD01 to restore
    pause
    exit /b 1
)

echo.
echo ========================================
echo STEP 3: Post-Cutover Verification
echo ========================================
powershell.exe -ExecutionPolicy Bypass -File "%~dp03-POST-CUTOVER-VERIFY.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo VERIFICATION FAILED
    echo ========================================
    echo Review logs and consider rollback
    pause
    exit /b 1
)

echo.
echo ========================================
echo CUTOVER COMPLETE
echo ========================================
echo All FSMO roles successfully transferred!
echo.
echo Next steps:
echo 1. Monitor replication for 2 hours
echo 2. Test user authentication
echo 3. Review event logs
echo.
pause
