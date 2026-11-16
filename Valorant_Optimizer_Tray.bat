@echo off
setlocal
cd /d "%~dp0"

:: Check for Administrator privileges; if not elevated, request elevation without showing a persistent terminal
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `\"%~dp0valorant_optimizer.ps1`\" -Tray' -Verb RunAs"
    exit /b
)

:: Launch the companion directly into the Windows System Tray with hidden console window
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0valorant_optimizer.ps1" -Tray
exit /b
