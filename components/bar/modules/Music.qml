import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../../../theme"
import "../../../services"
import ".."

BarGroup {
    id: musicModule

    implicitWidth: content.width + 16
    implicitHeight: 30

    // Only show if enabled, there's a player, and actual track data
    visible: ConfigService.barModuleMusic && Mpris.players.values.length > 0 && trackTitle.length > 0

    // Track the last active player (most recently playing)
    property string lastActivePlayerId: ""

    // Get the active player (prefer last active, then playing, then any with track)
    function getActivePlayer() {
        let players = Mpris.players.values
        if (players.length === 0) return null

        // Check if any player just started playing (switch to it)
        for (let p of players) {
            if (p && p.isPlaying) {
                // A player is playing - make it the last active
                lastActivePlayerId = p.identity || p.name || ""
                return p
            }
        }

        // No player is currently playing - stick with last active player if available
        if (lastActivePlayerId) {
            for (let p of players) {
                if (p && (p.identity === lastActivePlayerId || p.name === lastActivePlayerId)) {
                    return p
                }
            }
        }

        // Fallback: return first player with a track
        for (let p of players) {
            if (p && p.trackTitle) return p
        }

        // Last fallback: first player
        return players[0]
    }

    // Active player - auto-switches only when a new player starts playing
    property var player: getActivePlayer()

    // Timer to check for player state changes
    Timer {
        interval: 500
        running: Mpris.players.values.length > 0
        repeat: true
        onTriggered: musicModule.player = getActivePlayer()
    }

    property string trackTitle: player ? (player.trackTitle || "") : ""
    property string trackArtist: player ? (player.trackArtist || "") : ""
    property string trackAlbum: player ? (player.trackAlbum || "") : ""
    property string playerName: player ? (player.identity || "") : ""
    property bool isPlaying: player ? player.isPlaying : false

    // Control cava based on playing state
    onIsPlayingChanged: {
        if (isPlaying) {
            CavaService.open()
        } else {
            CavaService.close()
        }
    }

    // Album art
    property string artUrl: player ? (player.trackArtUrl || "") : ""

    // Progress tracking
    property real position: player ? player.position : 0
    property real length: player ? player.length : 0
    property real progress: length > 0 ? position / length : 0

    // Playback controls
    property bool canPrevious: player ? player.canGoPrevious : false
    property bool canNext: player ? player.canGoNext : false

    // Hover state tracking for popup - at module level so accessible everywhere
    property bool hoverModule: false
    // Check if mouse is over any part of the popup
    property bool hoverPopup: tooltipMouseArea.containsMouse ||
                              progressMouseArea.containsMouse ||
                              prevArea.containsMouse ||
                              playArea.containsMouse ||
                              nextArea.containsMouse

    // Format time helper
    function formatTime(seconds) {
        var mins = Math.floor(seconds / 60)
        var secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    // Get image path from URL
    function getImagePath(url) {
        if (!url) return ""
        if (url.startsWith("file://")) return url.substring(7)
        return url
    }

    // Progress update timer
    Timer {
        interval: 500
        running: musicModule.isPlaying && tooltip.visible
        repeat: true
        onTriggered: {
            if (musicModule.player) {
                musicModule.position = musicModule.player.position
            }
        }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 8

        // Cava bars when playing, icon when paused
        Item {
            width: musicModule.isPlaying ? cavaRow.width : playIcon.width
            height: 14
            anchors.verticalCenter: parent.verticalCenter

            Row {
                id: cavaRow
                visible: musicModule.isPlaying
                spacing: 2
                anchors.bottom: parent.bottom

                Repeater {
                    // Only show first 6 bars in the bar module
                    model: CavaService.values.slice(0, 6)
                    Rectangle {
                        width: 3
                        height: Math.max(3, modelData * 0.14)
                        radius: 1
                        color: Colors.primary
                        anchors.bottom: parent.bottom

                        Behavior on height {
                            NumberAnimation { duration: 50 }
                        }
                    }
                }
            }

            Text {
                id: playIcon
                visible: !musicModule.isPlaying
                anchors.verticalCenter: parent.verticalCenter
                text: "󰏤"
                font.pixelSize: 12
                font.family: Fonts.icon
                color: Colors.foreground
            }
        }

        // Track title
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: musicModule.trackTitle.length > 0
            text: {
                let t = musicModule.trackTitle
                if (t.length > 25) {
                    return t.substring(0, 22) + "..."
                }
                return t
            }
            font.pixelSize: 12
            color: Colors.foreground
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (musicModule.player && musicModule.player.canTogglePlaying) {
                musicModule.player.togglePlaying()
            }
        }
        onEntered: {
            musicModule.hoverModule = true
            if (musicModule.trackTitle.length > 0) {
                tooltip.show()
            }
        }
        onExited: {
            musicModule.hoverModule = false
            tooltip.scheduleClose()
        }
    }

    // Custom tooltip popup
    PopupWindow {
        id: tooltip
        anchor.window: QsWindow.window
        anchor.onAnchoring: {
            const pos = musicModule.mapToItem(QsWindow.window.contentItem, 0, musicModule.height)
            anchor.rect = Qt.rect(pos.x, pos.y, musicModule.width, 7)
        }
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        visible: false

        property real slideOffset: -tooltipContent.height

        function show() {
            closeTimer.stop()
            hideTimer.stop()
            visible = true
            slideOffset = 0
        }

        function hide() {
            slideOffset = -tooltipContent.height
            hideTimer.start()
        }

        function scheduleClose() {
            // Only schedule if not already scheduled
            if (!closeTimer.running) {
                closeTimer.start()
            }
        }

        Timer {
            id: closeTimer
            interval: 300  // Enough time to cross the gap
            onTriggered: {
                // Only close if not hovering either the module or popup
                if (!musicModule.hoverModule && !musicModule.hoverPopup) {
                    tooltip.hide()
                }
            }
        }

        Timer {
            id: hideTimer
            interval: 200
            onTriggered: tooltip.visible = false
        }

        implicitWidth: tooltipContent.width
        implicitHeight: tooltipContent.height
        color: "transparent"

        Rectangle {
            id: tooltipContent
            width: 280
            height: mainColumn.height + 24
            color: Colors.surface
            radius: 8
            border.width: 1
            border.color: Colors.overlay
            y: tooltip.slideOffset

            Behavior on y {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            MouseArea {
                id: tooltipMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onEntered: closeTimer.stop()
                onExited: tooltip.scheduleClose()
            }

            Column {
                id: mainColumn
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 12
                spacing: 12
                width: parent.width - 24

                // Top section: Album art + Track info
                Row {
                    spacing: 12
                    width: parent.width

                    // Album art
                    Rectangle {
                        width: 70
                        height: 70
                        radius: 6
                        color: Colors.overlay
                        clip: true

                        Image {
                            id: albumArt
                            anchors.fill: parent
                            source: musicModule.getImagePath(musicModule.artUrl)
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }

                        // Placeholder icon when no art
                        Text {
                            anchors.centerIn: parent
                            text: "󰎆"
                            font.pixelSize: 32
                            font.family: Fonts.icon
                            color: Colors.muted
                            visible: albumArt.status !== Image.Ready
                        }
                    }

                    // Track info
                    Column {
                        spacing: 4
                        width: parent.width - 82
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: musicModule.trackTitle
                            color: Colors.foreground
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            visible: musicModule.trackArtist.length > 0
                            text: musicModule.trackArtist
                            color: Colors.foregroundAlt
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            visible: musicModule.trackAlbum.length > 0
                            text: musicModule.trackAlbum
                            color: Colors.muted
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }

                // Cava visualization bars - full 40 bars in popup
                Item {
                    width: parent.width
                    height: 36
                    visible: musicModule.isPlaying

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        spacing: 1

                        Repeater {
                            model: CavaService.values
                            Rectangle {
                                width: 5
                                height: Math.max(4, modelData * 0.35)
                                radius: 2
                                color: Colors.primary
                                anchors.bottom: parent.bottom

                                Behavior on height {
                                    NumberAnimation { duration: 50 }
                                }
                            }
                        }
                    }
                }

                // Progress bar section
                Column {
                    width: parent.width
                    spacing: 4

                    // Progress bar
                    Rectangle {
                        id: progressBar
                        width: parent.width
                        height: 6
                        radius: 3
                        color: Colors.overlay

                        Rectangle {
                            width: parent.width * musicModule.progress
                            height: parent.height
                            radius: 3
                            color: Colors.primary

                            Behavior on width {
                                NumberAnimation { duration: 200 }
                            }
                        }

                        // Seek handle (visible on hover)
                        Rectangle {
                            visible: progressMouseArea.containsMouse
                            x: parent.width * musicModule.progress - 5
                            y: -2
                            width: 10
                            height: 10
                            radius: 5
                            color: Colors.foreground
                        }

                        MouseArea {
                            id: progressMouseArea
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: function(mouse) {
                                if (musicModule.player && musicModule.length > 0) {
                                    var seekPos = (mouse.x / progressBar.width) * musicModule.length
                                    seekPos = Math.max(0, Math.min(seekPos, musicModule.length))
                                    musicModule.player.position = seekPos
                                    musicModule.position = seekPos
                                }
                            }
                        }
                    }

                    // Time labels
                    Item {
                        width: parent.width
                        height: 14

                        Text {
                            anchors.left: parent.left
                            text: musicModule.formatTime(musicModule.position)
                            color: Colors.muted
                            font.pixelSize: 10
                        }

                        Text {
                            anchors.right: parent.right
                            text: musicModule.formatTime(musicModule.length)
                            color: Colors.muted
                            font.pixelSize: 10
                        }
                    }
                }

                // Playback controls
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    // Previous button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: prevArea.containsMouse ? Colors.overlay : "transparent"
                        opacity: musicModule.canPrevious ? 1.0 : 0.4

                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            font.pixelSize: 16
                            font.family: Fonts.icon
                            color: Colors.foreground
                        }

                        MouseArea {
                            id: prevArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: musicModule.canPrevious ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (musicModule.canPrevious && musicModule.player) {
                                    musicModule.player.previous()
                                }
                            }
                        }
                    }

                    // Play/Pause button
                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        color: playArea.containsMouse ? Colors.primary : Colors.overlay

                        Text {
                            anchors.centerIn: parent
                            text: musicModule.isPlaying ? "󰏤" : "󰐊"
                            font.pixelSize: 20
                            font.family: Fonts.icon
                            color: playArea.containsMouse ? Colors.background : Colors.foreground
                        }

                        MouseArea {
                            id: playArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (musicModule.player && musicModule.player.canTogglePlaying) {
                                    musicModule.player.togglePlaying()
                                }
                            }
                        }
                    }

                    // Next button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: nextArea.containsMouse ? Colors.overlay : "transparent"
                        opacity: musicModule.canNext ? 1.0 : 0.4

                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            font.pixelSize: 16
                            font.family: Fonts.icon
                            color: Colors.foreground
                        }

                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: musicModule.canNext ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (musicModule.canNext && musicModule.player) {
                                    musicModule.player.next()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
