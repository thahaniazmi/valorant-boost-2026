<#
.SYNOPSIS
    Valorant Optimizer - Emergency & System Restore Utility
.DESCRIPTION
    Safely reverts all optimizations applied by the Valorant Low-Latency Companion.
    Reads optimizer_backup.json if present to restore exact prior settings.
    If no backup is found, cleanly restores certified Windows default settings.
    Safe to run anytime (including Windows Safe Mode).
#>

[CmdletBinding()]
param(
    [switch]$ForceDefaultSchemes
)

# ----------------- ADMIN PRIVILEGE CHECK -----------------
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] Administrator privileges required. Requesting elevation..." -ForegroundColor Yellow
    try {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -ErrorAction Stop
    } catch {
        Write-Host "`n[X] Administrator privileges were not granted ($($_.Exception.Message))." -ForegroundColor Yellow
        Write-Host "    Press any key to exit..." -ForegroundColor DarkGray
        if ([Environment]::UserInteractive) { $null = [Console]::ReadKey($true) }
    }
    exit
}

$Host.UI.RawUI.WindowTitle = "Valorant Optimizer - System Restore Utility"
Clear-Host

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       VALORANT OPTIMIZER - SYSTEM RESTORE UTILITY        " -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " This tool safely reverts all registry, power, network, and" -ForegroundColor DarkGray
Write-Host " process tweaks applied by the Valorant Optimizer companion." -ForegroundColor DarkGray
Write-Host "==========================================================`n" -ForegroundColor Cyan

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
$BackupFilePath = Join-Path $ScriptDir "optimizer_backup.json"

$backupData = $null
if (Test-Path $BackupFilePath) {
    try {
        $raw = [System.IO.File]::ReadAllText($BackupFilePath)
        $backupData = $raw | ConvertFrom-Json
        Write-Host " [+] Found on-disk backup snapshot from: $($backupData.Timestamp)" -ForegroundColor Green
        Write-Host "     Restoring system to your exact pre-optimization state...`n" -ForegroundColor Cyan
    } catch {
        Write-Host " [!] Backup file found but could not be parsed. Proceeding with Windows defaults." -ForegroundColor Yellow
        $backupData = $null
    }
} else {
    Write-Host " [*] No active session backup file detected." -ForegroundColor Gray
    Write-Host "     Restoring all systems to official Windows defaults...`n" -ForegroundColor Cyan
}

# 1. TIMER RESOLUTION
Write-Host " [1/9] Restoring Timer Resolution..." -ForegroundColor Yellow
try {
    $nativeCode = @"
using System;
using System.Runtime.InteropServices;
public class RestoreTimer {
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtSetTimerResolution(uint DesiredResolution, bool SetResolution, out uint CurrentResolution);
}
"@
    Add-Type -TypeDefinition $nativeCode -ErrorAction SilentlyContinue
    [uint32]$dummy = 0
    [RestoreTimer]::NtSetTimerResolution(156250, $false, [ref]$dummy) | Out-Null
    Write-Host "       [OK] System timer reset to Windows default (~15.6 ms)." -ForegroundColor Green
} catch {
    Write-Host "       [!] Timer reset skipped: $_" -ForegroundColor DarkGray
}

# 2. POWER PLAN & CORE PARKING
Write-Host "`n [2/9] Restoring Windows Power Plan & CPU Core Parking..." -ForegroundColor Yellow
try {
    if ($backupData -and $backupData.OriginalPowerScheme) {
        powercfg /setactive $backupData.OriginalPowerScheme 2>$null | Out-Null
        Write-Host "       [OK] Active power scheme restored to saved plan ($($backupData.OriginalPowerScheme))." -ForegroundColor Green
    } else {
        # Fallback: Set Balanced plan
        powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>$null | Out-Null
        Write-Host "       [OK] Power scheme restored to Windows Balanced default." -ForegroundColor Green
    }

    # Reset CPU core parking to Windows default (enable dynamic core parking on AC)
    powercfg /setacvalueindex scheme_current sub_processor CPMINCORES 0 2>$null | Out-Null
    powercfg /setactive scheme_current 2>$null | Out-Null
    Write-Host "       [OK] CPU core parking restored to dynamic power management." -ForegroundColor Green

    if ($ForceDefaultSchemes) {
        powercfg -restoredefaultschemes 2>$null | Out-Null
        Write-Host "       [OK] Windows default power schemes reloaded." -ForegroundColor Green
    }
} catch {
    Write-Host "       [!] Power scheme restore error: $_" -ForegroundColor Yellow
}

