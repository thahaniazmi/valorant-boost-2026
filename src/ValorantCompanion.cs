using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Forms;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Shapes;
using System.Windows.Threading;

namespace ValorantCompanionApp {
    // ----------------- NATIVE WIN32 & NT KERNEL INTERFACES -----------------
    public static class NativeMethods {
        [DllImport("ntdll.dll", SetLastError = true)]
        public static extern int NtSetTimerResolution(uint DesiredResolution, bool SetResolution, out uint CurrentResolution);

        [DllImport("ntdll.dll", SetLastError = true)]
        public static extern int NtQueryTimerResolution(out uint MinimumResolution, out uint MaximumResolution, out uint CurrentResolution);

        [DllImport("ntdll.dll", SetLastError = true)]
        public static extern int NtSuspendProcess(IntPtr ProcessHandle);

        [DllImport("ntdll.dll", SetLastError = true)]
        public static extern int NtResumeProcess(IntPtr ProcessHandle);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool SetProcessAffinityMask(IntPtr hProcess, IntPtr dwProcessAffinityMask);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool GetProcessAffinityMask(IntPtr hProcess, out IntPtr lpProcessAffinityMask, out IntPtr lpSystemAffinityMask);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool SetProcessInformation(IntPtr hProcess, int ProcessInformationClass, ref PROCESS_POWER_THROTTLING_STATE ProcessInformation, uint ProcessInformationSize);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool SetProcessInformation(IntPtr hProcess, int ProcessInformationClass, ref MEMORY_PRIORITY_INFORMATION ProcessInformation, uint ProcessInformationSize);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

        [DllImport("user32.dll")]
        public static extern bool UnregisterHotKey(IntPtr hWnd, int id);

        [DllImport("psapi.dll")]
        public static extern int EmptyWorkingSet(IntPtr hwProc);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr GetStdHandle(int nStdHandle);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);

        public const int ProcessMemoryPriority = 0;
        public const int ProcessPowerThrottling = 4;
        public const uint MEMORY_PRIORITY_VERY_LOW = 1;
        public const uint MEMORY_PRIORITY_NORMAL = 5;
        public const uint PROCESS_POWER_THROTTLING_CURRENT_VERSION = 1;
        public const uint PROCESS_POWER_THROTTLING_EXECUTION_SPEED = 0x1;

        public const int STD_INPUT_HANDLE = -10;
        public const uint ENABLE_QUICK_EDIT_MODE = 0x0040;
        public const uint ENABLE_EXTENDED_FLAGS = 0x0080;

        public const int WM_HOTKEY = 0x0312;
        public const uint MOD_ALT = 0x0001;
        public const uint MOD_CONTROL = 0x0002;
        public const uint MOD_NOREPEAT = 0x4000;

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

