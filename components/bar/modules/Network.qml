import QtQuick
import Quickshell
import Quickshell.Io
import "../../../theme"
import ".."
import "../../common"

BarGroup {
    id: network

    implicitWidth: networkText.width + 16
    implicitHeight: 30

    property string status: "?"
    property bool connected: false
    property string connectionType: ""
    property string connectionName: ""
    property string ipAddress: ""
    property string gateway: ""
    property string device: ""
    property bool popupOpen: false

    // Hover state tracking - at module level so accessible everywhere
    property bool hoverModule: false
    property bool hoverPopup: tooltipMouseArea.containsMouse ||
                              ipMouseArea.containsMouse ||
                              gatewayMouseArea.containsMouse ||
                              gatewayLinkArea.containsMouse

    // Clipboard process
    Process {
        id: copyProcess
        command: ["wl-copy", ""]
    }

    function copyToClipboard(text) {
        copyProcess.command = ["wl-copy", text]
        copyProcess.running = true
        popupOpen = false
    }

    function openGateway() {
        Qt.openUrlExternally("http://" + network.gateway)
    }

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

    // Close timer - gives time to move mouse to popup
    Timer {
        id: closeTimer
        interval: 300
        repeat: false
        onTriggered: {
            // Only close if not hovering either the module or popup
            if (!network.hoverModule && !network.hoverPopup) {
                network.popupOpen = false
            }
        }
    }

    Text {
        id: networkText
        anchors.centerIn: parent
        text: network.status
        color: network.connected ? Colors.foreground : Colors.error
        font.pixelSize: Fonts.iconMedium
        font.family: Fonts.icon
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            closeTimer.stop()
            network.hoverModule = true
            network.popupOpen = true
        }

        onExited: {
            network.hoverModule = false
            closeTimer.start()
        }
    }

    HintTarget {
        targetElement: network
        scope: "bar"
        action: () => {
            network.popupOpen = true
        }
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

        visible: network.popupOpen

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

            // Mouse area for the entire popup
            MouseArea {
                id: tooltipMouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton  // Don't block clicks to children

                onEntered: closeTimer.stop()
                onExited: closeTimer.start()
            }

            // Keyboard handler for Escape
            Item {
                anchors.fill: parent
                focus: network.popupOpen

                Keys.onEscapePressed: {
                    network.popupOpen = false
                }
            }

            Column {
                id: tooltipColumn
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: network.connected ? network.connectionType : "Disconnected"
                    color: network.connected ? Colors.foreground : Colors.error
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    visible: network.connectionName.length > 0
                    text: network.connectionName
                    color: Colors.subtle
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    width: tooltipColumn.width
                    height: 1
                    color: Colors.overlay
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: network.connected
                }

                // IP Address row - clickable to copy
                Rectangle {
                    id: ipRowRect
                    visible: network.ipAddress.length > 0
                    width: ipRow.width + 16
                    height: 24
                    radius: 4
                    color: ipMouseArea.containsMouse ? Colors.overlay : "transparent"
                    anchors.horizontalCenter: parent.horizontalCenter

                    Row {
                        id: ipRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "󰩟 " + network.ipAddress
                            color: ipMouseArea.containsMouse ? Colors.foreground : Colors.muted
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.tiny
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "󰆏"
                            font.family: Fonts.icon
                            font.pixelSize: Fonts.iconTiny
                            color: ipMouseArea.containsMouse ? Colors.primary : Colors.muted
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: ipMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: closeTimer.stop()
                        onExited: closeTimer.start()
                        onClicked: {
                            // Strip subnet mask (e.g., /24) before copying
                            var ip = network.ipAddress.split("/")[0]
                            network.copyToClipboard(ip)
                        }
                    }

                    HintTarget {
                        targetElement: ipRowRect
                        scope: "bar"
                        enabled: tooltip.visible && network.ipAddress.length > 0
                        action: () => {
                            var ip = network.ipAddress.split("/")[0]
                            network.copyToClipboard(ip)
                        }
                    }
                }

                // Gateway row - clickable to copy or open in browser
                Rectangle {
                    id: gatewayRowRect
                    visible: network.gateway.length > 0
                    width: gatewayRow.width + 16
                    height: 24
                    radius: 4
                    color: gatewayMouseArea.containsMouse || gatewayLinkArea.containsMouse ? Colors.overlay : "transparent"
                    anchors.horizontalCenter: parent.horizontalCenter

                    Row {
                        id: gatewayRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            id: gatewayText
                            text: "󰛳 " + network.gateway
                            color: gatewayMouseArea.containsMouse ? Colors.foreground : Colors.muted
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.tiny
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                id: gatewayMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onEntered: closeTimer.stop()
                                onExited: closeTimer.start()
                                onClicked: network.copyToClipboard(network.gateway)
                            }

                            HintTarget {
                                targetElement: gatewayText
                                scope: "bar"
                                enabled: tooltip.visible && network.gateway.length > 0
                                action: () => network.copyToClipboard(network.gateway)
                            }
                        }

                        Text {
                            text: "󰆏"
                            font.family: Fonts.icon
                            font.pixelSize: Fonts.iconTiny
                            color: gatewayMouseArea.containsMouse || gatewayLinkArea.containsMouse ? Colors.primary : Colors.muted
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Open in browser button - always visible with larger hit area
                        Rectangle {
                            id: gatewayLinkBtn
                            width: 20
                            height: 20
                            radius: 4
                            color: gatewayLinkArea.containsMouse ? Colors.overlay : "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "󰈁"
                                font.family: Fonts.icon
                                font.pixelSize: Fonts.iconSmall
                                color: gatewayLinkArea.containsMouse ? Colors.foam : Colors.muted
                            }

                            MouseArea {
                                id: gatewayLinkArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onEntered: closeTimer.stop()
                                onExited: closeTimer.start()
                                onClicked: {
                                    network.openGateway()
                                    network.popupOpen = false
                                }
                            }

                            HintTarget {
                                targetElement: gatewayLinkBtn
                                scope: "bar"
                                enabled: tooltip.visible && network.gateway.length > 0
                                action: () => {
                                    network.openGateway()
                                    network.popupOpen = false
                                }
                            }
                        }
                    }
                }

                // Device row - not interactive
                Text {
                    visible: network.device.length > 0
                    text: "󰾲 " + network.device
                    color: Colors.muted
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.tiny
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
