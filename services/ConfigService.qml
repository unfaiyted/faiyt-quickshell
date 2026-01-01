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
            mode: "normal"  // normal, focus, nothing
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
    property string timeFormat: config.time?.format || "%H:%M"
    property string weatherCity: config.weather?.city || ""
    property string temperatureUnit: config.weather?.preferredUnit || "C"
    property int batteryLow: config.battery?.low || 20
    property int batteryCritical: config.battery?.critical || 10
    property int animationDuration: config.animations?.durationSmall || 200
    property int launcherMaxResults: config.launcher?.maxResults || 10

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
        timeFormat = config.time?.format || "%H:%M"
        weatherCity = config.weather?.city || ""
        temperatureUnit = config.weather?.preferredUnit || "C"
        batteryLow = config.battery?.low || 20
        batteryCritical = config.battery?.critical || 10
        animationDuration = config.animations?.durationSmall || 200
        launcherMaxResults = config.launcher?.maxResults || 10
        // AI config (API key from env var only)
        aiDefaultModel = config.ai?.defaultModel || "claude-sonnet-4-5-20250929"
        aiModels = config.ai?.models || []
        aiMaxTokens = config.ai?.maxTokens || 4096
        aiTemperature = config.ai?.temperature || 1.0
        aiSystemPrompt = config.ai?.systemPrompt || ""
        aiMcpServers = config.ai?.mcpServers || []
    }
}
