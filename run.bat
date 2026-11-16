@echo off
:: One-click launcher for Valorant Live Optimizer
:: Elevates to Administrator and launches the PowerShell companion script

cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0valorant_optimizer.ps1"
