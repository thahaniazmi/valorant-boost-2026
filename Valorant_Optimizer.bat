@echo off
setlocal
cd /d "%~dp0"

:: Elevate to Administrator if not already elevated
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting Administrator privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
    if %errorlevel% neq 0 (
        echo.
        echo [X] Administrator privileges were not granted or UAC prompt was dismissed.
        echo     Please right-click 'Valorant_Optimizer.bat' and select 'Run as administrator'.
        echo.
        timeout /t 4 >nul 2>&1 || pause
    )
    exit /b %errorlevel%
)

:: Locate or compile the native companion binary
set "EXE=%~dp0ValorantCompanion.exe"
if not exist "%EXE%" (
    if exist "%~dp0bin\ValorantCompanion.exe" (
        set "EXE=%~dp0bin\ValorantCompanion.exe"
    ) else if exist "%~dp0scripts\build.bat" (
        echo [i] First-time setup: Compiling native companion...
        call "%~dp0scripts\build.bat"
    )
)

if not exist "%EXE%" (
    echo [X] Error: Could not find or build ValorantCompanion.exe.
    pause
    exit /b 1
)

:: Handle explicit command-line flags
if /i "%~1"=="--gui" goto :do_gui
if /i "%~1"=="-gui" goto :do_gui
if /i "%~1"=="--dashboard" goto :do_gui
if /i "%~1"=="-dashboard" goto :do_gui
if /i "%~1"=="--tray" goto :do_tray
if /i "%~1"=="-tray" goto :do_tray
if /i "%~1"=="--restore" goto :do_restore
if /i "%~1"=="-restore" goto :do_restore
if /i "%~1"=="--console" goto :do_console
if /i "%~1"=="-console" goto :do_console

:: Interactive Launcher Menu (Defaults to System Tray after 3 seconds)
title Valorant Low-Latency Companion
cls
echo ==========================================================
echo               VALORANT LOW-LATENCY COMPANION
echo ==========================================================
echo.
echo  [1] Start in System Tray (Quiet background standby)  [Default]
echo  [2] Open Dashboard (Live telemetry ^& settings)
echo  [3] Launch Companion + Valorant together
echo  [4] Install Windows Startup Auto-Start
echo  [5] Restore Stock Defaults ^& Reset Clocks
echo  [Q] Exit
echo.
echo ==========================================================
echo  Starting in System Tray in 3 seconds... (Press 1-5 or Q)
echo ==========================================================

choice /c 12345Q /t 3 /d 1 /n /m ""
if errorlevel 6 goto :do_exit
if errorlevel 5 goto :do_restore
if errorlevel 4 goto :do_install
if errorlevel 3 goto :do_launch_game
if errorlevel 2 goto :do_gui
if errorlevel 1 goto :do_tray

:do_tray
echo.
echo  [+] Launching Companion into the Windows System Tray...
start "" "%EXE%"
echo  [+] Active now: Look for the Valorant icon near your clock.
echo  [+] Optimizations will engage automatically when Valorant starts.
echo.
timeout /t 2 >nul
exit /b 0

:do_gui
echo.
echo  [+] Opening Companion Dashboard...
start "" "%EXE%" --gui
exit /b 0

:do_launch_game
if exist "%~dp0scripts\Launch_Valorant.bat" (
    call "%~dp0scripts\Launch_Valorant.bat"
) else (
    start "" "%EXE%"
)
exit /b 0

:do_install
if exist "%~dp0scripts\Install_AutoStart.bat" (
    call "%~dp0scripts\Install_AutoStart.bat"
)
exit /b 0

:do_restore
if exist "%~dp0Restore_Defaults.bat" (
    call "%~dp0Restore_Defaults.bat"
)
exit /b 0

:do_console
if exist "%~dp0scripts\valorant_optimizer.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\valorant_optimizer.ps1"
) else if exist "%~dp0valorant_optimizer.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0valorant_optimizer.ps1"
)
exit /b 0

:do_exit
exit /b 0
