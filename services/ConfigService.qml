pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: configService

    // Config file path
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/faiyt-qs"
    readonly property string configPath: configDir + "/config.json"

    // Default configuration
    property var defaultConfig: ({
        // Appearance
        theme: "rose-pine",
        customThemes: {},  // User-created custom themes
        fonts: {
            ui: "",                      // Empty = system default
            mono: "monospace",
            icon: "Symbols Nerd Font",
            emoji: "Noto Color Emoji",
            scale: 1.0
        },
        bar: {
            mode: "normal",  // normal, focus, nothing
            workspacesPerPage: 10,  // Number of workspaces to show at once
            modules: {
                distroIcon: true,
                windowTitle: true,
                workspaces: true,
                micIndicator: true,
                systemResources: true,
                utilities: true,
                music: true,
                systemTray: true,
                network: true,
                battery: true,
                clock: true,
                weather: true
            },
            utilities: {
                screenshot: true,
                recording: true,
                colorPicker: true,
                wallpaper: true
            },
            systemResources: {
                ram: true,
                swap: true,
                cpu: true,
                download: true,
                upload: true,
                gpu: false,       // NVIDIA GPU usage (requires nvidia-smi)
                gpuTemp: false,   // NVIDIA GPU temperature
                cpuTemp: false    // CPU temperature via hwmon
            }
        },

        // Utility defaults
        utilities: {
            recording: {
                defaultMode: "record",  // "record", "record-hq", "record-gif"
                savePath: ""            // Empty = default ~/Videos/Recordings
            },
            screenshot: {
                annotateEnabled: false,
                savePath: ""            // Empty = default ~/Pictures/Screenshots
            }
        },

        // Time & Weather
        time: {
            format: "%H:%M",
            timezones: []  // [{id: "America/New_York", label: "New York"}, ...]
        },
        weather: {
            city: "",
            preferredUnit: "C"  // C or F
        },

        // Battery
        battery: {
            low: 20,
            critical: 10
        },

        // Animations
        animations: {
            durationSmall: 200,
            choreographyDelay: 20
        },

        // Launcher
        launcher: {
            maxResults: 10
        },

        // Overview
        overview: {
            itemsPerRow: 5,    // columns
            totalItems: 10     // total workspaces shown
        },

        // Search features
        search: {
            enableFeatures: {
                listPrefixes: true,
                actions: true,
                commands: true,
                mathResults: true,
                directorySearch: false,
                aiSearch: false,
                webSearch: false,
                gifSearch: true,
                tmuxSearch: true,
                bookmarkSearch: true
            },
            evaluators: {
                mathEvaluator: true,
                baseConverter: true,
                colorConverter: true,
                dateCalculator: true,
                percentageCalculator: true,
                timeCalculator: true,
                unitConverter: true
            }
        },

        // Stickers
        stickers: {
            enabled: true,
            packs: []  // [{id: string, key: string, name: string}]
        },

        // Bookmarks
        bookmarks: {
            browserType: "auto",        // "auto", "firefox", "zen"
            profilePath: "",            // Custom profile path (empty = auto-detect)
            showFavicons: true,         // Enable favicon fetching
            refreshOnOpen: true         // Refresh bookmarks when launcher opens
        },

        // AI Configuration (API keys use environment variables for security)
        ai: {
            // API key from ANTHROPIC_API_KEY env var - never stored in config
            defaultModel: "claude-sonnet-4-5-20250929",
            models: [
                "claude-sonnet-4-5-20250929",
                "claude-haiku-4-5-20251015",
                "claude-opus-4-5-20251101",
                "claude-sonnet-4-20250514",
                "claude-opus-4-1-20250805"
            ],
            maxTokens: 4096,
            temperature: 1.0,
            systemPrompt: "",
            mcpServers: []  // [{id, name, command, env, enabled}]
        },

        // Sidebar Quick Toggles
        sidebar: {
            quickToggles: {
                showFocusMode: false,      // Off by default
                showPowerSaver: false,     // Off by default
                vpnConnectionName: "",     // User configures
                nightLightTemp: 4500       // Kelvin temperature
            }
        },

        // Windows & Components
        windows: {
            bar: {
                enabled: true,
                corners: true
            },
            launcher: {
                enabled: true
            },
            sidebar: {
                leftEnabled: true,
                rightEnabled: true
            },
            overlays: {
                enabled: true,
                notifications: true,
                indicators: true,
                music: true,
                wallpaper: true
            },
            settings: {
                enabled: true
            }
        },

        // Requirements checking
        requirements: {
            dontShowOnStartup: false
        },

        // Indicators (OSD overlays)
        indicators: {
            enabled: true,
            timeout: 3000,              // ms before fade out
            showVolume: true,
            showBrightness: true,
            showKeyboardBacklight: true
        },

        // System state persistence (restored on startup)
        systemState: {
            lastVolume: null,           // 0-100, restored on startup
            lastBrightness: null,       // 0-100, restored on startup
            lastKbBrightness: null      // 0-100, restored on startup
        },

        // External programs configuration
        externalPrograms: {
            terminal: "kitty",          // Terminal emulator
            terminalExecFlag: "-e",     // Flag to execute command
            terminalCustom: "",         // Custom terminal if "custom" selected
            fileManager: "xdg-open",    // File manager
            fileManagerCustom: "",      // Custom file manager
            browser: "xdg-open",        // Browser
            browserCustom: "",          // Custom browser
            annotator: "napkin",        // Screenshot annotator
            annotatorCustom: ""         // Custom annotator
        }
    })

    // Current configuration (merged with defaults)
    property var config: JSON.parse(JSON.stringify(defaultConfig))

    // Flag to prevent saving before config is loaded
    property bool configLoaded: false

    // Initialize on creation
    Component.onCompleted: {
        configLoaded = false
        ensureConfigDir()
        loadConfig()
    }

    // Ensure config directory exists
    function ensureConfigDir() {
        mkdirProcess.running = true
    }

    Process {
        id: mkdirProcess
        command: ["mkdir", "-p", configService.configDir]
    }

    // Load configuration from file
    function loadConfig() {
        configBuffer = ""
        loadProcess.running = true
    }

    property string configBuffer: ""

    Process {
        id: loadProcess
        command: ["cat", configService.configPath]
        stdout: SplitParser {
            onRead: data => {
                configService.configBuffer += data + "\n"
            }
        }
        onRunningChanged: {
            if (!running && configBuffer.length > 0) {
                try {
                    const loaded = JSON.parse(configBuffer)
                    // Deep merge with defaults
                    configService.config = deepMerge(JSON.parse(JSON.stringify(configService.defaultConfig)), loaded)
                    console.log("ConfigService: Config loaded successfully")
                    console.log("  - Sticker packs in loaded config:", loaded.stickers?.packs?.length || 0)
                    console.log("  - Sticker packs after merge:", configService.config.stickers?.packs?.length || 0)
                } catch (e) {
                    console.log("ConfigService: Parse error, using defaults:", e)
                }
                configBuffer = ""
                configService.configLoaded = true
            } else if (!running) {
                console.log("ConfigService: No config file, using defaults")
                configService.configLoaded = true
            }
        }
    }

    // Save configuration to file
    function saveConfig() {
        // Prevent saving defaults before config is loaded
        if (!configLoaded) {
            console.log("ConfigService: Skipping save, config not yet loaded")
            return
        }
        const jsonStr = JSON.stringify(config, null, 2)
        saveProcess.command = ["bash", "-c", "echo '" + jsonStr.replace(/'/g, "'\\''") + "' > " + configPath]
        saveProcess.running = true
    }

    Process {
        id: saveProcess
        onRunningChanged: {
            if (!running) {
                console.log("ConfigService: Config saved")
            }
        }
    }

    // Deep merge helper
    function deepMerge(target, source) {
        for (let key in source) {
            if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {
                if (!target[key]) target[key] = {}
                deepMerge(target[key], source[key])
            } else {
                target[key] = source[key]
            }
        }
        return target
    }

    // Get value by dot notation path
    function getValue(path) {
        const parts = path.split('.')
        let current = config
        for (let part of parts) {
            if (current === undefined || current === null) return undefined
            current = current[part]
        }
        return current
    }

    // Set value by dot notation path
    function setValue(path, value) {
        const parts = path.split('.')
        let current = config
        for (let i = 0; i < parts.length - 1; i++) {
            if (!current[parts[i]]) current[parts[i]] = {}
            current = current[parts[i]]
        }
        current[parts[parts.length - 1]] = value
        // Force property change notification by cloning the config object
        config = JSON.parse(JSON.stringify(config))
    }

    // Convenience property accessors for common settings
    property string theme: config.theme || "rose-pine"
    property string barMode: config.bar?.mode || "normal"
    property int workspacesPerPage: config.bar?.workspacesPerPage || 10
    property string timeFormat: config.time?.format || "%H:%M"
    property var timezones: config.time?.timezones || []
    property string weatherCity: config.weather?.city || ""
    property string temperatureUnit: config.weather?.preferredUnit || "C"
    property int batteryLow: config.battery?.low || 20
    property int batteryCritical: config.battery?.critical || 10
    property int animationDuration: config.animations?.durationSmall || 200
    property int launcherMaxResults: config.launcher?.maxResults || 10
    property int overviewItemsPerRow: config.overview?.itemsPerRow || 5
    property int overviewTotalItems: config.overview?.totalItems || 10

    // Bar module visibility convenience properties
    property bool barModuleDistroIcon: config.bar?.modules?.distroIcon !== false
    property bool barModuleWindowTitle: config.bar?.modules?.windowTitle !== false
    property bool barModuleWorkspaces: config.bar?.modules?.workspaces !== false
    property bool barModuleMicIndicator: config.bar?.modules?.micIndicator !== false
    property bool barModuleSystemResources: config.bar?.modules?.systemResources !== false
    property bool barModuleUtilities: config.bar?.modules?.utilities !== false
    property bool barModuleMusic: config.bar?.modules?.music !== false
    property bool barModuleSystemTray: config.bar?.modules?.systemTray !== false
    property bool barModuleNetwork: config.bar?.modules?.network !== false
    property bool barModuleBattery: config.bar?.modules?.battery !== false
    property bool barModuleClock: config.bar?.modules?.clock !== false
    property bool barModuleWeather: config.bar?.modules?.weather !== false

    // Bar utility button visibility convenience properties
    property bool barUtilityScreenshot: config.bar?.utilities?.screenshot !== false
    property bool barUtilityRecording: config.bar?.utilities?.recording !== false
    property bool barUtilityColorPicker: config.bar?.utilities?.colorPicker !== false
    property bool barUtilityWallpaper: config.bar?.utilities?.wallpaper !== false

    // System resource visibility convenience properties
    property bool barResourceRam: config.bar?.systemResources?.ram !== false
    property bool barResourceSwap: config.bar?.systemResources?.swap !== false
    property bool barResourceCpu: config.bar?.systemResources?.cpu !== false
    property bool barResourceDownload: config.bar?.systemResources?.download !== false
    property bool barResourceUpload: config.bar?.systemResources?.upload !== false
    property bool barResourceGpu: config.bar?.systemResources?.gpu === true
    property bool barResourceGpuTemp: config.bar?.systemResources?.gpuTemp === true
    property bool barResourceCpuTemp: config.bar?.systemResources?.cpuTemp === true

    // Utility defaults convenience properties
    property string recordingDefaultMode: config.utilities?.recording?.defaultMode || "record"
    property string recordingSavePath: config.utilities?.recording?.savePath || ""
    property bool screenshotAnnotateEnabled: config.utilities?.screenshot?.annotateEnabled || false
    property string screenshotSavePath: config.utilities?.screenshot?.savePath || ""

    // Window enable/disable convenience properties
    property bool windowBarEnabled: config.windows?.bar?.enabled !== false
    property bool windowBarCorners: config.windows?.bar?.corners !== false
    property bool windowLauncherEnabled: config.windows?.launcher?.enabled !== false
    property bool windowSidebarLeftEnabled: config.windows?.sidebar?.leftEnabled !== false
    property bool windowSidebarRightEnabled: config.windows?.sidebar?.rightEnabled !== false
    property bool windowOverlaysEnabled: config.windows?.overlays?.enabled !== false
    property bool windowNotificationsEnabled: config.windows?.overlays?.notifications !== false
    property bool windowWallpaperEnabled: config.windows?.overlays?.wallpaper !== false

    // Quick Toggles convenience properties
    property bool quickToggleFocusMode: config.sidebar?.quickToggles?.showFocusMode ?? false
    property bool quickTogglePowerSaver: config.sidebar?.quickToggles?.showPowerSaver ?? false
    property string quickToggleVpnName: config.sidebar?.quickToggles?.vpnConnectionName ?? ""
    property int quickToggleNightTemp: config.sidebar?.quickToggles?.nightLightTemp ?? 4500

    // Sticker convenience properties
    property bool stickersEnabled: config.stickers?.enabled !== false
    property var stickerPacks: config.stickers?.packs || []

    // Custom themes convenience property
    property var customThemes: config.customThemes || {}

    // AI convenience accessors (API key from env var only)
    property string aiDefaultModel: config.ai?.defaultModel || "claude-sonnet-4-5-20250929"
    property var aiModels: config.ai?.models || []
    property int aiMaxTokens: config.ai?.maxTokens || 4096
    property real aiTemperature: config.ai?.temperature || 1.0
    property string aiSystemPrompt: config.ai?.systemPrompt || ""
    property var aiMcpServers: config.ai?.mcpServers || []

    // Indicator convenience properties
    property bool indicatorsEnabled: config.indicators?.enabled !== false
    property int indicatorTimeout: config.indicators?.timeout ?? 3000
    property bool indicatorShowVolume: config.indicators?.showVolume !== false
    property bool indicatorShowBrightness: config.indicators?.showBrightness !== false
    property bool indicatorShowKeyboardBacklight: config.indicators?.showKeyboardBacklight !== false

    // External programs convenience properties
    property string terminalCommand: {
        let t = config.externalPrograms?.terminal || "kitty"
        return t === "custom" ? (config.externalPrograms?.terminalCustom || "kitty") : t
    }
    property string terminalExecFlag: config.externalPrograms?.terminalExecFlag || "-e"
    property string fileManagerCommand: {
        let fm = config.externalPrograms?.fileManager || "xdg-open"
        return fm === "custom" ? (config.externalPrograms?.fileManagerCustom || "xdg-open") : fm
    }
    property string browserCommand: {
        let b = config.externalPrograms?.browser || "xdg-open"
        return b === "custom" ? (config.externalPrograms?.browserCustom || "xdg-open") : b
    }
    property string annotatorCommand: {
        let a = config.externalPrograms?.annotator || "napkin"
        return a === "custom" ? (config.externalPrograms?.annotatorCustom || "napkin") : a
    }

    // Update convenience properties when config changes
    onConfigChanged: {
        theme = config.theme || "rose-pine"
        barMode = config.bar?.mode || "normal"
        workspacesPerPage = config.bar?.workspacesPerPage || 10
        timeFormat = config.time?.format || "%H:%M"
        timezones = config.time?.timezones || []
        weatherCity = config.weather?.city || ""
        temperatureUnit = config.weather?.preferredUnit || "C"
        batteryLow = config.battery?.low || 20
        batteryCritical = config.battery?.critical || 10
        animationDuration = config.animations?.durationSmall || 200
        launcherMaxResults = config.launcher?.maxResults || 10
        overviewItemsPerRow = config.overview?.itemsPerRow || 5
        overviewTotalItems = config.overview?.totalItems || 10

        // Bar module visibility
        barModuleDistroIcon = config.bar?.modules?.distroIcon !== false
        barModuleWindowTitle = config.bar?.modules?.windowTitle !== false
        barModuleWorkspaces = config.bar?.modules?.workspaces !== false
        barModuleMicIndicator = config.bar?.modules?.micIndicator !== false
        barModuleSystemResources = config.bar?.modules?.systemResources !== false
        barModuleUtilities = config.bar?.modules?.utilities !== false
        barModuleMusic = config.bar?.modules?.music !== false
        barModuleSystemTray = config.bar?.modules?.systemTray !== false
        barModuleNetwork = config.bar?.modules?.network !== false
        barModuleBattery = config.bar?.modules?.battery !== false
        barModuleClock = config.bar?.modules?.clock !== false
        barModuleWeather = config.bar?.modules?.weather !== false

        // Bar utility button visibility
        barUtilityScreenshot = config.bar?.utilities?.screenshot !== false
        barUtilityRecording = config.bar?.utilities?.recording !== false
        barUtilityColorPicker = config.bar?.utilities?.colorPicker !== false
        barUtilityWallpaper = config.bar?.utilities?.wallpaper !== false

        // System resource visibility
        barResourceRam = config.bar?.systemResources?.ram !== false
        barResourceSwap = config.bar?.systemResources?.swap !== false
        barResourceCpu = config.bar?.systemResources?.cpu !== false
        barResourceDownload = config.bar?.systemResources?.download !== false
        barResourceUpload = config.bar?.systemResources?.upload !== false
        barResourceGpu = config.bar?.systemResources?.gpu === true
        barResourceGpuTemp = config.bar?.systemResources?.gpuTemp === true
        barResourceCpuTemp = config.bar?.systemResources?.cpuTemp === true

        // Utility defaults
        recordingDefaultMode = config.utilities?.recording?.defaultMode || "record"
        recordingSavePath = config.utilities?.recording?.savePath || ""
        screenshotAnnotateEnabled = config.utilities?.screenshot?.annotateEnabled || false
        screenshotSavePath = config.utilities?.screenshot?.savePath || ""

        // AI config (API key from env var only)
        aiDefaultModel = config.ai?.defaultModel || "claude-sonnet-4-5-20250929"
        aiModels = config.ai?.models || []
        aiMaxTokens = config.ai?.maxTokens || 4096
        aiTemperature = config.ai?.temperature || 1.0
        aiSystemPrompt = config.ai?.systemPrompt || ""
        aiMcpServers = config.ai?.mcpServers || []

        // Window enable/disable
        windowBarEnabled = config.windows?.bar?.enabled !== false
        windowBarCorners = config.windows?.bar?.corners !== false
        windowLauncherEnabled = config.windows?.launcher?.enabled !== false
        windowSidebarLeftEnabled = config.windows?.sidebar?.leftEnabled !== false
        windowSidebarRightEnabled = config.windows?.sidebar?.rightEnabled !== false
        windowOverlaysEnabled = config.windows?.overlays?.enabled !== false
        windowNotificationsEnabled = config.windows?.overlays?.notifications !== false
        windowWallpaperEnabled = config.windows?.overlays?.wallpaper !== false

        // Quick Toggles
        quickToggleFocusMode = config.sidebar?.quickToggles?.showFocusMode ?? false
        quickTogglePowerSaver = config.sidebar?.quickToggles?.showPowerSaver ?? false
        quickToggleVpnName = config.sidebar?.quickToggles?.vpnConnectionName ?? ""
        quickToggleNightTemp = config.sidebar?.quickToggles?.nightLightTemp ?? 4500

        // Stickers
        stickersEnabled = config.stickers?.enabled !== false
        stickerPacks = config.stickers?.packs || []

        // Custom themes
        customThemes = config.customThemes || {}

        // Indicators
        indicatorsEnabled = config.indicators?.enabled !== false
        indicatorTimeout = config.indicators?.timeout ?? 3000
        indicatorShowVolume = config.indicators?.showVolume !== false
        indicatorShowBrightness = config.indicators?.showBrightness !== false
        indicatorShowKeyboardBacklight = config.indicators?.showKeyboardBacklight !== false

        // External programs - these use computed properties, force re-evaluation
        let t = config.externalPrograms?.terminal || "kitty"
        terminalCommand = t === "custom" ? (config.externalPrograms?.terminalCustom || "kitty") : t
        terminalExecFlag = config.externalPrograms?.terminalExecFlag || "-e"
        let fm = config.externalPrograms?.fileManager || "xdg-open"
        fileManagerCommand = fm === "custom" ? (config.externalPrograms?.fileManagerCustom || "xdg-open") : fm
        let b = config.externalPrograms?.browser || "xdg-open"
        browserCommand = b === "custom" ? (config.externalPrograms?.browserCustom || "xdg-open") : b
        let a = config.externalPrograms?.annotator || "napkin"
        annotatorCommand = a === "custom" ? (config.externalPrograms?.annotatorCustom || "napkin") : a
    }
}
