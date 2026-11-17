@echo off
setlocal
set "ROOT_DIR=%~dp0.."
cd /d "%ROOT_DIR%"

echo ==========================================================
echo        LAUNCHING VALORANT WITH LOW-LATENCY COMPANION
echo ==========================================================
echo.

:: 1. Launch the Companion in the system tray
echo [1/2] Launching Companion in Windows System Tray...
set "TARGET_EXE=%ROOT_DIR%\ValorantCompanion.exe"
if not exist "%TARGET_EXE%" (
    if exist "%ROOT_DIR%\bin\ValorantCompanion.exe" (
        set "TARGET_EXE=%ROOT_DIR%\bin\ValorantCompanion.exe"
    ) else if exist "%~dp0build.bat" (
        call "%~dp0build.bat"
    )
)
if exist "%TARGET_EXE%" (
    start "" "%TARGET_EXE%"
)

:: 2. Locate and launch Valorant
echo [2/2] Launching Valorant...

set "VAL_STARTED=0"

:: Check common Riot Client paths
set "RIOT_EXE=C:\Riot Games\Riot Client\RiotClientServices.exe"
if exist "%RIOT_EXE%" (
    start "" "%RIOT_EXE%" --launch-product=valorant --launch-patchline=live
    set "VAL_STARTED=1"
    goto :done
)

set "RIOT_EXE_D=D:\Riot Games\Riot Client\RiotClientServices.exe"
if exist "%RIOT_EXE_D%" (
    start "" "%RIOT_EXE_D%" --launch-product=valorant --launch-patchline=live
    set "VAL_STARTED=1"
    goto :done
)

:: Try registry lookup for Riot Client
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\RiotClientServices.exe" /ve 2^>nul') do (
    if exist "%%~b" (
        start "" "%%~b" --launch-product=valorant --launch-patchline=live
        set "VAL_STARTED=1"
        goto :done
    )
)

:: Fallback: Try launching via URI protocol
start "" "riotclient://launch-product=valorant&launch-patchline=live" 2>nul
set "VAL_STARTED=1"

:done
echo.
echo [+] Valorant launched!
echo [+] The Companion is active in your System Tray.
echo     (Look for the Valorant icon near your Windows clock)
echo.
timeout /t 3 >nul
exit /b 0
