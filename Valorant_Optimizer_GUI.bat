@echo off
cd /d "%~dp0"
call "%~dp0run.bat" --gui %*
exit /b %errorlevel%
