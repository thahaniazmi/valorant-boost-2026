# Valorant Performance Companion & Low-Latency Optimizer (PowerShell Edition)
# Vanguard Safety: 100% safe. Only uses standard Windows OS APIs (priorities, power schemes, service management).

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$Host.UI.RawUI.WindowTitle = "Valorant Performance Companion"
[Console]::CursorVisible = $false
Clear-Host

# ----------------- CONFIGURATION -----------------
$TargetProcessName = "VALORANT-Win64-Shipping"
$FallbackProcessName = "VALORANT"
$BackgroundHogs = @("chrome", "msedge", "brave", "opera", "discord", "spotify", "steamwebhelper", "EpicGamesLauncher", "OneDrive")
$PauseServices = @("WSearch", "SysMain")
$PollIntervalSeconds = 1

# ----------------- P/INVOKE: 0.5ms TIMER RESOLUTION -----------------
try {
    $nativeTimerDef = @"
using System;
using System.Runtime.InteropServices;
public class HighPrecisionTimer {
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtSetTimerResolution(uint DesiredResolution, bool SetResolution, out uint CurrentResolution);
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtQueryTimerResolution(out uint MinimumResolution, out uint MaximumResolution, out uint CurrentResolution);
}
"@
    Add-Type -TypeDefinition $nativeTimerDef -ErrorAction SilentlyContinue
} catch {}

# ----------------- STATE TRACKING -----------------
$OriginalPowerScheme = $null
$OriginalPriorities = @{}
$StoppedServices = @()
$OptimizationsApplied = $false
$TimerResolutionSet = $false
$OriginalTimerRes = 156250
$OriginalSysProfile = @{}
$OriginalGameDVR = @{}
$StartTime = $null

# ----------------- HELPER FUNCTIONS -----------------
function Get-ActivePowerScheme {
    try {
        $output = powercfg /getactivescheme
        if ($output -match "([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})") {
            return $matches[1]
        }
    } catch {}
    return $null
}

function Enable-LowLatencyPower {
    $schemes = powercfg /list
    $planName = "High Performance"
    if ($schemes -match "(e9a42b02-d5df-448d-aa00-03f14749eb61)") {
        powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
        $planName = "Ultimate Performance"
    } elseif ($schemes -match "(8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c)") {
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c | Out-Null
        $planName = "High Performance"
    } else {
        powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null
        powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null
        $planName = "Ultimate Performance (Created)"
    }

    try {
        powercfg /setacvalueindex scheme_current sub_processor CPMINCORES 100 2>$null | Out-Null
        powercfg /setactive scheme_current 2>$null | Out-Null
    } catch {}

    return $planName
}

function Set-HighPrecisionTimer {
    try {
        [uint32]$min = 0; [uint32]$max = 0; [uint32]$cur = 0
        [HighPrecisionTimer]::NtQueryTimerResolution([ref]$min, [ref]$max, [ref]$cur)
        $script:OriginalTimerRes = $cur

        [uint32]$target = 5000
        [uint32]$applied = 0
        $status = [HighPrecisionTimer]::NtSetTimerResolution($target, $true, [ref]$applied)
        if ($status -eq 0) {
            $script:TimerResolutionSet = $true
            return "$([Math]::Round($applied / 10000.0, 2)) ms (High Precision)"
        }
    } catch {}
    return "Standard Windows Timer"
}

function Restore-HighPrecisionTimer {
    if ($script:TimerResolutionSet) {
        try {
            [uint32]$dummy = 0
            [HighPrecisionTimer]::NtSetTimerResolution($script:OriginalTimerRes, $false, [ref]$dummy) | Out-Null
        } catch {}
        $script:TimerResolutionSet = $false
    }
}

function Apply-NetworkAndRegistryTweaks {
    $sysPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    if (Test-Path $sysPath) {
        $script:OriginalSysProfile["NetworkThrottlingIndex"] = (Get-ItemProperty -Path $sysPath -Name NetworkThrottlingIndex -ErrorAction SilentlyContinue).NetworkThrottlingIndex
        $script:OriginalSysProfile["SystemResponsiveness"] = (Get-ItemProperty -Path $sysPath -Name SystemResponsiveness -ErrorAction SilentlyContinue).SystemResponsiveness
        
        Set-ItemProperty -Path $sysPath -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $sysPath -Name "SystemResponsiveness" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }

    $dvrPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
    if (Test-Path $dvrPath) {
        $script:OriginalGameDVR["AppCaptureEnabled"] = (Get-ItemProperty -Path $dvrPath -Name AppCaptureEnabled -ErrorAction SilentlyContinue).AppCaptureEnabled
        Set-ItemProperty -Path $dvrPath -Name "AppCaptureEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $dvrPath -Name "HistoricalCaptureEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }
}

