@echo off
setlocal
cd /d "%~dp0"

:: Elevate to Administrator if not already elevated
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting Administrator privileges to register startup task...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%~f0' -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
    if %errorlevel% neq 0 (
        echo.
        echo [X] Administrator privileges were not granted or UAC prompt was dismissed.
        echo     Please right-click 'Install_AutoStart_Tray.bat' and select 'Run as administrator'.
        echo.
        pause
    )
    exit /b
)

title Valorant Optimizer - Install System Tray Auto-Start
echo ==========================================================
echo   VALORANT COMPANION - SYSTEM TRAY AUTO-START INSTALLER
echo ==========================================================
echo.
echo Installing elevated Windows Scheduled Task...
echo This configures the companion to start silently in your
echo Windows System Tray on login with 0%% CPU overhead.
echo.

:: Ensure native binary is compiled
if not exist "%~dp0ValorantCompanion.exe" (
    if exist "%~dp0bin\ValorantCompanion.exe" (
        copy /y "%~dp0bin\ValorantCompanion.exe" "%~dp0ValorantCompanion.exe" >nul
    ) else if exist "%~dp0build.bat" (
        echo [i] Compiling native companion binary...
        call "%~dp0build.bat"
    )
)

set "TARGET_EXE=%~dp0ValorantCompanion.exe"
if not exist "%TARGET_EXE%" (
    echo [X] Error: %TARGET_EXE% not found.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$a = New-ScheduledTaskAction -Execute '%TARGET_EXE%' -WorkingDirectory '%~dp0'; $t = New-ScheduledTaskTrigger -AtLogOn; $p = New-ScheduledTaskPrincipal -UserId \"$env:USERDOMAIN\$env:USERNAME\" -RunLevel Highest; $s = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0; Register-ScheduledTask -TaskName 'ValorantOptimizerTray' -Action $a -Trigger $t -Principal $p -Settings $s -Force | Out-Null; if ($?) { Write-Host '  [+] SUCCESS: Windows Scheduled Task registered!' -ForegroundColor Green } else { exit 1 }"

if %errorlevel% equ 0 (
    echo.
    echo ----------------------------------------------------------
    echo  [OK] Task Name : ValorantOptimizerTray
    echo  [OK] Trigger   : At Windows User Logon
    echo  [OK] Privilege : Highest (Administrator - No UAC popups)
    echo  [OK] Target    : %TARGET_EXE%
    echo  [OK] Mode      : Silent System Tray (0%% CPU Standby)
    echo ----------------------------------------------------------
) else (
    echo.
    echo [!] Falling back to schtasks command line...
    schtasks /create /tn "ValorantOptimizerTray" /tr "\"%TARGET_EXE%\"" /sc onlogon /rl highest /f
    if %errorlevel% equ 0 (
        echo  [+] Task created successfully via schtasks!
    ) else (
        echo  [X] Failed to create scheduled task.
    )
)

echo.
echo Launching companion in the system tray for this session...
start "" "%TARGET_EXE%"
echo  [+] Active now: Look for the Valorant icon in your system tray.
echo  [+] Configured to auto-start on Windows login.
echo.
echo Setup is complete! Press any key to exit...
pause >nul
exit /b
