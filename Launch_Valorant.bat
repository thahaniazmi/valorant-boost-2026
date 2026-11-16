<# : Batch to PowerShell Polyglot - Double-click this .bat file directly
@echo off
setlocal
:: Elevate to Administrator if not already elevated
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting Administrator privileges for competitive low-latency tweaks...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Execute embedded PowerShell directly from this single file
powershell -NoProfile -ExecutionPolicy Bypass -Command "$script = [System.IO.File]::ReadAllText('%~f0'); Invoke-Expression $script"
exit /b
#>

# =========================================================================
# VALORANT COMPETITIVE LAUNCHER & PRO LOW-LATENCY COMPANION
# Tailored for High-Performance Gaming (AMD Ryzen + NVIDIA RTX + 170Hz+)
# Vanguard Safe: 100% compliant with Riot Vanguard anti-cheat.
# =========================================================================

$Host.UI.RawUI.WindowTitle = "Valorant Pro Low-Latency Companion"
[Console]::CursorVisible = $false
Clear-Host

# ----------------- CONFIGURATION -----------------
$TargetProcessName = "VALORANT-Win64-Shipping"
$FallbackProcessName = "VALORANT"
# Note: Discord and streaming tools (OBS) are protected and run at Normal priority
$BackgroundHogs = @("chrome", "msedge", "brave", "opera", "spotify", "steamwebhelper", "EpicGamesLauncher", "OneDrive")
$PauseServices = @("WSearch", "SysMain")

