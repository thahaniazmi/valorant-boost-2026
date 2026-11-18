<div align="center">

<img src="assets/valorant_logo.png" alt="Valorant Logo" width="260">

# Valorant Low-Latency Companion

![Valorant](https://img.shields.io/badge/VALORANT-Tuning-FF4655?style=for-the-badge&logo=riotgames&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![Vanguard Safe](https://img.shields.io/badge/Riot%20Vanguard-Safe-success?style=for-the-badge&logo=shield&logoColor=white)
![Latency](https://img.shields.io/badge/Timer%20Resolution-0.50ms-blueviolet?style=for-the-badge)

A quiet, lightweight Windows background utility that helps smooth out frametimes and tighten input latency while Valorant is running. Nothing bloated or intrusive—just sensible Windows tweaks that apply automatically when the game opens and revert cleanly when you close it.

---

</div>

> [!NOTE]
> **Vanguard Safe**: Strictly relies on standard Windows scheduling, power schemes, and interrupt APIs. It doesn't modify game files, hook graphics memory, or touch network packets.

---

## 🎯 At a Glance: What This Does

```
 ┌────────────────────────────────────────────────────────────────────────┐
 │                              LIFECYCLE                                 │
 └────────────────────────────────────────────────────────────────────────┘
          │
          ▼
 [1] Launch via System Tray (Install_AutoStart_Tray.bat) or Console HUD
          │  Clears stale DirectX & NVIDIA DXCache
          │  Quick cleanup of standby RAM
          ▼
 [2] Standby Mode (0.00% CPU Overhead)
          │  Quietly waits in system tray or console for Valorant
          ▼
 [3] Valorant Opens ──► Applies tweaks automatically:
          │  ├─► Timer Resolution : 0.50 ms (Native ntdll.dll API)
          │  ├─► Core 0 Isolation : Mouse & NIC DPCs isolated from game render loop
          │  ├─► Process Sleep    : Suspends select background apps while in match
          │  ├─► EcoQoS Steering  : Directs background tasks to E-cores
          │  ├─► Memory Priority  : Game Level 5 / Background RAM demoted
          │  ├─► CPU Cores        : Unparked on AC (CPMINCORES 100)
          │  ├─► GPU Performance  : Power state locked to prevent down-clocking
          │  ├─► Display Buffer   : Direct scanout (bypasses DWM buffer)
          │  ├─► Process Priority : High CPU & High Disk I/O (IFEO)
          │  ├─► Network Stack    : Nagle's algorithm disabled (no packet batching)
          │  ├─► Defender         : Real-time exclusions for game process
          │  └─► Live HUD / Tray  : Minimal session stats and status info
          ▼
 [4] Valorant Closes ──► Auto-reverts everything:
             Restores default timer, power scheme, process queues, and services.
```

---

## 🛠️ What Gets Tweaked

Applies a collection of small Windows optimizations when the game starts, then puts everything back when you're done.

| # | Optimization | Subsystem | Target / Mechanism | Benefit |
| :-: | :--- | :--- | :--- | :--- |
| **1** | **Shader Cache Cleanup** | Disk / DirectX | Cleans `DXCache`, `D3DSCache`, `Saved\Logs` | Prevents stale shader compilation hitches |
| **2** | **0.50 ms Timer Resolution** | Kernel / Scheduler | `NtSetTimerResolution(5000, true)` via `ntdll.dll` | Faster thread dispatch, consistent input polling |
| **3** | **Core 0 ISR & DPC Isolation** | Kernel / Affinity | `SetProcessAffinityMask` (reserves Core 0) | Keeps hardware mouse/NIC interrupts off game render loop |
| **4** | **Background App Suspend** | Kernel / Scheduler | `NtSuspendProcess` via `ntdll.dll` | Pauses idle background browser threads |
| **5** | **EcoQoS & E-Core Steering** | Kernel / Thread Director | `SetProcessInformation` (`PowerThrottling`) | Moves background tasks to E-cores, keeping P-cores for the game |
| **6** | **Memory Page Demotion** | Memory Manager | `SetProcessInformation` (`MemoryPriority: 1`) | Demotes background RAM so game working set stays cached |
| **7** | **CPU Core Unparking** | Power / CPU Cores | `powercfg /setacvalueindex ... CPMINCORES 100` | Prevents core wake delay during gameplay |
| **8** | **Performance Power Plan** | Powercfg / AC State | Activates Ultimate or High Performance GUID | Keeps clocks stable during quiet moments in-game |
| **9** | **Process Priority: High** | Windows Dispatcher | Sets `$valProc.PriorityClass = High` at runtime | Prioritizes game render threads over generic OS tasks |
| **10** | **IFEO CPU Priority** | Registry / IFEO | `CpuPriorityClass = 3` in `Image File Execution Options` | Ensures High priority immediately on game launch |
| **11** | **IFEO Disk I/O Priority** | Disk Scheduler | `IoPriority = 3` in `Image File Execution Options` | Prevents asset and audio streaming delays |
| **12** | **IFEO Memory Page Priority** | Memory Manager | `PagePriority = 5` in `Image File Execution Options` | Keeps game working set in physical RAM |
| **13** | **DWM Direct Scanout Bypass** | Display / DWM | `DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE` | Direct display scanout, bypasses desktop compositor buffer |
| **14** | **Safe GPU Hardware Profile** | Display Driver | Driver-level performance state enforcement | Prevents GPU throttling down during buy phases or smokes |
| **15** | **NVIDIA PowerMizer Lock** | GPU Driver | `PowerMizerLevel = 1` & `PowerMizerLevelAC = 1` | Locks performance clock state safely |
| **16** | **Nagle's Algorithm Disabled** | TCP/IP Stack | `TcpAckFrequency = 1` & `TCPNoDelay = 1` | Sends TCP packets immediately without batching delay |
| **17** | **Network Throttling Disabled** | Network / MMCSS | `NetworkThrottlingIndex = 0xFFFFFFFF` | Disables automated Windows network packet throttling |
| **18** | **Gaming Responsiveness Bias** | Multimedia Profile | `SystemResponsiveness = 0` in `SystemProfile` | Frees reserved OS CPU slice for foreground gaming |
| **19** | **Linear Mouse Tracking** | HID / Pointer | `MouseSpeed = 0`, `MouseThreshold1/2 = 0` | Ensures raw 1:1 hardware sensor curve |
| **20** | **Defender Process Exclusions** | Windows Security | `Add-MpPreference -ExclusionProcess` for game & vgc | Prevents background scans from interrupting gameplay |
| **21** | **Background App Throttling** | Task Scheduler | Sets background browsers to `BelowNormal` | Leaves more CPU headroom without needing to close tabs |
| **22** | **Discord & OBS Protected** | Audio / Video Stream | Explicitly locked at `Normal` priority | Keeps voice comms and streams running cleanly |
| **23** | **Heavy Services Paused** | Windows Services | Pauses `WSearch`, `SysMain`, and `DiagTrack` | Pauses search indexing and telemetry during matches |
| **24** | **Standby Memory Cleanup** | RAM Management | Single `[System.GC]::Collect()` pass prior to launch | Tidies standby RAM before entering a match |
| **25** | **DNS Resolver Flush** | DNS Client | Runs `ipconfig /flushdns` on start and exit | Clears stale routing cache for match servers |
| **26** | **Crash Backup & Recovery** | System Lifecycle | Snapshot in `optimizer_backup.json` + auto-recovery | Reverts cleanly on exit, crash, or manual restore |

---

## 🔬 Technical Details

### 🧠 Kernel Dispatcher & Thread Scheduling
* **Core 0 ISR & DPC Isolation (`SetProcessAffinityMask`):** Windows hardware drivers route mouse reports (1000Hz–8000Hz) and network packets almost exclusively to Logical CPU 0. Reserving Core 0 for hardware interrupts and steering Valorant to Cores 1..N helps avoid micro-stutters during flicks or fast gunfights.
* **Background App Suspend (`NtSuspendProcess` via `ntdll.dll`):** Rather than just lowering background priority, this pauses background browser threads so they don't eat CPU cycles or pollute cache lines while you're in a match. Everything unpauses immediately when you exit.
* **EcoQoS & E-Core Steering (`SetProcessInformation`):** On modern Intel and AMD hybrid processors, EcoQoS tells the Windows scheduler to run background apps on Efficiency cores, leaving Performance cores available for the game.
* **Memory Page Priority Demotion (`MemoryPriorityInformation`):** Sets background browser RAM to Level 1 (`MemoryPriorityVeryLow`) and Valorant to Level 5 (`MemoryPriorityNormal`), letting Windows discard background cache before paging game memory.

### ⚡ CPU & Power
* **0.50 ms Timer Resolution:** Calls `ntdll.dll!NtSetTimerResolution` for responsive thread scheduling and lower input latency.
* **Core Unparking:** Sets `CPMINCORES = 100` via `powercfg` to keep cores active and prevent sleep/wake latency hitches.
* **Performance Scheme:** Uses the high or ultimate performance scheme on AC power to keep clocks steady.
* **Responsiveness Setting:** Sets `SystemResponsiveness = 0` to prioritize foreground interactive processes.

### 🎯 Process & I/O Priority (IFEO)
* **High CPU Priority:** Sets `CpuPriorityClass = 3` via IFEO & runtime elevation for priority scheduling.
* **High Disk I/O Priority:** Sets `IoPriority = 3` via IFEO to help prevent audio stutter or texture streaming delays.
* **Memory Page Priority:** Sets `PagePriority = 5` via IFEO to signal Windows to keep game memory in physical RAM.

### 🖥️ Display & GPU
* **Direct Scanout (DWM Bypass):** Sets `DISABLEDXMAXIMIZEDWINDOWEDMODE` to bypass the desktop compositor buffer and shave off latency.
* **NVIDIA PowerMizer Lock:** Sets performance P-states via registry to avoid clock drops during quiet rounds without touching voltages or clock offsets.

### 🌐 Network & Input
* **Low Packet Latency:** Sets `TcpAckFrequency = 1` & `TCPNoDelay = 1` to send network packets right away.
* **Disable Network Throttling:** Sets `NetworkThrottlingIndex = 0xFFFFFFFF` to avoid system network throttling.
* **Raw Mouse Tracking:** Sets `MouseSpeed = 0` and thresholds to `0` to remove OS acceleration curves.
* **DNS Cache Flush:** Cleans DNS cache on startup and exit to ensure fresh routes to game servers.

### 🧹 Background Maintenance
* **Cache Cleanup:** Cleans `DXCache`, `D3DSCache`, and log files to prevent shader recompilation stutters.
* **Defender Exclusions:** Temporarily excludes Valorant and Vanguard to stop real-time background scans from spiking CPU.
* **Balanced Priorities:** Gently demotes background browsers while keeping Discord and OBS normal.
* **Service Pauses:** Pauses background indexing (`WSearch`), `SysMain`, and `DiagTrack` while playing.
* **Standby Memory Prep:** Performs a single GC pass at launch to free up memory cleanly.

### 🛡️ Safety & Restoration
* **Automatic Recovery:** Snapshots original settings to `optimizer_backup.json` and restores everything cleanly on match exit.
* **Restore Utility:** Run `Restore_Defaults.bat` anytime to reset Windows settings back to stock.

---

## 🎮 How to Use

Pick whichever fits your setup:

### Mode 1: Tray Watchdog (Recommended)
1. **Double-click `Install_AutoStart_Tray.bat` once.**
2. It sits quietly in the **Windows System Tray** on startup.
3. Uses essentially 0% CPU and very little memory (~20 MB).
4. **When you open Valorant**, tweaks kick in automatically.
5. **When you close Valorant**, everything returns to your normal Windows settings.
6. To uninstall auto-start, just run `Uninstall_AutoStart_Tray.bat`.

### Mode 2: Run in Tray on Demand
* Double-click **`Valorant_Optimizer_Tray.bat`**.
* Starts minimized directly in the tray with no command prompt window staying open.

### Mode 3: Launcher Shortcut
* Double-click **`Launch_Valorant_With_Tray.bat`**.
* Starts the tray helper and launches Valorant together. Feel free to send a shortcut of this to your desktop.

### Mode 4: Console HUD
* Double-click **`Valorant_Optimizer.bat`**.
* Shows a lightweight console HUD with session time, power scheme, timer resolution, and ping.
* Press **`T`** anytime to send it down to the tray.
* Double-click the tray icon to bring it back.

---

## 🔔 Tray Menu

Right-click the **Valorant icon** in your taskbar tray:

* **● Status**: Shows whether it's waiting or currently active in a match.
* **Show / Hide Monitoring HUD**: Toggle the terminal window.
* **Purge Caches & Standby Memory Now**: Quick manual cleanup if you ever want one.
* **Windows Startup Integration**: Toggle login auto-start directly.
* **Restore Defaults & Exit**: Restores stock Windows settings and exits.
* **Notifications**: Small tray notifications when settings engage and revert.

---

## ⚙️ Laptop Notes

If you're playing on a laptop and notice frame drops:

* **🔌 Keep AC Power Plugged In:** Laptops cut GPU power considerably on battery.
* **🚀 In-Game Video Settings:** Fullscreen, VSync OFF, and Reflex / Anti-Lag set to On + Boost.
* **🔋 OEM Software:** Set your laptop control center (Vantage, Armoury Crate, NitroSense, OMEN) to Performance.
* **🚫 Battery Savers:** In GeForce Experience or NVIDIA App, turn off WhisperMode and Battery Boost.
* **🌡️ Airflow:** Elevating the back of the laptop slightly helps thermals noticeably.

---

## 💻 Compatibility

| Component | Support | Notes |
| :--- | :--- | :--- |
| **OS** | Windows 10 & 11 (64-bit) | Home, Pro, and Enterprise. |
| **CPU** | Intel Core & AMD Ryzen | Unparks cores on AC power to keep frametimes steady. |
| **GPU** | NVIDIA RTX/GTX, AMD Radeon, Intel Arc | Helps prevent power state drops mid-match. |
| **Displays** | 60Hz to 540Hz+ | 0.50 ms timer keeps draw calls synchronized. |

---

## 🛡️ Safety & Recovery

* **Vanguard Safe:** Uses documented Windows APIs (`ntdll.dll`, `powercfg`, and IFEO). No DLL injections, no memory tampering, no game modifications.
* **Session Recovery:** Backs up state to `optimizer_backup.json` and auto-restores if a crash or unexpected shutdown happens.
* **Reset Utility:** Double-click `Restore_Defaults.bat` anytime to restore factory Windows settings.

---

## 📁 Files

| File | Description |
| :--- | :--- |
| **`Valorant_Optimizer_Tray.bat`** | Runs the companion directly in the tray with no visible console. |
| **`Install_AutoStart_Tray.bat`** | Adds a logon task to start the tray companion on boot. |
| **`Uninstall_AutoStart_Tray.bat`** | Removes the logon task cleanly. |
| **`Launch_Valorant_With_Tray.bat`**| Starts the tray companion and opens Valorant together. |
| **`Valorant_Optimizer.bat`** | Runs the interactive console HUD (press `T` to send to tray). |
| **`valorant_optimizer.ps1`** | Core PowerShell script handling optimizations and tray logic. |
| **`Restore_Defaults.bat`** | Resets all settings back to Windows defaults. |
| **`restore_defaults.ps1`** | PowerShell restore script. |
| **`run.bat`** | Quick alias launcher. |
| **`README.md`** | Setup guide and reference. |

---

<div align="center">

**Just a simple setup to keep things running smoothly. Hope it helps.**

</div>
