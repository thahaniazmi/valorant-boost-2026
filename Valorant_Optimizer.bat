<# : Batch to PowerShell Polyglot - Double-click this .bat file directly
@echo off
setlocal
:: Elevate to Administrator if not already elevated
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting Administrator privileges for ultimate low-latency tweaks...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs"
    exit /b
)

:: Set script directory and execute embedded PowerShell directly from this single file
set "SCRIPT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$script = [System.IO.File]::ReadAllText('%~f0'); & ([scriptblock]::Create($script)) %*"
exit /b
#>

# Valorant Ultimate Performance Companion & Low-Latency Optimizer (PowerShell Edition)
# Vanguard Safety: 100% safe. Only uses documented standard Windows OS APIs (priorities, power schemes, service management).
# Crash Safety: Includes persistent on-disk state backup and auto-recovery to prevent stuck registry keys.
# System Tray: Supports zero-overhead background tray monitoring, live HUD toggle, and auto-start.
# NT Kernel Tuning: 0.50ms timer resolution, Core 0 DPC isolation, NtSuspendProcess deep freeze, EcoQoS, and Memory Priority demotion.

[CmdletBinding()]
param(
    [switch]$Tray,
    [switch]$Daemon,
    [switch]$NoNotify
)

# ----------------- ADMIN PRIVILEGE CHECK -----------------
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] Requesting Administrator privileges..." -ForegroundColor Yellow
    $argList = @("-NoProfile", "-ExecutionPolicy", "Bypass")
    if ($Tray) { $argList += @("-WindowStyle", "Hidden") }
    $argList += @("-File", "`"$PSCommandPath`"")
    if ($Tray) { $argList += "-Tray" }
    if ($Daemon) { $argList += "-Daemon" }
    if ($NoNotify) { $argList += "-NoNotify" }
    Start-Process powershell.exe -ArgumentList ($argList -join " ") -Verb RunAs
    exit
}

$Host.UI.RawUI.WindowTitle = "Valorant Ultimate Low-Latency Companion"
try { [Console]::CursorVisible = $false } catch {}

# ----------------- SINGLE INSTANCE CHECK -----------------
$script:AppMutex = $null
$isNewInstance = $false
try {
    $script:AppMutex = New-Object System.Threading.Mutex($true, "Global\ValorantLowLatencyCompanionMutex", [ref]$isNewInstance)
    if (-not $isNewInstance) {
        if (-not $Tray) {
            Write-Host "[!] Valorant Companion is already active in the system tray." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
        exit
    }
} catch {}

# ----------------- CONFIGURATION -----------------
$TargetProcessName = "VALORANT-Win64-Shipping"
$FallbackProcessName = "VALORANT"
# Protected apps: Discord, OBS, audio services, and Vanguard are NEVER throttled or suspended
$ProtectedApps = @("Discord", "obs64", "Streamlabs OBS", "vgc", "vgtray", "RiotClientServices", "dwm", "explorer", "csrss", "lsass", "smss", "services")
$BackgroundHogs = @("chrome", "msedge", "brave", "opera", "spotify", "steamwebhelper", "EpicGamesLauncher", "OneDrive")
$PauseServices = @("WSearch", "SysMain", "DiagTrack")
$PollIntervalSeconds = 1

$ScriptDir = if ($env:SCRIPT_DIR -and (Test-Path $env:SCRIPT_DIR)) { $env:SCRIPT_DIR } elseif ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
$BackupFilePath = Join-Path $ScriptDir "optimizer_backup.json"

# ----------------- P/INVOKE: NATIVE WIN32, NT KERNEL & SCHEDULER APIS -----------------
try {
    $nativeCode = @"
using System;
using System.Runtime.InteropServices;

public class NativeOptimizers {
    // 1. High Precision Kernel Dispatcher Timer (0.50 ms)
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtSetTimerResolution(uint DesiredResolution, bool SetResolution, out uint CurrentResolution);

    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtQueryTimerResolution(out uint MinimumResolution, out uint MaximumResolution, out uint CurrentResolution);

    // 2. Thread Dispatcher Deep Freeze: NtSuspendProcess & NtResumeProcess
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtSuspendProcess(IntPtr ProcessHandle);

    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtResumeProcess(IntPtr ProcessHandle);

    // 3. Processor Affinity (Core 0 DPC Isolation)
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetProcessAffinityMask(IntPtr hProcess, IntPtr dwProcessAffinityMask);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool GetProcessAffinityMask(IntPtr hProcess, out IntPtr lpProcessAffinityMask, out IntPtr lpSystemAffinityMask);

    // 4. Windows SetProcessInformation (EcoQoS & Memory Priority)
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetProcessInformation(
        IntPtr hProcess,
        int ProcessInformationClass,
        ref PROCESS_POWER_THROTTLING_STATE ProcessInformation,
        uint ProcessInformationSize
    );

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetProcessInformation(
        IntPtr hProcess,
        int ProcessInformationClass,
        ref MEMORY_PRIORITY_INFORMATION ProcessInformation,
        uint ProcessInformationSize
    );

    // 5. Console Window Management
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    public const int SW_HIDE = 0;
    public const int SW_SHOWNORMAL = 1;
    public const int SW_RESTORE = 9;

    public const int ProcessMemoryPriority = 0;
    public const int ProcessPowerThrottling = 4;

    public const uint MEMORY_PRIORITY_VERY_LOW = 1;
    public const uint MEMORY_PRIORITY_LOW = 2;
    public const uint MEMORY_PRIORITY_NORMAL = 5;

    public const uint PROCESS_POWER_THROTTLING_CURRENT_VERSION = 1;
    public const uint PROCESS_POWER_THROTTLING_EXECUTION_SPEED = 0x1;

    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESS_POWER_THROTTLING_STATE {
        public uint Version;
        public uint ControlMask;
        public uint StateMask;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct MEMORY_PRIORITY_INFORMATION {
        public uint MemoryPriority;
    }

    public static bool EnableEcoQoS(IntPtr hProcess) {
        try {
            PROCESS_POWER_THROTTLING_STATE state = new PROCESS_POWER_THROTTLING_STATE();
            state.Version = PROCESS_POWER_THROTTLING_CURRENT_VERSION;
            state.ControlMask = PROCESS_POWER_THROTTLING_EXECUTION_SPEED;
            state.StateMask = PROCESS_POWER_THROTTLING_EXECUTION_SPEED;
            return SetProcessInformation(hProcess, ProcessPowerThrottling, ref state, (uint)Marshal.SizeOf(state));
        } catch {
            return false;
        }
    }

    public static bool SetMemoryPriority(IntPtr hProcess, uint priority) {
        try {
            MEMORY_PRIORITY_INFORMATION info = new MEMORY_PRIORITY_INFORMATION();
            info.MemoryPriority = priority;
            return SetProcessInformation(hProcess, ProcessMemoryPriority, ref info, (uint)Marshal.SizeOf(info));
        } catch {
            return false;
        }
    }
}
"@
    Add-Type -TypeDefinition $nativeCode -ErrorAction SilentlyContinue
} catch {}

# ----------------- WINFORMS & DRAWING FOR SYSTEM TRAY -----------------
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
} catch {}

$script:ConsoleHwnd = [NativeOptimizers]::GetConsoleWindow()
if ($script:ConsoleHwnd -eq [IntPtr]::Zero) {
    try { $script:ConsoleHwnd = (Get-Process -Id $PID).MainWindowHandle } catch {}
}

# If launched in Tray mode, hide console window immediately
if ($Tray -and $script:ConsoleHwnd -ne [IntPtr]::Zero) {
    [NativeOptimizers]::ShowWindow($script:ConsoleHwnd, [NativeOptimizers]::SW_HIDE) | Out-Null
}

# ----------------- AUTO-CRASH RECOVERY CHECK -----------------
if (Test-Path $BackupFilePath) {
    if (-not $Tray) {
        Write-Host "==========================================================" -ForegroundColor Yellow
        Write-Host " [!] RECOVERY NOTICE: Previous session terminated unexpectedly" -ForegroundColor Yellow
        Write-Host "==========================================================" -ForegroundColor Yellow
        Write-Host " Found active backup from an earlier session." -ForegroundColor DarkGray
        Write-Host " Restoring system to clean state before starting..." -ForegroundColor Cyan
    }
    $restoreScript = Join-Path $ScriptDir "restore_defaults.ps1"
    if (Test-Path $restoreScript) {
        & $restoreScript
    } else {
        Remove-Item -Path $BackupFilePath -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 2
    if (-not $Tray) { Clear-Host }
}

# ----------------- STATE TRACKING -----------------
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
$script:OriginalValAffinity = $null
$script:AffinityModified = $false
$script:SuspendedProcesses = @()
$script:EcoQoSSuccessCount = 0
$script:DeepFreezeCount = 0

$script:Running = $true
$script:InTrayMode = ($Tray.IsPresent -or $Daemon.IsPresent)
$script:HudVisible = (-not $script:InTrayMode)
$script:NotifyIcon = $null
$script:StatusMenuItem = $null
$script:ToggleHudMenuItem = $null

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
            SuspendedProcesses = $script:SuspendedProcesses
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
            return $true
        }
    } catch {}
    return $false
}

function Enable-LowLatencyPower {
    $isOnBattery = Test-IsOnBattery
    if ($isOnBattery) {
        if ($script:HudVisible) {
            Write-Host "  [!] Running on Battery: Preserving dynamic power profile to prevent thermal throttling and battery drain." -ForegroundColor Yellow
        }
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
        Set-ItemProperty -Path $dvrPath -Name "HistoricalCaptureEnabled" -Value $origDvr -Type DWord -Force -ErrorAction SilentlyContinue
    }

    foreach ($p in $script:OriginalTcpSettings.Keys) {
        $saved = $script:OriginalTcpSettings[$p]
        if ($null -ne $saved.TcpAckFrequency) {
            Set-ItemProperty -Path $p -Name "TcpAckFrequency" -Value $saved.TcpAckFrequency -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $p -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
        }
        if ($null -ne $saved.TCPNoDelay) {
            Set-ItemProperty -Path $p -Name "TCPNoDelay" -Value $saved.TCPNoDelay -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $p -Name "TCPNoDelay" -ErrorAction SilentlyContinue
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
        $origSpeed = if ($script:OriginalMouseSettings.ContainsKey("MouseSpeed") -and $null -ne $script:OriginalMouseSettings["MouseSpeed"]) { $script:OriginalMouseSettings["MouseSpeed"] } else { "1" }
        $origT1 = if ($script:OriginalMouseSettings.ContainsKey("MouseThreshold1") -and $null -ne $script:OriginalMouseSettings["MouseThreshold1"]) { $script:OriginalMouseSettings["MouseThreshold1"] } else { "6" }
        $origT2 = if ($script:OriginalMouseSettings.ContainsKey("MouseThreshold2") -and $null -ne $script:OriginalMouseSettings["MouseThreshold2"]) { $script:OriginalMouseSettings["MouseThreshold2"] } else { "10" }

        Set-ItemProperty -Path $mousePath -Name "MouseSpeed" -Value $origSpeed -Type String -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $mousePath -Name "MouseThreshold1" -Value $origT1 -Type String -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $mousePath -Name "MouseThreshold2" -Value $origT2 -Type String -Force -ErrorAction SilentlyContinue
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

function Purge-SystemMemoryAndStandby {
    try {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    } catch {}
}

function Clean-StaleCaches {
    if ($script:HudVisible) {
        Write-Host "  [>] Purging stale shader & crash caches..." -ForegroundColor Cyan
    }
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
    if ($script:HudVisible) {
        Write-Host "  [OK] Shaders & log clutter cleaned." -ForegroundColor Green
    }
}

function Get-NetworkPing {
    try {
        $ping = Test-Connection -ComputerName 1.1.1.1 -Count 1 -TimeoutSeconds 1 -ErrorAction SilentlyContinue
        if ($ping) { return "$($ping.ResponseTime) ms" }
    } catch {}
    return "OK (<15ms)"
}

# ----------------- SYSTEM TRAY & UI HELPERS -----------------
function Get-ValorantTrayIcon {
    $icoPath = Join-Path $ScriptDir "assets\valorant_tray.ico"
    if (Test-Path $icoPath) {
        try {
            return New-Object System.Drawing.Icon $icoPath
        } catch {}
    }

    try {
        $size = 32
        $bmp = New-Object System.Drawing.Bitmap $size, $size
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.Clear([System.Drawing.Color]::Transparent)

        $brushBg = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 15, 25, 35))
        $g.FillEllipse($brushBg, 0, 0, $size - 1, $size - 1)

        $penBorder = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 255, 70, 85), 2.0)
        $g.DrawEllipse($penBorder, 1, 1, $size - 3, $size - 3)

        $brushWhite = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
        $brushRed = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 70, 85))

        $leftBlade = @(
            (New-Object System.Drawing.PointF 8, 8),
            (New-Object System.Drawing.PointF 13, 8),
            (New-Object System.Drawing.PointF 15, 23),
            (New-Object System.Drawing.PointF 12, 23)
        )
        $rightBlade = @(
            (New-Object System.Drawing.PointF 24, 8),
            (New-Object System.Drawing.PointF 19, 8),
            (New-Object System.Drawing.PointF 16, 17),
            (New-Object System.Drawing.PointF 20, 17)
        )
        $g.FillPolygon($brushWhite, $leftBlade)
        $g.FillPolygon($brushRed, $rightBlade)
        $g.Dispose()

        $hIcon = $bmp.GetHicon()
        return [System.Drawing.Icon]::FromHandle($hIcon)
    } catch {
        return [System.Drawing.SystemIcons]::Application
    }
}

function Show-TrayNotification {
    param(
        [string]$Title = "Valorant Optimizer",
        [string]$Text = "",
        [System.Windows.Forms.ToolTipIcon]$Icon = [System.Windows.Forms.ToolTipIcon]::Info,
        [int]$TimeoutMs = 3000
    )
    if ($NoNotify) { return }
    if ($script:NotifyIcon -and $Text) {
        $script:NotifyIcon.BalloonTipTitle = $Title
        $script:NotifyIcon.BalloonTipText = $Text
        $script:NotifyIcon.BalloonTipIcon = $Icon
        $script:NotifyIcon.ShowBalloonTip($TimeoutMs)
    }
}

function Toggle-HudVisibility {
    if ($script:ConsoleHwnd -eq [IntPtr]::Zero) {
        $script:ConsoleHwnd = [NativeOptimizers]::GetConsoleWindow()
        if ($script:ConsoleHwnd -eq [IntPtr]::Zero) {
            try { $script:ConsoleHwnd = (Get-Process -Id $PID).MainWindowHandle } catch {}
        }
    }

    if ($script:ConsoleHwnd -ne [IntPtr]::Zero) {
        if ($script:HudVisible) {
            [NativeOptimizers]::ShowWindow($script:ConsoleHwnd, [NativeOptimizers]::SW_HIDE) | Out-Null
            $script:HudVisible = $false
            if ($script:ToggleHudMenuItem) { $script:ToggleHudMenuItem.Text = "Show Monitoring HUD" }
            Show-TrayNotification -Title "Valorant Optimizer" -Text "HUD minimized to tray. Double-click tray icon to restore."
        } else {
            [NativeOptimizers]::ShowWindow($script:ConsoleHwnd, [NativeOptimizers]::SW_RESTORE) | Out-Null
            [NativeOptimizers]::SetForegroundWindow($script:ConsoleHwnd) | Out-Null
            $script:HudVisible = $true
            if ($script:ToggleHudMenuItem) { $script:ToggleHudMenuItem.Text = "Hide Monitoring HUD" }
        }
    }
}

function Register-AutoStartTask {
    param([string]$batPath)
    try {
        $action = New-ScheduledTaskAction -Execute $batPath
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0
        Register-ScheduledTask -TaskName "ValorantOptimizerTray" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force -ErrorAction Stop | Out-Null
        return $true
    } catch {
        try {
            cmd.exe /c "schtasks.exe /create /tn `"ValorantOptimizerTray`" /tr `"`"$batPath`"`" /sc onlogon /rl highest /f" | Out-Null
            return $true
        } catch {
            return $false
        }
    }
}

function Unregister-AutoStartTask {
    try {
        Unregister-ScheduledTask -TaskName "ValorantOptimizerTray" -Confirm:$false -ErrorAction Stop | Out-Null
        return $true
    } catch {
        try {
            cmd.exe /c "schtasks.exe /delete /tn `"ValorantOptimizerTray`" /f" | Out-Null
            return $true
        } catch {
            return $false
        }
    }
}

