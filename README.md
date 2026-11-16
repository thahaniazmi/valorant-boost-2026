# Valorant Ultimate Low-Latency Launcher & Competitive Companion

A single, self-contained batch file tailored for competitive esports gaming (optimized specifically for **AMD Ryzen + NVIDIA RTX 40-Series + 170Hz+** displays). It launches Valorant, eliminates frame-drops and input latency during matches, and automatically restores your Windows defaults upon exit.

---

## ⚡ Complete Feature Suite

### 1. 🎯 Sub-Millisecond Input Latency (0.50 ms Timer Resolution)
- Sets Windows system timer resolution to **0.50 ms** via native `ntdll.dll` API calls.
- Synchronizes mouse sensor polling with high-refresh displays (144Hz / 165Hz / 170Hz+).
- Reverts cleanly to your system's original timer resolution upon exit.

### 2. ⚡ MSI (Message Signaled Interrupts) Mode on NVIDIA RTX 4050
- Switches your RTX 4050 GPU from legacy line-based interrupts to **MSI Mode** (`MSISupported = 1`).
- Eliminates DPC latency spikes (micro-stuttering during intense sound and visual executes).

### 3. 🖥️ True Exclusive Fullscreen (Bypass DWM Compositor)
- Injects compatibility flags (`~ DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE`) to give Valorant direct hardware scanout to your display.
- Eliminates the 1–2 frames of Desktop Window Manager (DWM) buffer latency.

### 4. 🚀 AMD Ryzen Core Parking Disabled (`CPMINCORES = 100%`)
- Eliminates 1% low frame drops caused by Ryzen aggressive mobile power saving.
- Keeps all 8 CPU cores and 16 threads unparked and awake on AC power during matches.

### 5. 🛡️ Windows Defender On-the-Fly Scan Exclusion
- Adds process exclusions for `VALORANT-Win64-Shipping.exe`, `RiotClientServices.exe`, and Riot Vanguard (`vgc.exe`).
- Stops real-time antivirus scans from hitching your CPU when loading map assets and sound effects.

### 6. 🧹 Periodic Background RAM Standby Sweeps (Every 60s in HUD)
- Empties inactive process working sets and purges the Windows Standby memory list before launch and **every 60 seconds** during your match.
- Wipes stale shader caches (`%localappdata%\NVIDIA\DXCache` and `D3DSCache`) before launch.

### 7. 💽 Windows IFEO Performance Injection
- Injects `CpuPriorityClass = 3` (High Priority), `IoPriority = 3` (High Disk I/O), and `PagePriority = 5` (Maximum Memory Page Priority) into Windows Image File Execution Options.
- Eliminates audio and texture streaming pop-in stutters.

### 8. 🌐 Zero-Packet-Lag TCP/IP Stack (Nagle's Algorithm Disabled)
- Injects `TcpAckFrequency = 1` and `TCPNoDelay = 1` on active network adapters.
- Sets `SystemResponsiveness = 0` (dedicates 100% CPU priority to foreground applications).
- Sets `NetworkThrottlingIndex = 0xFFFFFFFF` (disables Windows network packet throttling).

### 9. 🖱️ True 1:1 Mouse Hardware Curve
- Forces Windows `MouseSpeed = 0`, `MouseThreshold1 = 0`, and `MouseThreshold2 = 0` to disable OS-level pointer acceleration.

### 10. ⚡ NVIDIA PowerMizer (Maximum Performance State)
- Forces the RTX 4050 into performance state 1 on AC power, preventing core and memory clock downshifting between rounds.

### 11. 🛡️ Discord & Streaming Protection
- Discord and streaming applications (OBS) remain strictly at **Normal priority** so your 60 FPS screenshares and voice chat stay crisp.

### 12. 📡 Live In-Terminal HUD & Ping Monitor
- Real-time match session duration, PID, working set RAM, and periodic standby sweep counters.
- Live network latency ping to Riot game server routing.

---

## 🎮 How to Use

1. Double-click **[Launch_Valorant.bat](file:///c:/Users/thaha_yquhle8/Projects/valorant%20optimise/Launch_Valorant.bat)**.
2. Accept the Windows UAC (Admin prompt) if prompted.
3. The script launches Valorant, engages all optimizations, and displays the live HUD.
4. Minimize the terminal while you play.
5. When you close Valorant (or press `Q` in the terminal), everything automatically restores to normal!
