import QtQuick
import Quickshell.Services.Mpris
import "../../../services" as Services
import ".."

QtObject {
    id: root

    // ═══════════════════════════════════════════════════════════════
    // PANEL ACTIONS
    // ═══════════════════════════════════════════════════════════════

    readonly property var panelActions: [
        {
            type: "quickaction",
            category: "panel",
            title: "Settings",
            description: "Open settings panel",
            icon: "󰒓",
            keywords: ["settings", "preferences", "options", "configure", "config"],
            action: function() { QuickActionState.openSettings() }
        },
        {
            type: "quickaction",
            category: "panel",
            title: "Display Settings",
            description: "Configure monitors and displays",
            icon: "󰍹",
            keywords: ["display", "monitor", "screen", "resolution", "arrangement"],
            action: function() { QuickActionState.openDisplaySettings() }
        },
        {
            type: "quickaction",
            category: "panel",
            title: "Theme Settings",
            description: "Customize theme and colors",
            icon: "󰏘",
            keywords: ["theme", "color", "appearance", "style", "customize"],
            action: function() { QuickActionState.openThemeSettings() }
        },
        {
            type: "quickaction",
            category: "panel",
            title: "Wallpaper",
            description: "Change wallpaper",
            icon: "󰸉",
            keywords: ["wallpaper", "background", "image", "desktop"],
            action: function() { QuickActionState.openWallpaper() }
        },
        {
            type: "quickaction",
            category: "panel",
            title: "Overview",
            description: "Open workspace overview",
            icon: "󰕰",
            keywords: ["overview", "workspaces", "windows", "grid"],
            action: function() { QuickActionState.openOverview() }
        }
    ]

    // ═══════════════════════════════════════════════════════════════
    // BAR MODE ACTIONS
    // ═══════════════════════════════════════════════════════════════

    readonly property var barModeActions: [
        {
            type: "quickaction",
            category: "bar",
            title: "Bar: Normal Mode",
            description: "Set bar to normal display mode",
            icon: "󰊓",
            keywords: ["bar", "normal", "mode", "default", "show"],
            action: function() { QuickActionState.setBarMode("normal") }
        },
        {
            type: "quickaction",
            category: "bar",
            title: "Bar: Focus Mode",
            description: "Set bar to minimal focus mode",
            icon: "󰍐",
            keywords: ["bar", "focus", "mode", "minimal", "distraction"],
            action: function() { QuickActionState.setBarMode("focus") }
        },
        {
            type: "quickaction",
            category: "bar",
            title: "Bar: Hidden",
            description: "Hide the bar completely",
            icon: "󰘊",
            keywords: ["bar", "hidden", "hide", "nothing", "invisible"],
            action: function() { QuickActionState.setBarMode("nothing") }
        }
    ]

    // ═══════════════════════════════════════════════════════════════
    // MEDIA ACTIONS (dynamic based on player state)
    // ═══════════════════════════════════════════════════════════════

    property var mediaActions: {
        if (!QuickActionState.hasActivePlayer) return []

        let isPlaying = QuickActionState.isPlaying
        return [
            {
                type: "quickaction",
                category: "media",
                title: isPlaying ? "Pause" : "Play",
                description: isPlaying ? "Pause playback" : "Resume playback",
                icon: isPlaying ? "󰏤" : "󰐎",
                keywords: ["play", "pause", "music", "media", "player"],
                action: function() { QuickActionState.mediaPlayPause() }
            },
            {
                type: "quickaction",
                category: "media",
                title: "Next Track",
                description: "Skip to next track",
                icon: "󰒭",
                keywords: ["next", "skip", "forward", "music", "track"],
                action: function() { QuickActionState.mediaNext() }
            },
            {
                type: "quickaction",
                category: "media",
                title: "Previous Track",
                description: "Go to previous track",
                icon: "󰒮",
                keywords: ["previous", "back", "music", "track"],
                action: function() { QuickActionState.mediaPrevious() }
            },
            {
                type: "quickaction",
                category: "media",
                title: "Stop",
                description: "Stop playback",
                icon: "󰓛",
                keywords: ["stop", "music", "media", "player"],
                action: function() { QuickActionState.mediaStop() }
            }
        ]
    }

    // ═══════════════════════════════════════════════════════════════
    // TOGGLE ACTIONS (dynamic based on current state)
    // ═══════════════════════════════════════════════════════════════

    property var toggleActions: {
        let actions = []

        // WiFi
        let wifiOn = QuickActionState.wifiEnabled
        actions.push({
            type: "quickaction",
            category: "toggle",
            title: wifiOn ? "WiFi: On" : "WiFi: Off",
            description: wifiOn ? "Disable WiFi" : "Enable WiFi",
            icon: wifiOn ? "󰤨" : "󰤭",
            keywords: ["wifi", "wireless", "network", "internet", "toggle"],
            action: function() { QuickActionState.toggleWifi() }
        })

        // Bluetooth
        let btOn = QuickActionState.bluetoothEnabled
        actions.push({
            type: "quickaction",
            category: "toggle",
            title: btOn ? "Bluetooth: On" : "Bluetooth: Off",
            description: btOn ? "Disable Bluetooth" : "Enable Bluetooth",
            icon: btOn ? "󰂯" : "󰂲",
            keywords: ["bluetooth", "bt", "wireless", "toggle"],
            action: function() { QuickActionState.toggleBluetooth() }
        })

        // Microphone
        let micMuted = QuickActionState.micMuted
        actions.push({
            type: "quickaction",
            category: "toggle",
            title: micMuted ? "Mic: Muted" : "Mic: On",
            description: micMuted ? "Unmute microphone" : "Mute microphone",
            icon: micMuted ? "󰍭" : "󰍬",
            keywords: ["mic", "microphone", "mute", "unmute", "audio", "toggle"],
            action: function() { QuickActionState.toggleMic() }
        })

        // Night Light
        let nightOn = QuickActionState.nightLightEnabled
        actions.push({
            type: "quickaction",
            category: "toggle",
            title: nightOn ? "Night Light: On" : "Night Light: Off",
            description: nightOn ? "Disable night light" : "Enable night light",
            icon: nightOn ? "󱩌" : "󰖨",
            keywords: ["night", "light", "blue", "filter", "warm", "toggle"],
            action: function() { QuickActionState.toggleNightLight() }
        })

        // VPN (only if configured)
        if (Services.ConfigService.quickToggleVpnName) {
            let vpnOn = QuickActionState.vpnConnected
            actions.push({
                type: "quickaction",
                category: "toggle",
                title: vpnOn ? "VPN: Connected" : "VPN: Disconnected",
                description: vpnOn ? "Disconnect VPN" : "Connect VPN",
                icon: vpnOn ? "󰖂" : "󰖃",
                keywords: ["vpn", "tunnel", "network", "privacy", "toggle"],
                action: function() { QuickActionState.toggleVpn() }
            })
        }

        // Caffeine
        let caffeineOn = QuickActionState.caffeineEnabled
        actions.push({
            type: "quickaction",
            category: "toggle",
            title: caffeineOn ? "Caffeine: On" : "Caffeine: Off",
            description: caffeineOn ? "Allow idle sleep" : "Prevent idle sleep",
            icon: caffeineOn ? "󰅶" : "󰛊",
            keywords: ["caffeine", "idle", "sleep", "awake", "screen", "toggle"],
            action: function() { QuickActionState.toggleCaffeine() }
        })

        // Do Not Disturb
        let dndOn = QuickActionState.dndEnabled
        actions.push({
            type: "quickaction",
            category: "toggle",
            title: dndOn ? "DND: On" : "DND: Off",
            description: dndOn ? "Disable Do Not Disturb" : "Enable Do Not Disturb",
            icon: dndOn ? "󰂛" : "󰂚",
            keywords: ["dnd", "disturb", "notifications", "quiet", "silent", "toggle"],
            action: function() { QuickActionState.toggleDnd() }
        })

        return actions
    }

    // ═══════════════════════════════════════════════════════════════
    // ALL ACTIONS COMBINED
    // ═══════════════════════════════════════════════════════════════

    property var allActions: {
        let all = []
        all = all.concat(panelActions)
        all = all.concat(barModeActions)
        all = all.concat(mediaActions)
        all = all.concat(toggleActions)
        return all
    }

    // ═══════════════════════════════════════════════════════════════
    // SEARCH FUNCTION
    // ═══════════════════════════════════════════════════════════════

    function search(query, isPrefixSearch) {
        if (!query && !isPrefixSearch) return []

        let queryLower = query.toLowerCase()
        let results = []

        for (let action of allActions) {
            let score = 0

            // Title match (highest priority)
            let titleLower = action.title.toLowerCase()
            if (titleLower.startsWith(queryLower)) {
                score = 100
            } else if (titleLower.includes(queryLower)) {
                score = 80
            }

            // Keyword match
            if (score === 0 && action.keywords) {
                for (let keyword of action.keywords) {
                    if (keyword.startsWith(queryLower)) {
                        score = 70
                        break
                    } else if (keyword.includes(queryLower)) {
                        score = 50
                        break
                    }
                }
            }

            // Description match
            if (score === 0) {
                let descLower = action.description.toLowerCase()
                if (descLower.includes(queryLower)) {
                    score = 30
                }
            }

            // Category match (for prefix searches or generic terms)
            if (score === 0) {
                if (action.category === queryLower) {
                    score = 60
                }
            }

            if (score > 0) {
                // Add usage boost to score
                let itemId = "quickaction:" + (action.category || "unknown") + ":" + action.title
                let boost = Services.UsageStatsService.getBoostScore(itemId)

                // Store action with score for sorting
                results.push({
                    type: action.type,
                    category: action.category,
                    title: action.title,
                    description: action.description,
                    icon: action.icon,
                    keywords: action.keywords,
                    action: action.action,
                    _score: score + boost
                })
            }
        }

        // Sort by score (highest first)
        results.sort((a, b) => b._score - a._score)

        // Return results without the internal score
        return results.map(r => ({
            type: r.type,
            category: r.category,
            title: r.title,
            description: r.description,
            icon: r.icon,
            keywords: r.keywords,
            action: r.action
        }))
    }
}
