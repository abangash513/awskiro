@echo off
echo ========================================
echo WAC DC Quick Verification
echo ========================================
echo.
echo This will run essential health checks.
echo.
echo IMPORTANT: Right-click this file and select "Run as Administrator"
echo.
pause

PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Quick-Verification.ps1" -Domain wac.net

pause