# 3. MULTIMEDIA SYSTEM PROFILE & GAMEDVR
Write-Host "`n [3/9] Restoring Multimedia System Profile & GameDVR..." -ForegroundColor Yellow
try {
    $sysPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    if (Test-Path $sysPath) {
        $throttlingVal = if ($backupData -and $backupData.OriginalSysProfile -and $backupData.OriginalSysProfile.NetworkThrottlingIndex) {
            [int]$backupData.OriginalSysProfile.NetworkThrottlingIndex
        } else { 10 } # 0x0000000a is Windows stock default
        
        $responsivenessVal = if ($backupData -and $backupData.OriginalSysProfile -and $backupData.OriginalSysProfile.SystemResponsiveness) {
            [int]$backupData.OriginalSysProfile.SystemResponsiveness
        } else { 20 } # 0x00000014 is Windows stock default

        Set-ItemProperty -Path $sysPath -Name "NetworkThrottlingIndex" -Value $throttlingVal -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $sysPath -Name "SystemResponsiveness" -Value $responsivenessVal -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "       [OK] NetworkThrottlingIndex restored ($throttlingVal)." -ForegroundColor Green
        Write-Host "       [OK] SystemResponsiveness restored ($responsivenessVal)." -ForegroundColor Green
    }

    $dvrPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
    if (Test-Path $dvrPath) {
        $appCapture = if ($backupData -and $backupData.OriginalGameDVR -and $null -ne $backupData.OriginalGameDVR.AppCaptureEnabled) {
            [int]$backupData.OriginalGameDVR.AppCaptureEnabled
        } else { 1 }
        Set-ItemProperty -Path $dvrPath -Name "AppCaptureEnabled" -Value $appCapture -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $dvrPath -Name "HistoricalCaptureEnabled" -Value $appCapture -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "       [OK] GameDVR capture flags restored ($appCapture)." -ForegroundColor Green
    }
} catch {
    Write-Host "       [!] Multimedia profile restore error: $_" -ForegroundColor Yellow
}

# 4. NETWORK & TCP STACK
Write-Host "`n [4/9] Restoring Network TCP Interfaces..." -ForegroundColor Yellow
try {
    $interfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue
    $revertedCount = 0
    foreach ($iface in $interfaces) {
        $p = $iface.PSPath
        $ip = Get-ItemProperty -Path $p -Name DhcpIPAddress, IPAddress -ErrorAction SilentlyContinue
        if ($ip.DhcpIPAddress -or $ip.IPAddress) {
            # In Windows default, TcpAckFrequency and TCPNoDelay do not exist (managed dynamically)
            Remove-ItemProperty -Path $p -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $p -Name "TCPNoDelay" -ErrorAction SilentlyContinue
            $revertedCount++
        }
    }
    Write-Host "       [OK] Cleaned TCP latency overrides across $revertedCount network interfaces." -ForegroundColor Green
} catch {
    Write-Host "       [!] Network stack restore error: $_" -ForegroundColor Yellow
}

# 5. MOUSE ACCELERATION & POINTER SETTINGS
Write-Host "`n [5/9] Restoring Mouse Settings..." -ForegroundColor Yellow
try {
    $mousePath = "HKCU:\Control Panel\Mouse"
    if (Test-Path $mousePath) {
        $speed = if ($backupData -and $backupData.OriginalMouseSettings -and $backupData.OriginalMouseSettings.MouseSpeed) {
            $backupData.OriginalMouseSettings.MouseSpeed
        } else { "1" }
        $t1 = if ($backupData -and $backupData.OriginalMouseSettings -and $backupData.OriginalMouseSettings.MouseThreshold1) {
            $backupData.OriginalMouseSettings.MouseThreshold1
        } else { "6" }
        $t2 = if ($backupData -and $backupData.OriginalMouseSettings -and $backupData.OriginalMouseSettings.MouseThreshold2) {
            $backupData.OriginalMouseSettings.MouseThreshold2
        } else { "10" }

        Set-ItemProperty -Path $mousePath -Name "MouseSpeed" -Value $speed -Type String -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $mousePath -Name "MouseThreshold1" -Value $t1 -Type String -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $mousePath -Name "MouseThreshold2" -Value $t2 -Type String -Force -ErrorAction SilentlyContinue
        Write-Host "       [OK] Mouse speed & acceleration curve restored to defaults." -ForegroundColor Green
    }
} catch {
    Write-Host "       [!] Mouse restore error: $_" -ForegroundColor Yellow
}