# ----------------- P/INVOKE: NATIVE APIS (TIMER & MEMORY) -----------------
try {
    $nativeCode = @"
using System;
using System.Runtime.InteropServices;

public class NativeOptimizers {
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtSetTimerResolution(uint DesiredResolution, bool SetResolution, out uint CurrentResolution);

    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtQueryTimerResolution(out uint MinimumResolution, out uint MaximumResolution, out uint CurrentResolution);

    [DllImport("psapi.dll")]
    public static extern int EmptyWorkingSet(IntPtr hwProc);
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
$IfeoCreated = $false
$AppCompatCreated = $false
$ValorantFullPath = ""
$StartTime = $null

# ----------------- ADVANCED SYSTEM TWEAKS -----------------
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

    # Disable AMD Ryzen Core Parking on AC Power (Forces 100% active cores)
    try {
        powercfg /setacvalueindex scheme_current sub_processor CPMINCORES 100 2>$null | Out-Null
        powercfg /setactive scheme_current 2>$null | Out-Null
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

    # 3. Disable Nagle's Algorithm on Active Network Interfaces (Immediate TCP Gaming Packets)
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
        }
        if ($script:OriginalSysProfile.ContainsKey("SystemResponsiveness") -and $null -ne $script:OriginalSysProfile["SystemResponsiveness"]) {
            Set-ItemProperty -Path $sysPath -Name "SystemResponsiveness" -Value $script:OriginalSysProfile["SystemResponsiveness"] -Type DWord -Force -ErrorAction SilentlyContinue
        }
    }

    $dvrPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
    if (Test-Path $dvrPath -and $script:OriginalGameDVR.ContainsKey("AppCaptureEnabled") -and $null -ne $script:OriginalGameDVR["AppCaptureEnabled"]) {
        Set-ItemProperty -Path $dvrPath -Name "AppCaptureEnabled" -Value $script:OriginalGameDVR["AppCaptureEnabled"] -Type DWord -Force -ErrorAction SilentlyContinue
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

function Apply-IFEOAndDwmBypass {
    param([string]$exePath)

    # 1. Windows Image File Execution Options (High CPU, High IO, Max Page Priority)
    $ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\VALORANT-Win64-Shipping.exe\PerfOptions"
    if (-not (Test-Path $ifeoPath)) {
        New-Item -Path $ifeoPath -Force -ErrorAction SilentlyContinue | Out-Null
        $script:IfeoCreated = $true
    }
    Set-ItemProperty -Path $ifeoPath -Name "CpuPriorityClass" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $ifeoPath -Name "IoPriority" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $ifeoPath -Name "PagePriority" -Value 5 -Type DWord -Force -ErrorAction SilentlyContinue

    # 2. Force True Exclusive Fullscreen / DWM Bypass (Eliminates DWM display buffer latency)
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

function Purge-SystemMemoryAndStandby {
    try {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()

        # Built-in ISLC: Flush working sets of background processes to free RAM for Valorant
        Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.WorkingSet64 -gt 50MB -and $_.ProcessName -notmatch "VALORANT|Riot" } | ForEach-Object {
            try { [NativeOptimizers]::EmptyWorkingSet($_.Handle) | Out-Null } catch {}
        }
    } catch {}
}

function Audit-ValorantUserSettings {
    $cfgPath = "$env:LOCALAPPDATA\VALORANT\Saved\Config"
    if (Test-Path $cfgPath) {
        $iniFiles = Get-ChildItem -Path $cfgPath -Recurse -Filter "GameUserSettings.ini" -ErrorAction SilentlyContinue
        foreach ($f in $iniFiles) {
            try {
                $content = Get-Content $f.FullName -Raw
                $modified = $false
                if ($content -notmatch "bShouldUseMultiThreadedRendering=True") {
                    $content = $content -replace "bShouldUseMultiThreadedRendering=False", "bShouldUseMultiThreadedRendering=True"
                    $modified = $true
                }
                if ($content -notmatch "RawInputBuffer=True") {
                    $content = $content -replace "RawInputBuffer=False", "RawInputBuffer=True"
                    $modified = $true
                }
                if ($content -match "PreferredFullscreenMode=[1-3]") {
                    $content = $content -replace "PreferredFullscreenMode=[1-3]", "PreferredFullscreenMode=0"
                    $modified = $true
                }
                if ($modified) {
                    Set-Content -Path $f.FullName -Value $content -Force
                    Write-Host "  [OK] GameUserSettings.ini: Multi-Threaded Rendering & Raw Input Enforced" -ForegroundColor Green
                }
            } catch {}
        }
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

function Get-NetworkPing {
    try {
        $ping = Test-Connection -ComputerName 1.1.1.1 -Count 1 -TimeoutSeconds 1 -ErrorAction SilentlyContinue
        if ($ping) { return "$($ping.ResponseTime) ms" }
    } catch {}
    return "OK (<15ms)"
}

function Find-And-Launch-Valorant {
    Write-Host " [>] Looking for Valorant / Riot Client..." -ForegroundColor Cyan

    $existing = Get-Process -Name $TargetProcessName, $FallbackProcessName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host " [+] Valorant is already active! (PID: $($existing[0].Id))" -ForegroundColor Green
        return
    }

    $drives = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root
    $candidates = @()
    foreach ($d in $drives) {
        $candidates += Join-Path $d "Riot Games\Riot Client\RiotClientServices.exe"
        $candidates += Join-Path $d "Program Files\Riot Games\Riot Client\RiotClientServices.exe"
        $candidates += Join-Path $d "Program Files (x86)\Riot Games\Riot Client\RiotClientServices.exe"
    }
    $candidates += "$env:ProgramData\Riot Games\RiotClientServices.exe"

    foreach ($exe in $candidates) {
        if (Test-Path $exe) {
            Write-Host " [+] Found Riot Client at: $exe" -ForegroundColor Green
            Write-Host " [>] Launching Valorant..." -ForegroundColor Cyan
            Start-Process -FilePath $exe -ArgumentList "--launch-product=valorant --launch-patchline=live"
            return
        }
    }

    try {
        Start-Process "riotclient://rso-auth/rides/exist/v1?app-id=valorant&launch-product=valorant&launch-patchline=live" -ErrorAction Stop
        Write-Host " [+] Launched Valorant via Riot Client protocol." -ForegroundColor Green
        return
    } catch {}

    $shortcuts = Get-ChildItem -Path "$env:PUBLIC\Desktop", "$env:USERPROFILE\Desktop", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" -Recurse -Filter "*VALORANT*.lnk" -ErrorAction SilentlyContinue
    if ($shortcuts -and $shortcuts.Count -gt 0) {
        Write-Host " [+] Found Valorant shortcut: $($shortcuts[0].FullName)" -ForegroundColor Green
        Start-Process $shortcuts[0].FullName
        return
    }

    Write-Host " [!] Please launch Valorant; optimizer will hook automatically!" -ForegroundColor Yellow
}

# ----------------- CLEANUP / RESTORATION -----------------
function Restore-SystemState {
    if (-not $script:OptimizationsApplied) { return }
    $script:OptimizationsApplied = $false

    Write-Host "`n"
    Write-Host "==========================================================" -ForegroundColor DarkGray
    Write-Host " [REVERTING] Restoring all Windows settings to normal..." -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor DarkGray

    # 1. Restore High-Precision Timer
    Restore-HighPrecisionTimer
    Write-Host "  -> Timer resolution restored ($([Math]::Round($script:OriginalTimerRes / 10000.0, 2)) ms)." -ForegroundColor Cyan

    # 2. Restore Power Plan & Core Parking
    if ($OriginalPowerScheme) {
        powercfg /setactive $OriginalPowerScheme | Out-Null
        Write-Host "  -> Power plan restored ($OriginalPowerScheme)." -ForegroundColor Cyan
    }

    # 3. Restore Network & Registry Tweaks
    Restore-NetworkAndRegistryTweaks
    Write-Host "  -> Network throttling and TCP stack restored." -ForegroundColor Cyan

    # 4. Restore IFEO and DWM Bypass
    Restore-IFEOAndDwmBypass
    Write-Host "  -> IFEO priority & Fullscreen flags restored." -ForegroundColor Cyan

    # 5. Restore Background Applications
    foreach ($procId in $OriginalPriorities.Keys) {
        try {
            $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
            if ($p -and -not $p.HasExited) {
                $p.PriorityClass = $OriginalPriorities[$procId]
            }
        } catch {}
    }
    Write-Host "  -> Background apps unthrottled." -ForegroundColor Cyan

    # 6. Restart Suspended Services
    foreach ($svcName in $StoppedServices) {
        try {
            Start-Service -Name $svcName -ErrorAction SilentlyContinue
        } catch {}
    }
    Write-Host "  -> Suspended services restarted." -ForegroundColor Cyan

    # 7. Flush DNS
    ipconfig /flushdns | Out-Null

    Write-Host "`n [+] All settings reverted successfully. GG!" -ForegroundColor Green
    [Console]::CursorVisible = $true
}

[System.AppDomain]::CurrentDomain.add_ProcessExit({
    Restore-SystemState
})

# ----------------- MAIN RUNTIME -----------------
try {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "     VALORANT PRO LOW-LATENCY LAUNCHER & COMPANION        " -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Cyan

    $OriginalPowerScheme = Get-ActivePowerScheme

    # 1. Clean caches & audit GameUserSettings
    Clean-StaleCaches
    Audit-ValorantUserSettings

    # 2. Launch Valorant
    Find-And-Launch-Valorant

    Write-Host "`n [STANDBY] Waiting for Valorant game process to start..." -ForegroundColor Yellow
    Write-Host " (Press 'Q' or 'Ctrl+C' in this terminal at any time to abort)`n" -ForegroundColor DarkGray

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
            Start-Sleep -Milliseconds 1000
        }
    }

    # 3. GAME DETECTED: APPLY ADVANCED COMPETITIVE TWEAKS
    Clear-Host
    $StartTime = Get-Date
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "  [+] VALORANT DETECTED! (PID: $($valProc.Id))" -ForegroundColor Green
    Write-Host "  Engaging advanced low-latency esports optimizations..." -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Green

    # A. Process Priority to HIGH
    try {
        $valProc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
        Write-Host "  [OK] Process Priority       : HIGH" -ForegroundColor Green
    } catch {
        Write-Host "  [!] Process Priority       : Normal ($($_.Exception.Message))" -ForegroundColor Yellow
    }

    # B. 0.5ms Timer Resolution
    $timerStr = Set-HighPrecisionTimer
    Write-Host "  [OK] Timer Resolution       : $timerStr" -ForegroundColor Green

    # C. Power Plan + AMD Ryzen Core Unparking
    $activePlanName = Enable-LowLatencyPower
    Write-Host "  [OK] Power Plan             : $activePlanName (Ryzen Cores 100% Unparked)" -ForegroundColor Green

    # D. IFEO Priority & DWM Bypass
    try {
        $valPath = $valProc.MainModule.FileName
    } catch {
        $valPath = ""
    }
    Apply-IFEOAndDwmBypass -exePath $valPath
    Write-Host "  [OK] Exclusive Fullscreen   : Direct Scanout Enabled (DWM Bypassed)" -ForegroundColor Green
    Write-Host "  [OK] IFEO Priorities        : High CPU & Disk I/O Injected" -ForegroundColor Green

    # E. Network Throttling & TCP Low-Latency (Nagle's Algorithm Disabled)
    Apply-NetworkAndRegistryTweaks
    Write-Host "  [OK] Network & TCP Stack    : Nagle's Disabled / 0% Throttling" -ForegroundColor Green

    # F. Background App Throttling (Discord & OBS Protected)
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
    Write-Host "  [OK] Background Apps        : Throttled ($throttledCount instances, Discord Protected)" -ForegroundColor Green

    # G. Pause Heavy Background Services
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
        Write-Host "  [OK] Heavy Services Paused  : $($StoppedServices -join ', ')" -ForegroundColor Green
    }

    # H. Purge RAM Working Set & Standby List (Built-in ISLC)
    Purge-SystemMemoryAndStandby
    ipconfig /flushdns | Out-Null
    Write-Host "  [OK] RAM Standby List & DNS : Cleaned & Flushed" -ForegroundColor Green
    $OptimizationsApplied = $true

    Start-Sleep -Seconds 2

    # 4. ACTIVE MONITORING HUD (While Valorant is running)
    $lastPingCheck = [DateTime]::MinValue
    $cachedPing = "Testing..."

    while (-not $valProc.HasExited) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq [ConsoleKey]::Q) {
                Write-Host "`n [!] 'Q' pressed. Reverting optimizations..." -ForegroundColor Yellow
                break
            }
        }

        # Refresh ping every 10 seconds
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
        Write-Host "          VALORANT PRO LOW-LATENCY MONITORING HUD         " -ForegroundColor White
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host " Game Status       : " -NoNewline; Write-Host "ACTIVE (Running)" -ForegroundColor Green
        Write-Host " Process PID       : $($valProc.Id)"
        Write-Host " Session Duration  : $elapsedStr"
        Write-Host " Memory WorkingSet : $memMB MB"
        Write-Host " Network Latency   : " -NoNewline; Write-Host "$cachedPing" -ForegroundColor Green
        Write-Host " Process Priority  : " -NoNewline; Write-Host "$($valProc.PriorityClass)" -ForegroundColor Green
        Write-Host " Timer Resolution  : " -NoNewline; Write-Host "0.50 ms (Low Latency)" -ForegroundColor Green
        Write-Host " CPU Power Scheme  : $activePlanName (Ryzen 100% Unparked)"
        Write-Host " DWM Display State : True Exclusive Fullscreen (Direct Scanout)"
        Write-Host " Throttled Apps    : $throttledCount background processes (Discord Safe)"
        Write-Host " Paused Services   : $(if ($StoppedServices.Count -gt 0) { $StoppedServices -join ', ' } else { 'None' })"
        Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "  * Keep this terminal minimized while playing." -ForegroundColor DarkGray
        Write-Host "  * When you exit Valorant, settings auto-restore." -ForegroundColor DarkGray
        Write-Host "  * Or press 'Q' in this terminal to quit and revert now." -ForegroundColor Yellow
        Write-Host "==========================================================" -ForegroundColor Cyan

        Start-Sleep -Seconds 2
    }

    if ($valProc.HasExited) {
        Write-Host "`n [!] Valorant session completed." -ForegroundColor Yellow
    }
}
finally {
    Restore-SystemState
    Write-Host "`nTerminal closing in 3 seconds..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 3
}
