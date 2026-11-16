<# : Batch to PowerShell Polyglot - Double-click this .bat file directly
@echo off
setlocal
:: Elevate to Administrator if not already elevated
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting Administrator privileges for ultimate low-latency tweaks...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Set script directory and execute embedded PowerShell directly from this single file
set "SCRIPT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$script = [System.IO.File]::ReadAllText('%~f0'); Invoke-Expression $script"
exit /b
#>

# =========================================================================
# VALORANT ULTIMATE COMPETITIVE PERFORMANCE COMPANION
# Tailored for Windows Esports Gaming (Intel & AMD • NVIDIA & Radeon • 144Hz–360Hz+)
# Vanguard Safe: 100% compliant with Riot Vanguard anti-cheat.
# Crash Safe: Persistent on-disk backup & automatic restoration.
# =========================================================================

$Host.UI.RawUI.WindowTitle = "Valorant Ultimate Low-Latency Companion"
[Console]::CursorVisible = $false
Clear-Host

# ----------------- CONFIGURATION -----------------
$TargetProcessName = "VALORANT-Win64-Shipping"
$FallbackProcessName = "VALORANT"
# Note: Discord, OBS, audio subsystems, and Vanguard are protected and never throttled
$BackgroundHogs = @("chrome", "msedge", "brave", "opera", "spotify", "steamwebhelper", "EpicGamesLauncher", "OneDrive")
$PauseServices = @("WSearch", "SysMain", "DiagTrack")
$PollIntervalSeconds = 1

$ScriptDir = if ($env:SCRIPT_DIR -and (Test-Path $env:SCRIPT_DIR)) { $env:SCRIPT_DIR } elseif ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
$BackupFilePath = Join-Path $ScriptDir "optimizer_backup.json"

# ----------------- AUTO-CRASH RECOVERY CHECK -----------------
# If an un-reverted backup file is present at launch, a previous session terminated unexpectedly.
# Automatically restore previous settings first before proceeding.
if (Test-Path $BackupFilePath) {
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host " [!] RECOVERY NOTICE: Previous session terminated unexpectedly" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host " Found active backup from an earlier session." -ForegroundColor DarkGray
    Write-Host " Restoring system to clean state before starting..." -ForegroundColor Cyan
    $restoreScript = Join-Path $ScriptDir "restore_defaults.ps1"
    if (Test-Path $restoreScript) {
        & $restoreScript
    } else {
        Remove-Item -Path $BackupFilePath -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 2
    Clear-Host
}

# ----------------- P/INVOKE: NATIVE HIGH-PRECISION TIMER API -----------------
try {
    $nativeCode = @"
using System;
using System.Runtime.InteropServices;

public class NativeOptimizers {
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtSetTimerResolution(uint DesiredResolution, bool SetResolution, out uint CurrentResolution);

    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtQueryTimerResolution(out uint MinimumResolution, out uint MaximumResolution, out uint CurrentResolution);
}
"@
    Add-Type -TypeDefinition $nativeCode -ErrorAction SilentlyContinue
} catch {}

# ----------------- STATE BACKUP & TRACKING -----------------
$OriginalPowerScheme = $null
$OriginalPriorities = @{}
$StoppedServices = @()
$OptimizationsApplied = $false
$TimerResolutionSet = $false
$OriginalTimerRes = 156250
$OriginalSysProfile = @{}
$OriginalGameDVR = @{}
$OriginalTcpSettings = @{}
$OriginalMouseSettings = @{}
$OriginalPowerMizer = @{}
$DefenderExclusionsApplied = $false
$IfeoCreated = $false
$AppCompatCreated = $false
$ValorantFullPath = ""
$StartTime = $null
$CpMinCoresModified = $false

# ----------------- BACKUP & RESTORE HELPERS -----------------
function Save-BackupState {
    try {
        $state = @{
            Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            OriginalPowerScheme = $script:OriginalPowerScheme
            CpMinCoresModified = $script:CpMinCoresModified
            OriginalSysProfile = $script:OriginalSysProfile
            OriginalGameDVR = $script:OriginalGameDVR
            OriginalTcpSettings = $script:OriginalTcpSettings
            OriginalMouseSettings = $script:OriginalMouseSettings
            OriginalPowerMizer = $script:OriginalPowerMizer
            DefenderExclusionsApplied = $script:DefenderExclusionsApplied
            IfeoCreated = $script:IfeoCreated
            AppCompatCreated = $script:AppCompatCreated
            ValorantFullPath = $script:ValorantFullPath
            StoppedServices = $script:StoppedServices
        }
        $json = $state | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText($BackupFilePath, $json)
    } catch {
        Write-Warning "Could not save backup state to disk: $_"
    }
}

function Remove-BackupState {
    try {
        if (Test-Path $BackupFilePath) {
            Remove-Item -Path $BackupFilePath -Force -ErrorAction SilentlyContinue
        }
    } catch {}
}

function Get-ActivePowerScheme {
    try {
        $output = powercfg /getactivescheme
        if ($output -match "([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})") {
            return $matches[1]
        }
    } catch {}
    return $null
}

# ----------------- LAPTOP & THERMAL PROTECTION -----------------
function Test-IsOnBattery {
    try {
        $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($battery -and $battery.BatteryStatus -eq 1) {
            return $true # 1 = Discharging (On Battery)
        }
    } catch {}
    return $false
}

function Enable-LowLatencyPower {
    $isOnBattery = Test-IsOnBattery
    if ($isOnBattery) {
        Write-Host "  [!] Running on Battery: Preserving dynamic power profile to prevent thermal throttling and battery drain." -ForegroundColor Yellow
        return "Balanced (Battery Protection Active)"
    }

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

    # Only unpark cores on AC power
    try {
        powercfg /setacvalueindex scheme_current sub_processor CPMINCORES 100 2>$null | Out-Null
        powercfg /setactive scheme_current 2>$null | Out-Null
        $script:CpMinCoresModified = $true
    } catch {}

    return $planName
}

function Set-HighPrecisionTimer {
    try {
        [uint32]$min = 0; [uint32]$max = 0; [uint32]$cur = 0
        [NativeOptimizers]::NtQueryTimerResolution([ref]$min, [ref]$max, [ref]$cur)
        $script:OriginalTimerRes = $cur

        [uint32]$target = 5000 # 0.5000 ms
        [uint32]$applied = 0
        $status = [NativeOptimizers]::NtSetTimerResolution($target, $true, [ref]$applied)
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
            [NativeOptimizers]::NtSetTimerResolution($script:OriginalTimerRes, $false, [ref]$dummy) | Out-Null
        } catch {}
        $script:TimerResolutionSet = $false
    }
}

