import QtQuick
import Quickshell.Io
import "../../../theme"

Item {
    id: quickToggles

    implicitHeight: 88
    implicitWidth: parent.width

    property bool wifiEnabled: true
    property bool bluetoothEnabled: false
    property bool idleInhibited: false

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
        running: quickToggles.idleInhibited
    }

    // Refresh status periodically
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            wifiStatusProcess.running = true
            btStatusProcess.running = true
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

        Row {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // WiFi Toggle
            ToggleButton {
                width: (parent.width - 16) / 3
                height: parent.height
                active: quickToggles.wifiEnabled
                icon: quickToggles.wifiEnabled ? "󰤨" : "󰤭"
                label: "WiFi"
                onClicked: wifiToggleProcess.running = true
            }

            // Bluetooth Toggle
            ToggleButton {
                width: (parent.width - 16) / 3
                height: parent.height
                active: quickToggles.bluetoothEnabled
                icon: quickToggles.bluetoothEnabled ? "󰂯" : "󰂲"
                label: "BT"
                onClicked: btToggleProcess.running = true
            }

            // Idle Inhibitor Toggle
            ToggleButton {
                width: (parent.width - 16) / 3
                height: parent.height
                active: quickToggles.idleInhibited
                icon: quickToggles.idleInhibited ? "󰅶" : "󰛊"
                label: "Caffeine"
                activeColor: Colors.gold
                onClicked: quickToggles.idleInhibited = !quickToggles.idleInhibited
            }
        }
    }

    // Reusable Toggle Button Component
    component ToggleButton: Column {
        id: toggleBtn

        property bool active: false
        property string icon: ""
        property string label: ""
        property color activeColor: Colors.primary
        signal clicked()

        spacing: 4

        // Main toggle button
        Rectangle {
            width: parent.width
            height: parent.height - oblongIndicator.height - parent.spacing
            radius: 12

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
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 18
                    color: toggleBtn.active ? toggleBtn.activeColor : Colors.foregroundAlt

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                Text {
                    text: toggleBtn.label
                    font.pixelSize: 11
                    font.bold: true
                    color: toggleBtn.active ? Colors.foreground : Colors.foregroundAlt

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: toggleBtn.clicked()

                onEntered: {
                    if (!toggleBtn.active) {
                        parent.color = Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.7)
                    }
                }

                onExited: {
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