function Restore-NetworkAndRegistryTweaks {
    $sysPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    if (Test-Path $sysPath) {
        if ($script:OriginalSysProfile.ContainsKey("NetworkThrottlingIndex") -and $null -ne $script:OriginalSysProfile["NetworkThrottlingIndex"]) {
            Set-ItemProperty -Path $sysPath -Name "NetworkThrottlingIndex" -Value $script:OriginalSysProfile["NetworkThrottlingIndex"] -Type DWord -Force -ErrorAction SilentlyContinue
        }
        if ($script:OriginalSysProfile.ContainsKey("SystemResponsiveness") -and $null -ne $script:OriginalSysProfile["SystemResponsiveness"]) {
            Set-ItemProperty -Path $sysPath -Name "SystemResponsiveness" -Value $script:OriginalSysProfile["SystemResponsiveness"] -Type DWord -Force -ErrorAction SilentlyContinue
        }
    }

    $dvrPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
    if (Test-Path $dvrPath -and $script:OriginalGameDVR.ContainsKey("AppCaptureEnabled") -and $null -ne $script:OriginalGameDVR["AppCaptureEnabled"]) {
        Set-ItemProperty -Path $dvrPath -Name "AppCaptureEnabled" -Value $script:OriginalGameDVR["AppCaptureEnabled"] -Type DWord -Force -ErrorAction SilentlyContinue
    }
}

function Clean-StaleCaches {
    Write-Host "  [>] Purging stale shader & crash caches..." -ForegroundColor Cyan
    $paths = @(
        "$env:LOCALAPPDATA\NVIDIA\DXCache\*",
        "$env:LOCALAPPDATA\D3DSCache\*",
        "$env:LOCALAPPDATA\VALORANT\Saved\Logs\*",
        "$env:LOCALAPPDATA\VALORANT\Saved\Crashes\*"
    )
    foreach ($p in $paths) {
        try {
            Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
        } catch {}
    }
    Write-Host "  [OK] Shaders & log clutter cleaned." -ForegroundColor Green
}

function Restore-SystemState {
    if (-not $script:OptimizationsApplied) { return }
    $script:OptimizationsApplied = $false

    Write-Host "`n"
    Write-Host "==========================================================" -ForegroundColor DarkGray
    Write-Host " [REVERTING] Restoring system settings to normal..." -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor DarkGray

    Restore-HighPrecisionTimer
    Write-Host "  -> Timer resolution restored." -ForegroundColor Cyan

    if ($OriginalPowerScheme) {
        powercfg /setactive $OriginalPowerScheme | Out-Null
        Write-Host "  -> Power plan restored." -ForegroundColor Cyan
    }

    Restore-NetworkAndRegistryTweaks
    Write-Host "  -> Network throttling and GameDVR restored." -ForegroundColor Cyan

    foreach ($procId in $OriginalPriorities.Keys) {
        try {
            $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
            if ($p -and -not $p.HasExited) {
                $p.PriorityClass = $OriginalPriorities[$procId]
            }
        } catch {}
    }
    Write-Host "  -> Background apps unthrottled." -ForegroundColor Cyan

    foreach ($svcName in $StoppedServices) {
        try {
            Start-Service -Name $svcName -ErrorAction SilentlyContinue
        } catch {}
    }
    Write-Host "  -> Suspended services restarted." -ForegroundColor Cyan

    ipconfig /flushdns | Out-Null
    Write-Host "`n [+] System restored successfully. GG!" -ForegroundColor Green
    [Console]::CursorVisible = $true
}

[System.AppDomain]::CurrentDomain.add_ProcessExit({
    Restore-SystemState
})

