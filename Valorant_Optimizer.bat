@echo off
setlocal
cd /d "%~dp0"

set "EXE=%~dp0ValorantCompanion.exe"
if not exist "%EXE%" set "EXE=%~dp0bin\ValorantCompanion.exe"

if not exist "%EXE%" (
    if exist "%~dp0scripts\build.bat" (
        call "%~dp0scripts\build.bat"
    ) else (
        echo [X] Error: Could not find ValorantCompanion.exe
        pause
        exit /b 1
    )
)

:: Explicit command-line overrides
if /i "%~1"=="--console" goto :do_console
if /i "%~1"=="-console" goto :do_console
if /i "%~1"=="--restore" goto :do_restore
if /i "%~1"=="-restore" goto :do_restore

:: Launch native companion instantaneously
start "" "%EXE%" %*
exit /b 0

:do_restore
if exist "%~dp0Restore_Defaults.bat" call "%~dp0Restore_Defaults.bat"
exit /b 0

:do_console
if exist "%~dp0scripts\valorant_optimizer.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\valorant_optimizer.ps1"
)
exit /b 0
