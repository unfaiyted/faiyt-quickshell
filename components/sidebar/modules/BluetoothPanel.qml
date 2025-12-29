import QtQuick
import QtQuick.Controls
import Quickshell
import "../../../theme"
import "../../../services"

Item {
    id: bluetoothPanel

    property bool showAdapterDropdown: false

    // Convenience aliases to service
    property var adapters: BluetoothService.adapters
    property var devices: BluetoothService.devices
    property var discoveredDevices: BluetoothService.discoveredDevices
    property var currentAdapter: BluetoothService.currentAdapter
    property bool powered: BluetoothService.powered
    property bool scanning: BluetoothService.scanning
    property string connectingMac: BluetoothService.connectingMac

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Header with adapter selector
        Row {
            width: parent.width
            spacing: 8

            Text {
                text: "Bluetooth"
                font.pixelSize: 12
                font.bold: true
                color: Colors.foregroundAlt
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { width: parent.width - 150; height: 1 }

            // Adapter selector button
            Rectangle {
                width: 70
                height: 24
                radius: 6
                color: adapterBtn.containsMouse ? Colors.surface : Colors.overlay
                anchors.verticalCenter: parent.verticalCenter
                visible: bluetoothPanel.adapters.length > 1

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "Adapter"
                        font.pixelSize: 10
                        color: Colors.foreground
                    }

                    Text {
                        text: "󰅀"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 10
                        color: Colors.foreground
                    }
                }

                MouseArea {
                    id: adapterBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bluetoothPanel.showAdapterDropdown = !bluetoothPanel.showAdapterDropdown
                }
            }
        }

        // Adapter dropdown
        Rectangle {
            width: parent.width
            height: adaptersList.height + 16
            radius: 8
            color: Colors.surface
            visible: bluetoothPanel.showAdapterDropdown && bluetoothPanel.adapters.length > 1

            Column {
                id: adaptersList
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                spacing: 4

                Repeater {
                    model: bluetoothPanel.adapters

                    Rectangle {
                        width: adaptersList.width
                        height: 36
                        radius: 6
                        color: adapterArea.containsMouse ? Colors.overlay : "transparent"

                        property var adapterItem: modelData
                        property int adapterIdx: index
                        property bool isSelected: BluetoothService.selectedAdapterIndex === index

                        Row {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Text {
                                text: isSelected ? "󰄬" : "󰝦"
                                font.family: "Symbols Nerd Font"
                                font.pixelSize: 14
                                color: isSelected ? Colors.primary : Colors.foregroundMuted
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Text {
                                    text: adapterItem.name
                                    font.pixelSize: 11
                                    color: Colors.foreground
                                    elide: Text.ElideRight
                                    width: adaptersList.width - 50
                                }

                                Text {
                                    text: adapterItem.powered ? "Powered on" : "Powered off"
                                    font.pixelSize: 9
                                    color: adapterItem.powered ? Colors.success : Colors.foregroundMuted
                                }
                            }
                        }

                        MouseArea {
                            id: adapterArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                BluetoothService.selectAdapter(adapterIdx)
                                bluetoothPanel.showAdapterDropdown = false
                            }
                        }
                    }
                }
            }
        }

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
                    width: parent.width - 120

                    Text {
                        text: bluetoothPanel.currentAdapter ? bluetoothPanel.currentAdapter.name : "No adapter"
                        font.pixelSize: 12
                        color: Colors.foreground
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        property int connectedCount: bluetoothPanel.devices.filter(d => d.connected).length
                        text: !bluetoothPanel.powered ? "Off" :
                              connectedCount > 0 ? connectedCount + " connected" : "Ready"
                        font.pixelSize: 11
                        color: Colors.foregroundAlt
                    }
                }

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
                        onClicked: BluetoothService.togglePower()
                    }
                }
            }
        }

        // Device list
        Flickable {
            width: parent.width
            height: parent.height - (bluetoothPanel.showAdapterDropdown && bluetoothPanel.adapters.length > 1 ? 180 : 100)
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

                // My Devices header
                Row {
                    width: parent.width
                    spacing: 8
                    visible: bluetoothPanel.powered

                    Text {
                        text: "My Devices"
                        font.pixelSize: 12
                        font.bold: true
                        color: Colors.foregroundAlt
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item { width: parent.width - 140; height: 1 }

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
                            onClicked: BluetoothService.toggleScanning()
                        }
                    }
                }

                // Empty state
                Item {
                    width: parent.width
                    height: 60
                    visible: bluetoothPanel.powered && bluetoothPanel.devices.length === 0

                    Text {
                        anchors.centerIn: parent
                        text: "No paired devices"
                        font.pixelSize: 12
                        color: Colors.foregroundMuted
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
                                        const icon = (device.icon || "").toLowerCase()
                                        const name = (device.name || "").toLowerCase()
                                        if (icon.includes("headset") || icon.includes("headphone") ||
                                            name.includes("airpod") || name.includes("headphone") || name.includes("buds"))
                                            return "󰋋"
                                        if (icon.includes("speaker") || name.includes("speaker") || name.includes("soundbar"))
                                            return "󰓃"
                                        if (icon.includes("keyboard") || name.includes("keyboard"))
                                            return "󰌌"
                                        if (icon.includes("mouse") || name.includes("mouse"))
                                            return "󰍽"
                                        if (icon.includes("phone") || name.includes("phone") || name.includes("iphone"))
                                            return "󰏲"
                                        if (name.includes("watch"))
                                            return "󰖉"
                                        if (icon.includes("gaming") || name.includes("controller") || name.includes("gamepad"))
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
                                    text: {
                                        if (isConnecting) return "Connecting..."
                                        if (device.connected) {
                                            if (device.battery >= 0) {
                                                return "Connected · " + device.battery + "%"
                                            }
                                            return "Connected"
                                        }
                                        return "Paired"
                                    }
                                    font.pixelSize: 10
                                    color: device.connected ? Colors.success : Colors.foregroundMuted
                                }
                            }

                            // Status
                            Item {
                                width: 32
                                height: 32
                                anchors.verticalCenter: parent.verticalCenter

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
                                    BluetoothService.disconnectDevice(device.mac)
                                } else {
                                    BluetoothService.connectDevice(device.mac)
                                }
                            }
                        }
                    }
                }

                // Available Devices section (when scanning)
                Row {
                    width: parent.width
                    spacing: 8
                    visible: bluetoothPanel.powered && bluetoothPanel.scanning

                    Text {
                        text: "Available Devices"
                        font.pixelSize: 12
                        font.bold: true
                        color: Colors.foregroundAlt
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "󰑓"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 12
                        color: Colors.primary
                        anchors.verticalCenter: parent.verticalCenter

                        RotationAnimation on rotation {
                            running: bluetoothPanel.scanning
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 1000
                        }
                    }
                }

                // Scanning empty state
                Item {
                    width: parent.width
                    height: 40
                    visible: bluetoothPanel.powered && bluetoothPanel.scanning && bluetoothPanel.discoveredDevices.length === 0

                    Text {
                        anchors.centerIn: parent
                        text: "Searching for devices..."
                        font.pixelSize: 11
                        color: Colors.foregroundMuted
                    }
                }

                // Discovered device items
                Repeater {
                    model: bluetoothPanel.scanning ? bluetoothPanel.discoveredDevices : []

                    Rectangle {
                        width: deviceColumn.width
                        height: 56
                        radius: 10
                        color: discoveredArea.containsMouse ? Colors.overlay : Colors.surface

                        property var device: modelData
                        property bool isPairing: bluetoothPanel.connectingMac === device.mac

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            // Device icon
                            Rectangle {
                                width: 32
                                height: 32
                                radius: 8
                                color: Colors.overlay
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        const icon = (device.icon || "").toLowerCase()
                                        const name = (device.name || "").toLowerCase()
                                        if (icon.includes("headset") || icon.includes("headphone") ||
                                            name.includes("airpod") || name.includes("headphone") || name.includes("buds"))
                                            return "󰋋"
                                        if (icon.includes("speaker") || name.includes("speaker") || name.includes("soundbar"))
                                            return "󰓃"
                                        if (icon.includes("keyboard") || name.includes("keyboard"))
                                            return "󰌌"
                                        if (icon.includes("mouse") || name.includes("mouse"))
                                            return "󰍽"
                                        if (icon.includes("phone") || name.includes("phone") || name.includes("iphone"))
                                            return "󰏲"
                                        if (name.includes("watch"))
                                            return "󰖉"
                                        if (icon.includes("gaming") || name.includes("controller") || name.includes("gamepad"))
                                            return "󰊖"
                                        return "󰂯"
                                    }
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 16
                                    color: Colors.foreground
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
                                    text: isPairing ? "Pairing..." : "Tap to pair"
                                    font.pixelSize: 10
                                    color: Colors.foregroundMuted
                                }
                            }

                            // Pairing indicator
                            Item {
                                width: 32
                                height: 32
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰑓"
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 16
                                    color: Colors.primary
                                    visible: isPairing

                                    RotationAnimation on rotation {
                                        running: isPairing
                                        loops: Animation.Infinite
                                        from: 0
                                        to: 360
                                        duration: 800
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: discoveredArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                BluetoothService.connectDevice(device.mac)
                            }
                        }
                    }
                }

                // Bluetooth off state
                Item {
                    width: parent.width
                    height: 120
                    visible: !bluetoothPanel.powered

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
                            text: "Bluetooth is off"
                            font.pixelSize: 12
                            color: Colors.foregroundMuted
                        }
                    }
                }
            }
        }
    }
}
