import QtQuick
import Quickshell.Io
import "../../../services"
import "../../../theme"
import "../../notifications" as Notifications
import "../../common"

Item {
    id: quickToggles

    implicitHeight: 170
    implicitWidth: parent.width

    // Toggle states
    property bool wifiEnabled: true
    property bool bluetoothEnabled: false
    property bool idleInhibited: false
    property bool micMuted: false
    property bool vpnConnected: false
    property bool focusModeEnabled: false
    property bool powerSaverEnabled: false

    // Night light state comes from NightLightService
    property bool nightLightEnabled: NightLightService.nightLightEnabled

    // Store previous bar mode for focus mode restore
    property string previousBarMode: "normal"

    // Check WiFi status
    Process {
        id: wifiStatusProcess
        command: ["nmcli", "radio", "wifi"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                quickToggles.wifiEnabled = data.trim() === "enabled"
            }
        }
    }

    // Check Bluetooth status
    Process {
        id: btStatusProcess
        command: ["bluetoothctl", "show"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                if (data.includes("Powered:")) {
                    quickToggles.bluetoothEnabled = data.includes("yes")
                }
            }
        }
    }

    // Check Mic mute status via wpctl
    Process {
        id: micStatusProcess
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                // Output is like "Volume: 1.00" or "Volume: 1.00 [MUTED]"
                quickToggles.micMuted = data.includes("[MUTED]")
            }
        }
    }

    // Toggle Mic mute via wpctl
    Process {
        id: micToggleProcess
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
        onRunningChanged: {
            if (!running) {
                micStatusProcess.running = true
            }
        }
    }

    // Night Light is now managed by NightLightService

    // Check VPN status
    Process {
        id: vpnStatusProcess
        command: ["nmcli", "-t", "-f", "NAME,TYPE,STATE", "connection", "show", "--active"]
        running: true
        property string vpnName: ConfigService.quickToggleVpnName

        stdout: SplitParser {
            onRead: data => {
                if (vpnStatusProcess.vpnName && data.includes(vpnStatusProcess.vpnName) && data.includes("activated")) {
                    quickToggles.vpnConnected = true
                }
            }
        }

        onRunningChanged: {
            if (!running && !vpnConnected) {
                // Reset if no match found
                quickToggles.vpnConnected = false
            }
        }
    }

    // Check Power Profile status
    Process {
        id: powerProfileStatusProcess
        command: ["powerprofilesctl", "get"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                quickToggles.powerSaverEnabled = data.trim() === "power-saver"
            }
        }
    }

    // Toggle WiFi
    Process {
        id: wifiToggleProcess
        command: ["nmcli", "radio", "wifi", quickToggles.wifiEnabled ? "off" : "on"]
        onRunningChanged: {
            if (!running) {
                wifiStatusProcess.running = true
            }
        }
    }

    // Toggle Bluetooth
    Process {
        id: btToggleProcess
        command: ["bluetoothctl", "power", quickToggles.bluetoothEnabled ? "off" : "on"]
        onRunningChanged: {
            if (!running) {
                btStatusProcess.running = true
            }
        }
    }

    // Idle inhibitor process (keeps running while inhibited)
    Process {
        id: idleInhibitProcess
        command: ["systemd-inhibit", "--what=idle", "--who=quickshell", "--why=User requested", "sleep", "infinity"]
        running: quickToggles.idleInhibited || quickToggles.focusModeEnabled
    }

    // Toggle VPN ON
    Process {
        id: vpnOnProcess
        command: ["nmcli", "connection", "up", ConfigService.quickToggleVpnName]
        onRunningChanged: {
            if (!running) {
                vpnStatusProcess.running = true
            }
        }
    }

    // Toggle VPN OFF
    Process {
        id: vpnOffProcess
        command: ["nmcli", "connection", "down", ConfigService.quickToggleVpnName]
        onRunningChanged: {
            if (!running) {
                quickToggles.vpnConnected = false
            }
        }
    }

    // Toggle Power Profile
    Process {
        id: powerProfileToggleProcess
        command: ["powerprofilesctl", "set", quickToggles.powerSaverEnabled ? "balanced" : "power-saver"]
        onRunningChanged: {
            if (!running) {
                powerProfileStatusProcess.running = true
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
            // Night Light status is managed by NightLightService
            if (ConfigService.quickToggleVpnName) {
                vpnStatusProcess.running = true
            }
            if (ConfigService.quickTogglePowerSaver) {
                powerProfileStatusProcess.running = true
            }
        }
    }

    // Focus Mode toggle function
    function toggleFocusMode() {
        if (!focusModeEnabled) {
            // Enable Focus Mode
            previousBarMode = ConfigService.barMode
            Notifications.NotificationState.doNotDisturb = true
            ConfigService.setValue("bar.mode", "focus")
            ConfigService.saveConfig()
            focusModeEnabled = true
        } else {
            // Disable Focus Mode
            Notifications.NotificationState.doNotDisturb = false
            ConfigService.setValue("bar.mode", previousBarMode)
            ConfigService.saveConfig()
            focusModeEnabled = false
        }
    }

    // Container with elevated background
    Rectangle {
        id: container
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        radius: 12
        color: Colors.backgroundElevated
        border.width: 1
        border.color: Colors.border

        Grid {
            anchors.fill: parent
            anchors.margins: 12
            columns: 3
            rows: 2
            spacing: 8

            // Row 1: WiFi, Bluetooth, Caffeine/Focus
            ToggleButton {
                width: (parent.width - 16) / 3
                height: (parent.height - 8) / 2
                active: quickToggles.wifiEnabled
                icon: quickToggles.wifiEnabled ? "󰤨" : "󰤭"
                label: "WiFi"
                tooltip: quickToggles.wifiEnabled ? "Disable WiFi" : "Enable WiFi"
                onClicked: wifiToggleProcess.running = true
            }

            ToggleButton {
                width: (parent.width - 16) / 3
                height: (parent.height - 8) / 2
                active: quickToggles.bluetoothEnabled
                icon: quickToggles.bluetoothEnabled ? "󰂯" : "󰂲"
                label: "BT"
                tooltip: quickToggles.bluetoothEnabled ? "Disable Bluetooth" : "Enable Bluetooth"
                onClicked: btToggleProcess.running = true
            }

            // Caffeine or Focus Mode (Focus replaces Caffeine when enabled)
            ToggleButton {
                width: (parent.width - 16) / 3
                height: (parent.height - 8) / 2
                visible: !ConfigService.quickToggleFocusMode
                active: quickToggles.idleInhibited
                icon: quickToggles.idleInhibited ? "󰅶" : "󰛊"
                label: "Caffeine"
                tooltip: quickToggles.idleInhibited ? "Allow Idle Sleep" : "Prevent Idle Sleep"
                activeColor: Colors.gold
                onClicked: quickToggles.idleInhibited = !quickToggles.idleInhibited
            }

            ToggleButton {
                width: (parent.width - 16) / 3
                height: (parent.height - 8) / 2
                visible: ConfigService.quickToggleFocusMode
                active: quickToggles.focusModeEnabled
                icon: quickToggles.focusModeEnabled ? "󱥿" : "󰀜"
                label: "Focus"
                tooltip: quickToggles.focusModeEnabled ? "Disable Focus Mode" : "Enable Focus Mode (DND + Caffeine)"
                activeColor: Colors.iris
                onClicked: quickToggles.toggleFocusMode()
            }

            // Row 2: Mic, Night Light, VPN/Power
            ToggleButton {
                width: (parent.width - 16) / 3
                height: (parent.height - 8) / 2
                active: !quickToggles.micMuted
                icon: quickToggles.micMuted ? "󰍭" : "󰍬"
                label: "Mic"
                tooltip: quickToggles.micMuted ? "Unmute Microphone" : "Mute Microphone"
                onClicked: micToggleProcess.running = true
            }

            ToggleButton {
                width: (parent.width - 16) / 3
                height: (parent.height - 8) / 2
                active: quickToggles.nightLightEnabled
                icon: quickToggles.nightLightEnabled ? "󱩌" : "󰖨"
                label: "Night"
                tooltip: quickToggles.nightLightEnabled ? "Disable Night Light" : "Enable Night Light (" + ConfigService.quickToggleNightTemp + "K)"
                activeColor: Colors.gold
                onClicked: {
                    // Use NightLightService for toggle - handles auto mode override tracking
                    NightLightService.onManualToggle(!quickToggles.nightLightEnabled)
                }
            }

            // VPN or Power Saver (Power Saver replaces VPN when enabled)
            ToggleButton {
                width: (parent.width - 16) / 3
                height: (parent.height - 8) / 2
                visible: !ConfigService.quickTogglePowerSaver
                active: quickToggles.vpnConnected
                icon: quickToggles.vpnConnected ? "󰖁" : "󰖂"
                label: "VPN"
                tooltip: ConfigService.quickToggleVpnName === "" ? "Configure VPN in Settings" : (quickToggles.vpnConnected ? "Disconnect " + ConfigService.quickToggleVpnName : "Connect " + ConfigService.quickToggleVpnName)
                activeColor: Colors.pine
                enabled: ConfigService.quickToggleVpnName !== ""
                onClicked: {
                    if (ConfigService.quickToggleVpnName) {
                        if (quickToggles.vpnConnected) {
                            vpnOffProcess.running = true
                        } else {
                            vpnOnProcess.running = true
                        }
                    }
                }
            }

            ToggleButton {
                width: (parent.width - 16) / 3
                height: (parent.height - 8) / 2
                visible: ConfigService.quickTogglePowerSaver
                active: quickToggles.powerSaverEnabled
                icon: quickToggles.powerSaverEnabled ? "󰌪" : "󱐋"
                label: "Power"
                tooltip: quickToggles.powerSaverEnabled ? "Switch to Balanced Profile" : "Switch to Power Saver"
                activeColor: Colors.foam
                onClicked: powerProfileToggleProcess.running = true
            }
        }
    }

    // Reusable Toggle Button Component
    component ToggleButton: Column {
        id: toggleBtn

        property bool active: false
        property bool enabled: true
        property string icon: ""
        property string label: ""
        property string tooltip: ""
        property color activeColor: Colors.primary
        property string hintScope: "sidebar-right"
        signal clicked()

        spacing: 4
        opacity: enabled ? 1.0 : 0.5

        // Hint navigation target
        HintTarget {
            targetElement: btnRect
            scope: toggleBtn.hintScope
            action: () => { if (toggleBtn.enabled) toggleBtn.clicked() }
            enabled: toggleBtn.enabled && toggleBtn.visible
        }

        // Main toggle button
        Rectangle {
            id: btnRect
            width: parent.width
            height: parent.height - oblongIndicator.height - parent.spacing
            radius: 12

            property bool hovered: false

            // Semi-transparent background
            color: toggleBtn.active
                ? Qt.rgba(toggleBtn.activeColor.r, toggleBtn.activeColor.g, toggleBtn.activeColor.b, 0.15)
                : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.5)

            border.width: 1
            border.color: toggleBtn.active
                ? Qt.rgba(toggleBtn.activeColor.r, toggleBtn.activeColor.g, toggleBtn.activeColor.b, 0.3)
                : Colors.border

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Behavior on border.color {
                ColorAnimation { duration: 150 }
            }

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: toggleBtn.icon
                    font.family: Fonts.icon
                    font.pixelSize: Fonts.iconLarge
                    color: toggleBtn.active ? toggleBtn.activeColor : Colors.foregroundAlt

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                Text {
                    text: toggleBtn.label
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    font.bold: true
                    color: toggleBtn.active ? Colors.foreground : Colors.foregroundAlt

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }

            // Tooltip
            Rectangle {
                id: tooltipRect
                visible: btnRect.hovered && toggleBtn.tooltip !== "" && tooltipTimer.running === false
                anchors.bottom: parent.top
                anchors.bottomMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                width: tooltipText.width + 16
                height: tooltipText.height + 8
                radius: 6
                color: Colors.surface
                border.width: 1
                border.color: Colors.border
                z: 100

                Text {
                    id: tooltipText
                    anchors.centerIn: parent
                    text: toggleBtn.tooltip
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    color: Colors.foreground
                }
            }

            Timer {
                id: tooltipTimer
                interval: 500
                repeat: false
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: toggleBtn.enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                hoverEnabled: true

                onClicked: {
                    if (toggleBtn.enabled) {
                        toggleBtn.clicked()
                    }
                }

                onEntered: {
                    tooltipTimer.restart()
                    btnRect.hovered = true
                    if (toggleBtn.enabled && !toggleBtn.active) {
                        parent.color = Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.7)
                    }
                }

                onExited: {
                    tooltipTimer.stop()
                    btnRect.hovered = false
                    if (!toggleBtn.active) {
                        parent.color = Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.5)
                    }
                }
            }
        }

        // Oblong indicator showing on/off status
        Rectangle {
            id: oblongIndicator
            width: 20
            height: 6
            radius: 3
            anchors.horizontalCenter: parent.horizontalCenter
            color: toggleBtn.active ? Colors.secondary : Colors.muted

            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }
    }
}