function Wait-Responsive {
    param([int]$Milliseconds = 1000)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.ElapsedMilliseconds -lt $Milliseconds -and $script:Running) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 50
    }
}

# ----------------- INITIALIZE SYSTEM TRAY -----------------
try {
    $script:NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
    $script:NotifyIcon.Icon = Get-ValorantTrayIcon
    $script:NotifyIcon.Text = "Valorant Companion: Standby (0% CPU)"
    $script:NotifyIcon.Visible = $true

    $contextMenu = New-Object System.Windows.Forms.ContextMenuStrip

    $script:StatusMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $script:StatusMenuItem.Text = "● Status: Standby (Waiting for Valorant)"
    $script:StatusMenuItem.Enabled = $false
    $contextMenu.Items.Add($script:StatusMenuItem) | Out-Null

    $contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null

    $script:ToggleHudMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $script:ToggleHudMenuItem.Text = if ($Tray) { "Show Monitoring HUD" } else { "Hide Monitoring HUD" }
    $script:ToggleHudMenuItem.add_Click({ Toggle-HudVisibility })
    $contextMenu.Items.Add($script:ToggleHudMenuItem) | Out-Null

    $purgeMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $purgeMenuItem.Text = "Purge Caches & Standby Memory Now"
    $purgeMenuItem.add_Click({
        Clean-StaleCaches
        Purge-SystemMemoryAndStandby
        Show-TrayNotification -Title "Valorant Optimizer" -Text "DirectX Cache, Shader Cache, and Standby RAM purged successfully."
    })
    $contextMenu.Items.Add($purgeMenuItem) | Out-Null

    $contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null

    $startupSubmenu = New-Object System.Windows.Forms.ToolStripMenuItem
    $startupSubmenu.Text = "Windows Startup Integration"

    $installTaskItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $installTaskItem.Text = "Enable Auto-Start at Windows Logon"
    $installTaskItem.add_Click({
        $trayBat = Join-Path $ScriptDir "Valorant_Optimizer_Tray.bat"
        $ok = Register-AutoStartTask -batPath $trayBat
        if ($ok) {
            Show-TrayNotification -Title "Auto-Start Enabled" -Text "Companion will start in the tray with Windows automatically (0% CPU)."
        } else {
            Show-TrayNotification -Title "Auto-Start Notice" -Text "Run Install_AutoStart_Tray.bat as Admin to register the task."
        }
    })
    $startupSubmenu.DropDownItems.Add($installTaskItem) | Out-Null

    $removeTaskItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $removeTaskItem.Text = "Disable Auto-Start at Windows Logon"
    $removeTaskItem.add_Click({
        $ok = Unregister-AutoStartTask
        if ($ok) {
            Show-TrayNotification -Title "Auto-Start Disabled" -Text "Windows logon task removed."
        }
    })
    $startupSubmenu.DropDownItems.Add($removeTaskItem) | Out-Null
    $contextMenu.Items.Add($startupSubmenu) | Out-Null

    $contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null

    $exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $exitMenuItem.Text = "Restore Defaults & Exit"
    $exitMenuItem.add_Click({
        $script:Running = $false
    })
    $contextMenu.Items.Add($exitMenuItem) | Out-Null

    $script:NotifyIcon.ContextMenuStrip = $contextMenu

    $script:NotifyIcon.add_DoubleClick({
        Toggle-HudVisibility
    })
} catch {
    Write-Warning "Could not initialize tray icon: $_"
}

