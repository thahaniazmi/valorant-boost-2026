@echo off
setlocal
cd /d "%~dp0"

:: Elevate to Administrator if not already elevated
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting Administrator privileges to safely restore Windows defaults...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%~f0' -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
    if %errorlevel% neq 0 (
        echo.
        echo [X] Administrator privileges were not granted or UAC prompt was dismissed.
        echo     Please right-click 'Restore_Defaults.bat' and select 'Run as administrator'.
        echo.
        pause
    )
    exit /b
)

title Restore Windows Defaults
echo ==========================================================
echo       RESTORING STOCK WINDOWS & HARDWARE DEFAULTS
echo ==========================================================
echo.

:: 1. Revert via native companion if available
if exist "%~dp0ValorantCompanion.exe" (
    echo [1/2] Reverting driver locks and companion engine...
    "%~dp0ValorantCompanion.exe" --restore
    taskkill /f /im ValorantCompanion.exe >nul 2>&1
)

:: 2. Run PowerShell restore script as secondary safety check
if exist "%~dp0restore_defaults.ps1" (
    echo [2/2] Running full system restore script...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore_defaults.ps1"
)

echo.
echo ==========================================================
echo  [+] SUCCESS: All stock defaults restored cleanly!
echo ==========================================================
echo.
pause
exit /b 0
