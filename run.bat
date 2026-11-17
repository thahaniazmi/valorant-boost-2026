@echo off
cd /d "%~dp0"
call "%~dp0Valorant_Optimizer.bat" %*
exit /b %errorlevel%