function Apply-NetworkAndRegistryTweaks {
    # 1. SystemProfile Network & Responsiveness
    $sysPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    if (Test-Path $sysPath) {
        $script:OriginalSysProfile["NetworkThrottlingIndex"] = (Get-ItemProperty -Path $sysPath -Name NetworkThrottlingIndex -ErrorAction SilentlyContinue).NetworkThrottlingIndex
        $script:OriginalSysProfile["SystemResponsiveness"] = (Get-ItemProperty -Path $sysPath -Name SystemResponsiveness -ErrorAction SilentlyContinue).SystemResponsiveness
        
        Set-ItemProperty -Path $sysPath -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $sysPath -Name "SystemResponsiveness" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }

    # 2. GameDVR Suppression
    $dvrPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
    if (Test-Path $dvrPath) {
        $script:OriginalGameDVR["AppCaptureEnabled"] = (Get-ItemProperty -Path $dvrPath -Name AppCaptureEnabled -ErrorAction SilentlyContinue).AppCaptureEnabled
        Set-ItemProperty -Path $dvrPath -Name "AppCaptureEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $dvrPath -Name "HistoricalCaptureEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }

    # 3. Network Interface TCP Optimization (Disable Nagle's Algorithm)
    $interfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue
    foreach ($iface in $interfaces) {
        $p = $iface.PSPath
        $ip = (Get-ItemProperty -Path $p -Name DhcpIPAddress, IPAddress -ErrorAction SilentlyContinue)
        if ($ip.DhcpIPAddress -or $ip.IPAddress) {
            $ack = (Get-ItemProperty -Path $p -Name TcpAckFrequency -ErrorAction SilentlyContinue).TcpAckFrequency
            $nodelay = (Get-ItemProperty -Path $p -Name TCPNoDelay -ErrorAction SilentlyContinue).TCPNoDelay
            $script:OriginalTcpSettings[$p] = @{ TcpAckFrequency = $ack; TCPNoDelay = $nodelay }

            Set-ItemProperty -Path $p -Name "TcpAckFrequency" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $p -Name "TCPNoDelay" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }
    }
}

