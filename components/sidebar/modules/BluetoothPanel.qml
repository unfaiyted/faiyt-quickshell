import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../../../theme"

Item {
    id: bluetoothPanel

    property bool powered: false
    property bool scanning: false
    property var devices: []
    property string connectingMac: ""

    // Check adapter status
    Process {
        id: adapterProcess
        command: ["bluetoothctl", "show"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                if (data.includes("Powered:")) {
                    bluetoothPanel.powered = data.includes("yes")
                }
            }
        }
    }

    // Get paired devices
    Process {
        id: pairedProcess
        command: ["bluetoothctl", "devices", "Paired"]
        running: true

        property var pairedList: []

        stdout: SplitParser {
            onRead: data => {
                // Format: "Device XX:XX:XX:XX:XX:XX Name"
                const match = data.match(/Device\s+([0-9A-Fa-f:]+)\s+(.+)/)
                if (match) {
                    pairedProcess.pairedList.push({
                        mac: match[1],
                        name: match[2],
                        paired: true,
                        connected: false
                    })
                }
            }
        }

        onRunningChanged: {
            if (!running) {
                // After getting paired, check connected
                connectedProcess.running = true
            }
        }
    }

    // Get connected devices
    Process {
        id: connectedProcess
        command: ["bluetoothctl", "devices", "Connected"]

        property var connectedMacs: []

        stdout: SplitParser {
            onRead: data => {
                const match = data.match(/Device\s+([0-9A-Fa-f:]+)/)
                if (match) {
                    connectedMacs.push(match[1])
                }
            }
        }

        onRunningChanged: {
            if (!running) {
                // Mark connected devices and update list
                let deviceList = pairedProcess.pairedList.map(function(d) {
                    return {
                        mac: d.mac,
                        name: d.name,
                        paired: d.paired,
                        connected: connectedMacs.includes(d.mac)
                    }
                })
                // Sort: connected first
                deviceList.sort(function(a, b) { return b.connected - a.connected })
                bluetoothPanel.devices = deviceList

                // Reset for next refresh
                pairedProcess.pairedList = []
                connectedMacs = []
            }
        }
    }

    // Power toggle
    Process {
        id: powerProcess
        command: ["bluetoothctl", "power", bluetoothPanel.powered ? "off" : "on"]
        onRunningChanged: {
            if (!running) refreshDevices()
        }
    }

    // Connect to device
    Process {
        id: connectProcess
        property string targetMac: ""
        command: ["bluetoothctl", "connect", targetMac]
        onRunningChanged: {
            if (!running) {
                bluetoothPanel.connectingMac = ""
                refreshDevices()
            }
        }
    }

    // Disconnect from device
    Process {
        id: disconnectProcess
        property string targetMac: ""
        command: ["bluetoothctl", "disconnect", targetMac]
        onRunningChanged: {
            if (!running) {
                bluetoothPanel.connectingMac = ""
                refreshDevices()
            }
        }
    }

    // Remove device
    Process {
        id: removeProcess
        property string targetMac: ""
        command: ["bluetoothctl", "remove", targetMac]
        onRunningChanged: {
            if (!running) refreshDevices()
        }
    }

    // Scan toggle
    Process {
        id: scanProcess
        command: ["bluetoothctl", "scan", bluetoothPanel.scanning ? "off" : "on"]
    }

    function refreshDevices() {
        adapterProcess.running = true
        pairedProcess.running = true
    }

    function connectDevice(mac) {
        bluetoothPanel.connectingMac = mac
        connectProcess.targetMac = mac
        connectProcess.running = true
    }

    function disconnectDevice(mac) {
        bluetoothPanel.connectingMac = mac
        disconnectProcess.targetMac = mac
        disconnectProcess.running = true
    }

    // Auto-refresh when panel is visible
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: refreshDevices()
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 16

        // Status row
        Rectangle {
            width: parent.width
            height: 56
            radius: 12
            color: Colors.surface

            Row {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // Bluetooth icon
                Rectangle {
                    width: 32
                    height: 32
                    radius: 8
                    color: bluetoothPanel.powered ? Colors.primary : Colors.overlay
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: bluetoothPanel.powered ? "󰂯" : "󰂲"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 16
                        color: bluetoothPanel.powered ? Colors.background : Colors.foregroundMuted
                    }
                }

                // Status text
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: "Bluetooth"
                        font.pixelSize: 13
                        font.bold: true
                        color: Colors.foreground
                    }

                    Text {
                        property int connectedCount: bluetoothPanel.devices.filter(d => d.connected).length
                        text: !bluetoothPanel.powered ? "Off" :
                              connectedCount > 0 ? connectedCount + " connected" : "No devices"
                        font.pixelSize: 11
                        color: Colors.foregroundAlt
                    }
                }

                // Spacer
                Item { width: parent.width - 180; height: 1 }

                // Power switch
                Rectangle {
                    width: 44
                    height: 24
                    radius: 12
                    color: bluetoothPanel.powered ? Colors.primary : Colors.overlay
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Rectangle {
                        x: bluetoothPanel.powered ? 22 : 2
                        y: 2
                        width: 20
                        height: 20
                        radius: 10
                        color: Colors.foreground

                        Behavior on x {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: powerProcess.running = true
                    }
                }
            }
        }

        // Devices header
        Row {
            width: parent.width
            spacing: 8

            Text {
                text: "Devices"
                font.pixelSize: 12
                font.bold: true
                color: Colors.foregroundAlt
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { width: parent.width - 100; height: 1 }

            // Scan button
            Rectangle {
                width: 32
                height: 32
                radius: 8
                color: scanArea.containsMouse ? Colors.surface : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "󰑓"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 16
                    color: bluetoothPanel.scanning ? Colors.primary : Colors.foreground

                    RotationAnimation on rotation {
                        running: bluetoothPanel.scanning
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1000
                    }
                }

                MouseArea {
                    id: scanArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        bluetoothPanel.scanning = !bluetoothPanel.scanning
                        scanProcess.running = true
                    }
                }
            }
        }

        // Device list
        Flickable {
            width: parent.width
            height: parent.height - 130
            clip: true
            contentHeight: deviceColumn.height
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                active: true
                policy: ScrollBar.AsNeeded
            }

            Column {
                id: deviceColumn
                width: parent.width
                spacing: 8

                // Empty state
                Item {
                    width: parent.width
                    height: 120
                    visible: bluetoothPanel.devices.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰂲"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 32
                            color: Colors.foregroundMuted
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: bluetoothPanel.powered ? "No paired devices" : "Bluetooth is off"
                            font.pixelSize: 12
                            color: Colors.foregroundMuted
                        }
                    }
                }

                // Device items
                Repeater {
                    model: bluetoothPanel.devices

                    Rectangle {
                        width: deviceColumn.width
                        height: 56
                        radius: 10
                        color: deviceArea.containsMouse ? Colors.overlay : Colors.surface

                        property var device: modelData
                        property bool isConnecting: bluetoothPanel.connectingMac === device.mac

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            // Device icon
                            Rectangle {
                                width: 32
                                height: 32
                                radius: 8
                                color: device.connected ? Colors.primary : Colors.overlay
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        const name = device.name.toLowerCase()
                                        if (name.includes("airpod") || name.includes("headphone") || name.includes("buds"))
                                            return "󰋋"
                                        if (name.includes("speaker") || name.includes("soundbar"))
                                            return "󰓃"
                                        if (name.includes("keyboard"))
                                            return "󰌌"
                                        if (name.includes("mouse"))
                                            return "󰍽"
                                        if (name.includes("phone") || name.includes("iphone"))
                                            return "󰏲"
                                        if (name.includes("watch"))
                                            return "󰖉"
                                        if (name.includes("controller") || name.includes("gamepad"))
                                            return "󰊖"
                                        return "󰂯"
                                    }
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 16
                                    color: device.connected ? Colors.background : Colors.foreground
                                }
                            }

                            // Device info
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                width: parent.width - 100

                                Text {
                                    text: device.name
                                    font.pixelSize: 12
                                    color: Colors.foreground
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: device.connected ? "Connected" : "Paired"
                                    font.pixelSize: 10
                                    color: device.connected ? Colors.success : Colors.foregroundMuted
                                }
                            }

                            // Status/action area
                            Item {
                                width: 32
                                height: 32
                                anchors.verticalCenter: parent.verticalCenter

                                // Loading spinner
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰑓"
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 16
                                    color: Colors.primary
                                    visible: isConnecting

                                    RotationAnimation on rotation {
                                        running: isConnecting
                                        loops: Animation.Infinite
                                        from: 0
                                        to: 360
                                        duration: 800
                                    }
                                }

                                // Connected checkmark
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰄬"
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 16
                                    color: Colors.success
                                    visible: device.connected && !isConnecting
                                }
                            }
                        }

                        MouseArea {
                            id: deviceArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (device.connected) {
                                    disconnectDevice(device.mac)
                                } else {
                                    connectDevice(device.mac)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
