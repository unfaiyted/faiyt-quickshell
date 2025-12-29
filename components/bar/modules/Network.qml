import QtQuick
import Quickshell
import Quickshell.Io
import "../../../theme"
import ".."

BarGroup {
    id: network

    implicitWidth: networkText.width + 16
    implicitHeight: 24

    property string status: "?"
    property bool connected: false
    property string connectionType: ""
    property string connectionName: ""
    property string ipAddress: ""
    property string gateway: ""
    property string device: ""

    Process {
        id: netProcess
        command: ["bash", "-c", "nmcli -t -f TYPE,STATE,DEVICE d | grep -E '^(wifi|ethernet):connected' | head -1"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const parts = data.split(":")
                if (parts.length >= 3) {
                    network.device = parts[2].trim()
                    if (parts[0] === "wifi") {
                        network.status = "󰤨"
                        network.connectionType = "WiFi"
                        network.connected = true
                    } else if (parts[0] === "ethernet") {
                        network.status = "󰈀"
                        network.connectionType = "Ethernet"
                        network.connected = true
                    }
                    // Fetch detailed info
                    detailProcess.running = true
                } else {
                    network.status = "󰤭"
                    network.connected = false
                    network.connectionType = ""
                }
            }
        }
    }

    Process {
        id: detailProcess
        command: ["bash", "-c", "nmcli -t device show " + network.device + " 2>/dev/null | grep -E '(GENERAL.CONNECTION|IP4.ADDRESS\\[1\\]|IP4.GATEWAY)'"]

        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("GENERAL.CONNECTION:")) {
                    network.connectionName = data.split(":")[1] || ""
                } else if (data.startsWith("IP4.ADDRESS")) {
                    network.ipAddress = data.split(":")[1] || ""
                } else if (data.startsWith("IP4.GATEWAY:")) {
                    network.gateway = data.split(":")[1] || ""
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: netProcess.running = true
    }

    Text {
        id: networkText
        anchors.centerIn: parent
        text: network.status
        color: network.connected ? Colors.foreground : Colors.error
        font.pixelSize: 14
        font.family: "Symbols Nerd Font"
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }

    // Custom tooltip popup
    PopupWindow {
        id: tooltip
        anchor.window: QsWindow.window
        anchor.onAnchoring: {
            const pos = network.mapToItem(QsWindow.window.contentItem, 0, network.height)
            anchor.rect = Qt.rect(pos.x, pos.y, network.width, 7)
        }
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        visible: mouseArea.containsMouse

        implicitWidth: tooltipContent.width
        implicitHeight: tooltipContent.height
        color: "transparent"

        Rectangle {
            id: tooltipContent
            width: tooltipColumn.width + 24
            height: tooltipColumn.height + 16
            color: Colors.surface
            radius: 8
            border.width: 1
            border.color: Colors.overlay

            Column {
                id: tooltipColumn
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: network.connected ? network.connectionType : "Disconnected"
                    color: network.connected ? Colors.foreground : Colors.error
                    font.pixelSize: 12
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    visible: network.connectionName.length > 0
                    text: network.connectionName
                    color: Colors.subtle
                    font.pixelSize: 11
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    width: tooltipColumn.width
                    height: 1
                    color: Colors.overlay
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: network.connected
                }

                Text {
                    visible: network.ipAddress.length > 0
                    text: "󰩟 " + network.ipAddress
                    color: Colors.muted
                    font.pixelSize: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    visible: network.gateway.length > 0
                    text: "󰛳 " + network.gateway
                    color: Colors.muted
                    font.pixelSize: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    visible: network.device.length > 0
                    text: "󰾲 " + network.device
                    color: Colors.muted
                    font.pixelSize: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
