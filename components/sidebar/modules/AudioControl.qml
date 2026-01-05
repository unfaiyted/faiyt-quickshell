import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../../theme"
import "../../../services"
import "../../common"

Item {
    id: audioControl

    // CRITICAL: PwObjectTracker binds nodes so audio properties work
    PwObjectTracker {
        id: nodeTracker
        objects: Pipewire.nodes.values
    }

    // State for device selection dropdowns
    property bool showOutputDevices: false
    property bool showInputDevices: false
    property int showAppOutputFor: -1  // Stream ID for which to show output dropdown

    // Helper to get volume percentage
    function volumePercent(node) {
        if (!node || !node.audio) return 0
        return Math.round(node.audio.volume * 100)
    }

    // Helper to set volume
    function setVolume(node, percent) {
        if (node && node.audio) {
            node.audio.volume = percent / 100
        }
    }

    // Get output devices (hardware sinks, not streams)
    function getOutputDevices() {
        let devices = []
        for (let node of Pipewire.nodes.values) {
            if (node && node.isSink && !node.isStream && node.audio) {
                devices.push(node)
            }
        }
        return devices
    }

    // Get input devices (hardware sources, not streams)
    function getInputDevices() {
        let devices = []
        for (let node of Pipewire.nodes.values) {
            if (node && !node.isSink && !node.isStream && node.audio) {
                devices.push(node)
            }
        }
        return devices
    }

    // Get audio streams (apps playing audio - sink streams)
    function getAudioStreams() {
        let streams = []
        for (let node of Pipewire.nodes.values) {
            if (node && node.isStream && node.audio) {
                // Filter out system/monitor streams
                let name = (node.name || "").toLowerCase()
                if (!name.includes("peak") && !name.includes("monitor")) {
                    streams.push(node)
                }
            }
        }
        return streams
    }

    // Get display name for a node
    function getNodeName(node) {
        if (!node) return "Unknown"
        return node.nickname || node.description || node.name || "Unknown"
    }

    // Get speaker icon based on volume
    function getSpeakerIcon(node) {
        if (!node || !node.audio) return "󰖁"
        if (node.audio.muted) return "󰖁"
        let vol = volumePercent(node)
        if (vol > 66) return "󰕾"
        if (vol > 33) return "󰖀"
        if (vol > 0) return "󰕿"
        return "󰖁"
    }

    // Move a stream to a different output sink
    function moveStreamToSink(stream, sink) {
        if (!stream || !sink) return
        // Use wpctl to move the stream
        // wpctl set-node-target <stream-id> <sink-id>
        // Fallback to pactl if wpctl doesn't support this
        moveStreamProc.streamId = stream.id
        moveStreamProc.sinkId = sink.id
        moveStreamProc.running = true
    }

    // Process to move stream using wpctl
    Process {
        id: moveStreamProc
        property int streamId: 0
        property int sinkId: 0
        // Use pw-metadata to set the target.node for the stream
        command: ["bash", "-c", "pw-metadata -n " + streamId + " target.node " + sinkId]
        onRunningChanged: {
            if (!running) {
                audioControl.showAppOutputFor = -1
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // ═══════════════════════════════════════════════════════════
        // OUTPUT SECTION
        // ═══════════════════════════════════════════════════════════
        Row {
            width: parent.width
            spacing: 8

            Text {
                text: "Output"
                font.pixelSize: 12
                font.bold: true
                color: Colors.foregroundAlt
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { width: parent.width - 130; height: 1 }

            // Device selector button
            Rectangle {
                id: outputDeviceSelectorBtn
                width: 70
                height: 24
                radius: 6
                color: outputDeviceBtn.containsMouse ? Colors.surface : Colors.overlay
                anchors.verticalCenter: parent.verticalCenter
                visible: getOutputDevices().length > 1

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "Device"
                        font.pixelSize: 10
                        color: Colors.foreground
                    }

                    Text {
                        text: "󰅀"
                        font.family: Fonts.icon
                        font.pixelSize: 10
                        color: Colors.foreground
                    }
                }

                MouseArea {
                    id: outputDeviceBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioControl.showOutputDevices = !audioControl.showOutputDevices
                }

                HintTarget {
                    targetElement: outputDeviceSelectorBtn
                    scope: "sidebar-right"
                    action: () => audioControl.showOutputDevices = !audioControl.showOutputDevices
                    enabled: getOutputDevices().length > 1
                }
            }
        }

        // Output device dropdown
        Rectangle {
            width: parent.width
            height: outputDevicesList.height + 16
            radius: 8
            color: Colors.surface
            visible: audioControl.showOutputDevices && getOutputDevices().length > 1

            Column {
                id: outputDevicesList
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                spacing: 4

                Repeater {
                    model: getOutputDevices()

                    Rectangle {
                        id: outputDeviceItem
                        width: outputDevicesList.width
                        height: 32
                        radius: 6
                        color: deviceArea.containsMouse ? Colors.overlay : "transparent"

                        property var device: modelData
                        property bool isDefault: Pipewire.defaultAudioSink && device &&
                            Pipewire.defaultAudioSink.id === device.id

                        Row {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Text {
                                text: isDefault ? "󰄬" : "󰝦"
                                font.family: Fonts.icon
                                font.pixelSize: 14
                                color: isDefault ? Colors.primary : Colors.foregroundMuted
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: getNodeName(device)
                                font.pixelSize: 11
                                color: Colors.foreground
                                elide: Text.ElideRight
                                width: parent.width - 30
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: deviceArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Pipewire.preferredDefaultAudioSink = device
                                audioControl.showOutputDevices = false
                            }
                        }

                        HintTarget {
                            targetElement: outputDeviceItem
                            scope: "sidebar-right"
                            action: () => {
                                Pipewire.preferredDefaultAudioSink = device
                                audioControl.showOutputDevices = false
                            }
                            enabled: audioControl.showOutputDevices
                        }
                    }
                }
            }
        }

        // Default output with volume control
        Rectangle {
            width: parent.width
            height: 80
            radius: 12
            color: Colors.surface
            visible: Pipewire.defaultAudioSink !== null

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Row {
                    width: parent.width
                    spacing: 12

                    // Volume icon (clickable to mute)
                    Rectangle {
                        id: outputMuteBtn
                        width: 36
                        height: 36
                        radius: 8
                        color: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted
                            ? Colors.error : Colors.primary

                        Text {
                            anchors.centerIn: parent
                            text: getSpeakerIcon(Pipewire.defaultAudioSink)
                            font.family: Fonts.icon
                            font.pixelSize: 18
                            color: Colors.background
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                    Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
                                }
                            }
                        }

                        HintTarget {
                            targetElement: outputMuteBtn
                            scope: "sidebar-right"
                            action: () => {
                                if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                    Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
                                }
                            }
                            enabled: Pipewire.defaultAudioSink !== null
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        width: parent.width - 60

                        Text {
                            text: getNodeName(Pipewire.defaultAudioSink)
                            font.pixelSize: 12
                            color: Colors.foreground
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted
                                ? "Muted" : volumePercent(Pipewire.defaultAudioSink) + "%"
                            font.pixelSize: 11
                            color: Colors.foregroundAlt
                        }
                    }
                }

                // Volume slider
                Item {
                    width: parent.width
                    height: 8

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: Colors.overlay
                    }

                    Rectangle {
                        width: parent.width * Math.min(volumePercent(Pipewire.defaultAudioSink) / 100, 1.5)
                        height: parent.height
                        radius: 4
                        color: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted
                            ? Colors.foregroundMuted : Colors.primary

                        Behavior on width {
                            NumberAnimation { duration: 50 }
                        }
                    }

                    Rectangle {
                        x: Math.min(parent.width * volumePercent(Pipewire.defaultAudioSink) / 100, parent.width * 1.5) - width / 2
                        y: -4
                        width: 16
                        height: 16
                        radius: 8
                        color: Colors.foreground
                        visible: outputSlider.containsMouse || outputSlider.pressed
                    }

                    MouseArea {
                        id: outputSlider
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true

                        onPositionChanged: function(mouse) {
                            if (pressed) {
                                let vol = Math.max(0, Math.min(150, (mouse.x / width) * 100))
                                setVolume(Pipewire.defaultAudioSink, vol)
                            }
                        }

                        onClicked: function(mouse) {
                            let vol = Math.max(0, Math.min(150, (mouse.x / width) * 100))
                            setVolume(Pipewire.defaultAudioSink, vol)
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════
        // INPUT SECTION
        // ═══════════════════════════════════════════════════════════
        Row {
            width: parent.width
            spacing: 8

            Text {
                text: "Input"
                font.pixelSize: 12
                font.bold: true
                color: Colors.foregroundAlt
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { width: parent.width - 120; height: 1 }

            // Device selector button
            Rectangle {
                id: inputDeviceSelectorBtn
                width: 70
                height: 24
                radius: 6
                color: inputDeviceBtn.containsMouse ? Colors.surface : Colors.overlay
                anchors.verticalCenter: parent.verticalCenter
                visible: getInputDevices().length > 1

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "Device"
                        font.pixelSize: 10
                        color: Colors.foreground
                    }

                    Text {
                        text: "󰅀"
                        font.family: Fonts.icon
                        font.pixelSize: 10
                        color: Colors.foreground
                    }
                }

                MouseArea {
                    id: inputDeviceBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioControl.showInputDevices = !audioControl.showInputDevices
                }

                HintTarget {
                    targetElement: inputDeviceSelectorBtn
                    scope: "sidebar-right"
                    action: () => audioControl.showInputDevices = !audioControl.showInputDevices
                    enabled: getInputDevices().length > 1
                }
            }
        }

        // Input device dropdown
        Rectangle {
            width: parent.width
            height: inputDevicesList.height + 16
            radius: 8
            color: Colors.surface
            visible: audioControl.showInputDevices && getInputDevices().length > 1

            Column {
                id: inputDevicesList
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                spacing: 4

                Repeater {
                    model: getInputDevices()

                    Rectangle {
                        id: inputDeviceItem
                        width: inputDevicesList.width
                        height: 32
                        radius: 6
                        color: inputDeviceArea.containsMouse ? Colors.overlay : "transparent"

                        property var device: modelData
                        property bool isDefault: Pipewire.defaultAudioSource && device &&
                            Pipewire.defaultAudioSource.id === device.id

                        Row {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Text {
                                text: isDefault ? "󰄬" : "󰝦"
                                font.family: Fonts.icon
                                font.pixelSize: 14
                                color: isDefault ? Colors.foam : Colors.foregroundMuted
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: getNodeName(device)
                                font.pixelSize: 11
                                color: Colors.foreground
                                elide: Text.ElideRight
                                width: parent.width - 30
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: inputDeviceArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Pipewire.preferredDefaultAudioSource = device
                                audioControl.showInputDevices = false
                            }
                        }

                        HintTarget {
                            targetElement: inputDeviceItem
                            scope: "sidebar-right"
                            action: () => {
                                Pipewire.preferredDefaultAudioSource = device
                                audioControl.showInputDevices = false
                            }
                            enabled: audioControl.showInputDevices
                        }
                    }
                }
            }
        }

        // Default input with volume control
        Rectangle {
            width: parent.width
            height: 80
            radius: 12
            color: Colors.surface
            visible: Pipewire.defaultAudioSource !== null

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Row {
                    width: parent.width
                    spacing: 12

                    // Mic icon (clickable to mute)
                    Rectangle {
                        id: inputMuteBtn
                        width: 36
                        height: 36
                        radius: 8
                        color: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted
                            ? Colors.error : Colors.foam

                        Text {
                            anchors.centerIn: parent
                            text: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted
                                ? "󰍭" : "󰍬"
                            font.family: Fonts.icon
                            font.pixelSize: 18
                            color: Colors.background
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
                                    Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted
                                }
                            }
                        }

                        HintTarget {
                            targetElement: inputMuteBtn
                            scope: "sidebar-right"
                            action: () => {
                                if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
                                    Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted
                                }
                            }
                            enabled: Pipewire.defaultAudioSource !== null
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        width: parent.width - 60

                        Text {
                            text: getNodeName(Pipewire.defaultAudioSource)
                            font.pixelSize: 12
                            color: Colors.foreground
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted
                                ? "Muted" : volumePercent(Pipewire.defaultAudioSource) + "%"
                            font.pixelSize: 11
                            color: Colors.foregroundAlt
                        }
                    }
                }

                // Volume slider
                Item {
                    width: parent.width
                    height: 8

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: Colors.overlay
                    }

                    Rectangle {
                        width: parent.width * Math.min(volumePercent(Pipewire.defaultAudioSource) / 100, 1.5)
                        height: parent.height
                        radius: 4
                        color: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted
                            ? Colors.foregroundMuted : Colors.foam

                        Behavior on width {
                            NumberAnimation { duration: 50 }
                        }
                    }

                    Rectangle {
                        x: Math.min(parent.width * volumePercent(Pipewire.defaultAudioSource) / 100, parent.width * 1.5) - width / 2
                        y: -4
                        width: 16
                        height: 16
                        radius: 8
                        color: Colors.foreground
                        visible: inputSlider.containsMouse || inputSlider.pressed
                    }

                    MouseArea {
                        id: inputSlider
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true

                        onPositionChanged: function(mouse) {
                            if (pressed) {
                                let vol = Math.max(0, Math.min(150, (mouse.x / width) * 100))
                                setVolume(Pipewire.defaultAudioSource, vol)
                            }
                        }

                        onClicked: function(mouse) {
                            let vol = Math.max(0, Math.min(150, (mouse.x / width) * 100))
                            setVolume(Pipewire.defaultAudioSource, vol)
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════
        // APPLICATIONS SECTION
        // ═══════════════════════════════════════════════════════════
        Text {
            text: "Applications"
            font.pixelSize: 12
            font.bold: true
            color: Colors.foregroundAlt
        }

        // App mixer list
        Flickable {
            width: parent.width
            height: Math.max(60, parent.height - 340)
            clip: true
            contentHeight: appColumn.height
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                active: true
                policy: ScrollBar.AsNeeded
            }

            Column {
                id: appColumn
                width: parent.width
                spacing: 8

                // Empty state
                Item {
                    width: parent.width
                    height: 60
                    visible: getAudioStreams().length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰝚"
                            font.family: Fonts.icon
                            font.pixelSize: 24
                            color: Colors.foregroundMuted
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No audio streams"
                            font.pixelSize: 11
                            color: Colors.foregroundMuted
                        }
                    }
                }

                // Stream items
                Repeater {
                    model: getAudioStreams()

                    Column {
                        width: appColumn.width
                        spacing: 4

                        property var stream: modelData
                        property bool isMuted: stream && stream.audio ? stream.audio.muted : false
                        property bool showingOutputs: audioControl.showAppOutputFor === (stream ? stream.id : -1)

                        Rectangle {
                            width: parent.width
                            height: 72
                            radius: 10
                            color: Colors.surface

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                Row {
                                    width: parent.width
                                    spacing: 10

                                    // App icon
                                    Rectangle {
                                        id: appMuteBtn
                                        width: 28
                                        height: 28
                                        radius: 6
                                        color: isMuted ? Colors.overlay : Colors.primary

                                        Text {
                                            anchors.centerIn: parent
                                            text: IconService.getIcon(stream ? stream.name : "")
                                            font.family: Fonts.icon
                                            font.pixelSize: 14
                                            color: isMuted ? Colors.foregroundMuted : Colors.background
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (stream && stream.audio) {
                                                    stream.audio.muted = !stream.audio.muted
                                                }
                                            }
                                        }

                                        HintTarget {
                                            targetElement: appMuteBtn
                                            scope: "sidebar-right"
                                            action: () => {
                                                if (stream && stream.audio) {
                                                    stream.audio.muted = !stream.audio.muted
                                                }
                                            }
                                        }
                                    }

                                    // App name
                                    Text {
                                        text: getNodeName(stream)
                                        font.pixelSize: 11
                                        color: Colors.foreground
                                        elide: Text.ElideRight
                                        width: parent.width - 120
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    // Volume percentage
                                    Text {
                                        text: volumePercent(stream) + "%"
                                        font.pixelSize: 10
                                        color: Colors.foregroundAlt
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    // Output selector button
                                    Rectangle {
                                        width: 50
                                        height: 22
                                        radius: 4
                                        color: outputBtn.containsMouse ? Colors.overlay : "transparent"
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: getOutputDevices().length > 1

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 2

                                            Text {
                                                text: "󰕾"
                                                font.family: Fonts.icon
                                                font.pixelSize: 10
                                                color: Colors.foregroundAlt
                                            }

                                            Text {
                                                text: "󰅀"
                                                font.family: Fonts.icon
                                                font.pixelSize: 8
                                                color: Colors.foregroundAlt
                                            }
                                        }

                                        MouseArea {
                                            id: outputBtn
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (showingOutputs) {
                                                    audioControl.showAppOutputFor = -1
                                                } else {
                                                    audioControl.showAppOutputFor = stream.id
                                                }
                                            }
                                        }
                                    }
                                }

                                // Volume slider
                                Item {
                                    width: parent.width
                                    height: 6

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 3
                                        color: Colors.overlay
                                    }

                                    Rectangle {
                                        width: parent.width * Math.min(volumePercent(stream) / 100, 1.5)
                                        height: parent.height
                                        radius: 3
                                        color: isMuted ? Colors.foregroundMuted : Colors.primary

                                        Behavior on width {
                                            NumberAnimation { duration: 50 }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -6

                                        onPositionChanged: function(mouse) {
                                            if (pressed && stream) {
                                                let vol = Math.max(0, Math.min(150, (mouse.x / width) * 100))
                                                setVolume(stream, vol)
                                            }
                                        }

                                        onClicked: function(mouse) {
                                            if (stream) {
                                                let vol = Math.max(0, Math.min(150, (mouse.x / width) * 100))
                                                setVolume(stream, vol)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Output device dropdown for this stream
                        Rectangle {
                            width: parent.width
                            height: outputsList.height + 12
                            radius: 8
                            color: Colors.overlay
                            visible: showingOutputs

                            Column {
                                id: outputsList
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 6
                                spacing: 2

                                Repeater {
                                    model: getOutputDevices()

                                    Rectangle {
                                        width: outputsList.width
                                        height: 28
                                        radius: 4
                                        color: sinkArea.containsMouse ? Colors.surface : "transparent"

                                        property var sink: modelData
                                        property bool isDefault: Pipewire.defaultAudioSink && sink &&
                                            Pipewire.defaultAudioSink.id === sink.id

                                        Row {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            Text {
                                                text: isDefault ? "󰄬" : "󰝦"
                                                font.family: Fonts.icon
                                                font.pixelSize: 12
                                                color: isDefault ? Colors.primary : Colors.foregroundMuted
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Text {
                                                text: getNodeName(sink)
                                                font.pixelSize: 10
                                                color: Colors.foreground
                                                elide: Text.ElideRight
                                                width: parent.width - 30
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        MouseArea {
                                            id: sinkArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                moveStreamToSink(stream, sink)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