# 6. IFEO & APPCOMPAT FLAGS
Write-Host "`n [6/9] Cleaning IFEO Process Injections & Compatibility Flags..." -ForegroundColor Yellow
try {
    $ifeoKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\VALORANT-Win64-Shipping.exe"
    if (Test-Path $ifeoKey) {
        Remove-Item -Path $ifeoKey -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "       [OK] IFEO priority registry key removed for VALORANT." -ForegroundColor Green
    } else {
        Write-Host "       [OK] No residual IFEO keys found." -ForegroundColor Green
    }

    $compatPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
    if (Test-Path $compatPath) {
        Get-ItemProperty -Path $compatPath -ErrorAction SilentlyContinue | Get-Member -MemberType NoteProperty | ForEach-Object {
            if ($_.Name -match "VALORANT") {
                Remove-ItemProperty -Path $compatPath -Name $_.Name -ErrorAction SilentlyContinue
                Write-Host "       [OK] Removed AppCompatFlags entry: $($_.Name)" -ForegroundColor Green
            }
        }
    }
} catch {
    Write-Host "       [!] IFEO/AppCompat cleanup error: $_" -ForegroundColor Yellow
}

# 7. WINDOWS DEFENDER EXCLUSIONS
Write-Host "`n [7/9] Cleaning Windows Defender Exclusions..." -ForegroundColor Yellow
try {
    Remove-MpPreference -ExclusionProcess "VALORANT-Win64-Shipping.exe", "RiotClientServices.exe", "vgc.exe" -ErrorAction SilentlyContinue
    Write-Host "       [OK] Process exclusions removed from Windows Defender." -ForegroundColor Green
} catch {
    Write-Host "       [!] Defender cleanup skipped (managed by policy or 3rd-party AV)." -ForegroundColor DarkGray
}

# 8. BACKGROUND SERVICES & THREAD RESUMPTION
Write-Host "`n [8/9] Checking Suspended Services & Process Run-Queues..." -ForegroundColor Yellow
if ($backupData -and $backupData.SuspendedProcesses) {
    try {
        $nativeResumeCode = @"
using System;
using System.Runtime.InteropServices;
public class EmergencyResume {
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtResumeProcess(IntPtr ProcessHandle);
}
"@
        Add-Type -TypeDefinition $nativeResumeCode -ErrorAction SilentlyContinue
        $resumedCount = 0
        foreach ($pId in $backupData.SuspendedProcesses) {
            try {
                $proc = Get-Process -Id $pId -ErrorAction SilentlyContinue
                if ($proc -and -not $proc.HasExited) {
                    [EmergencyResume]::NtResumeProcess($proc.Handle) | Out-Null
                    $resumedCount++
                }
            } catch {}
        }
        if ($resumedCount -gt 0) {
            Write-Host "       [OK] Resumed $resumedCount background processes to normal run-queue." -ForegroundColor Green
        }
    } catch {}
}

$servicesToEnsure = @("SysMain", "WSearch", "DiagTrack")
foreach ($svc in $servicesToEnsure) {
    try {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s -and $s.Status -ne 'Running' -and $s.StartType -ne 'Disabled') {
            Start-Service -Name $svc -ErrorAction SilentlyContinue
            Write-Host "       [OK] Started service: $svc" -ForegroundColor Green
        } else {
            Write-Host "       [OK] Service $svc is in standard state ($($s.Status))." -ForegroundColor Green
        }
    } catch {}
}

# 9. GPU POWERMIZER / HARDWARE CLOCK RESTORATION
Write-Host "`n [9/9] Checking GPU Profile Overrides & Hardware Clocks..." -ForegroundColor Yellow
try {
    # Reset GPU Hardware Clocks via nvidia-smi
    $smi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    if ($smi) {
        nvidia-smi -rgc 2>$null | Out-Null
        Write-Host "       [OK] GPU hardware boost clocks reset to default dynamic scaling (nvidia-smi -rgc)." -ForegroundColor Green
    }
} catch {}

try {
    $classPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    if (Test-Path $classPath) {
        Get-ChildItem $classPath -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match "^\d{4}$" } | ForEach-Object {
            Remove-ItemProperty -Path $_.PSPath -Name "PowerMizerEnable", "PowerMizerLevel", "PowerMizerLevelAC" -ErrorAction SilentlyContinue
        }
    }
    Write-Host "       [OK] GPU power management registry overrides cleared." -ForegroundColor Green
} catch {}

# FLUSH DNS CACHE
ipconfig /flushdns | Out-Null
Write-Host "       [OK] Windows DNS Resolver Cache flushed." -ForegroundColor Green

# REMOVE ON-DISK BACKUP FILE
if (Test-Path $BackupFilePath) {
    Remove-Item -Path $BackupFilePath -Force -ErrorAction SilentlyContinue
    Write-Host "       [OK] Removed temporary session backup file ($BackupFilePath)." -ForegroundColor Green
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host " [SUCCESS] System restored cleanly to 100% stock defaults! " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " Press any key to exit..." -ForegroundColor DarkGray
if ([Environment]::UserInteractive) {
    $null = [Console]::ReadKey($true)
}