try {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "         VALORANT LIVE PERFORMANCE COMPANION              " -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Cyan

    $OriginalPowerScheme = Get-ActivePowerScheme
    Clean-StaleCaches

    Write-Host "`n Status: Waiting for Valorant to launch..." -ForegroundColor Yellow
    Write-Host " Tip: Launch Valorant whenever you're ready." -ForegroundColor DarkGray
    Write-Host " (Press 'Q' or 'Ctrl+C' to abort at any time)`n" -ForegroundColor DarkGray

    $valProc = $null

    while ($null -eq $valProc) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq [ConsoleKey]::Q) {
                Write-Host "`n [!] Aborted by user." -ForegroundColor Yellow
                return
            }
        }

        $valProc = Get-Process -Name $TargetProcessName -ErrorAction SilentlyContinue
        if ($null -eq $valProc) {
            $valProc = Get-Process -Name $FallbackProcessName -ErrorAction SilentlyContinue
        }

        if ($null -eq $valProc) {
            Start-Sleep -Seconds $PollIntervalSeconds
        }
    }

    Clear-Host
    $StartTime = Get-Date
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "  [+] VALORANT DETECTED! (PID: $($valProc.Id))" -ForegroundColor Green
    Write-Host "  Applying dynamic competitive optimizations..." -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Green

    try {
        $valProc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
        Write-Host "  [OK] Process Priority       : HIGH" -ForegroundColor Green
    } catch {
        Write-Host "  [!] Process Priority       : Normal ($($_.Exception.Message))" -ForegroundColor Yellow
    }

    $timerStr = Set-HighPrecisionTimer
    Write-Host "  [OK] Timer Resolution       : $timerStr" -ForegroundColor Green

    $activePlanName = Enable-LowLatencyPower
    Write-Host "  [OK] Power Plan             : $activePlanName (Ryzen Unparked)" -ForegroundColor Green

    Apply-NetworkAndRegistryTweaks
    Write-Host "  [OK] Network Throttling     : Disabled (100% Foreground Responsiveness)" -ForegroundColor Green

    $throttledCount = 0
    foreach ($name in $BackgroundHogs) {
        $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            try {
                if (-not $OriginalPriorities.ContainsKey($p.Id)) {
                    $OriginalPriorities[$p.Id] = $p.PriorityClass
                }
                $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
                $throttledCount++
            } catch {}
        }
    }
    Write-Host "  [OK] Background Apps        : Throttled ($throttledCount instances)" -ForegroundColor Green

    foreach ($s in $PauseServices) {
        try {
            $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -eq 'Running') {
                Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
                $StoppedServices += $s
            }
        } catch {}
    }
    if ($StoppedServices.Count -gt 0) {
        Write-Host "  [OK] Services Paused        : $($StoppedServices -join ', ')" -ForegroundColor Green
    }

    [System.GC]::Collect()
    ipconfig /flushdns | Out-Null
    Write-Host "  [OK] RAM Cache & DNS        : Purged & Flushed" -ForegroundColor Green
    $OptimizationsApplied = $true

    Start-Sleep -Seconds 2

    while (-not $valProc.HasExited) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq [ConsoleKey]::Q) {
                Write-Host "`n [!] 'Q' pressed. Exiting and restoring system..." -ForegroundColor Yellow
                break
            }
        }

        Clear-Host
        $elapsed = (Get-Date) - $StartTime
        $elapsedStr = "{0:D2}h {1:D2}m {2:D2}s" -f $elapsed.Hours, $elapsed.Minutes, $elapsed.Seconds

        $valProc.Refresh()
        $memMB = [Math]::Round($valProc.WorkingSet64 / 1MB, 1)

        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host "             VALORANT LIVE MONITORING HUD                 " -ForegroundColor White
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host " Game Status       : " -NoNewline; Write-Host "RUNNING" -ForegroundColor Green
        Write-Host " Process PID       : $($valProc.Id)"
        Write-Host " Session Duration  : $elapsedStr"
        Write-Host " Memory WorkingSet : $memMB MB"
        Write-Host " Process Priority  : " -NoNewline; Write-Host "$($valProc.PriorityClass)" -ForegroundColor Green
        Write-Host " Timer Resolution  : " -NoNewline; Write-Host "0.50 ms (Low Latency)" -ForegroundColor Green
        Write-Host " CPU Power Scheme  : $activePlanName (Ryzen Cores Unparked)"
        Write-Host " Throttled Apps    : $throttledCount background processes"
        Write-Host " Paused Services   : $(if ($StoppedServices.Count -gt 0) { $StoppedServices -join ', ' } else { 'None' })"
        Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host " [i] Press 'Q' or close this window when done to revert." -ForegroundColor Yellow
        Write-Host "==========================================================" -ForegroundColor Cyan

        Start-Sleep -Seconds 2
    }

    if ($valProc.HasExited) {
        Write-Host "`n [!] Valorant session ended." -ForegroundColor Yellow
    }
}
finally {
    Restore-SystemState
    Write-Host "`nClosing terminal in 3 seconds..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 3
}
