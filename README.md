# Valorant All-in-One Launcher & Low-Latency Companion

A single, self-contained batch file tailored for high-performance esports gaming (especially AMD Ryzen + NVIDIA RTX laptops/desktops). It launches Valorant, eliminates frame-drops and input latency during matches, and automatically restores your Windows defaults upon exit.

---

## ⚡ Key Features Added

### 1. 🎯 Sub-Millisecond Input Latency (0.50 ms Timer Resolution)
- Sets Windows system timer resolution to **0.50 ms** via native `ntdll.dll` API calls (replacing Windows default 15.6 ms jitter).
- Synchronizes mouse sensor polling with high-refresh displays (144Hz / 165Hz / 170Hz+).
- Reverts cleanly to your system's original timer resolution upon exit.

### 2. ⚡ AMD Ryzen Core Parking Disabled (`CPMINCORES = 100%`)
- Eliminates 1% low frame drops caused by Ryzen aggressive mobile power saving.
- Keeps all CPU cores unparked and awake on AC power during matches.

### 3. 🛡️ Network Latency & Foreground Responsiveness
- Sets `SystemResponsiveness = 0` (dedicates 100% CPU priority to foreground applications).
- Sets `NetworkThrottlingIndex = 0xFFFFFFFF` (disables Windows network packet throttling).
- Flushes local DNS cache.

### 4. 🧹 Pre-Launch DirectX & NVIDIA Shader Purge
- Cleans stale shader cache (`%localappdata%\NVIDIA\DXCache` and `D3DSCache`) before launch to eliminate map-loading hitches and ability-cast stutter.
- Cleans old Valorant crash logs and dumps.

### 5. 🚀 High Process Priority & Resource Freeing
- Promotes `VALORANT-Win64-Shipping.exe` to **High priority**.
- Throttles background hogs (Chrome, Edge, Discord, Spotify, Steam, etc.) to `BelowNormal`.
- Temporarily pauses background indexing services (`Windows Search`, `SysMain`).

### 6. 🔄 Instant Revert & Vanguard Safety
- **100% Riot Vanguard safe**: Strictly utilizes standard Windows OS management APIs.
- When you close Valorant or press **`Q`** in the terminal, all original power plans, timer resolutions, registry keys, and background apps are immediately restored to normal.

---

## 🎮 How to Use

1. Double-click **[Launch_Valorant.bat](file:///c:/Users/thaha_yquhle8/Projects/valorant%20optimise/Launch_Valorant.bat)**.
2. Accept the Windows UAC (Admin prompt) if prompted.
3. The script launches Valorant, optimizes your system, and displays the live HUD.
4. Minimize the terminal while you play.
5. When you close Valorant (or press `Q` in the terminal), everything automatically restores to normal!
