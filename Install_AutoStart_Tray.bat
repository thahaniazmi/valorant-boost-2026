@echo off
setlocal
cd /d "%~dp0"

:: Elevate to Administrator if not already elevated
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting Administrator privileges to register startup task...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

title Valorant Optimizer - Install System Tray Auto-Start
echo ==========================================================
echo   VALORANT OPTIMIZER - SYSTEM TRAY AUTO-START INSTALLER
echo ==========================================================
echo.
echo Installing elevated Windows Scheduled Task...
echo This configures the companion to start silently in your
echo Windows System Tray on login with 0%% CPU overhead.
echo.
echo Whenever you launch Valorant, optimizations will engage
echo automatically. When you exit Valorant, defaults are restored!
echo.

set "TARGET_BAT=%~dp0Valorant_Optimizer_Tray.bat"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$a = New-ScheduledTaskAction -Execute '%TARGET_BAT%'; $t = New-ScheduledTaskTrigger -AtLogOn; $p = New-ScheduledTaskPrincipal -UserId \"$env:USERDOMAIN\$env:USERNAME\" -RunLevel Highest; $s = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0; Register-ScheduledTask -TaskName 'ValorantOptimizerTray' -Action $a -Trigger $t -Principal $p -Settings $s -Force | Out-Null; if ($?) { Write-Host '  [+] SUCCESS: Windows Scheduled Task registered!' -ForegroundColor Green } else { exit 1 }"

if %errorlevel% equ 0 (
    echo.
    echo ----------------------------------------------------------
    echo  [OK] Task Name : ValorantOptimizerTray
    echo  [OK] Trigger   : At Windows User Logon
    echo  [OK] Privilege : Highest (Administrator - No UAC popups)
    echo  [OK] Target    : %TARGET_BAT%
    echo ----------------------------------------------------------
) else (
    echo.
    echo [!] Falling back to schtasks command line...
    schtasks /create /tn "ValorantOptimizerTray" /tr "\"%TARGET_BAT%\"" /sc onlogon /rl highest /f
    if %errorlevel% equ 0 (
        echo  [+] Task created successfully via schtasks!
    ) else (
        echo  [X] Failed to create scheduled task.
    )
)

echo.
echo Launching companion in the system tray for this session...
start "" "%TARGET_BAT%"
echo  [+] Active now: Look for the Valorant icon in your system tray.
echo  [+] Configured to auto-start on Windows login.
echo.
echo Setup is complete! Press any key to exit...
pause >nul
exit /b
