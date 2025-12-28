import QtQuick
import Quickshell.Io
import "../../../theme"

Item {
    id: quickToggles

    implicitHeight: 56
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

    Row {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // WiFi Toggle
        Rectangle {
            width: (parent.width - 16) / 3
            height: 40
            radius: 10
            color: quickToggles.wifiEnabled ? Colors.primary : Colors.surface

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: quickToggles.wifiEnabled ? "󰤨" : "󰤭"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 18
                    color: quickToggles.wifiEnabled ? Colors.background : Colors.foreground
                }

                Text {
                    text: "WiFi"
                    font.pixelSize: 11
                    font.bold: true
                    color: quickToggles.wifiEnabled ? Colors.background : Colors.foreground
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: wifiToggleProcess.running = true
            }
        }

        // Bluetooth Toggle
        Rectangle {
            width: (parent.width - 16) / 3
            height: 40
            radius: 10
            color: quickToggles.bluetoothEnabled ? Colors.primary : Colors.surface

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: quickToggles.bluetoothEnabled ? "󰂯" : "󰂲"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 18
                    color: quickToggles.bluetoothEnabled ? Colors.background : Colors.foreground
                }

                Text {
                    text: "BT"
                    font.pixelSize: 11
                    font.bold: true
                    color: quickToggles.bluetoothEnabled ? Colors.background : Colors.foreground
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: btToggleProcess.running = true
            }
        }

        // Idle Inhibitor Toggle
        Rectangle {
            width: (parent.width - 16) / 3
            height: 40
            radius: 10
            color: quickToggles.idleInhibited ? Colors.gold : Colors.surface

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: quickToggles.idleInhibited ? "󰅶" : "󰛊"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 18
                    color: quickToggles.idleInhibited ? Colors.background : Colors.foreground
                }

                Text {
                    text: "Caffeine"
                    font.pixelSize: 11
                    font.bold: true
                    color: quickToggles.idleInhibited ? Colors.background : Colors.foreground
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: quickToggles.idleInhibited = !quickToggles.idleInhibited
            }
        }
    }
}
