import QtQuick
import QtQuick.Controls
import Quickshell.Services.Pipewire
import "../../../theme"

Item {
    id: audioControl

    property bool showAllApps: false

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

    // Helper to get output devices (sinks that are not streams)
    function getOutputDevices() {
        let devices = []
        for (let i = 0; i < Pipewire.nodes.length; i++) {
            let node = Pipewire.nodes[i]
            if (node.isSink && !node.isStream && node.audio) {
                devices.push(node)
            }
        }
        return devices
    }

    // Helper to get input devices (sources that are not streams)
    function getInputDevices() {
        let devices = []
        for (let i = 0; i < Pipewire.nodes.length; i++) {
            let node = Pipewire.nodes[i]
            if (!node.isSink && !node.isStream && node.audio) {
                devices.push(node)
            }
        }
        return devices
    }

    // Helper to get audio streams (apps)
    function getAudioStreams() {
        let streams = []
        for (let i = 0; i < Pipewire.nodes.length; i++) {
            let node = Pipewire.nodes[i]
            if (node.isStream && node.audio) {
                // Filter out system streams
                let name = (node.name || "").toLowerCase()
                if (!name.includes("peak") && !name.includes("monitor")) {
                    streams.push(node)
                }
            }
        }
        return streams
    }

    // Get icon for app name
    function getAppIcon(name) {
        let n = (name || "").toLowerCase()
        if (n.includes("firefox")) return "󰈹"
        if (n.includes("chrome") || n.includes("chromium")) return ""
        if (n.includes("spotify")) return "󰓇"
        if (n.includes("discord")) return "󰙯"
        if (n.includes("obs")) return "󰑋"
        if (n.includes("mpv") || n.includes("vlc") || n.includes("video")) return "󰕧"
        if (n.includes("music") || n.includes("rhythmbox") || n.includes("clementine")) return "󰎆"
        if (n.includes("game") || n.includes("steam")) return "󰊖"
        return "󰓃"
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Output Section
        Text {
            text: "Output"
            font.pixelSize: 12
            font.bold: true
            color: Colors.foregroundAlt
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
                        width: 36
                        height: 36
                        radius: 8
                        color: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted
                            ? Colors.error : Colors.primary

                        Text {
                            anchors.centerIn: parent
                            text: {
                                if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) return "󰖁"
                                if (Pipewire.defaultAudioSink.audio.muted) return "󰖁"
                                let vol = volumePercent(Pipewire.defaultAudioSink)
                                if (vol > 66) return "󰕾"
                                if (vol > 33) return "󰖀"
                                return "󰕿"
                            }
                            font.family: "Symbols Nerd Font"
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
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        width: parent.width - 60

                        Text {
                            text: Pipewire.defaultAudioSink ? (Pipewire.defaultAudioSink.description || Pipewire.defaultAudioSink.name || "Speaker") : "Speaker"
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

        // Input Section
        Text {
            text: "Input"
            font.pixelSize: 12
            font.bold: true
            color: Colors.foregroundAlt
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
                        width: 36
                        height: 36
                        radius: 8
                        color: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted
                            ? Colors.error : Colors.foam

                        Text {
                            anchors.centerIn: parent
                            text: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted
                                ? "󰍭" : "󰍬"
                            font.family: "Symbols Nerd Font"
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
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        width: parent.width - 60

                        Text {
                            text: Pipewire.defaultAudioSource ? (Pipewire.defaultAudioSource.description || Pipewire.defaultAudioSource.name || "Microphone") : "Microphone"
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

        // Applications Section
        Row {
            width: parent.width
            spacing: 8

            Text {
                text: "Applications"
                font.pixelSize: 12
                font.bold: true
                color: Colors.foregroundAlt
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { width: parent.width - 120; height: 1 }

            // Filter toggle
            Rectangle {
                width: 28
                height: 28
                radius: 6
                color: filterArea.containsMouse ? Colors.surface : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: audioControl.showAllApps ? "󰈈" : "󰈉"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 14
                    color: audioControl.showAllApps ? Colors.primary : Colors.foregroundMuted
                }

                MouseArea {
                    id: filterArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: audioControl.showAllApps = !audioControl.showAllApps
                }
            }
        }

        // App mixer list
        Flickable {
            width: parent.width
            height: parent.height - 280
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

                    Text {
                        anchors.centerIn: parent
                        text: "No audio streams"
                        font.pixelSize: 11
                        color: Colors.foregroundMuted
                    }
                }

                // Stream items
                Repeater {
                    model: getAudioStreams()

                    Rectangle {
                        width: appColumn.width
                        height: 56
                        radius: 10
                        color: Colors.surface

                        property var stream: modelData
                        property bool isMuted: stream && stream.audio ? stream.audio.muted : false

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            // App icon
                            Rectangle {
                                width: 32
                                height: 32
                                radius: 8
                                color: isMuted ? Colors.overlay : Colors.primary
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: getAppIcon(stream ? stream.name : "")
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 16
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
                            }

                            // App info and slider
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                width: parent.width - 50

                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Text {
                                        text: stream ? (stream.description || stream.name || "App") : "App"
                                        font.pixelSize: 11
                                        color: Colors.foreground
                                        elide: Text.ElideRight
                                        width: parent.width - 40
                                    }

                                    Text {
                                        text: volumePercent(stream) + "%"
                                        font.pixelSize: 10
                                        color: Colors.foregroundAlt
                                    }
                                }

                                // Mini slider
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
                    }
                }
            }
        }
    }
}