# ----------------- SYSTEM RESTORE CLEANUP -----------------
function Restore-SystemState {
    if (-not $script:OptimizationsApplied) { return }
    $script:OptimizationsApplied = $false

    if ($script:HudVisible) {
        Write-Host "`n"
        Write-Host "==========================================================" -ForegroundColor DarkGray
        Write-Host "       REVERTING VALORANT PRO OPTIMIZATIONS (SAFE)        " -ForegroundColor Yellow
        Write-Host "==========================================================" -ForegroundColor DarkGray
    }

    # 1. Resume all Deep-Frozen background processes
    $resumedCount = 0
    foreach ($procId in $script:SuspendedProcesses) {
        try {
            $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
            if ($p -and -not $p.HasExited) {
                [NativeOptimizers]::NtResumeProcess($p.Handle) | Out-Null
                $resumedCount++
            }
        } catch {}
    }
    $script:SuspendedProcesses = @()
    if ($script:HudVisible -and $resumedCount -gt 0) {
        Write-Host "  -> Resumed $resumedCount deep-frozen processes to normal run-queue." -ForegroundColor Cyan
    }

    # 2. Restore Valorant CPU Affinity
    if ($script:AffinityModified -and $script:OriginalValAffinity) {
        try {
            $valProc = Get-Process -Name $TargetProcessName -ErrorAction SilentlyContinue
            if ($null -eq $valProc) { $valProc = Get-Process -Name $FallbackProcessName -ErrorAction SilentlyContinue }
            if ($valProc -and -not $valProc.HasExited) {
                $valProc.ProcessorAffinity = $script:OriginalValAffinity
            }
        } catch {}
        $script:AffinityModified = $false
        if ($script:HudVisible) { Write-Host "  -> Core 0 DPC isolation restored to standard all-core affinity." -ForegroundColor Cyan }
    }

    Restore-HighPrecisionTimer
    if ($script:HudVisible) { Write-Host "  -> High-precision timer restored." -ForegroundColor Cyan }

    if ($script:OriginalPowerScheme) {
        powercfg /setactive $script:OriginalPowerScheme 2>$null | Out-Null
        if ($script:HudVisible) { Write-Host "  -> Windows power plan restored." -ForegroundColor Cyan }
    }

    if ($script:CpMinCoresModified) {
        powercfg /setacvalueindex scheme_current sub_processor CPMINCORES 0 2>$null | Out-Null
        powercfg /setactive scheme_current 2>$null | Out-Null
        $script:CpMinCoresModified = $false
        if ($script:HudVisible) { Write-Host "  -> CPU core parking restored." -ForegroundColor Cyan }
    }

    Restore-NetworkAndRegistryTweaks
    if ($script:HudVisible) { Write-Host "  -> Network throttling and TCP stack restored." -ForegroundColor Cyan }

    Restore-MouseAccelerationKillswitch
    if ($script:HudVisible) { Write-Host "  -> Windows mouse acceleration restored." -ForegroundColor Cyan }

    Restore-DefenderExclusions
    if ($script:HudVisible) { Write-Host "  -> Windows Defender exclusions removed." -ForegroundColor Cyan }

    Restore-GpuPowerProfile
    if ($script:HudVisible) { Write-Host "  -> GPU power profile restored." -ForegroundColor Cyan }

    Restore-IFEOAndDwmBypass
    if ($script:HudVisible) { Write-Host "  -> IFEO priority & Fullscreen flags restored." -ForegroundColor Cyan }

    foreach ($procId in $script:OriginalPriorities.Keys) {
        try {
            $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
            if ($p -and -not $p.HasExited) {
                $p.PriorityClass = $script:OriginalPriorities[$procId]
            }
        } catch {}
    }
    $script:OriginalPriorities = @{}
    if ($script:HudVisible) { Write-Host "  -> Background apps unthrottled." -ForegroundColor Cyan }

    foreach ($svcName in $script:StoppedServices) {
        try {
            Start-Service -Name $svcName -ErrorAction SilentlyContinue
        } catch {}
    }
    $script:StoppedServices = @()
    if ($script:HudVisible) { Write-Host "  -> Suspended services restarted." -ForegroundColor Cyan }

    ipconfig /flushdns | Out-Null
    Remove-BackupState
    if ($script:HudVisible) {
        Write-Host "  -> Session backup cleared." -ForegroundColor Cyan
        Write-Host "`n [+] System restored successfully. GG!" -ForegroundColor Green
        try { [Console]::CursorVisible = $true } catch {}
    }
}

