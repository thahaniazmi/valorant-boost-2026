# Valorant Ultimate Low-Latency Companion

A single, self-contained batch file tailored for competitive esports gaming (optimized specifically for **AMD Ryzen + NVIDIA RTX 40-Series + 170Hz+** displays). 

Run it before or during your gaming session. It monitors for Valorant, eliminates frame-drops and input latency during matches, and automatically restores your Windows defaults upon exit.

---

## 📁 The Only File You Need
* **[Valorant_Optimizer.bat](file:///c:/Users/thaha_yquhle8/Projects/valorant%20optimise/Valorant_Optimizer.bat)**: Double-click this single file (or copy it to your Desktop).

---

## ⚡ How It Works

1. **Launch Optimizer**: Double-click `Valorant_Optimizer.bat`.
   - It cleans your DirectX/NVIDIA shader caches and audits config files.
   - It displays `[STANDBY] Ready and waiting for Valorant to open...`.
2. **Launch Valorant Yourself**:
   - Open Valorant normally through your desktop icon or Riot Client.
   - The script detects the game engine in real time and engages all pro-level tweaks.
3. **While You Play**:
   - **0.50 ms High-Precision Timer**: Synchronizes mouse sensor polling with your 170Hz panel.
   - **Direct Scanout / DWM Bypass**: Direct hardware writes to the display buffer, bypassing Windows compositor lag.
   - **AMD Ryzen Core Unparking (`CPMINCORES = 100%`)**: Prevents 1% low frame crashes down to 60 FPS.
   - **NVIDIA RTX 4050 MSI Interrupts**: Switched to Message Signaled Interrupts to eliminate DPC spikes.
   - **Windows Defender Exclusions**: Silently excludes game files from real-time scans.
   - **Zero Packet Delay**: Disables Nagle's algorithm (`TcpAckFrequency = 1`, `TCPNoDelay = 1`).
   - **1:1 Mouse Hardware Curve**: Removes OS-level pointer acceleration.
   - **Periodic RAM Sweeps**: Purges Standby RAM every 60 seconds.
   - **Discord Protected**: Voice chat and 60 FPS screenshares stay smooth.
4. **When You Exit**:
   - Close Valorant (or press `Q` in the terminal).
   - Every single setting, power plan, timer, and registry key immediately restores to your Windows defaults.
