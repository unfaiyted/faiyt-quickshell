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
        bar: {
            mode: "normal",  // normal, focus, nothing
            workspacesPerPage: 10,  // Number of workspaces to show at once
            modules: {
                windowTitle: true,
                workspaces: true,
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
                upload: true
            }
        },

        // Utility defaults
        utilities: {
            recording: {
                defaultMode: "record"  // "record", "record-hq", "record-gif"
            },
            screenshot: {
                annotateEnabled: false
            }
        },

        // Time & Weather
        time: {
            format: "%H:%M"
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

        // Search features
        search: {
            enableFeatures: {
                listPrefixes: true,
                actions: true,
                commands: true,
                mathResults: true,
                directorySearch: false,
                aiSearch: false,
                webSearch: false
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
        }
    })

    // Current configuration (merged with defaults)
    property var config: JSON.parse(JSON.stringify(defaultConfig))

    // Initialize on creation
    Component.onCompleted: {
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
                } catch (e) {
                    console.log("ConfigService: Parse error, using defaults:", e)
                }
                configBuffer = ""
            } else if (!running) {
                console.log("ConfigService: No config file, using defaults")
            }
        }
    }

    // Save configuration to file
    function saveConfig() {
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
        // Force property change notification by reassigning
        config = config
    }

    // Convenience property accessors for common settings
    property string theme: config.theme || "rose-pine"
    property string barMode: config.bar?.mode || "normal"
    property int workspacesPerPage: config.bar?.workspacesPerPage || 10
    property string timeFormat: config.time?.format || "%H:%M"
    property string weatherCity: config.weather?.city || ""
    property string temperatureUnit: config.weather?.preferredUnit || "C"
    property int batteryLow: config.battery?.low || 20
    property int batteryCritical: config.battery?.critical || 10
    property int animationDuration: config.animations?.durationSmall || 200
    property int launcherMaxResults: config.launcher?.maxResults || 10

    // Bar module visibility convenience properties
    property bool barModuleWindowTitle: config.bar?.modules?.windowTitle !== false
    property bool barModuleWorkspaces: config.bar?.modules?.workspaces !== false
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

    // Utility defaults convenience properties
    property string recordingDefaultMode: config.utilities?.recording?.defaultMode || "record"
    property bool screenshotAnnotateEnabled: config.utilities?.screenshot?.annotateEnabled || false

    // AI convenience accessors (API key from env var only)
    property string aiDefaultModel: config.ai?.defaultModel || "claude-sonnet-4-5-20250929"
    property var aiModels: config.ai?.models || []
    property int aiMaxTokens: config.ai?.maxTokens || 4096
    property real aiTemperature: config.ai?.temperature || 1.0
    property string aiSystemPrompt: config.ai?.systemPrompt || ""
    property var aiMcpServers: config.ai?.mcpServers || []

    // Update convenience properties when config changes
    onConfigChanged: {
        theme = config.theme || "rose-pine"
        barMode = config.bar?.mode || "normal"
        workspacesPerPage = config.bar?.workspacesPerPage || 10
        timeFormat = config.time?.format || "%H:%M"
        weatherCity = config.weather?.city || ""
        temperatureUnit = config.weather?.preferredUnit || "C"
        batteryLow = config.battery?.low || 20
        batteryCritical = config.battery?.critical || 10
        animationDuration = config.animations?.durationSmall || 200
        launcherMaxResults = config.launcher?.maxResults || 10

        // Bar module visibility
        barModuleWindowTitle = config.bar?.modules?.windowTitle !== false
        barModuleWorkspaces = config.bar?.modules?.workspaces !== false
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

        // Utility defaults
        recordingDefaultMode = config.utilities?.recording?.defaultMode || "record"
        screenshotAnnotateEnabled = config.utilities?.screenshot?.annotateEnabled || false

        // AI config (API key from env var only)
        aiDefaultModel = config.ai?.defaultModel || "claude-sonnet-4-5-20250929"
        aiModels = config.ai?.models || []
        aiMaxTokens = config.ai?.maxTokens || 4096
        aiTemperature = config.ai?.temperature || 1.0
        aiSystemPrompt = config.ai?.systemPrompt || ""
        aiMcpServers = config.ai?.mcpServers || []
    }
}
