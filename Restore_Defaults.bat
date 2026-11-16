<# : Batch to PowerShell Polyglot - Double-click this .bat file directly
@echo off
setlocal
:: Elevate to Administrator if not already elevated
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting Administrator privileges to safely restore Windows defaults...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Set script directory and execute embedded PowerShell restore utility
set "SCRIPT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$script = [System.IO.File]::ReadAllText('%~f0'); Invoke-Expression $script"
exit /b
#>

# PowerShell logic starts here
$ScriptDir = if ($env:SCRIPT_DIR -and (Test-Path $env:SCRIPT_DIR)) { $env:SCRIPT_DIR } elseif ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }

$restoreScript = Join-Path $ScriptDir "restore_defaults.ps1"
if (Test-Path $restoreScript) {
    & $restoreScript
} else {
    Write-Host "[!] restore_defaults.ps1 not found in $ScriptDir" -ForegroundColor Red
    pause
}
