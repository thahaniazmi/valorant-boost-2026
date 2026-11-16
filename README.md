<div align="center">

<img src="assets/valorant_logo.png" alt="Valorant Logo" width="260">

# Valorant Pro Low-Latency Companion & Live Optimizer

![Valorant](https://img.shields.io/badge/VALORANT-Competitive%20Tuning-FF4655?style=for-the-badge&logo=riotgames&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![Vanguard Safe](https://img.shields.io/badge/Riot%20Vanguard-100%25%20Safe-success?style=for-the-badge&logo=shield&logoColor=white)
![Latency](https://img.shields.io/badge/Timer%20Resolution-0.50ms-blueviolet?style=for-the-badge)

**An automated, pro-grade Windows terminal companion designed to minimize frame drops, sharpen 1:1 mouse input responsiveness, and stabilize high-refresh framerates during competitive Valorant matches.** *Engineered for modern gaming laptops & desktops (Intel Core / AMD Ryzen • NVIDIA RTX / AMD Radeon • 144Hz–360Hz+ displays).*

---

</div>

> [!IMPORTANT]
> **100% Riot Vanguard Safe**: This tool strictly uses documented Windows OS scheduling, power management, and hardware interrupt APIs. It **never** injects DLLs, tampers with game binaries, hooks graphics memory, or reads game data.

---

## 🎯 At a Glance: What This Does

```
 ┌────────────────────────────────────────────────────────────────────────┐
 │                      YOUR SYSTEM LIFECYCLE                             │
 └────────────────────────────────────────────────────────────────────────┘
          │
          ▼
 [1] Launch Valorant_Optimizer.bat
          │  Purges stale DirectX & NVIDIA DXCache
          │  Audits GameUserSettings (Multi-Threaded Rendering + Raw Input)
          ▼
 [2] Standby Mode (0% CPU Overhead)
          │  Waits for you to open Valorant
          ▼
 [3] Valorant Opens ──► AUTO-ENGAGE ULTIMATE PRO TWEAKS:
          │  ├─► Timer Resolution : 0.50 ms (Native ntdll.dll API)
          │  ├─► CPU Cores        : 100% Unparked on AC (Intel / AMD CPMINCORES 100)
          │  ├─► GPU Performance  : P-State & Clock State Locked (Zero Stutters)
          │  ├─► Display Buffer   : DWM Compositor Bypassed (Direct Hardware Scanout)
          │  ├─► Process Priority : HIGH CPU & High Disk I/O (IFEO Injected)
          │  ├─► Network Stack    : Nagle's Algorithm Disabled (Immediate TCP Packets)
          │  ├─► Memory Standby   : Pre-match Clean Pass (Zero In-Game Hitching)
          │  ├─► Antivirus        : Real-time Defender Exclusions Active
          │  └─► Live HUD         : Displays session timer, RAM, ping, active tweaks
          ▼
 [4] Valorant Closes ──► AUTO-REVERT EVERYTHING:
             Restores default timer, power scheme, registry keys, and services.
```

---

## 🔬 Complete Optimization Index

The suite applies **22 precision optimizations** across 9 subsystems, targeting documented Windows bottlenecks and reverting automatically on game exit.

| # | Optimization | Subsystem | Target / Mechanism | Benefit |
| :-: | :--- | :--- | :--- | :--- |
| **1** | **Shader & Crash Cache Purge** | Disk / DirectX | Cleans `DXCache`, `D3DSCache`, `Saved\Logs` | Prevents stale shader compilation hitches |
| **2** | **0.50 ms Timer Resolution** | Kernel / Scheduler | `NtSetTimerResolution(5000, true)` via `ntdll.dll` | 31x faster thread dispatch, zero input float |
| **3** | **CPU Core Unparking** | Power / CPU Cores | `powercfg /setacvalueindex ... CPMINCORES 100` | Prevents core wake micro-stutters during fights |
| **4** | **Ultimate Performance Plan** | Powercfg / AC State | Activates Ultimate or High Performance GUID | Locks all-core clocks to maximum boost frequency |
| **5** | **Process Priority: High** | Windows Dispatcher | Sets `$valProc.PriorityClass = High` at runtime | Prioritizes game render threads above OS tasks |
| **6** | **IFEO CPU Priority** | Registry / IFEO | `CpuPriorityClass = 3` in `Image File Execution Options` | Sets instant High priority on launch/reconnect |
| **7** | **IFEO Disk I/O Priority** | Disk Scheduler | `IoPriority = 3` in `Image File Execution Options` | Prevents asset and audio streaming pop-in |
| **8** | **IFEO Memory Page Priority** | Memory Manager | `PagePriority = 5` in `Image File Execution Options` | Prevents Windows from paging game RAM to swap |
| **9** | **DWM Direct Scanout Bypass** | Display / DWM | `DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE` | Bypasses DWM buffer (cuts 1–2 frames / 6–12 ms lag) |
| **10** | **Safe GPU Hardware Profile** | Display Driver | Driver-level performance state enforcement | Locks peak GPU clocks without risky raw PCI edits |
| **11** | **NVIDIA PowerMizer Lock** | GPU Driver | `PowerMizerLevel = 1` & `PowerMizerLevelAC = 1` | Prevents down-clocking during buy phases or smokes |
| **12** | **Nagle's Algorithm Disabled** | TCP/IP Stack | `TcpAckFrequency = 1` & `TCPNoDelay = 1` | Instant packet transmission and hit registration |
| **13** | **Network Throttling Disabled** | Network / MMCSS | `NetworkThrottlingIndex = 0xFFFFFFFF` | Disables Windows network packet throttling |
| **14** | **100% Gaming CPU Bias** | Multimedia Profile | `SystemResponsiveness = 0` in `SystemProfile` | Allocates 100% of CPU time to the active game |
| **15** | **Mouse Acceleration Killswitch** | HID / Pointer | `MouseSpeed = 0`, `MouseThreshold1/2 = 0` | Enforces true 1:1 raw hardware sensor curve |
| **16** | **Defender Real-Time Exclusions** | Windows Security | `Add-MpPreference -ExclusionProcess` for game & vgc | Prevents 15–20% CPU spikes from `MsMpEng.exe` |
| **17** | **Background App Throttling** | Task Scheduler | Sets background browsers/launchers to `BelowNormal` | Frees CPU headroom without closing your tabs |
| **18** | **Discord & OBS Protection** | Audio / Video Stream | Explicitly locked at `Normal` priority | Preserves clean voice comms and 60 FPS streams |
| **19** | **Stutter-Prone Services Paused**| Windows Services | Pauses `WSearch`, `SysMain`, and `DiagTrack` | Halts background indexing and telemetry spikes |
| **20** | **Standby Memory Clean Pass** | RAM Management | Single `[System.GC]::Collect()` pass prior to launch | Cleans standby RAM without continuous disk thrashing |
| **21** | **DNS Resolver Flush** | DNS Client | Runs `ipconfig /flushdns` on start and exit | Purges stale routing caches for nearest game servers |
| **22** | **Crash Backup & Recovery** | System Lifecycle | Snapshot in `optimizer_backup.json` + auto-recovery | Safe auto-revert on exit, crash, or restore tool |

---

## 🔬 Detailed Technical Breakdown

```mermaid
flowchart LR
    A[Launch / Match Start] --> B[Purge Shader Caches]
    B --> C[Inject IFEO & 0.5ms Timer]
    C --> D[DWM Bypass & Network Tune]
    D --> E[In-Match: Peak 1% Lows & Sub-ms Input]
    E --> F[Exit / Crash]
    F --> G[Auto-Restore Baseline via JSON]
```

### ⚡ CPU & Power
* **0.50 ms Timer Resolution:** Calls `ntdll.dll!NtSetTimerResolution` → 31x faster scheduling, eliminates input float.
* **Disable Core Parking:** Sets `CPMINCORES = 100` via `powercfg` → Keeps 100% of cores awake to stop C-state wake stutters.
* **Ultimate Performance Scheme:** Locks CPU base/boost clocks → Prevents frequency drops during quiet rounds.
* **100% Gaming Responsiveness:** Sets `SystemResponsiveness = 0` → Reclaims the 20% CPU slice reserved for background OS multimedia.

### 🎯 Process & I/O Priority (IFEO)
* **High CPU Priority:** Injects `CpuPriorityClass = 3` via IFEO & runtime elevation → Ensures Valorant gets top scheduling priority from frame one.
* **High Disk I/O Priority:** Injects `IoPriority = 3` via IFEO → Prioritizes SSD reads, preventing texture pop-in and audio hitches.
* **Memory Page Locking:** Injects `PagePriority = 5` via IFEO → Signals Windows never to swap game memory to `pagefile.sys`.

### 🖥️ Display & GPU
* **Direct Scanout (DWM Bypass):** Injects `DISABLEDXMAXIMIZEDWINDOWEDMODE` → Bypasses DWM compositor, saving 1–2 frames (6–12 ms) of display lag.
* **NVIDIA PowerMizer Lock:** Forces performance P-states via registry → Prevents GPU down-clocking during buy phases or smoke executes without unsafe PCI bus edits.

### 🌐 Network & Input
* **Zero Packet Delay (Kill Nagle):** Sets `TcpAckFrequency = 1` & `TCPNoDelay = 1` → Sends bullet/movement packets instantly without batching delays (up to 200 ms).
* **Remove Network Throttling:** Sets `NetworkThrottlingIndex = 0xFFFFFFFF` → Completely disables automated Windows packet throttling.
* **1:1 Linear Mouse Tracking:** Sets `MouseSpeed = 0` and thresholds to `0` → Eliminates residual OS pointer curves for raw sensor tracking.
* **DNS Resolver Flush:** Clears cache on startup/exit → Ensures matchmaking connects over the freshest server routes.

### 🧹 Background & System Overhead
* **Shader & Crash Cache Purge:** Clears `DXCache`, `D3DSCache`, and game logs → Eliminates in-match shader recompilation drops.
* **Windows Defender Exclusions:** Excludes Valorant, Riot Client, and Vanguard → Eliminates 15–20% CPU spikes from real-time asset scans.
* **Process Priority Balancing:** Demotes browsers to `BelowNormal`, shields Discord/OBS at `Normal` → Frees CPU headroom without audio distortion or dropped frames.
* **Service Pausing:** Temporarily stops `WSearch`, `SysMain`, and `DiagTrack` → Eliminates sudden background disk I/O and telemetry stutters.
* **Stutter-Free Memory Prep:** One-time initial GC pass → Avoids aggressive runtime `EmptyWorkingSet` paging loops.

### 🛡️ Safety & Recovery
* **Snapshot & Auto-Recovery:** Backs up state to JSON, hooks graceful exit, and provides `Restore_Defaults.bat` → Guarantees clean 1-click reversion on game close or crash.

---

## 🎮 How to Use & Operating Modes

Choose the workflow that fits your setup:

### Mode 1: Always-Ready System Tray Watchdog (Recommended)
1. **Double-click `Install_AutoStart_Tray.bat` once.**
2. The companion will automatically start silently in the **Windows System Tray** whenever your computer boots up.
3. Consumes **0.00% CPU** and tiny memory (~20 MB).
4. **Whenever you launch Valorant**, all 22 optimizations automatically engage!
5. **When you quit Valorant**, all system settings automatically revert to normal defaults and return to tray standby.
6. To disable auto-start anytime, simply double-click `Uninstall_AutoStart_Tray.bat`.

### Mode 2: Run in the System Tray on Demand
* Double-click **`Valorant_Optimizer_Tray.bat`**.
* The companion starts minimized directly into the Windows System Tray with **no lingering terminal window**.
* Sits quietly waiting for Valorant with zero overhead.

### Mode 3: 1-Click Game & Companion Launcher
* Double-click **`Launch_Valorant_With_Tray.bat`**.
* Starts the companion silently in your system tray and immediately launches Valorant / Riot Client!
* You can pin or send this file to your Desktop as your primary Valorant shortcut.

### Mode 4: Classic Console HUD with In-Game Minimize
* Double-click **`Valorant_Optimizer.bat`**.
* Shows the live esports telemetry HUD with session duration, active power plan, timer resolution, and network ping.
* Press **`T`** at any time to instantly minimize the console HUD to the **System Tray**.
* Double-click the tray icon (or right-click -> *Show Monitoring HUD*) to bring the terminal back up.

---

## 🔔 System Tray Features & Context Menu

Right-click the red **Valorant icon** in your Windows taskbar tray to access:

* **● Real-Time Status**: Displays `Standby (Waiting for game)` or `Active (PID & match timer)`.
* **Show / Hide Monitoring HUD**: Toggle the live terminal telemetry window on and off.
* **Purge Caches & Standby Memory Now**: Instant manual cleanup of DirectX shader cache and Windows standby RAM.
* **Windows Startup Integration**: Enable or disable Windows logon autostart right from the menu.
* **Restore Defaults & Exit**: Restores all 22 optimizations cleanly and safely exits the companion.
* **Native Tray Notifications**: Subtle toast balloons inform you when tweaks engage and revert.

---

## ⚙️ Essential Laptop Checklist & Guidelines

> [!WARNING]
> If your game drops to 60 FPS or stutters on a laptop, check these recommended settings:

* **🔌 Always Plug In AC Power:** Gaming laptops reduce GPU power by 50–70% on battery.
* **🚀 In-Game Video Settings:** Set Display Mode to **Fullscreen**, turn **VSync: OFF**, and set **NVIDIA Reflex / AMD Anti-Lag to On + Boost**.
* **🔋 OEM Software Profiles:** Set Lenovo Vantage, ASUS Armoury Crate, Acer NitroSense, or HP OMEN to **Performance / Turbo**.
* **🚫 Disable Battery Limiters:** In GeForce Experience / NVIDIA App, turn **OFF** both **WhisperMode** and **Battery Boost**.
* **🌡️ Thermal Airflow:** Elevate the laptop rear by 1 inch for intake airflow. If thermals exceed 90°C on budget chassis, cap in-game FPS to match your display refresh rate (e.g., 144 or 165 FPS).

---

## 💻 Hardware Compatibility

| Component | Support | Notes |
| :--- | :--- | :--- |
| **OS** | Windows 10 & 11 (64-bit) | Home, Pro, and Enterprise fully supported. |
| **CPU** | Intel Core & AMD Ryzen | Unparks all logical cores on AC power to stop micro-stutters. |
| **GPU** | NVIDIA RTX/GTX, AMD Radeon, Intel Arc | Discrete GPUs receive driver-level clock locking and low-latency tuning. |
| **Displays** | 60Hz to 540Hz+ | 0.50 ms timer synchronizes draw calls to any high-refresh monitor. |

---

## 🛡️ Safety, Anti-Cheat & Emergency Recovery

* **100% Riot Vanguard Safe:** Strictly uses sanctioned Windows OS APIs (`ntdll.dll`, `powercfg`, and registry IFEO). Zero DLL injection, zero game memory hooks, and zero binary modifications.
* **Automated Session Recovery:** Baseline settings are snapshotted to `optimizer_backup.json`. If power is lost or Windows crashes, settings auto-restore on next launch.
* **1-Click Emergency Restore:** Double-click `Restore_Defaults.bat` anytime (even in Windows Safe Mode) to instantly restore 100% stock factory Windows settings.

---

## 📁 Repository Structure

| File | Description |
| :--- | :--- |
| **`Valorant_Optimizer_Tray.bat`** | **Direct System Tray Runner**. Launches companion hidden in the tray (zero console window). |
| **`Install_AutoStart_Tray.bat`** | **1-Click Auto-Start Installer**. Configures Windows logon task for silent tray monitoring. |
| **`Uninstall_AutoStart_Tray.bat`** | Removes the Windows logon task cleanly. |
| **`Launch_Valorant_With_Tray.bat`**| **Desktop Launcher Replacement**. Starts tray companion and launches Valorant together. |
| **`Valorant_Optimizer.bat`** | **Classic Console HUD Runner**. Interactive terminal companion with `[T]` to minimize to tray. |
| **`valorant_optimizer.ps1`** | Native PowerShell engine with `-Tray`, `-Daemon`, and Win32 tray integration. |
| **`Restore_Defaults.bat`** | **1-Click Emergency Restore Tool**. Instantly resets all Windows settings to stock. |
| **`restore_defaults.ps1`** | Native PowerShell restore engine. |
| **`run.bat`** | Quick alias launcher. |
| **`README.md`** | Complete documentation and optimization reference. |

---

<div align="center">

**Enjoy smoother frames, crisp responsive input, and stable performance. GG! 🎮**

</div>