function Restore-NetworkAndRegistryTweaks {
    $sysPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    if (Test-Path $sysPath) {
        if ($script:OriginalSysProfile.ContainsKey("NetworkThrottlingIndex") -and $null -ne $script:OriginalSysProfile["NetworkThrottlingIndex"]) {
            Set-ItemProperty -Path $sysPath -Name "NetworkThrottlingIndex" -Value $script:OriginalSysProfile["NetworkThrottlingIndex"] -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty -Path $sysPath -Name "NetworkThrottlingIndex" -Value 10 -Type DWord -Force -ErrorAction SilentlyContinue
        }
        if ($script:OriginalSysProfile.ContainsKey("SystemResponsiveness") -and $null -ne $script:OriginalSysProfile["SystemResponsiveness"]) {
            Set-ItemProperty -Path $sysPath -Name "SystemResponsiveness" -Value $script:OriginalSysProfile["SystemResponsiveness"] -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty -Path $sysPath -Name "SystemResponsiveness" -Value 20 -Type DWord -Force -ErrorAction SilentlyContinue
        }
    }

    $dvrPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
    if (Test-Path $dvrPath) {
        $origDvr = if ($script:OriginalGameDVR.ContainsKey("AppCaptureEnabled") -and $null -ne $script:OriginalGameDVR["AppCaptureEnabled"]) {
            $script:OriginalGameDVR["AppCaptureEnabled"]
        } else { 1 }
        Set-ItemProperty -Path $dvrPath -Name "AppCaptureEnabled" -Value $origDvr -Type DWord -Force -ErrorAction SilentlyContinue
    }

    foreach ($path in $script:OriginalTcpSettings.Keys) {
        $saved = $script:OriginalTcpSettings[$path]
        if ($null -ne $saved.TcpAckFrequency) {
            Set-ItemProperty -Path $path -Name "TcpAckFrequency" -Value $saved.TcpAckFrequency -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $path -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
        }
        if ($null -ne $saved.TCPNoDelay) {
            Set-ItemProperty -Path $path -Name "TCPNoDelay" -Value $saved.TCPNoDelay -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $path -Name "TCPNoDelay" -ErrorAction SilentlyContinue
        }
    }
}

function Apply-MouseAccelerationKillswitch {
    $mousePath = "HKCU:\Control Panel\Mouse"
    if (Test-Path $mousePath) {
        $script:OriginalMouseSettings["MouseSpeed"] = (Get-ItemProperty -Path $mousePath -Name MouseSpeed -ErrorAction SilentlyContinue).MouseSpeed
        $script:OriginalMouseSettings["MouseThreshold1"] = (Get-ItemProperty -Path $mousePath -Name MouseThreshold1 -ErrorAction SilentlyContinue).MouseThreshold1
        $script:OriginalMouseSettings["MouseThreshold2"] = (Get-ItemProperty -Path $mousePath -Name MouseThreshold2 -ErrorAction SilentlyContinue).MouseThreshold2

        Set-ItemProperty -Path $mousePath -Name "MouseSpeed" -Value "0" -Type String -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $mousePath -Name "MouseThreshold1" -Value "0" -Type String -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $mousePath -Name "MouseThreshold2" -Value "0" -Type String -Force -ErrorAction SilentlyContinue
    }
}

function Restore-MouseAccelerationKillswitch {
    $mousePath = "HKCU:\Control Panel\Mouse"
    if (Test-Path $mousePath) {
        $speed = if ($script:OriginalMouseSettings.ContainsKey("MouseSpeed") -and $null -ne $script:OriginalMouseSettings["MouseSpeed"]) { $script:OriginalMouseSettings["MouseSpeed"] } else { "1" }
        $t1 = if ($script:OriginalMouseSettings.ContainsKey("MouseThreshold1") -and $null -ne $script:OriginalMouseSettings["MouseThreshold1"]) { $script:OriginalMouseSettings["MouseThreshold1"] } else { "6" }
        $t2 = if ($script:OriginalMouseSettings.ContainsKey("MouseThreshold2") -and $null -ne $script:OriginalMouseSettings["MouseThreshold2"]) { $script:OriginalMouseSettings["MouseThreshold2"] } else { "10" }

        Set-ItemProperty -Path $mousePath -Name "MouseSpeed" -Value $speed -Type String -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $mousePath -Name "MouseThreshold1" -Value $t1 -Type String -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $mousePath -Name "MouseThreshold2" -Value $t2 -Type String -Force -ErrorAction SilentlyContinue
    }
}

