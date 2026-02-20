@echo off
REM WAC AD CUTOVER - Emergency Rollback Script
REM Run this file as Domain Admin on AD01 ONLY IF CUTOVER FAILS

echo ========================================
echo WAC AD CUTOVER - EMERGENCY ROLLBACK
echo ========================================
echo.
echo WARNING: This will rollback FSMO roles to AD01/AD02
echo Only run this if the cutover failed!
echo.
echo Press CTRL+C to cancel, or
pause

powershell.exe -ExecutionPolicy Bypass -File "%~dp04-ROLLBACK.ps1"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo ROLLBACK SUCCESSFUL
    echo ========================================
    echo FSMO roles restored to AD01/AD02
) else (
    echo.
    echo ========================================
    echo ROLLBACK FAILED
    echo ========================================
    echo Manual intervention required
)

pause
