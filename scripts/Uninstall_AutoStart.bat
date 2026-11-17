@echo off
setlocal
set "ROOT_DIR=%~dp0.."
cd /d "%ROOT_DIR%"

:: Elevate to Administrator if not already elevated
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting Administrator privileges to remove startup task...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%~f0' -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
    if %errorlevel% neq 0 (
        echo.
        echo [X] Administrator privileges were not granted or UAC prompt was dismissed.
        echo     Please right-click and select 'Run as administrator'.
        echo.
        pause
    )
    exit /b
)

title Valorant Companion - Remove Auto-Start Task
echo ==========================================================
echo        VALORANT COMPANION - REMOVE AUTO-START
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
exit /b 0
