@echo off
setlocal
set "ROOT_DIR=%~dp0.."
cd /d "%ROOT_DIR%"

:: Elevate to Administrator if not already elevated
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting Administrator privileges to register startup task...
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

title Valorant Companion - Install Auto-Start Task
echo ==========================================================
echo        VALORANT COMPANION - AUTO-START INSTALLER
echo ==========================================================
echo.
echo Installing elevated Windows Scheduled Task...
echo This configures the companion to start silently in your
echo Windows System Tray on login with 0%% CPU overhead.
echo.

set "TARGET_EXE=%ROOT_DIR%\ValorantCompanion.exe"
if not exist "%TARGET_EXE%" (
    if exist "%ROOT_DIR%\bin\ValorantCompanion.exe" (
        copy /y "%ROOT_DIR%\bin\ValorantCompanion.exe" "%TARGET_EXE%" >nul
    ) else if exist "%~dp0build.bat" (
        echo [i] Compiling companion binary...
        call "%~dp0build.bat"
    )
)

if not exist "%TARGET_EXE%" (
    echo [X] Error: Could not locate or build %TARGET_EXE%.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$a = New-ScheduledTaskAction -Execute '%TARGET_EXE%' -WorkingDirectory '%ROOT_DIR%'; $t = New-ScheduledTaskTrigger -AtLogOn; $p = New-ScheduledTaskPrincipal -UserId \"$env:USERDOMAIN\$env:USERNAME\" -RunLevel Highest; $s = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0; Register-ScheduledTask -TaskName 'ValorantOptimizerTray' -Action $a -Trigger $t -Principal $p -Settings $s -Force | Out-Null; if ($?) { Write-Host '  [+] SUCCESS: Windows Scheduled Task registered!' -ForegroundColor Green } else { exit 1 }"

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
exit /b 0