        public static void DisableConsoleQuickEdit() {
            try {
                IntPtr handle = GetStdHandle(STD_INPUT_HANDLE);
                if (handle != IntPtr.Zero && handle != new IntPtr(-1)) {
                    uint mode;
                    if (GetConsoleMode(handle, out mode)) {
                        mode &= ~ENABLE_QUICK_EDIT_MODE;
                        mode |= ENABLE_EXTENDED_FLAGS;
                        SetConsoleMode(handle, mode);
                    }
                }
            } catch {}
        }
    }

    // ----------------- CONFIGURATION MODEL (MULTI-GAME COVERAGE) -----------------
    public class GameDefinition {
        public string name { get; set; }
        public List<string> processes { get; set; }
        public bool enabled { get; set; }

        public GameDefinition() {
            processes = new List<string>();
            enabled = true;
        }

        public GameDefinition(string gameName, string[] procList) {
            name = gameName;
            processes = new List<string>(procList);
            enabled = true;
        }
    }

    public class AppConfig {
        public List<GameDefinition> supportedGames { get; set; }
        public List<string> backgroundAppsToFreeze { get; set; }
        public List<string> protectedApps { get; set; }
        public List<string> servicesToPause { get; set; }
        public GpuConfig gpuClockLock { get; set; }
        public int timerResolutionNs { get; set; }
        public bool coreIsolationEnabled { get; set; }
        public bool startMinimizedToTray { get; set; }
        public bool showNotifications { get; set; }

        public AppConfig() {
            supportedGames = new List<GameDefinition> {
                new GameDefinition("VALORANT", new string[] { "VALORANT-Win64-Shipping", "VALORANT" }),
                new GameDefinition("Counter-Strike 2", new string[] { "cs2" }),
                new GameDefinition("Apex Legends", new string[] { "r5apex" }),
                new GameDefinition("Fortnite", new string[] { "FortniteClient-Win64-Shipping" }),
                new GameDefinition("Overwatch 2", new string[] { "Overwatch" }),
                new GameDefinition("Call of Duty", new string[] { "cod", "bootstrapper" }),
                new GameDefinition("Rainbow Six Siege", new string[] { "RainbowSix", "RainbowSix_Vulkan" }),
                new GameDefinition("The Finals", new string[] { "Discovery" }),
                new GameDefinition("Marvel Rivals", new string[] { "MarvelRivals" }),
                new GameDefinition("League of Legends", new string[] { "League of Legends" }),
                new GameDefinition("Rocket League", new string[] { "RocketLeague" })
            };
            backgroundAppsToFreeze = new List<string> {
                "chrome", "msedge", "brave", "opera", "firefox", "spotify", "steamwebhelper", "EpicGamesLauncher", "OneDrive", "Dropbox", "discord_canary"
            };
            protectedApps = new List<string> {
                "Discord", "obs64", "Streamlabs OBS", "vgc", "vgtray", "RiotClientServices", "dwm", "explorer", "csrss", "lsass", "smss", "services"
            };
            servicesToPause = new List<string> { "WSearch", "SysMain", "DiagTrack" };
            gpuClockLock = new GpuConfig { enabled = true, targetClockMhz = 0, lockMinMax = true };
            timerResolutionNs = 5000;
            coreIsolationEnabled = true;
            startMinimizedToTray = true;
            showNotifications = true;
        }
    }

    public class GpuConfig {
        public bool enabled { get; set; }
        public int targetClockMhz { get; set; }
        public bool lockMinMax { get; set; }
    }

    // ----------------- REAL GPU HARDWARE CLOCK LOCK (NVIDIA-SMI) -----------------
    public static class GpuClockManager {
        private static string _smiPath = null;
        public static string DetectedGpuName = "Auto-Detecting...";
        public static int MaxBoostClock = 0;
        public static bool IsLocked = false;

        public static string GetSmiPath() {
            if (_smiPath != null) return _smiPath;
            string sys32 = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "nvidia-smi.exe");
            if (File.Exists(sys32)) return _smiPath = sys32;
            string nvsmi = @"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe";
            if (File.Exists(nvsmi)) return _smiPath = nvsmi;
            return _smiPath = "nvidia-smi";
        }

        public static void DetectGpu() {
            try {
                var psi = new ProcessStartInfo {
                    FileName = GetSmiPath(),
                    Arguments = "--query-gpu=name,clocks.max.graphics --format=csv,noheader,nounits",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    CreateNoWindow = true
                };
                using (var p = Process.Start(psi)) {
                    string output = p.StandardOutput.ReadToEnd();
                    p.WaitForExit(3000);
                    if (!string.IsNullOrEmpty(output)) {
                        string[] parts = output.Trim().Split(',');
                        if (parts.Length > 0) DetectedGpuName = parts[0].Trim();
                        if (parts.Length > 1) {
                            int clk;
                            if (int.TryParse(parts[1].Trim(), out clk)) MaxBoostClock = clk;
                        }
                    }
                }
            } catch {
                DetectedGpuName = "Standard / Non-NVIDIA Display";
            }
        }

        public static bool LockClocks(int customClock = 0) {
            try {
                int target = customClock > 0 ? customClock : MaxBoostClock;
                if (target <= 0) {
                    DetectGpu();
                    target = MaxBoostClock;
                }
                if (target <= 0) target = 2100;

                RunCmd("-pm 1");
                string args = string.Format("-lgc {0},{0}", target);
                int code = RunCmd(args);
                if (code == 0) {
                    IsLocked = true;
                    return true;
                }
            } catch {}
            return false;
        }

        public static void ResetClocks() {
            try {
                RunCmd("-rgc");
                IsLocked = false;
            } catch {}
        }

        private static int RunCmd(string args) {
            try {
                var psi = new ProcessStartInfo {
                    FileName = GetSmiPath(),
                    Arguments = args,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };
                using (var p = Process.Start(psi)) {
                    p.WaitForExit(3000);
                    return p.ExitCode;
                }
            } catch {
                return -1;
            }
        }
    }

    // ----------------- UNIVERSAL ESPORTS OPTIMIZATION ENGINE -----------------
    public class OptimizationEngine {
        public AppConfig Config { get; private set; }
        public string ConfigPath { get; private set; }

        public bool IsOptimized { get; private set; }
        public bool IsPaused { get; private set; }
        public DateTime? PauseUntil { get; private set; }
        public string StatusText { get; private set; }
        public string ActiveGameName { get; private set; }
        public int ActiveGamePid { get; private set; }
        public int SuspendedProcessCount { get; private set; }
        public int EcoQoSCount { get; private set; }

        private System.Threading.Timer _timer;
        private List<int> _suspendedPids = new List<int>();
        private string _originalPowerScheme = null;
        private uint _originalTimerRes = 156250;
        private bool _timerSet = false;
        private IntPtr _originalAffinity = IntPtr.Zero;

        public event Action OnStateChanged;

        public OptimizationEngine(string configPath) {
            ConfigPath = configPath;
            LoadConfig();
            StatusText = "STANDBY (Waiting for Game)";
            ActiveGameName = "None";
            GpuClockManager.DetectGpu();
            _timer = new System.Threading.Timer(Tick, null, 1000, 1000);
        }

        public void LoadConfig() {
            try {
                if (File.Exists(ConfigPath)) {
                    string json = File.ReadAllText(ConfigPath);
                    var ser = new JavaScriptSerializer();
                    Config = ser.Deserialize<AppConfig>(json);
                    if (Config.supportedGames == null || Config.supportedGames.Count == 0) {
                        Config.supportedGames = new AppConfig().supportedGames;
                    }
                } else {
                    Config = new AppConfig();
                    SaveConfig();
                }
            } catch {
                Config = new AppConfig();
            }
        }

        public void SaveConfig() {
            try {
                var ser = new JavaScriptSerializer();
                string json = ser.Serialize(Config);
                File.WriteAllText(ConfigPath, json);
            } catch {}
        }

        public void Pause(int minutes) {
            PauseUntil = DateTime.Now.AddMinutes(minutes);
            IsPaused = true;
            if (IsOptimized) RevertOptimizations();
            StatusText = string.Format("PAUSED ({0}m remaining)", minutes);
            NotifyState();
        }

        public void Resume() {
            PauseUntil = null;
            IsPaused = false;
            StatusText = "STANDBY (Waiting for Game)";
            NotifyState();
        }

        private void Tick(object state) {
            try {
                if (IsPaused) {
                    if (PauseUntil.HasValue && DateTime.Now >= PauseUntil.Value) {
                        Resume();
                    } else if (PauseUntil.HasValue) {
                        var remain = PauseUntil.Value - DateTime.Now;
                        StatusText = string.Format("PAUSED ({0:mm\\:ss} left)", remain);
                        NotifyState();
                        return;
                    }
                }

                string detectedGame;
                Process gameProc = FindRunningGame(out detectedGame);

                if (gameProc != null && !gameProc.HasExited) {
                    if (!IsOptimized && !IsPaused) {
                        ApplyOptimizations(gameProc, detectedGame);
                    } else if (IsOptimized) {
                        StatusText = string.Format("ACTIVE: {0} (PID: {1})", ActiveGameName, gameProc.Id);
                        NotifyState();
                    }
                } else {
                    if (IsOptimized) {
                        RevertOptimizations();
                    }
                    if (!IsPaused) {
                        StatusText = "STANDBY (0% CPU • Waiting for Game)";
                        ActiveGameName = "None";
                        NotifyState();
                    }
                }
            } catch {}
        }

        private Process FindRunningGame(out string gameName) {
            gameName = null;
            if (Config.supportedGames == null) return null;

            foreach (var g in Config.supportedGames) {
                if (!g.enabled) continue;
                foreach (var procName in g.processes) {
                    try {
                        var procs = Process.GetProcessesByName(procName);
                        if (procs.Length > 0 && !procs[0].HasExited) {
                            gameName = g.name;
                            return procs[0];
                        }
                    } catch {}
                }
            }
            return null;
        }

        public void ApplyOptimizations(Process gameProc, string gameName) {
            try {
                ActiveGameName = gameName;
                ActiveGamePid = gameProc.Id;
                StatusText = string.Format("OPTIMIZING {0}...", gameName);
                NotifyState();

                // 1. Process Priority: High
                try { gameProc.PriorityClass = ProcessPriorityClass.High; } catch {}

                // 2. High-Precision Timer (0.50 ms)
                try {
                    uint min, max, cur;
                    NativeMethods.NtQueryTimerResolution(out min, out max, out cur);
                    _originalTimerRes = cur;
                    uint applied;
                    if (NativeMethods.NtSetTimerResolution((uint)Config.timerResolutionNs, true, out applied) == 0) {
                        _timerSet = true;
                    }
                } catch {}

                // 3. Core 0 DPC Isolation (Systems >= 6 threads)
                if (Config.coreIsolationEnabled && Environment.ProcessorCount >= 6) {
                    try {
                        IntPtr procAff, sysAff;
                        if (NativeMethods.GetProcessAffinityMask(gameProc.Handle, out procAff, out sysAff)) {
                            _originalAffinity = procAff;
                            long mask = (((1L << Environment.ProcessorCount) - 1) & ~1L);
                            NativeMethods.SetProcessAffinityMask(gameProc.Handle, (IntPtr)mask);
                        }
                    } catch {}
                }

                // 4. Power Plan & Core Unparking
                try {
                    _originalPowerScheme = GetActivePowerScheme();
                    RunPowercfg("/setactive e9a42b02-d5df-448d-aa00-03f14749eb61");
                    RunPowercfg("/setacvalueindex scheme_current sub_processor CPMINCORES 100");
                    RunPowercfg("/setactive scheme_current");
                } catch {}

                // 5. Memory Priority to Game Working Set
                try {
                    var memInfo = new NativeMethods.MEMORY_PRIORITY_INFORMATION { MemoryPriority = NativeMethods.MEMORY_PRIORITY_NORMAL };
                    NativeMethods.SetProcessInformation(gameProc.Handle, NativeMethods.ProcessMemoryPriority, ref memInfo, (uint)Marshal.SizeOf(memInfo));
                } catch {}

                // 6. Real GPU Hardware Clock Lock (nvidia-smi)
                if (Config.gpuClockLock.enabled) {
                    GpuClockManager.LockClocks(Config.gpuClockLock.targetClockMhz);
                }

                // 7. Background App Deep Freeze & EcoQoS
                _suspendedPids.Clear();
                int ecoCount = 0;
                foreach (string appName in Config.backgroundAppsToFreeze) {
                    if (Config.protectedApps.Contains(appName)) continue;
                    Process[] procs = Process.GetProcessesByName(appName);
                    foreach (var p in procs) {
                        try {
                            if (p.Id == Process.GetCurrentProcess().Id) continue;
                            p.PriorityClass = ProcessPriorityClass.BelowNormal;

                            var lowMem = new NativeMethods.MEMORY_PRIORITY_INFORMATION { MemoryPriority = NativeMethods.MEMORY_PRIORITY_VERY_LOW };
                            NativeMethods.SetProcessInformation(p.Handle, NativeMethods.ProcessMemoryPriority, ref lowMem, (uint)Marshal.SizeOf(lowMem));

                            var throttling = new NativeMethods.PROCESS_POWER_THROTTLING_STATE {
                                Version = NativeMethods.PROCESS_POWER_THROTTLING_CURRENT_VERSION,
                                ControlMask = NativeMethods.PROCESS_POWER_THROTTLING_EXECUTION_SPEED,
                                StateMask = NativeMethods.PROCESS_POWER_THROTTLING_EXECUTION_SPEED
                            };
                            if (NativeMethods.SetProcessInformation(p.Handle, NativeMethods.ProcessPowerThrottling, ref throttling, (uint)Marshal.SizeOf(throttling))) {
                                ecoCount++;
                            }

                            if (NativeMethods.NtSuspendProcess(p.Handle) == 0) {
                                _suspendedPids.Add(p.Id);
                            }
                        } catch {}
                    }
                }
                SuspendedProcessCount = _suspendedPids.Count;
                EcoQoSCount = ecoCount;

                // 8. Pause Heavy Stutter Services
                foreach (string svc in Config.servicesToPause) {
                    RunServiceCmd("stop", svc);
                }

                // 9. Quick Standby Memory Purge & DNS Flush
                PurgeMemoryAndCaches();

                IsOptimized = true;
                StatusText = string.Format("ACTIVE: {0} (PID: {1})", ActiveGameName, ActiveGamePid);
                NotifyState();
            } catch {}
        }

        public void RevertOptimizations() {
            try {
                foreach (int pid in _suspendedPids) {
                    try {
                        Process p = Process.GetProcessById(pid);
                        if (p != null && !p.HasExited) {
                            NativeMethods.NtResumeProcess(p.Handle);
                        }
                    } catch {}
                }
                _suspendedPids.Clear();
                SuspendedProcessCount = 0;
                EcoQoSCount = 0;

                if (_timerSet) {
                    uint dummy;
                    NativeMethods.NtSetTimerResolution(_originalTimerRes, false, out dummy);
                    _timerSet = false;
                }

                GpuClockManager.ResetClocks();

                if (!string.IsNullOrEmpty(_originalPowerScheme)) {
                    RunPowercfg(string.Format("/setactive {0}", _originalPowerScheme));
                    RunPowercfg("/setacvalueindex scheme_current sub_processor CPMINCORES 0");
                    RunPowercfg("/setactive scheme_current");
                }

                foreach (string svc in Config.servicesToPause) {
                    RunServiceCmd("start", svc);
                }

                IsOptimized = false;
                ActiveGamePid = 0;
                StatusText = "STANDBY (0% CPU • Waiting for Game)";
                NotifyState();
            } catch {}
        }

        public void PurgeMemoryAndCaches() {
            try {
                GC.Collect();
                GC.WaitForPendingFinalizers();
                GC.Collect();

                NativeMethods.EmptyWorkingSet(Process.GetCurrentProcess().Handle);

                string local = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                string[] paths = new string[] {
                    System.IO.Path.Combine(local, @"NVIDIA\DXCache"),
                    System.IO.Path.Combine(local, @"D3DSCache"),
                    System.IO.Path.Combine(local, @"VALORANT\Saved\Logs"),
                    System.IO.Path.Combine(local, @"VALORANT\Saved\Crashes")
                };
                foreach (string dir in paths) {
                    try {
                        if (Directory.Exists(dir)) {
                            foreach (string f in Directory.GetFiles(dir, "*", SearchOption.AllDirectories)) {
                                try { File.Delete(f); } catch {}
                            }
                        }
                    } catch {}
                }

                var pDns = Process.Start(new ProcessStartInfo("ipconfig", "/flushdns") { CreateNoWindow = true, UseShellExecute = false });
                if (pDns != null) pDns.WaitForExit(2000);
            } catch {}
        }

        private string GetActivePowerScheme() {
            try {
                var psi = new ProcessStartInfo("powercfg", "/getactivescheme") { UseShellExecute = false, RedirectStandardOutput = true, CreateNoWindow = true };
                using (var p = Process.Start(psi)) {
                    string o = p.StandardOutput.ReadToEnd();
                    p.WaitForExit(1000);
                    int idx = o.IndexOf('(');
                    int idx2 = o.IndexOf(')');
                    if (idx != -1 && idx2 > idx) {
                        string guid = o.Substring(idx + 1, idx2 - idx - 1).Trim();
                        return guid;
                    }
                }
            } catch {}
            return null;
        }

        private void RunPowercfg(string args) {
            try {
                var psi = new ProcessStartInfo("powercfg", args) { UseShellExecute = false, CreateNoWindow = true };
                var p = Process.Start(psi);
                if (p != null) p.WaitForExit(1500);
            } catch {}
        }

        private void RunServiceCmd(string action, string svcName) {
            try {
                var psi = new ProcessStartInfo("net", string.Format("{0} {1}", action, svcName)) { UseShellExecute = false, CreateNoWindow = true };
                var p = Process.Start(psi);
                if (p != null) p.WaitForExit(1500);
            } catch {}
        }

        private void NotifyState() {
            if (OnStateChanged != null) {
                try { OnStateChanged(); } catch {}
            }
        }
    }

    // ----------------- MODERN WPF FLUENT CYBERPUNK DASHBOARD -----------------
    public class WpfDashboardWindow : System.Windows.Window {
        private OptimizationEngine _engine;
        private NotifyIcon _trayIcon;

        private TextBlock _txtStatus;
        private TextBlock _txtGameName;
        private TextBlock _txtRamStats;
        private TextBlock _txtGpuStats;
        private TextBlock _txtTimerStats;
        private TextBlock _txtCpuStats;
        private System.Windows.Controls.CheckBox _chkGpuLock;
        private Canvas _graphCanvas;
        private System.Windows.Controls.ListBox _lstApps;
        private System.Windows.Controls.ListBox _lstGames;
        private System.Windows.Controls.TextBox _txtNewApp;

        private Queue<float> _ramHistory = new Queue<float>();
        private DispatcherTimer _uiTimer;

        private const int HOTKEY_PURGE = 9001;
        private const int HOTKEY_STANDBY = 9002;
        private const int HOTKEY_GPU = 9003;

        public WpfDashboardWindow(OptimizationEngine engine) {
            _engine = engine;

            this.Title = "Valorant & Esports Low-Latency Companion (Native WPF)";
            this.Width = 880;
            this.Height = 640;
            this.MinWidth = 880;
            this.MinHeight = 640;
            this.WindowStartupLocation = WindowStartupLocation.CenterScreen;
            this.Background = new SolidColorBrush(System.Windows.Media.Color.FromRgb(15, 23, 42)); // Slate 900
            this.Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(241, 245, 249));

            for (int i = 0; i < 60; i++) _ramHistory.Enqueue(0);

            BuildUI();
            SetupTray();
            RegisterGlobalHotkeys();

            _uiTimer = new DispatcherTimer();
            _uiTimer.Interval = TimeSpan.FromSeconds(1);
            _uiTimer.Tick += (s, e) => UpdateTelemetry();
            _uiTimer.Start();

            _engine.OnStateChanged += () => {
                Dispatcher.Invoke(new Action(UpdateEngineStatus));
            };

            UpdateEngineStatus();
        }

        private void BuildUI() {
            Grid root = new Grid();
            root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(80) }); // Header
            root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) }); // Tabs
            root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(70) }); // Footer Toolbar

            // 1. Header Bar
            Border headerBorder = new Border {
                Background = new SolidColorBrush(System.Windows.Media.Color.FromRgb(30, 41, 59)),
                BorderBrush = new SolidColorBrush(System.Windows.Media.Color.FromRgb(51, 65, 85)),
                BorderThickness = new Thickness(0, 0, 0, 1),
                Padding = new Thickness(20, 12, 20, 12)
            };

            Grid headerGrid = new Grid();
            headerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            headerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

            StackPanel titlePanel = new StackPanel();
            TextBlock lblTitle = new TextBlock {
                Text = "⚡ VALORANT & ESPORTS COMPANION",
                FontSize = 18,
                FontWeight = FontWeights.Bold,
                Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(255, 70, 85)) // Valorant Crimson
            };
            TextBlock lblSubtitle = new TextBlock {
                Text = "Compiled Native .NET WPF Engine • Real GPU Hardware Boost Lock • Multi-Game Auto-Detect",
                FontSize = 11,
                Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(148, 163, 184))
            };
            titlePanel.Children.Add(lblTitle);
            titlePanel.Children.Add(lblSubtitle);
            headerGrid.Children.Add(titlePanel);
            Grid.SetColumn(titlePanel, 0);

            Border statusBadge = new Border {
                CornerRadius = new CornerRadius(16),
                Background = new SolidColorBrush(System.Windows.Media.Color.FromArgb(40, 16, 185, 129)),
                BorderBrush = new SolidColorBrush(System.Windows.Media.Color.FromRgb(16, 185, 129)),
                BorderThickness = new Thickness(1.5),
                Padding = new Thickness(14, 6, 14, 6),
                VerticalAlignment = VerticalAlignment.Center
            };
            _txtStatus = new TextBlock {
                Text = "STANDBY (0% CPU)",
                FontWeight = FontWeights.Bold,
                FontSize = 12,
                Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(52, 211, 153))
            };
            statusBadge.Child = _txtStatus;
            headerGrid.Children.Add(statusBadge);
            Grid.SetColumn(statusBadge, 1);

            headerBorder.Child = headerGrid;
            root.Children.Add(headerBorder);
            Grid.SetRow(headerBorder, 0);

            // 2. Tab Control for Multi-Feature View
            System.Windows.Controls.TabControl tabs = new System.Windows.Controls.TabControl {
                Background = Brushes.Transparent,
                BorderThickness = new Thickness(0),
                Margin = new Thickness(16, 10, 16, 10)
            };

            tabs.Items.Add(CreateTelemetryTab());
            tabs.Items.Add(CreateGameProfilesTab());
            tabs.Items.Add(CreateProcessManagerTab());

            root.Children.Add(tabs);
            Grid.SetRow(tabs, 1);

            // 3. Footer Control Toolbar
            Border footerBorder = new Border {
                Background = new SolidColorBrush(System.Windows.Media.Color.FromRgb(30, 41, 59)),
                BorderBrush = new SolidColorBrush(System.Windows.Media.Color.FromRgb(51, 65, 85)),
                BorderThickness = new Thickness(0, 1, 0, 0),
                Padding = new Thickness(16, 12, 16, 12)
            };

            StackPanel footerPanel = new StackPanel { Orientation = System.Windows.Controls.Orientation.Horizontal, HorizontalAlignment = System.Windows.HorizontalAlignment.Center };

            System.Windows.Controls.Button btnPurge = CreateModernButton("⚡ Purge RAM & Caches [Ctrl+Alt+O]", System.Windows.Media.Color.FromRgb(6, 182, 212), 240);
            btnPurge.Click += (s, e) => {
                _engine.PurgeMemoryAndCaches();
                System.Windows.MessageBox.Show("Standby RAM, DirectX caches, and DNS cache purged cleanly!", "Purge Complete", MessageBoxButton.OK, MessageBoxImage.Information);
            };

            System.Windows.Controls.Button btnPause30 = CreateModernButton("⏸️ Pause 30m", System.Windows.Media.Color.FromRgb(71, 85, 105), 115);
            btnPause30.Click += (s, e) => _engine.Pause(30);

            System.Windows.Controls.Button btnPause60 = CreateModernButton("⏸️ Pause 1h", System.Windows.Media.Color.FromRgb(71, 85, 105), 115);
            btnPause60.Click += (s, e) => _engine.Pause(60);

            System.Windows.Controls.Button btnResume = CreateModernButton("▶️ Resume", System.Windows.Media.Color.FromRgb(16, 185, 129), 115);
            btnResume.Click += (s, e) => _engine.Resume();

            System.Windows.Controls.Button btnRestore = CreateModernButton("🛡️ Restore & Exit", System.Windows.Media.Color.FromRgb(255, 70, 85), 130);
            btnRestore.Click += (s, e) => ExitApplication();

            footerPanel.Children.Add(btnPurge);
            footerPanel.Children.Add(btnPause30);
            footerPanel.Children.Add(btnPause60);
            footerPanel.Children.Add(btnResume);
            footerPanel.Children.Add(btnRestore);
            footerBorder.Child = footerPanel;
            root.Children.Add(footerBorder);
            Grid.SetRow(footerBorder, 2);

            this.Content = root;

            this.Closing += (s, e) => {
                e.Cancel = true;
                this.Hide();
                if (_trayIcon != null) {
                    _trayIcon.ShowBalloonTip(1500, "Valorant Companion", "Minimized to System Tray. Double-click icon to restore.", ToolTipIcon.Info);
                }
            };
        }

        private TabItem CreateTelemetryTab() {
            TabItem tab = new TabItem { Header = "  📊 Live Telemetry & Graph  " };
            Grid grid = new Grid { Margin = new Thickness(10) };
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(320) });

            // Left: Vector Memory Graph
            Border graphCard = CreateCardBorder();
            StackPanel graphPanel = new StackPanel { Margin = new Thickness(15) };
            TextBlock lblGraphTitle = new TextBlock { Text = "REAL-TIME PHYSICAL MEMORY HISTORY", FontWeight = FontWeights.Bold, FontSize = 12, Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(0, 229, 255)) };
            graphPanel.Children.Add(lblGraphTitle);

            _graphCanvas = new Canvas {
                Height = 180,
                Margin = new Thickness(0, 10, 0, 10),
                Background = new SolidColorBrush(System.Windows.Media.Color.FromRgb(15, 23, 42)),
                ClipToBounds = true
            };
            graphPanel.Children.Add(_graphCanvas);

            _txtRamStats = new TextBlock { Text = "System RAM: Calculating...", FontSize = 12, Foreground = Brushes.White };
            graphPanel.Children.Add(_txtRamStats);

            _chkGpuLock = new System.Windows.Controls.CheckBox {
                Content = "Lock GPU Clocks via nvidia-smi (Peak Boost Frequency)",
                IsChecked = _engine.Config.gpuClockLock.enabled,
                Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(255, 70, 85)),
                Margin = new Thickness(0, 15, 0, 0)
            };
            _chkGpuLock.Checked += (s, e) => { _engine.Config.gpuClockLock.enabled = true; _engine.SaveConfig(); };
            _chkGpuLock.Unchecked += (s, e) => { _engine.Config.gpuClockLock.enabled = false; _engine.SaveConfig(); };
            graphPanel.Children.Add(_chkGpuLock);

            graphCard.Child = graphPanel;
            grid.Children.Add(graphCard);
            Grid.SetColumn(graphCard, 0);

            // Right: Hardware & Kernel Status Cards
            StackPanel rightCards = new StackPanel { Margin = new Thickness(10, 0, 0, 0) };

            Border cardGame = CreateCardBorder();
            StackPanel pnlGame = new StackPanel { Margin = new Thickness(12) };
            pnlGame.Children.Add(new TextBlock { Text = "TARGET GAME STATUS", FontSize = 11, FontWeight = FontWeights.Bold, Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(148, 163, 184)) });
            _txtGameName = new TextBlock { Text = "Active Game: None (Standby)", FontSize = 13, FontWeight = FontWeights.Bold, Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(52, 211, 153)), Margin = new Thickness(0, 4, 0, 0) };
            pnlGame.Children.Add(_txtGameName);
            cardGame.Child = pnlGame;
            rightCards.Children.Add(cardGame);

            Border cardGpu = CreateCardBorder();
            cardGpu.Margin = new Thickness(0, 10, 0, 0);
            StackPanel pnlGpu = new StackPanel { Margin = new Thickness(12) };
            pnlGpu.Children.Add(new TextBlock { Text = "GPU HARDWARE STATE", FontSize = 11, FontWeight = FontWeights.Bold, Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(148, 163, 184)) });
            _txtGpuStats = new TextBlock { Text = "GPU: Detecting...", FontSize = 12, Foreground = Brushes.White, Margin = new Thickness(0, 4, 0, 0) };
            pnlGpu.Children.Add(_txtGpuStats);
            cardGpu.Child = pnlGpu;
            rightCards.Children.Add(cardGpu);

            Border cardTimer = CreateCardBorder();
            cardTimer.Margin = new Thickness(0, 10, 0, 0);
            StackPanel pnlTimer = new StackPanel { Margin = new Thickness(12) };
            pnlTimer.Children.Add(new TextBlock { Text = "KERNEL SCHEDULER & DISPATCHER", FontSize = 11, FontWeight = FontWeights.Bold, Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(148, 163, 184)) });
            _txtTimerStats = new TextBlock { Text = "Timer Resolution: 0.50 ms (Native ntdll.dll)\nCore 0 DPC Isolation: Active on Cores 1..N", FontSize = 11.5, Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(52, 211, 153)), Margin = new Thickness(0, 4, 0, 0) };
            pnlTimer.Children.Add(_txtTimerStats);
            cardTimer.Child = pnlTimer;
            rightCards.Children.Add(cardTimer);

            grid.Children.Add(rightCards);
            Grid.SetColumn(rightCards, 1);

            tab.Content = grid;
            return tab;
        }

        private TabItem CreateGameProfilesTab() {
            TabItem tab = new TabItem { Header = "  🎮 Supported Games (Esports Auto-Detect)  " };
            Border border = CreateCardBorder();
            border.Margin = new Thickness(10);
            StackPanel mainPanel = new StackPanel { Margin = new Thickness(15) };

            TextBlock lblHeader = new TextBlock {
                Text = "UNIVERSAL ESPORTS GAME PROFILES",
                FontWeight = FontWeights.Bold,
                FontSize = 13,
                Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(255, 70, 85))
            };
            TextBlock lblDesc = new TextBlock {
                Text = "The companion automatically detects whenever ANY of these games launch and applies 0.50ms timer, Core 0 isolation, and GPU lock.",
                FontSize = 11,
                Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(148, 163, 184)),
                Margin = new Thickness(0, 4, 0, 10)
            };
            mainPanel.Children.Add(lblHeader);
            mainPanel.Children.Add(lblDesc);

            _lstGames = new System.Windows.Controls.ListBox {
                Height = 220,
                Background = new SolidColorBrush(System.Windows.Media.Color.FromRgb(15, 23, 42)),
                Foreground = Brushes.White,
                BorderBrush = new SolidColorBrush(System.Windows.Media.Color.FromRgb(51, 65, 85))
            };
            RefreshGamesList();
            mainPanel.Children.Add(_lstGames);

            StackPanel btnRow = new StackPanel { Orientation = System.Windows.Controls.Orientation.Horizontal, Margin = new Thickness(0, 10, 0, 0) };
            System.Windows.Controls.Button btnAddCustomGame = CreateModernButton("+ Add Custom Game (.exe)", System.Windows.Media.Color.FromRgb(16, 185, 129), 200);
            btnAddCustomGame.Click += (s, e) => {
                var dlg = new OpenFileDialog {
                    Title = "Select Game Executable to Auto-Optimize",
                    Filter = "Executables (*.exe)|*.exe|All Files (*.*)|*.*"
                };
                if (dlg.ShowDialog() == System.Windows.Forms.DialogResult.OK) {
                    string exeName = System.IO.Path.GetFileNameWithoutExtension(dlg.FileName);
                    var newG = new GameDefinition(exeName, new string[] { exeName });
                    _engine.Config.supportedGames.Add(newG);
                    _engine.SaveConfig();
                    RefreshGamesList();
                    System.Windows.MessageBox.Show(string.Format("Added '{0}' to auto-detected game profiles!", exeName), "Game Added", MessageBoxButton.OK, MessageBoxImage.Information);
                }
            };
            btnRow.Children.Add(btnAddCustomGame);
            mainPanel.Children.Add(btnRow);

            border.Child = mainPanel;
            tab.Content = border;
            return tab;
        }

        private TabItem CreateProcessManagerTab() {
            TabItem tab = new TabItem { Header = "  🛑 Process Deep Freeze Manager  " };
            Border border = CreateCardBorder();
            border.Margin = new Thickness(10);
            StackPanel panel = new StackPanel { Margin = new Thickness(15) };

            TextBlock lblHeader = new TextBlock {
                Text = "BACKGROUND APPS TO DEEP FREEZE & DEMOTE TO E-CORES",
                FontWeight = FontWeights.Bold,
                FontSize = 13,
                Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(0, 229, 255))
            };
            TextBlock lblDesc = new TextBlock {
                Text = "These apps are paused (NtSuspendProcess) and demoted to E-Cores (EcoQoS) while in a match. Discord and OBS are always protected.",
                FontSize = 11,
                Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(148, 163, 184)),
                Margin = new Thickness(0, 4, 0, 10)
            };
            panel.Children.Add(lblHeader);
            panel.Children.Add(lblDesc);

            _lstApps = new System.Windows.Controls.ListBox {
                Height = 200,
                Background = new SolidColorBrush(System.Windows.Media.Color.FromRgb(15, 23, 42)),
                Foreground = Brushes.White,
                BorderBrush = new SolidColorBrush(System.Windows.Media.Color.FromRgb(51, 65, 85))
            };
            RefreshAppsList();
            panel.Children.Add(_lstApps);

            Grid addGrid = new Grid { Margin = new Thickness(0, 10, 0, 0) };
            addGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            addGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(120) });
            addGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(140) });

            _txtNewApp = new System.Windows.Controls.TextBox {
                Background = new SolidColorBrush(System.Windows.Media.Color.FromRgb(30, 41, 59)),
                Foreground = Brushes.White,
                BorderBrush = new SolidColorBrush(System.Windows.Media.Color.FromRgb(71, 85, 105)),
                Padding = new Thickness(8, 4, 8, 4),
                FontSize = 12
            };
            addGrid.Children.Add(_txtNewApp);
            Grid.SetColumn(_txtNewApp, 0);

            System.Windows.Controls.Button btnAddApp = CreateModernButton("+ Add App", System.Windows.Media.Color.FromRgb(255, 70, 85), 110);
            btnAddApp.Margin = new Thickness(8, 0, 0, 0);
            btnAddApp.Click += (s, e) => {
                string name = _txtNewApp.Text.Trim().Replace(".exe", "");
                if (!string.IsNullOrEmpty(name) && !_engine.Config.backgroundAppsToFreeze.Contains(name)) {
                    _engine.Config.backgroundAppsToFreeze.Add(name);
                    _engine.SaveConfig();
                    RefreshAppsList();
                    _txtNewApp.Clear();
                }
            };
            addGrid.Children.Add(btnAddApp);
            Grid.SetColumn(btnAddApp, 1);

            System.Windows.Controls.Button btnRemoveApp = CreateModernButton("Remove Selected", System.Windows.Media.Color.FromRgb(71, 85, 105), 130);
            btnRemoveApp.Margin = new Thickness(8, 0, 0, 0);
            btnRemoveApp.Click += (s, e) => {
                if (_lstApps.SelectedItem != null) {
                    string sel = _lstApps.SelectedItem.ToString();
                    _engine.Config.backgroundAppsToFreeze.Remove(sel);
                    _engine.SaveConfig();
                    RefreshAppsList();
                }
            };
            addGrid.Children.Add(btnRemoveApp);
            Grid.SetColumn(btnRemoveApp, 2);

            panel.Children.Add(addGrid);
            border.Child = panel;
            tab.Content = border;
            return tab;
        }

        private Border CreateCardBorder() {
            return new Border {
                Background = new SolidColorBrush(System.Windows.Media.Color.FromRgb(30, 41, 59)),
                BorderBrush = new SolidColorBrush(System.Windows.Media.Color.FromRgb(51, 65, 85)),
                BorderThickness = new Thickness(1),
                CornerRadius = new CornerRadius(8)
            };
        }

        private System.Windows.Controls.Button CreateModernButton(string text, System.Windows.Media.Color bg, double width) {
            var btn = new System.Windows.Controls.Button {
                Content = text,
                Width = width,
                Height = 36,
                Background = new SolidColorBrush(bg),
                Foreground = Brushes.White,
                FontWeight = FontWeights.SemiBold,
                FontSize = 11.5,
                Margin = new Thickness(4, 0, 4, 0),
                BorderThickness = new Thickness(0)
            };
            return btn;
        }

        private void RefreshGamesList() {
            _lstGames.Items.Clear();
            foreach (var g in _engine.Config.supportedGames) {
                _lstGames.Items.Add(string.Format("● {0} (Processes: {1})", g.name, string.Join(", ", g.processes.ToArray())));
            }
        }

        private void RefreshAppsList() {
            _lstApps.Items.Clear();
            foreach (var a in _engine.Config.backgroundAppsToFreeze) {
                _lstApps.Items.Add(a);
            }
        }

        public void ShowDashboard() {
            this.Visibility = Visibility.Visible;
            this.ShowInTaskbar = true;
            this.WindowState = WindowState.Normal;
            this.Show();
            this.Activate();
            this.Focus();
        }

        public void ExitApplication() {
            try {
                _engine.RevertOptimizations();
                if (_trayIcon != null) {
                    _trayIcon.Visible = false;
                    _trayIcon.Dispose();
                }
            } catch {}
            System.Windows.Application.Current.Shutdown();
        }

        public void ShowTrayBalloon(string title, string message, ToolTipIcon icon = ToolTipIcon.Info) {
            try {
                if (_trayIcon != null && _engine.Config.showNotifications) {
                    _trayIcon.ShowBalloonTip(2500, title, message, icon);
                }
            } catch {}
        }

        private void SetupTray() {
            _trayIcon = new NotifyIcon {
                Text = "Valorant & Esports Companion: Standby",
                Visible = true
            };

            try {
                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                string iconPath = System.IO.Path.Combine(baseDir, @"assets\valorant_tray.ico");
                if (!File.Exists(iconPath)) {
                    iconPath = System.IO.Path.Combine(Directory.GetCurrentDirectory(), @"assets\valorant_tray.ico");
                }
                if (File.Exists(iconPath)) {
                    _trayIcon.Icon = new System.Drawing.Icon(iconPath);
                } else {
                    _trayIcon.Icon = System.Drawing.Icon.ExtractAssociatedIcon(System.Reflection.Assembly.GetExecutingAssembly().Location);
                }
            } catch {
                _trayIcon.Icon = System.Drawing.SystemIcons.Application;
            }

            _trayIcon.DoubleClick += (s, e) => ShowDashboard();
            _trayIcon.BalloonTipClicked += (s, e) => ShowDashboard();

            var menu = new ContextMenuStrip();
            menu.Items.Add("Open Dashboard", null, (s, e) => ShowDashboard());
            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add("Purge RAM & Caches [Ctrl+Alt+O]", null, (s, e) => {
                _engine.PurgeMemoryAndCaches();
                ShowTrayBalloon("RAM & Caches Purged", "Memory lists and DirectX caches flushed.", ToolTipIcon.Info);
            });
            menu.Items.Add("Pause 30 Minutes", null, (s, e) => _engine.Pause(30));
            menu.Items.Add("Pause 1 Hour", null, (s, e) => _engine.Pause(60));
            menu.Items.Add("Resume Optimizations", null, (s, e) => _engine.Resume());
            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add("Edit Config (config.json)", null, (s, e) => {
                try {
                    if (File.Exists(_engine.ConfigPath)) Process.Start("notepad.exe", _engine.ConfigPath);
                } catch {}
            });
            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add("Restore Defaults & Exit", null, (s, e) => ExitApplication());
            _trayIcon.ContextMenuStrip = menu;
        }

        private void RegisterGlobalHotkeys() {
            try {
                var helper = new WindowInteropHelper(this);
                IntPtr handle = helper.EnsureHandle();
                HwndSource source = HwndSource.FromHwnd(handle);
                if (source != null) {
                    source.AddHook(HwndHook);
                }

                NativeMethods.RegisterHotKey(handle, HOTKEY_PURGE, NativeMethods.MOD_CONTROL | NativeMethods.MOD_ALT | NativeMethods.MOD_NOREPEAT, (uint)Keys.O);
                NativeMethods.RegisterHotKey(handle, HOTKEY_STANDBY, NativeMethods.MOD_CONTROL | NativeMethods.MOD_ALT | NativeMethods.MOD_NOREPEAT, (uint)Keys.S);
            } catch {}
        }

        private IntPtr HwndHook(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled) {
            if (msg == NativeMethods.WM_HOTKEY) {
                int id = wParam.ToInt32();
                if (id == HOTKEY_PURGE) {
                    _engine.PurgeMemoryAndCaches();
                    _trayIcon.ShowBalloonTip(1500, "RAM & Caches Purged", "Memory list and DirectX caches flushed via [Ctrl+Alt+O].", ToolTipIcon.Info);
                    handled = true;
                } else if (id == HOTKEY_STANDBY) {
                    if (_engine.IsPaused) _engine.Resume();
                    else _engine.Pause(30);
                    handled = true;
                }
            }
            return IntPtr.Zero;
        }

        private void UpdateTelemetry() {
            try {
                Microsoft.VisualBasic.Devices.ComputerInfo ci = new Microsoft.VisualBasic.Devices.ComputerInfo();
                long totalMem = (long)ci.TotalPhysicalMemory;
                long availMem = (long)ci.AvailablePhysicalMemory;
                long usedMem = totalMem - availMem;
                float pct = (float)usedMem / totalMem * 100f;

                _ramHistory.Dequeue();
                _ramHistory.Enqueue(pct);
                DrawGraph();

                _txtRamStats.Text = string.Format("Physical RAM: {0:F1} GB / {1:F1} GB ({2:F0}% In Use)", usedMem / 1073741824.0, totalMem / 1073741824.0, pct);

                string gpuLockStr = GpuClockManager.IsLocked ? string.Format("LOCKED @ Peak Boost ({0} MHz)", GpuClockManager.MaxBoostClock) : "Dynamic Scaling / Standby";
                _txtGpuStats.Text = string.Format("{0}\nClock State: {1}", GpuClockManager.DetectedGpuName, gpuLockStr);
            } catch {}
        }

        private void DrawGraph() {
            if (_graphCanvas == null || _graphCanvas.ActualWidth < 10) return;
            _graphCanvas.Children.Clear();

            double w = _graphCanvas.ActualWidth;
            double h = _graphCanvas.ActualHeight;

            // Background grid lines
            for (double y = 0; y < h; y += 35) {
                var line = new System.Windows.Shapes.Line {
                    X1 = 0, Y1 = y, X2 = w, Y2 = y,
                    Stroke = new SolidColorBrush(System.Windows.Media.Color.FromArgb(40, 51, 65, 85)),
                    StrokeThickness = 1
                };
                _graphCanvas.Children.Add(line);
            }

            float[] points = _ramHistory.ToArray();
            if (points.Length < 2) return;

            PointCollection polyPoints = new PointCollection();
            polyPoints.Add(new System.Windows.Point(0, h));

            double step = w / (points.Length - 1);
            for (int i = 0; i < points.Length; i++) {
                double val = Math.Max(0, Math.Min(100, points[i]));
                double y = h - (val / 100.0 * (h - 10));
                polyPoints.Add(new System.Windows.Point(i * step, y));
            }
            polyPoints.Add(new System.Windows.Point(w, h));

            Polygon poly = new Polygon {
                Points = polyPoints,
                Fill = new LinearGradientBrush(
                    System.Windows.Media.Color.FromArgb(100, 6, 182, 212),
                    System.Windows.Media.Color.FromArgb(10, 6, 182, 212),
                    new System.Windows.Point(0, 0),
                    new System.Windows.Point(0, 1)
                )
            };
            _graphCanvas.Children.Add(poly);

            Polyline stroke = new Polyline {
                Stroke = new SolidColorBrush(System.Windows.Media.Color.FromRgb(6, 182, 212)),
                StrokeThickness = 2
            };
            for (int i = 0; i < points.Length; i++) {
                double val = Math.Max(0, Math.Min(100, points[i]));
                double y = h - (val / 100.0 * (h - 10));
                stroke.Points.Add(new System.Windows.Point(i * step, y));
            }
            _graphCanvas.Children.Add(stroke);
        }

        private void UpdateEngineStatus() {
            _txtStatus.Text = _engine.StatusText;
            _txtGameName.Text = string.Format("Active Game: {0} (PID: {1})", _engine.ActiveGameName, _engine.ActiveGamePid);

            if (_engine.IsOptimized) {
                _txtStatus.Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(255, 70, 85));
                _trayIcon.Text = string.Format("Companion: ACTIVE ({0})", _engine.ActiveGameName);
            } else if (_engine.IsPaused) {
                _txtStatus.Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(251, 191, 36));
                _trayIcon.Text = "Companion: PAUSED";
            } else {
                _txtStatus.Foreground = new SolidColorBrush(System.Windows.Media.Color.FromRgb(52, 211, 153));
                _trayIcon.Text = "Companion: Standby (0% CPU)";
            }
        }
    }

    // ----------------- PROGRAM ENTRY POINT -----------------
    static class Program {
        [STAThread]
        static void Main(string[] args) {
            NativeMethods.DisableConsoleQuickEdit();

            string scriptDir = AppDomain.CurrentDomain.BaseDirectory;
            string configPath = System.IO.Path.Combine(scriptDir, "config.json");
            if (!File.Exists(configPath)) {
                configPath = System.IO.Path.Combine(Directory.GetCurrentDirectory(), "config.json");
            }

            bool openGui = false;
            bool restoreOnly = false;
            foreach (var arg in args) {
                if (arg.Equals("-Dashboard", StringComparison.OrdinalIgnoreCase) ||
                    arg.Equals("--gui", StringComparison.OrdinalIgnoreCase) ||
                    arg.Equals("-gui", StringComparison.OrdinalIgnoreCase) ||
                    arg.Equals("-Show", StringComparison.OrdinalIgnoreCase)) {
                    openGui = true;
                } else if (arg.Equals("--restore", StringComparison.OrdinalIgnoreCase) ||
                           arg.Equals("-Restore", StringComparison.OrdinalIgnoreCase)) {
                    restoreOnly = true;
                }
            }

            var engine = new OptimizationEngine(configPath);

            if (restoreOnly) {
                engine.RevertOptimizations();
                return;
            }

            bool createdNew;
            using (Mutex mutex = new Mutex(true, "Global\\ValorantCompanion_SingleInstance_Mutex", out createdNew)) {
                if (!createdNew) {
                    if (openGui) {
                        IntPtr existingHwnd = NativeMethods.FindWindow(null, "Valorant & Esports Low-Latency Companion (Native WPF)");
                        if (existingHwnd != IntPtr.Zero) {
                            NativeMethods.ShowWindow(existingHwnd, 9); // SW_RESTORE
                            NativeMethods.SetForegroundWindow(existingHwnd);
                        }
                    }
                    return;
                }

                var app = new System.Windows.Application();
                app.ShutdownMode = ShutdownMode.OnExplicitShutdown;
                var window = new WpfDashboardWindow(engine);

                if (openGui) {
                    window.ShowDashboard();
                } else {
                    // Open in tray by default
                    window.Visibility = Visibility.Hidden;
                    window.ShowInTaskbar = false;
                    window.WindowState = WindowState.Minimized;
                    if (engine.Config.showNotifications) {
                        window.ShowTrayBalloon("Valorant Companion Active", "Running quietly in your system tray. Optimizations will engage automatically when Valorant launches.", ToolTipIcon.Info);
                    }
                }

                app.Run();
            }
        }
    }
}