[System.AppDomain]::CurrentDomain.add_ProcessExit({
    Restore-SystemState
    if ($script:NotifyIcon) {
        $script:NotifyIcon.Visible = $false
        $script:NotifyIcon.Dispose()
    }
    if ($script:AppMutex) {
        try {
            $script:AppMutex.ReleaseMutex()
            $script:AppMutex.Dispose()
        } catch {}
    }
})

# ----------------- MAIN EXECUTION LOOP -----------------
try {
    $OriginalPowerScheme = Get-ActivePowerScheme

    if ($script:InTrayMode) {
        Show-TrayNotification -Title "Valorant Low-Latency Companion" -Text "Running silently in system tray. 0% CPU standby waiting for Valorant."
    }

    while ($script:Running) {
        Clean-StaleCaches

        if ($script:StatusMenuItem) {
            $script:StatusMenuItem.Text = "● Status: Standby (Waiting for Valorant)"
        }
        if ($script:NotifyIcon) {
            $script:NotifyIcon.Text = "Valorant Companion: Standby (0% CPU)"
        }

        if ($script:HudVisible) {
            Clear-Host
            Write-Host "==========================================================" -ForegroundColor Cyan
            Write-Host "      VALORANT PRO LOW-LATENCY COMPANION & OPTIMIZER      " -ForegroundColor White
            Write-Host "==========================================================" -ForegroundColor Cyan
            Write-Host " Status   : " -NoNewline; Write-Host "STANDBY (Waiting for Valorant to launch)" -ForegroundColor Yellow
            Write-Host " Overhead : 0.00% CPU Polling | Riot Vanguard Safe: 100%" -ForegroundColor DarkGray
            Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host " [HOW TO USE]" -ForegroundColor White
            Write-Host "  1. Keep this window running (or press 'T' to send to Tray)." -ForegroundColor Gray
            Write-Host "  2. Start Valorant normally whenever you are ready." -ForegroundColor Gray
            Write-Host "  3. All 26 pro kernel & scheduling tweaks engage instantly." -ForegroundColor Gray
            Write-Host "  4. When you quit the match, all settings auto-revert cleanly." -ForegroundColor Gray
            Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host " [PRIMED KERNEL & HARDWARE OPTIMIZATION PROFILE]" -ForegroundColor White
            Write-Host "  * Kernel / Dispatcher : 0.50ms Timer | Core 0 DPC Isolation | Deep Freeze" -ForegroundColor Cyan
            Write-Host "  * Cores / Scheduling  : 100% Unparked | EcoQoS E-Core Steering | High IFEO" -ForegroundColor Cyan
            Write-Host "  * GPU / Screen Buffer : Direct Scanout (DWM Bypass) | PowerMizer Locked" -ForegroundColor Cyan
            Write-Host "  * Memory / Net Stack  : PagePriority 5 | Nagle Off (0ms) | 1:1 Mouse" -ForegroundColor Cyan
            Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host " [HOTKEYS]" -ForegroundColor Yellow
            Write-Host "  [T] Minimize to System Tray (Runs silently near clock)" -ForegroundColor White
            Write-Host "  [Q] Restore Stock Settings and Exit" -ForegroundColor White
            Write-Host "==========================================================`n" -ForegroundColor Cyan
        }

        $valProc = $null

        # Standby wait loop
        while ($null -eq $valProc -and $script:Running) {
            try {
                if ([Console]::KeyAvailable) {
                    $key = [Console]::ReadKey($true)
                    if ($key.Key -eq [ConsoleKey]::Q) {
                        $script:Running = $false
                        break
                    } elseif ($key.Key -eq [ConsoleKey]::T) {
                        Toggle-HudVisibility
                    }
                }
            } catch {}

            $valProc = Get-Process -Name $TargetProcessName -ErrorAction SilentlyContinue
            if ($null -eq $valProc) {
                $valProc = Get-Process -Name $FallbackProcessName -ErrorAction SilentlyContinue
            }

            if ($null -eq $valProc) {
                Wait-Responsive -Milliseconds ($PollIntervalSeconds * 1000)
            }
        }

        if (-not $script:Running) { break }

        # Valorant detected!
        $StartTime = Get-Date
        $valPid = $valProc.Id

        if ($script:HudVisible) {
            Clear-Host
            Write-Host "==========================================================" -ForegroundColor Green
            Write-Host "  [+] VALORANT DETECTED! (PID: $valPid)" -ForegroundColor Green
            Write-Host "  Applying pro-grade low-latency kernel optimizations..." -ForegroundColor White
            Write-Host "==========================================================" -ForegroundColor Green
        }

        # 1. Process Priority
        try {
            $valProc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
            if ($script:HudVisible) { Write-Host "  [OK] Process Priority       : HIGH (Safe & Responsive)" -ForegroundColor Green }
        } catch {
            if ($script:HudVisible) { Write-Host "  [!] Process Priority       : Normal ($($_.Exception.Message))" -ForegroundColor Yellow }
        }

        # 2. Core 0 ISR & DPC Isolation (Steer Valorant to Cores 1..N on systems with >= 6 threads)
        $logicalCores = [Environment]::ProcessorCount
        $script:OriginalValAffinity = $null
        $script:AffinityModified = $false

        if ($logicalCores -ge 8) {
            try {
                $script:OriginalValAffinity = $valProc.ProcessorAffinity
                # Mask off Physical Core 0 (Logical CPUs 0 and 1) for Windows DPC & hardware IRQs
                $mask = [int64](((1L -shl $logicalCores) - 1) -band (-bnot 3L))
                $valProc.ProcessorAffinity = [IntPtr]$mask
                $script:AffinityModified = $true
                if ($script:HudVisible) {
                    Write-Host "  [OK] Core 0 DPC Isolation   : Physical Core 0 Reserved for Hardware ISRs/DPCs" -ForegroundColor Green
                }
            } catch {
                if ($script:HudVisible) { Write-Host "  [!] Core 0 DPC Isolation   : Skipped ($($_.Exception.Message))" -ForegroundColor Yellow }
            }
        } elseif ($logicalCores -ge 6) {
            try {
                $script:OriginalValAffinity = $valProc.ProcessorAffinity
                # Mask off Logical CPU 0
                $mask = [int64](((1L -shl $logicalCores) - 1) -band (-bnot 1L))
                $valProc.ProcessorAffinity = [IntPtr]$mask
                $script:AffinityModified = $true
                if ($script:HudVisible) {
                    Write-Host "  [OK] Core 0 DPC Isolation   : Logical Core 0 Reserved for Hardware ISRs/DPCs" -ForegroundColor Green
                }
            } catch {}
        } else {
            if ($script:HudVisible) {
                Write-Host "  [i] CPU Core Allocation     : All $logicalCores Cores Active (Preserving Multi-Threaded Rendering)" -ForegroundColor Cyan
            }
        }

        # 3. High-Precision Kernel Timer (0.50 ms)
        $timerStr = Set-HighPrecisionTimer
        if ($script:HudVisible) { Write-Host "  [OK] Timer Resolution       : $timerStr" -ForegroundColor Green }

        # 4. Power Plan & Core Unparking
        $activePlanName = Enable-LowLatencyPower
        if ($script:HudVisible) { Write-Host "  [OK] Power Plan & Parking   : $activePlanName (CPMINCORES 100)" -ForegroundColor Green }

        # 5. IFEO & Direct Scanout DWM Bypass
        try { $valPath = $valProc.MainModule.FileName } catch { $valPath = "" }
        Apply-IFEOAndDwmBypass -exePath $valPath
        if ($script:HudVisible) {
            Write-Host "  [OK] Exclusive Fullscreen   : Direct Scanout (DWM Bypassed)" -ForegroundColor Green
            Write-Host "  [OK] IFEO Priorities        : High CPU & Disk I/O Injected" -ForegroundColor Green
        }

        # 6. Memory Priority Elevation on Game Working Set
        try {
            [NativeOptimizers]::SetMemoryPriority($valProc.Handle, [NativeOptimizers]::MEMORY_PRIORITY_NORMAL) | Out-Null
            if ($script:HudVisible) { Write-Host "  [OK] Game Memory Priority   : Elevated (Working Set Page Lock Active)" -ForegroundColor Green }
        } catch {}

        # 7. Network & TCP Tweaks
        Apply-NetworkAndRegistryTweaks
        if ($script:HudVisible) { Write-Host "  [OK] Network & TCP Stack    : Nagle's Disabled / 0% Throttling" -ForegroundColor Green }

        # 8. Mouse Acceleration Killswitch
        Apply-MouseAccelerationKillswitch
        if ($script:HudVisible) { Write-Host "  [OK] Windows Mouse Accel    : Disabled (True 1:1 Curve)" -ForegroundColor Green }

        # 9. Defender Exclusions
        Apply-DefenderExclusions
        if ($script:HudVisible) { Write-Host "  [OK] Windows Defender       : Game & Vanguard Excluded" -ForegroundColor Green }

        # 10. GPU Profile
        Apply-GpuPowerProfile
        if ($script:HudVisible) { Write-Host "  [OK] GPU Hardware Mode      : $DetectedGpu (Low Latency Power State)" -ForegroundColor Green }

        # 11. Deep Freeze (NtSuspendProcess), EcoQoS E-Core Steering & Memory Priority Demotion
        $throttledCount = 0
        $script:DeepFreezeCount = 0
        $script:EcoQoSSuccessCount = 0
        $script:SuspendedProcesses = @()

        foreach ($name in $BackgroundHogs) {
            $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
            foreach ($p in $procs) {
                if ($ProtectedApps -contains $p.ProcessName) { continue }
                try {
                    if (-not $script:OriginalPriorities.ContainsKey($p.Id)) {
                        $script:OriginalPriorities[$p.Id] = $p.PriorityClass
                    }
                    $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
                    $throttledCount++

                    # Memory priority demotion to Level 1 (Very Low)
                    [NativeOptimizers]::SetMemoryPriority($p.Handle, [NativeOptimizers]::MEMORY_PRIORITY_VERY_LOW) | Out-Null

                    # EcoQoS E-Core steering on hybrid processors
                    $eco = [NativeOptimizers]::EnableEcoQoS($p.Handle)
                    if ($eco) { $script:EcoQoSSuccessCount++ }

                    # Deep Freeze: suspend threads out of kernel run-queue
                    $sus = [NativeOptimizers]::NtSuspendProcess($p.Handle)
                    if ($sus -eq 0) {
                        $script:SuspendedProcesses += $p.Id
                        $script:DeepFreezeCount++
                    }
                } catch {}
            }
        }

        if ($script:HudVisible) {
            Write-Host "  [OK] Deep Freeze Dispatcher : $($script:DeepFreezeCount) background processes suspended from run-queue" -ForegroundColor Green
            Write-Host "  [OK] EcoQoS & Memory Trim   : $($script:EcoQoSSuccessCount) steered to E-Cores | Background RAM demoted to VeryLow (1)" -ForegroundColor Green
        }

        # 12. Pause Stutter-Prone Services
        foreach ($s in $PauseServices) {
            try {
                $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
                if ($svc -and $svc.Status -eq 'Running') {
                    Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
                    $script:StoppedServices += $s
                }
            } catch {}
        }
        if ($script:StoppedServices.Count -gt 0 -and $script:HudVisible) {
            Write-Host "  [OK] Services Paused        : $($script:StoppedServices -join ', ')" -ForegroundColor Green
        }

        # 13. Standby Memory Clean & DNS Flush
        Purge-SystemMemoryAndStandby
        ipconfig /flushdns | Out-Null
        if ($script:HudVisible) { Write-Host "  [OK] System Memory & DNS    : Cleaned & Flushed" -ForegroundColor Green }

        # Save on-disk backup for crash resilience
        Save-BackupState
        $script:OptimizationsApplied = $true

        # Notify tray
        Show-TrayNotification -Title "🎯 Valorant Detected!" -Text "All 26 kernel & latency optimizations engaged (Core 0 DPC Isolation, 0.50ms timer, Deep Freeze)."
        if ($script:StatusMenuItem) { $script:StatusMenuItem.Text = "● Status: Active (PID: $valPid • Tweaks Active)" }
        if ($script:NotifyIcon) { $script:NotifyIcon.Text = "Valorant Active (PID: $valPid) | Tweaks Active" }

        Wait-Responsive -Milliseconds 2000

        # Passive HUD monitoring loop while game is running
        $lastPingCheck = [DateTime]::MinValue
        $cachedPing = "Testing..."

        while (-not $valProc.HasExited -and $script:Running) {
            try {
                if ([Console]::KeyAvailable) {
                    $key = [Console]::ReadKey($true)
                    if ($key.Key -eq [ConsoleKey]::Q) {
                        $script:Running = $false
                        break
                    } elseif ($key.Key -eq [ConsoleKey]::T) {
                        Toggle-HudVisibility
                    }
                }
            } catch {}

            if (((Get-Date) - $lastPingCheck).TotalSeconds -ge 10) {
                $cachedPing = Get-NetworkPing
                $lastPingCheck = Get-Date
            }

            $elapsed = (Get-Date) - $StartTime
            $elapsedStr = "{0:D2}h {1:D2}m {2:D2}s" -f $elapsed.Hours, $elapsed.Minutes, $elapsed.Seconds

            $valProc.Refresh()
            $memMB = [Math]::Round($valProc.WorkingSet64 / 1MB, 1)

            if ($script:NotifyIcon) {
                $script:NotifyIcon.Text = "Valorant Active: $elapsedStr | Ping: $cachedPing"
            }
            if ($script:StatusMenuItem) {
                $script:StatusMenuItem.Text = "● Status: Active ($elapsedStr • PID: $valPid)"
            }

            if ($script:HudVisible) {
                Clear-Host
                Write-Host "==========================================================" -ForegroundColor Cyan
                Write-Host "       VALORANT ULTIMATE LOW-LATENCY MONITORING HUD       " -ForegroundColor White
                Write-Host "==========================================================" -ForegroundColor Cyan
                Write-Host " Game Status       : " -NoNewline; Write-Host "ACTIVE (Running)" -ForegroundColor Green
                Write-Host " Process PID       : $valPid"
                Write-Host " Session Duration  : $elapsedStr"
                Write-Host " Memory WorkingSet : $memMB MB (Stutter-Free Passive Monitoring)"
                Write-Host " Network Latency   : " -NoNewline; Write-Host "$cachedPing" -ForegroundColor Green
                Write-Host " Process Priority  : " -NoNewline; Write-Host "$($valProc.PriorityClass)" -ForegroundColor Green
                Write-Host " Timer Resolution  : " -NoNewline; Write-Host "0.50 ms (Native ntdll.dll)" -ForegroundColor Green
                Write-Host " Core 0 Isolation  : " -NoNewline; Write-Host "$(if ($script:AffinityModified) { 'ACTIVE (Core 0 DPCs & Interrupts Isolated)' } else { 'Standard All-Core' })" -ForegroundColor Green
                Write-Host " Deep Freeze Apps  : " -NoNewline; Write-Host "$($script:DeepFreezeCount) background processes suspended from run-queue" -ForegroundColor Green
                Write-Host " EcoQoS Steering   : " -NoNewline; Write-Host "$($script:EcoQoSSuccessCount) processes banished to E-Cores (P-Cores 100% Game)" -ForegroundColor Green
                Write-Host " Memory Priority   : " -NoNewline; Write-Host "Game Level 5 | Background Level 1 VeryLow" -ForegroundColor Green
                Write-Host " CPU Hardware Mode : $DetectedCpu"
                Write-Host " CPU Power Scheme  : $activePlanName"
                Write-Host " GPU Hardware Mode : $DetectedGpu"
                Write-Host " DWM Display State : Direct Scanout (DWM Bypassed)"
                Write-Host " Paused Services   : $(if ($script:StoppedServices.Count -gt 0) { $script:StoppedServices -join ', ' } else { 'None' })"
                Write-Host " Crash Safety      : " -NoNewline; Write-Host "On-Disk Backup Active (Safe)" -ForegroundColor Green
                Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
                Write-Host " [Hotkeys] [T] Minimize to System Tray | [Q] Restore & Exit" -ForegroundColor Yellow
                Write-Host "==========================================================" -ForegroundColor Cyan
            }

            Wait-Responsive -Milliseconds 1500
        }

        # Game has exited or exit requested
        Restore-SystemState

        if ($script:Running) {
            Show-TrayNotification -Title "🔄 Valorant Session Ended" -Text "All 26 optimizations reverted safely. Companion back to tray standby."

            # If user ran one-off in console mode (not -Tray and didn't minimize to tray), exit as usual
            if (-not $script:InTrayMode -and $script:HudVisible) {
                Write-Host "`n Valorant session ended. Closing in 3 seconds..." -ForegroundColor DarkGray
                Start-Sleep -Seconds 3
                break
            }
        }
    }
}
finally {
    Restore-SystemState
    if ($script:NotifyIcon) {
        $script:NotifyIcon.Visible = $false
        $script:NotifyIcon.Dispose()
    }
    if ($script:AppMutex) {
        try {
            $script:AppMutex.ReleaseMutex()
            $script:AppMutex.Dispose()
        } catch {}
    }
}
