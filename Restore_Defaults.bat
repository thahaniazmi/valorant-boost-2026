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
        timeout /t 4 >nul 2>&1 || pause
    )
    exit /b
)

title Restore Windows Defaults
cls
echo ==========================================================
echo       RESTORING STOCK WINDOWS & HARDWARE DEFAULTS
echo ==========================================================
echo.

:: 1. Revert via native companion if available
set "EXE=%~dp0ValorantCompanion.exe"
if not exist "%EXE%" set "EXE=%~dp0bin\ValorantCompanion.exe"

if exist "%EXE%" (
    echo [1/2] Reverting driver locks and companion engine...
    "%EXE%" --restore
    taskkill /f /im ValorantCompanion.exe >nul 2>&1
)

:: 2. Run PowerShell restore script as secondary safety check
set "RESTORE_PS=%~dp0scripts\restore_defaults.ps1"
if not exist "%RESTORE_PS%" set "RESTORE_PS=%~dp0restore_defaults.ps1"

if exist "%RESTORE_PS%" (
    echo [2/2] Running full system restore script...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%RESTORE_PS%"
)

echo.
echo ==========================================================
echo  [+] SUCCESS: All stock defaults restored cleanly!
echo ==========================================================
echo.
timeout /t 5 >nul 2>&1 || pause
exit /b 0
