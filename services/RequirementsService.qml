pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: requirementsService

    // Results of checks
    property var toolResults: ({})
    property var envResults: ({})
    property bool checkComplete: false
    property bool hasMissingRequired: false
    property bool hasMissingOptional: false
    property int installedCount: 0
    property int totalCount: 0

    // Define all requirements
    readonly property var requirements: [
        // Core (Required)
        { name: "quickshell", category: "Core", required: true, description: "Shell runtime" },
        { name: "hyprctl", category: "Core", required: true, description: "Hyprland WM control" },
        { name: "bash", category: "Core", required: true, description: "Shell execution" },

        // Clipboard (Required)
        { name: "wl-copy", category: "Clipboard", required: true, description: "Copy to clipboard" },
        { name: "wl-paste", category: "Clipboard", required: true, description: "Paste from clipboard" },

        // Audio
        { name: "wpctl", category: "Audio", required: true, description: "PipeWire audio control" },
        { name: "cava", category: "Audio", required: false, description: "Audio visualizer" },

        // Network (Required)
        { name: "nmcli", category: "Network", required: true, description: "NetworkManager control" },
        { name: "curl", category: "Network", required: true, description: "HTTP requests" },

        // Bluetooth (Required)
        { name: "bluetoothctl", category: "Bluetooth", required: true, description: "Bluetooth management" },
        { name: "busctl", category: "Bluetooth", required: true, description: "D-Bus queries" },

        // Power/System (Required)
        { name: "systemctl", category: "Power", required: true, description: "Power management" },
        { name: "systemd-inhibit", category: "Power", required: true, description: "Idle inhibit" },

        // Screen Capture (Optional)
        { name: "grim", category: "Screen Capture", required: false, description: "Screenshots" },
        { name: "slurp", category: "Screen Capture", required: false, description: "Area selection" },
        { name: "wf-recorder", category: "Screen Capture", required: false, description: "Screen recording" },
        { name: "hyprpicker", category: "Screen Capture", required: false, description: "Color picker" },
        { name: "napkin", category: "Screen Capture", required: false, description: "Screenshot annotation" },
        { name: "montage", category: "Screen Capture", required: false, description: "Multi-monitor screenshots" },

        // Media Processing (Optional)
        { name: "ffmpeg", category: "Media", required: false, description: "Video/GIF conversion" },
        { name: "ffprobe", category: "Media", required: false, description: "Media info" },
        { name: "convert", category: "Media", required: false, description: "ImageMagick conversion" },

        // Sticker Support (Optional)
        { name: "openssl", category: "Stickers", required: false, description: "Sticker decryption" },
        { name: "python3", category: "Stickers", required: false, description: "Protobuf parsing" },

        // Bookmark Search (Optional)
        { name: "sqlite3", category: "Bookmarks", required: false, description: "Browser bookmark database" },

        // System Info (Required)
        { name: "free", category: "System Info", required: true, description: "RAM usage" },
        { name: "top", category: "System Info", required: true, description: "CPU usage" },
        { name: "uptime", category: "System Info", required: true, description: "System uptime" },
        { name: "whoami", category: "System Info", required: true, description: "Username" },
        { name: "hostname", category: "System Info", required: true, description: "Hostname" },
        { name: "fc-list", category: "System Info", required: false, description: "Font listing" },

        // Quick Toggles (Optional)
        { name: "hyprsunset", category: "Quick Toggles", required: false, description: "Night light" },
        { name: "powerprofilesctl", category: "Quick Toggles", required: false, description: "Power profiles" },

        // Wallpaper (Optional)
        { name: "swww", category: "Wallpaper", required: false, description: "Animated wallpapers" },

        // Terminals (Optional)
        { name: "kitty", category: "Terminals", required: false, description: "Default terminal (configurable in Settings → External Programs)" },
        { name: "tmux", category: "Terminals", required: false, description: "Terminal multiplexer" },

        // Notifications (Optional)
        { name: "notify-send", category: "Notifications", required: false, description: "Desktop notifications" },

        // Utilities (Required)
        { name: "pgrep", category: "Utilities", required: true, description: "Process search" },
        { name: "pkill", category: "Utilities", required: true, description: "Process kill" },
        { name: "xdg-open", category: "Utilities", required: true, description: "Open files" },
        { name: "grep", category: "Utilities", required: true, description: "Text search" },
        { name: "awk", category: "Utilities", required: true, description: "Text processing" },
        { name: "sed", category: "Utilities", required: true, description: "Stream editing" }
    ]

    readonly property var envRequirements: [
        { name: "ANTHROPIC_API_KEY", category: "Environment", required: false, description: "AI Chat feature" },
        { name: "TENOR_API_KEY", category: "Environment", required: false, description: "GIF search" },
        { name: "QS_NET_SPEED_MBPS", category: "Environment", required: false, description: "Network speed calibration" }
    ]

    // Get unique categories
    readonly property var categories: {
        let cats = new Set()
        for (let req of requirements) {
            cats.add(req.category)
        }
        cats.add("Environment")
        return Array.from(cats)
    }

    // Get requirements by category
    function getByCategory(category) {
        if (category === "Environment") {
            return envRequirements.map(function(req) {
                return {
                    name: req.name,
                    category: req.category,
                    required: req.required,
                    description: req.description,
                    installed: envResults[req.name] || false
                }
            })
        }
        return requirements
            .filter(function(req) { return req.category === category })
            .map(function(req) {
                return {
                    name: req.name,
                    category: req.category,
                    required: req.required,
                    description: req.description,
                    installed: toolResults[req.name] || false
                }
            })
    }

    // Get category stats
    function getCategoryStats(category) {
        let items = getByCategory(category)
        let installed = items.filter(i => i.installed).length
        let total = items.length
        let hasRequired = items.some(i => i.required)
        let missingRequired = items.some(i => i.required && !i.installed)
        return { installed, total, hasRequired, missingRequired }
    }

    // Check all requirements
    function checkAll() {
        checkComplete = false
        toolResults = {}
        envResults = {}
        pendingChecks = requirements.length

        // Check environment variables
        for (let env of envRequirements) {
            let value = Quickshell.env(env.name)
            envResults[env.name] = value !== "" && value !== undefined
        }

        // Start all tool checks
        for (let req of requirements) {
            checkTool(req.name)
        }
    }

    property int pendingChecks: 0

    function checkTool(name) {
        let proc = checkProcessComponent.createObject(requirementsService, { toolName: name })
        proc.running = true
    }

    function onCheckComplete(name, installed) {
        let newResults = Object.assign({}, toolResults)
        newResults[name] = installed
        toolResults = newResults

        pendingChecks--
        if (pendingChecks <= 0) {
            finishChecks()
        }
    }

    function finishChecks() {
        // Calculate stats
        let installed = 0
        let missingReq = false
        let missingOpt = false

        for (let req of requirements) {
            if (toolResults[req.name]) {
                installed++
            } else if (req.required) {
                missingReq = true
            } else {
                missingOpt = true
            }
        }

        for (let env of envRequirements) {
            if (envResults[env.name]) {
                installed++
            } else {
                missingOpt = true
            }
        }

        installedCount = installed
        totalCount = requirements.length + envRequirements.length
        hasMissingRequired = missingReq
        hasMissingOptional = missingOpt
        checkComplete = true
    }

    // Refresh checks
    function refresh() {
        checkAll()
    }

    Component {
        id: checkProcessComponent

        Process {
            id: checkProcess
            property string toolName: ""
            command: ["bash", "-c", "command -v " + toolName + " >/dev/null 2>&1 && echo 'found' || echo 'missing'"]

            stdout: SplitParser {
                onRead: data => {
                    let installed = data.trim() === "found"
                    requirementsService.onCheckComplete(checkProcess.toolName, installed)
                    checkProcess.destroy()
                }
            }

            onExited: (code) => {
                // Fallback if stdout didn't fire
                if (toolName in requirementsService.toolResults === false) {
                    requirementsService.onCheckComplete(toolName, false)
                    destroy()
                }
            }
        }
    }

    // Start checking on load
    Component.onCompleted: {
        checkAll()
    }
}
