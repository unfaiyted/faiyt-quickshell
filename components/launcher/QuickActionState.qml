pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../../services"
import "../notifications" as Notifications
import "../settings"
import "../overview"
import "../monitors"
import "../wallpaper"

Singleton {
    id: root

    // ═══════════════════════════════════════════════════════════════
    // TOGGLE STATES
    // ═══════════════════════════════════════════════════════════════

    property bool wifiEnabled: true
    property bool bluetoothEnabled: false
    property bool micMuted: false
    property bool nightLightEnabled: false
    property bool vpnConnected: false
    property string detectedVpnType: ""  // "nmcli" or "wg-quick"
    property bool caffeineEnabled: false
    property bool dndEnabled: Notifications.NotificationState.doNotDisturb

    // Store previous bar mode for focus mode restore
    property string previousBarMode: "normal"
    property bool focusModeEnabled: false

    // ═══════════════════════════════════════════════════════════════
    // MEDIA STATE
    // ═══════════════════════════════════════════════════════════════

    property bool hasActivePlayer: getActivePlayer() !== null
    property bool isPlaying: {
        let player = getActivePlayer()
        return player ? player.isPlaying : false
    }

    function getActivePlayer() {
        let players = Mpris.players.values
        if (!players || players.length === 0) return null

        // Prefer playing player
        for (let p of players) {
            if (p.isPlaying) return p
        }
        // Fall back to any player with a track
        for (let p of players) {
            if (p.trackTitle) return p
        }
        return players[0] || null
    }

    // ═══════════════════════════════════════════════════════════════
    // STATUS CHECK PROCESSES
    // ═══════════════════════════════════════════════════════════════

    Process {
        id: wifiStatusProcess
        command: ["nmcli", "radio", "wifi"]
        running: true
        stdout: SplitParser {
            onRead: data => { root.wifiEnabled = data.trim() === "enabled" }
        }
    }

    Process {
        id: btStatusProcess
        command: ["bluetoothctl", "show"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data.includes("Powered:")) {
                    root.bluetoothEnabled = data.includes("yes")
                }
            }
        }
    }

    Process {
        id: micStatusProcess
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: true
        stdout: SplitParser {
            onRead: data => { root.micMuted = data.includes("[MUTED]") }
        }
    }

    Process {
        id: nightLightStatusProcess
        command: ["pgrep", "-x", "hyprsunset"]
        running: true
        property bool foundProcess: false
        stdout: SplitParser {
            onRead: data => {
                if (data.trim().length > 0) {
                    nightLightStatusProcess.foundProcess = true
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                root.nightLightEnabled = foundProcess
                foundProcess = false
            }
        }
    }

    // VPN status (NetworkManager)
    Process {
        id: vpnStatusProcess
        command: ["nmcli", "-t", "-f", "NAME,TYPE,STATE", "connection", "show", "--active"]
        running: ConfigService.quickToggleVpnType !== "wg-quick"
        property string vpnName: ConfigService.quickToggleVpnName
        stdout: SplitParser {
            onRead: data => {
                if (vpnStatusProcess.vpnName && data.includes(vpnStatusProcess.vpnName) && data.includes("activated")) {
                    root.vpnConnected = true
                    root.detectedVpnType = "nmcli"
                }
            }
        }
        onRunningChanged: {
            if (!running && !vpnConnected && ConfigService.quickToggleVpnType === "nmcli") {
                root.vpnConnected = false
            }
        }
    }

    // VPN status (WireGuard wg-quick interface)
    Process {
        id: wgStatusProcess
        command: ["ip", "link", "show", ConfigService.quickToggleVpnInterface]
        running: ConfigService.quickToggleVpnType !== "nmcli"
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.vpnConnected = true
                root.detectedVpnType = "wg-quick"
            } else if (ConfigService.quickToggleVpnType === "wg-quick") {
                root.vpnConnected = false
                root.detectedVpnType = ""
            } else if (ConfigService.quickToggleVpnType === "auto" && !root.vpnConnected) {
                root.detectedVpnType = ""
            }
        }
    }

    // Refresh status periodically
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            wifiStatusProcess.running = true
            btStatusProcess.running = true
            micStatusProcess.running = true
            nightLightStatusProcess.running = true

            // VPN status check based on type config
            const vpnType = ConfigService.quickToggleVpnType
            if (vpnType === "auto") {
                wgStatusProcess.running = true
                if (ConfigService.quickToggleVpnName) {
                    vpnStatusProcess.running = true
                }
            } else if (vpnType === "wg-quick") {
                wgStatusProcess.running = true
            } else if (vpnType === "nmcli" && ConfigService.quickToggleVpnName) {
                vpnStatusProcess.running = true
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TOGGLE ACTIONS
    // ═══════════════════════════════════════════════════════════════

    Process {
        id: wifiToggleProcess
        command: ["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"]
        onRunningChanged: { if (!running) wifiStatusProcess.running = true }
    }

    Process {
        id: btToggleProcess
        command: ["bluetoothctl", "power", root.bluetoothEnabled ? "off" : "on"]
        onRunningChanged: { if (!running) btStatusProcess.running = true }
    }

    Process {
        id: micToggleProcess
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
        onRunningChanged: { if (!running) micStatusProcess.running = true }
    }

    Process {
        id: nightLightOnProcess
        command: ["hyprsunset", "-t", ConfigService.quickToggleNightTemp.toString()]
        onRunningChanged: { if (!running) nightLightStatusProcess.running = true }
    }

    Process {
        id: nightLightOffProcess
        command: ["pkill", "-x", "hyprsunset"]
        onRunningChanged: { if (!running) nightLightStatusProcess.running = true }
    }

    // VPN ON (NetworkManager)
    Process {
        id: vpnOnProcess
        command: ["nmcli", "connection", "up", ConfigService.quickToggleVpnName]
        onRunningChanged: { if (!running) vpnStatusProcess.running = true }
    }

    // VPN OFF (NetworkManager)
    Process {
        id: vpnOffProcess
        command: ["nmcli", "connection", "down", ConfigService.quickToggleVpnName]
        onRunningChanged: { if (!running) root.vpnConnected = false }
    }

    // VPN ON (WireGuard wg-quick with pkexec)
    Process {
        id: wgOnProcess
        command: ["pkexec", "wg-quick", "up", ConfigService.quickToggleVpnInterface]
        onRunningChanged: { if (!running) wgStatusProcess.running = true }
    }

    // VPN OFF (WireGuard wg-quick with pkexec)
    Process {
        id: wgOffProcess
        command: ["pkexec", "wg-quick", "down", ConfigService.quickToggleVpnInterface]
        onRunningChanged: {
            if (!running) {
                root.vpnConnected = false
                root.detectedVpnType = ""
            }
        }
    }

    // Idle inhibitor process (keeps running while inhibited)
    Process {
        id: idleInhibitProcess
        command: ["systemd-inhibit", "--what=idle", "--who=quickshell", "--why=User requested", "sleep", "infinity"]
        running: root.caffeineEnabled || root.focusModeEnabled
    }

    // ═══════════════════════════════════════════════════════════════
    // ACTION FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    function toggleWifi() {
        wifiToggleProcess.running = true
    }

    function toggleBluetooth() {
        btToggleProcess.running = true
    }

    function toggleMic() {
        micToggleProcess.running = true
    }

    function toggleNightLight() {
        if (nightLightEnabled) {
            nightLightEnabled = false  // Optimistic
            nightLightOffProcess.running = true
        } else {
            nightLightEnabled = true  // Optimistic
            nightLightOnProcess.running = true
        }
    }

    function toggleVpn() {
        const vpnType = ConfigService.quickToggleVpnType
        const hasNmcli = ConfigService.quickToggleVpnName !== ""
        const hasWg = ConfigService.quickToggleVpnInterface !== ""

        if (!hasNmcli && !hasWg) return

        const useWgQuick = vpnType === "wg-quick" ||
                          (vpnType === "auto" && detectedVpnType === "wg-quick") ||
                          (vpnType === "auto" && !vpnConnected && hasWg)

        if (vpnConnected) {
            // Disconnect
            if (useWgQuick || detectedVpnType === "wg-quick") {
                wgOffProcess.running = true
            } else {
                vpnOffProcess.running = true
            }
        } else {
            // Connect - prefer wg-quick in auto mode if interface is configured
            if (useWgQuick) {
                wgOnProcess.running = true
            } else if (hasNmcli) {
                vpnOnProcess.running = true
            }
        }
    }

    function toggleCaffeine() {
        caffeineEnabled = !caffeineEnabled
    }

    function toggleDnd() {
        Notifications.NotificationState.doNotDisturb = !Notifications.NotificationState.doNotDisturb
        dndEnabled = Notifications.NotificationState.doNotDisturb
    }

    function toggleFocusMode() {
        if (!focusModeEnabled) {
            previousBarMode = ConfigService.barMode
            Notifications.NotificationState.doNotDisturb = true
            ConfigService.setValue("bar.mode", "focus")
            ConfigService.saveConfig()
            focusModeEnabled = true
            dndEnabled = true
        } else {
            Notifications.NotificationState.doNotDisturb = false
            ConfigService.setValue("bar.mode", previousBarMode)
            ConfigService.saveConfig()
            focusModeEnabled = false
            dndEnabled = false
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // PANEL ACTIONS
    // ═══════════════════════════════════════════════════════════════

    function openSettings() {
        SettingsState.open()
    }

    function openDisplaySettings() {
        MonitorsState.openedFromSettings = false
        MonitorsState.open()
    }

    function openThemeSettings() {
        ThemePanelState.open()
    }

    function openWallpaper() {
        WallpaperState.toggle()
    }

    function openOverview() {
        OverviewState.open()
    }

    // ═══════════════════════════════════════════════════════════════
    // BAR MODE ACTIONS
    // ═══════════════════════════════════════════════════════════════

    function setBarMode(mode) {
        ConfigService.setValue("bar.mode", mode)
        ConfigService.saveConfig()
    }

    // ═══════════════════════════════════════════════════════════════
    // MEDIA ACTIONS
    // ═══════════════════════════════════════════════════════════════

    function mediaPlayPause() {
        let player = getActivePlayer()
        if (player) player.togglePlaying()
    }

    function mediaNext() {
        let player = getActivePlayer()
        if (player && player.canGoNext) player.next()
    }

    function mediaPrevious() {
        let player = getActivePlayer()
        if (player && player.canGoPrevious) player.previous()
    }

    function mediaStop() {
        let player = getActivePlayer()
        if (player) player.stop()
    }
}