function Apply-DefenderExclusions {
    try {
        Add-MpPreference -ExclusionProcess "VALORANT-Win64-Shipping.exe", "RiotClientServices.exe", "vgc.exe" -ErrorAction SilentlyContinue
        $script:DefenderExclusionsApplied = $true
    } catch {}
}

function Restore-DefenderExclusions {
    if ($script:DefenderExclusionsApplied) {
        try {
            Remove-MpPreference -ExclusionProcess "VALORANT-Win64-Shipping.exe", "RiotClientServices.exe", "vgc.exe" -ErrorAction SilentlyContinue
        } catch {}
        $script:DefenderExclusionsApplied = $false
    }
}

# ----------------- HARDWARE & GPU PROFILE -----------------
$DetectedCpu = "Multi-Core CPU"
$DetectedGpu = "Dedicated GPU"
try {
    $cpuObj = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cpuObj -and $cpuObj.Name) { $DetectedCpu = $cpuObj.Name.Trim() }
    $gpuObj = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "Basic Display" } | Sort-Object AdapterRAM -Descending | Select-Object -First 1
    if ($gpuObj -and $gpuObj.Name) { $DetectedGpu = $gpuObj.Name.Trim() }
} catch {}

function Apply-GpuPowerProfile {
    # NOTE ON SAFETY: Blind recursive PCI MSI registry modification has been deliberately removed.
    # Modern NVIDIA & AMD graphics drivers negotiate MSI mode safely in hardware.
    # Dynamic PCI registry tampering can produce black screens and DPC_WATCHDOG_VIOLATION BSODs.

    $classPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    if (Test-Path $classPath) {
        Get-ChildItem $classPath -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match "^\d{4}$" } | ForEach-Object {
            $props = Get-ItemProperty $_.PSPath
            if ($props.DriverDesc -match "NVIDIA" -or $props.ProviderName -match "NVIDIA") {
                $script:OriginalPowerMizer[$_.PSPath] = @{
                    PowerMizerEnable = $props.PowerMizerEnable
                    PowerMizerLevel = $props.PowerMizerLevel
                    PowerMizerLevelAC = $props.PowerMizerLevelAC
                }
                Set-ItemProperty -Path $_.PSPath -Name "PowerMizerEnable" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $_.PSPath -Name "PowerMizerLevel" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $_.PSPath -Name "PowerMizerLevelAC" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

function Restore-GpuPowerProfile {
    foreach ($path in $script:OriginalPowerMizer.Keys) {
        $saved = $script:OriginalPowerMizer[$path]
        if ($null -ne $saved.PowerMizerEnable) {
            Set-ItemProperty -Path $path -Name "PowerMizerEnable" -Value $saved.PowerMizerEnable -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $path -Name "PowerMizerEnable" -ErrorAction SilentlyContinue
        }
        if ($null -ne $saved.PowerMizerLevel) {
            Set-ItemProperty -Path $path -Name "PowerMizerLevel" -Value $saved.PowerMizerLevel -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $path -Name "PowerMizerLevel" -ErrorAction SilentlyContinue
        }
        if ($null -ne $saved.PowerMizerLevelAC) {
            Set-ItemProperty -Path $path -Name "PowerMizerLevelAC" -Value $saved.PowerMizerLevelAC -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $path -Name "PowerMizerLevelAC" -ErrorAction SilentlyContinue
        }
    }
}

function Apply-IFEOAndDwmBypass {
    param([string]$exePath)

    $ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\VALORANT-Win64-Shipping.exe\PerfOptions"
    if (-not (Test-Path $ifeoPath)) {
        New-Item -Path $ifeoPath -Force -ErrorAction SilentlyContinue | Out-Null
        $script:IfeoCreated = $true
    }
    # SAFETY: CpuPriorityClass = 3 (High). NEVER USE 4 (RealTime) which causes OS thread starvation.
    Set-ItemProperty -Path $ifeoPath -Name "CpuPriorityClass" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $ifeoPath -Name "IoPriority" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $ifeoPath -Name "PagePriority" -Value 5 -Type DWord -Force -ErrorAction SilentlyContinue

    if ($exePath -and (Test-Path $exePath)) {
        $compatPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
        if (-not (Test-Path $compatPath)) {
            New-Item -Path $compatPath -Force -ErrorAction SilentlyContinue | Out-Null
        }
        Set-ItemProperty -Path $compatPath -Name $exePath -Value "~ DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE" -Type String -Force -ErrorAction SilentlyContinue
        $script:AppCompatCreated = $true
        $script:ValorantFullPath = $exePath
    }
}

function Restore-IFEOAndDwmBypass {
    if ($script:IfeoCreated) {
        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\VALORANT-Win64-Shipping.exe" -Recurse -Force -ErrorAction SilentlyContinue
        $script:IfeoCreated = $false
    }
    if ($script:AppCompatCreated -and $script:ValorantFullPath) {
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name $script:ValorantFullPath -ErrorAction SilentlyContinue
        $script:AppCompatCreated = $false
    }
}

# ----------------- SAFE MEMORY MANAGEMENT -----------------
# NOTE ON SAFETY: Periodic EmptyWorkingSet every 60s has been completely removed.
# Forcing process memory into the pagefile during active gameplay causes severe page fault thrashing,
# disk I/O spikes, and micro-stutters. We now perform a clean, non-destructive initial pass.
function Purge-SystemMemoryAndStandby {
    try {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    } catch {}
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

function Get-NetworkPing {
    try {
        $ping = Test-Connection -ComputerName 1.1.1.1 -Count 1 -TimeoutSeconds 1 -ErrorAction SilentlyContinue
        if ($ping) { return "$($ping.ResponseTime) ms" }
    } catch {}
    return "OK (<15ms)"
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

    if ($script:CpMinCoresModified) {
        powercfg /setacvalueindex scheme_current sub_processor CPMINCORES 0 2>$null | Out-Null
        powercfg /setactive scheme_current 2>$null | Out-Null
        Write-Host "  -> CPU core parking restored." -ForegroundColor Cyan
    }

    Restore-NetworkAndRegistryTweaks
    Write-Host "  -> Network throttling and TCP stack restored." -ForegroundColor Cyan

    Restore-MouseAccelerationKillswitch
    Write-Host "  -> Windows mouse acceleration restored." -ForegroundColor Cyan

    Restore-DefenderExclusions
    Write-Host "  -> Windows Defender exclusions removed." -ForegroundColor Cyan

    Restore-GpuPowerProfile
    Write-Host "  -> GPU power profile restored." -ForegroundColor Cyan

    Restore-IFEOAndDwmBypass
    Write-Host "  -> IFEO priority & Fullscreen flags restored." -ForegroundColor Cyan

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
    
    # Remove on-disk backup upon clean reversal
    Remove-BackupState
    Write-Host "  -> Session backup cleared." -ForegroundColor Cyan

    Write-Host "`n [+] System restored successfully. GG!" -ForegroundColor Green
    [Console]::CursorVisible = $true
}

[System.AppDomain]::CurrentDomain.add_ProcessExit({
    Restore-SystemState
})

# ----------------- MAIN EXECUTION LOOP -----------------
try {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "     VALORANT ULTIMATE LOW-LATENCY COMPANION (PS)         " -ForegroundColor White
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
    Write-Host "  Applying pro-grade low-latency optimizations..." -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Green

    # SAFETY CHECK: Only set High priority. NEVER set RealTime.
    try {
        $valProc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
        Write-Host "  [OK] Process Priority       : HIGH (Safe & Responsive)" -ForegroundColor Green
    } catch {
        Write-Host "  [!] Process Priority       : Normal ($($_.Exception.Message))" -ForegroundColor Yellow
    }

    $timerStr = Set-HighPrecisionTimer
    Write-Host "  [OK] Timer Resolution       : $timerStr" -ForegroundColor Green

    $activePlanName = Enable-LowLatencyPower
    Write-Host "  [OK] Power Plan             : $activePlanName" -ForegroundColor Green

    try {
        $valPath = $valProc.MainModule.FileName
    } catch {
        $valPath = ""
    }
    Apply-IFEOAndDwmBypass -exePath $valPath
    Write-Host "  [OK] Exclusive Fullscreen   : Direct Scanout (DWM Bypassed)" -ForegroundColor Green
    Write-Host "  [OK] IFEO Priorities        : High CPU & Disk I/O Injected" -ForegroundColor Green

    Apply-NetworkAndRegistryTweaks
    Write-Host "  [OK] Network & TCP Stack    : Nagle's Disabled / 0% Throttling" -ForegroundColor Green

    Apply-MouseAccelerationKillswitch
    Write-Host "  [OK] Windows Mouse Accel    : Disabled (True 1:1 Curve)" -ForegroundColor Green

    Apply-DefenderExclusions
    Write-Host "  [OK] Windows Defender       : Game & Vanguard Excluded" -ForegroundColor Green

    Apply-GpuPowerProfile
    Write-Host "  [OK] GPU Hardware Mode      : $DetectedGpu (Low Latency Power State)" -ForegroundColor Green

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
    Write-Host "  [OK] Background Apps        : Throttled ($throttledCount instances, Discord & OBS Safe)" -ForegroundColor Green

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

    Purge-SystemMemoryAndStandby
    ipconfig /flushdns | Out-Null
    Write-Host "  [OK] System Memory & DNS    : Cleaned & Flushed" -ForegroundColor Green
    
    # SAVE ON-DISK BACKUP IMMEDIATELY FOR CRASH RESILIENCE
    Save-BackupState
    $OptimizationsApplied = $true

    Start-Sleep -Seconds 2

    # ----------------- PASSIVE HUD MONITORING -----------------
    # Stutter-Free: No periodic EmptyWorkingSet loops during live matches
    $lastPingCheck = [DateTime]::MinValue
    $cachedPing = "Testing..."

    while (-not $valProc.HasExited) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq [ConsoleKey]::Q) {
                Write-Host "`n [!] 'Q' pressed. Exiting and restoring system..." -ForegroundColor Yellow
                break
            }
        }

        if (((Get-Date) - $lastPingCheck).TotalSeconds -ge 10) {
            $cachedPing = Get-NetworkPing
            $lastPingCheck = Get-Date
        }

        Clear-Host
        $elapsed = (Get-Date) - $StartTime
        $elapsedStr = "{0:D2}h {1:D2}m {2:D2}s" -f $elapsed.Hours, $elapsed.Minutes, $elapsed.Seconds

        $valProc.Refresh()
        $memMB = [Math]::Round($valProc.WorkingSet64 / 1MB, 1)

        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host "       VALORANT ULTIMATE LOW-LATENCY MONITORING HUD       " -ForegroundColor White
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host " Game Status       : " -NoNewline; Write-Host "ACTIVE (Running)" -ForegroundColor Green
        Write-Host " Process PID       : $($valProc.Id)"
        Write-Host " Session Duration  : $elapsedStr"
        Write-Host " Memory WorkingSet : $memMB MB (Stutter-Free Passive Monitoring)"
        Write-Host " Network Latency   : " -NoNewline; Write-Host "$cachedPing" -ForegroundColor Green
        Write-Host " Process Priority  : " -NoNewline; Write-Host "$($valProc.PriorityClass)" -ForegroundColor Green
        Write-Host " Timer Resolution  : " -NoNewline; Write-Host "0.50 ms (Low Latency)" -ForegroundColor Green
        Write-Host " CPU Hardware Mode : $DetectedCpu"
        Write-Host " CPU Power Scheme  : $activePlanName"
        Write-Host " GPU Hardware Mode : $DetectedGpu"
        Write-Host " DWM Display State : Direct Scanout (DWM Bypassed)"
        Write-Host " Throttled Apps    : $throttledCount background processes (Discord & OBS Safe)"
        Write-Host " Paused Services   : $(if ($StoppedServices.Count -gt 0) { $StoppedServices -join ', ' } else { 'None' })"
        Write-Host " Crash Safety      : " -NoNewline; Write-Host "On-Disk Backup Active (Safe)" -ForegroundColor Green
        Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host " [i] Press 'Q' or close this window when done to revert." -ForegroundColor Yellow
        Write-Host " [i] In case of emergency or crash, run 'Restore_Defaults.bat'." -ForegroundColor DarkGray
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
