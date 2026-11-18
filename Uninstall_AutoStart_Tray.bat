@echo off
setlocal
cd /d "%~dp0"

:: Elevate to Administrator if not already elevated
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting Administrator privileges to remove startup task...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

title Valorant Optimizer - Remove Auto-Start Task
echo ==========================================================
echo   VALORANT OPTIMIZER - REMOVE SYSTEM TRAY AUTO-START
echo ==========================================================
echo.
echo Removing scheduled task 'ValorantOptimizerTray'...

powershell -NoProfile -ExecutionPolicy Bypass -Command "Unregister-ScheduledTask -TaskName 'ValorantOptimizerTray' -Confirm:$false -ErrorAction SilentlyContinue | Out-Null; schtasks /delete /tn 'ValorantOptimizerTray' /f >$null 2>&1"

echo.
echo  [+] SUCCESS: Auto-start scheduled task successfully removed.
echo      The companion will no longer start automatically at logon.
echo.
echo Press any key to exit...
pause >nul
exit /b
