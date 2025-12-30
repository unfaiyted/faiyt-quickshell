import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../../../theme"

Item {
    id: wifiPanel

    property bool enabled: true
    property string currentSsid: ""
    property int currentSignal: 0
    property var networks: []
    property string connectingTo: ""
    property string connectionStatus: ""  // "connecting", "success", "failed"
    property string passwordSsid: ""
    property string passwordInput: ""

    // Check WiFi status and current connection
    Process {
        id: statusProcess
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                wifiPanel.enabled = data.trim() === "enabled"
            }
        }

        onRunningChanged: {
            if (!running && wifiPanel.enabled) {
                currentProcess.running = true
            }
        }
    }

    // Get current connection
    Process {
        id: currentProcess
        command: ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]

        stdout: SplitParser {
            onRead: data => {
                if (data.includes(":wifi:") || data.includes(":802-11-wireless:")) {
                    const parts = data.split(":")
                    wifiPanel.currentSsid = parts[0]
                }
            }
        }

        onRunningChanged: {
            if (!running) {
                scanProcess.running = true
            }
        }
    }

    // Scan for networks
    Process {
        id: scanProcess
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "device", "wifi", "list", "--rescan", "auto"]

        property var networkList: []

        stdout: SplitParser {
            onRead: data => {
                const parts = data.split(":")
                if (parts.length >= 3 && parts[0].trim() !== "") {
                    const ssid = parts[0]
                    const signal = parseInt(parts[1]) || 0
                    const security = parts[2] || ""
                    const inUse = parts[3] === "*"

                    // Update current signal if connected
                    if (inUse) {
                        wifiPanel.currentSignal = signal
                    }

                    // Avoid duplicates
                    if (!scanProcess.networkList.find(function(n) { return n.ssid === ssid })) {
                        scanProcess.networkList.push({
                            ssid: ssid,
                            signal: signal,
                            secured: security !== "" && security !== "--",
                            connected: inUse
                        })
                    }
                }
            }
        }

        onRunningChanged: {
            if (!running) {
                // Sort: connected first, then by signal strength
                networkList.sort(function(a, b) {
                    if (a.connected !== b.connected) return b.connected - a.connected
                    return b.signal - a.signal
                })
                wifiPanel.networks = networkList
                networkList = []
            }
        }
    }

    // Toggle WiFi
    Process {
        id: toggleProcess
        command: ["nmcli", "radio", "wifi", wifiPanel.enabled ? "off" : "on"]
        onRunningChanged: {
            if (!running) {
                statusProcess.running = true
            }
        }
    }

    // Connect to network
    Process {
        id: connectProcess
        property string targetSsid: ""
        property string password: ""
        command: password !== ""
            ? ["nmcli", "device", "wifi", "connect", targetSsid, "password", password]
            : ["nmcli", "device", "wifi", "connect", targetSsid]

        onRunningChanged: {
            if (!running) {
                // Check if connection succeeded
                wifiPanel.connectionStatus = wifiPanel.currentSsid === targetSsid ? "success" : "failed"
                wifiPanel.connectingTo = ""
                wifiPanel.passwordSsid = ""
                wifiPanel.passwordInput = ""
                refreshNetworks()

                // Clear status after 3 seconds
                statusTimer.restart()
            }
        }
    }

    // Disconnect
    Process {
        id: disconnectProcess
        command: ["nmcli", "connection", "down", wifiPanel.currentSsid]
        onRunningChanged: {
            if (!running) {
                wifiPanel.currentSsid = ""
                wifiPanel.currentSignal = 0
                refreshNetworks()
            }
        }
    }

    Timer {
        id: statusTimer
        interval: 3000
        onTriggered: wifiPanel.connectionStatus = ""
    }

    function refreshNetworks() {
        statusProcess.running = true
    }

    function connectToNetwork(ssid, secured) {
        // Check if we have a saved connection
        wifiPanel.connectingTo = ssid
        wifiPanel.connectionStatus = "connecting"

        if (secured && ssid !== wifiPanel.currentSsid) {
            // Check if saved
            savedCheckProcess.targetSsid = ssid
            savedCheckProcess.running = true
        } else {
            connectProcess.targetSsid = ssid
            connectProcess.password = ""
            connectProcess.running = true
        }
    }

    // Check for saved connection
    Process {
        id: savedCheckProcess
        property string targetSsid: ""
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show"]

        property bool found: false

        stdout: SplitParser {
            onRead: data => {
                if (data.trim() === savedCheckProcess.targetSsid) {
                    savedCheckProcess.found = true
                }
            }
        }

        onRunningChanged: {
            if (!running) {
                if (found) {
                    // Saved connection exists, connect directly
                    connectProcess.targetSsid = targetSsid
                    connectProcess.password = ""
                    connectProcess.running = true
                } else {
                    // Need password
                    wifiPanel.passwordSsid = targetSsid
                    wifiPanel.connectingTo = ""
                    wifiPanel.connectionStatus = ""
                }
                found = false
            }
        }
    }

    // Auto-refresh
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: refreshNetworks()
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

                // WiFi icon
                Rectangle {
                    width: 32
                    height: 32
                    radius: 8
                    color: wifiPanel.enabled ? Colors.primary : Colors.overlay
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (!wifiPanel.enabled) return "󰤭"
                            if (wifiPanel.currentSignal >= 80) return "󰤨"
                            if (wifiPanel.currentSignal >= 60) return "󰤥"
                            if (wifiPanel.currentSignal >= 40) return "󰤢"
                            if (wifiPanel.currentSignal >= 20) return "󰤟"
                            return "󰤯"
                        }
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 16
                        color: wifiPanel.enabled ? Colors.background : Colors.foregroundMuted
                    }
                }

                // Status text
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: "Wi-Fi"
                        font.pixelSize: 13
                        font.bold: true
                        color: Colors.foreground
                    }

                    Text {
                        text: !wifiPanel.enabled ? "Off" :
                              wifiPanel.currentSsid !== "" ? wifiPanel.currentSsid : "Not connected"
                        font.pixelSize: 11
                        color: Colors.foregroundAlt
                        elide: Text.ElideRight
                        width: 120
                    }
                }

                // Spacer
                Item { width: parent.width - 280; height: 1 }

                // Signal strength
                Text {
                    text: wifiPanel.currentSignal + "%"
                    font.pixelSize: 11
                    color: Colors.foregroundAlt
                    anchors.verticalCenter: parent.verticalCenter
                    visible: wifiPanel.currentSsid !== ""
                }

                // Power switch
                Rectangle {
                    width: 44
                    height: 24
                    radius: 12
                    color: wifiPanel.enabled ? Colors.primary : Colors.overlay
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Rectangle {
                        x: wifiPanel.enabled ? 22 : 2
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
                        onClicked: toggleProcess.running = true
                    }
                }
            }
        }

        // Networks header
        Row {
            width: parent.width
            spacing: 8

            Text {
                text: "Available Networks"
                font.pixelSize: 12
                font.bold: true
                color: Colors.foregroundAlt
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { width: parent.width - 150; height: 1 }

            // Refresh button
            Rectangle {
                width: 32
                height: 32
                radius: 8
                color: refreshArea.containsMouse ? Colors.surface : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "󰑓"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 16
                    color: Colors.foreground

                    RotationAnimation on rotation {
                        running: scanProcess.running
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1000
                    }
                }

                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: refreshNetworks()
                }
            }
        }

        // Password dialog
        Rectangle {
            width: parent.width
            height: passwordColumn.height + 24
            radius: 12
            color: Colors.surface
            visible: wifiPanel.passwordSsid !== ""

            Column {
                id: passwordColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 12

                Row {
                    spacing: 8

                    Text {
                        text: "󰌾"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 16
                        color: Colors.foreground
                    }

                    Text {
                        text: "Connect to " + wifiPanel.passwordSsid
                        font.pixelSize: 12
                        font.bold: true
                        color: Colors.foreground
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 8
                    color: Colors.overlay

                    TextInput {
                        id: passwordField
                        anchors.fill: parent
                        anchors.margins: 10
                        font.pixelSize: 12
                        color: Colors.foreground
                        echoMode: TextInput.Password
                        clip: true

                        onTextChanged: wifiPanel.passwordInput = text
                        Keys.onReturnPressed: {
                            if (text !== "") {
                                connectProcess.targetSsid = wifiPanel.passwordSsid
                                connectProcess.password = text
                                wifiPanel.connectingTo = wifiPanel.passwordSsid
                                wifiPanel.connectionStatus = "connecting"
                                connectProcess.running = true
                            }
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Password"
                        font.pixelSize: 12
                        color: Colors.foregroundMuted
                        visible: passwordField.text === ""
                    }
                }

                Row {
                    spacing: 8
                    anchors.right: parent.right

                    Rectangle {
                        width: 70
                        height: 32
                        radius: 8
                        color: cancelArea.containsMouse ? Colors.overlay : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.pixelSize: 11
                            color: Colors.foreground
                        }

                        MouseArea {
                            id: cancelArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                wifiPanel.passwordSsid = ""
                                wifiPanel.passwordInput = ""
                                passwordField.text = ""
                            }
                        }
                    }

                    Rectangle {
                        width: 70
                        height: 32
                        radius: 8
                        color: wifiPanel.passwordInput !== "" ? Colors.primary : Colors.overlay

                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            font.pixelSize: 11
                            font.bold: true
                            color: wifiPanel.passwordInput !== "" ? Colors.background : Colors.foregroundMuted
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: wifiPanel.passwordInput !== ""
                            onClicked: {
                                connectProcess.targetSsid = wifiPanel.passwordSsid
                                connectProcess.password = wifiPanel.passwordInput
                                wifiPanel.connectingTo = wifiPanel.passwordSsid
                                wifiPanel.connectionStatus = "connecting"
                                connectProcess.running = true
                            }
                        }
                    }
                }
            }
        }

        // Network list
        Flickable {
            width: parent.width
            height: parent.height - (wifiPanel.passwordSsid !== "" ? 230 : 130)
            clip: true
            contentHeight: networkColumn.height
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                active: true
                policy: ScrollBar.AsNeeded
            }

            Column {
                id: networkColumn
                width: parent.width
                spacing: 6

                // Empty state
                Item {
                    width: parent.width
                    height: 120
                    visible: wifiPanel.networks.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰤭"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 32
                            color: Colors.foregroundMuted
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: wifiPanel.enabled ? "No networks found" : "WiFi is off"
                            font.pixelSize: 12
                            color: Colors.foregroundMuted
                        }
                    }
                }

                // Network items
                Repeater {
                    model: wifiPanel.networks

                    Rectangle {
                        width: networkColumn.width
                        height: 48
                        radius: 10
                        color: netArea.containsMouse ? Colors.overlay : Colors.surface

                        property var network: modelData
                        property bool isConnecting: wifiPanel.connectingTo === network.ssid
                        property bool isConnected: network.connected
                        property bool showSuccess: wifiPanel.connectionStatus === "success" && network.ssid === wifiPanel.currentSsid
                        property bool showFailed: wifiPanel.connectionStatus === "failed" && network.ssid === wifiPanel.connectingTo

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            // Signal icon
                            Text {
                                text: {
                                    if (network.signal >= 80) return "󰤨"
                                    if (network.signal >= 60) return "󰤥"
                                    if (network.signal >= 40) return "󰤢"
                                    if (network.signal >= 20) return "󰤟"
                                    return "󰤯"
                                }
                                font.family: "Symbols Nerd Font"
                                font.pixelSize: 18
                                color: isConnected ? Colors.primary : Colors.foreground
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Lock icon for secured networks
                            Text {
                                text: "󰌾"
                                font.family: "Symbols Nerd Font"
                                font.pixelSize: 12
                                color: Colors.foregroundMuted
                                anchors.verticalCenter: parent.verticalCenter
                                visible: network.secured
                            }

                            // Network name
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                width: parent.width - 120

                                Text {
                                    text: network.ssid
                                    font.pixelSize: 12
                                    color: Colors.foreground
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: "Connected"
                                    font.pixelSize: 10
                                    color: Colors.success
                                    visible: isConnected
                                }
                            }

                            // Signal percentage
                            Text {
                                text: network.signal + "%"
                                font.pixelSize: 10
                                color: Colors.foregroundMuted
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Status indicator
                            Item {
                                width: 24
                                height: 24
                                anchors.verticalCenter: parent.verticalCenter

                                // Spinner
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰑓"
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 14
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

                                // Success
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰄬"
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 14
                                    color: Colors.success
                                    visible: showSuccess
                                }

                                // Failed
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 14
                                    color: Colors.error
                                    visible: showFailed
                                }
                            }
                        }

                        MouseArea {
                            id: netArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (isConnected) {
                                    disconnectProcess.running = true
                                } else {
                                    connectToNetwork(network.ssid, network.secured)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
