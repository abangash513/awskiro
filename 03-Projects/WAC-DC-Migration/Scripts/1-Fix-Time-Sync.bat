@echo off
echo ========================================
echo WAC Time Sync Fix
echo ========================================
echo.
echo This will fix time synchronization issues.
echo.
echo IMPORTANT: Right-click this file and select "Run as Administrator"
echo.
pause

PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Fix-TimeSync-Simple.ps1"

pause
