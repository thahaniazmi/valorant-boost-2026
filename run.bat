@echo off
setlocal
cd /d "%~dp0"

:: Elevate to Administrator if not already elevated
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting Administrator privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
    exit /b %errorlevel%
)

:: Ensure binary is compiled
if not exist "%~dp0ValorantCompanion.exe" (
    if exist "%~dp0bin\ValorantCompanion.exe" (
        copy /y "%~dp0bin\ValorantCompanion.exe" "%~dp0ValorantCompanion.exe" >nul
    ) else if exist "%~dp0build.bat" (
        echo [i] First-time setup: Compiling native companion binary...
        call "%~dp0build.bat"
    )
)

if not exist "%~dp0ValorantCompanion.exe" (
    echo [X] Error: Could not find or build ValorantCompanion.exe.
    pause
    exit /b 1
)

:: Launch the companion (opens directly into Windows System Tray by default)
start "" "%~dp0ValorantCompanion.exe" %*
exit /b 0
