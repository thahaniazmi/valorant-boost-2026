# Valorant Pro Low-Latency Launcher & Competitive Companion

A single, self-contained batch file tailored for high-performance esports gaming (optimized for **AMD Ryzen + NVIDIA RTX + 170Hz+** displays). It launches Valorant, eliminates frame-drops and input latency during matches, and automatically restores your Windows defaults upon exit.

---

## ⚡ Complete Feature Suite

### 1. 🎯 Sub-Millisecond Input Latency (0.50 ms Timer Resolution)
- Sets Windows system timer resolution to **0.50 ms** via native `ntdll.dll` API calls.
- Synchronizes mouse sensor polling with high-refresh displays (144Hz / 165Hz / 170Hz+).
- Reverts cleanly to your system's original timer resolution upon exit.

### 2. 🖥️ True Exclusive Fullscreen (Bypass DWM Compositor)
- Injects compatibility flags (`~ DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE`) to give Valorant direct hardware scanout to your display.
- Eliminates the 1–2 frames of Desktop Window Manager (DWM) buffer latency.

### 3. ⚡ AMD Ryzen Core Parking Disabled (`CPMINCORES = 100%`)
- Eliminates 1% low frame drops caused by Ryzen aggressive mobile power saving.
- Keeps all 8 CPU cores and 16 threads unparked and awake on AC power during matches.

### 4. 💽 Windows IFEO Performance Injection
- Injects `CpuPriorityClass = 3` (High Priority), `IoPriority = 3` (High Disk I/O), and `PagePriority = 5` (Maximum Memory Page Priority) into Windows Image File Execution Options.
- Eliminates audio and texture streaming pop-in stutters.

### 5. 🌐 Zero-Packet-Lag TCP/IP Stack (Nagle's Algorithm Disabled)
- Injects `TcpAckFrequency = 1` and `TCPNoDelay = 1` on active network adapters.
- Sets `SystemResponsiveness = 0` (dedicates 100% CPU priority to foreground applications).
- Sets `NetworkThrottlingIndex = 0xFFFFFFFF` (disables Windows network packet throttling).
- Flushes local DNS cache.

### 6. 🧹 Native Built-in ISLC & Shader Purge
- Empties inactive process working sets and purges the Windows Standby memory list before and during matches.
- Wipes stale shader caches (`%localappdata%\NVIDIA\DXCache` and `D3DSCache`) before launch to eliminate ability-cast stutters.

### 7. 🛡️ Discord & Streaming Protection
- Discord and streaming applications (OBS) are completely protected at **Normal** priority so your 60 FPS screenshares and voice chat stay crisp.

### 8. 📡 Live In-Terminal HUD & Ping Monitor
- Real-time match session duration, PID, and working set RAM.
- Live network latency ping to Riot game server routing.

---

## 🎮 How to Use

1. Double-click **[Launch_Valorant.bat](file:///c:/Users/thaha_yquhle8/Projects/valorant%20optimise/Launch_Valorant.bat)**.
2. Accept the Windows UAC (Admin prompt) if prompted.
3. The script launches Valorant, engages all optimizations, and displays the live HUD.
4. Minimize the terminal while you play.
5. When you close Valorant (or press `Q` in the terminal), everything automatically restores to normal!
