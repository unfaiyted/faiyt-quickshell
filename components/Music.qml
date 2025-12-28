import QtQuick
import Quickshell.Services.Mpris
import "../theme"

BarGroup {
    id: musicModule

    implicitWidth: content.width + 16
    implicitHeight: 24

    // Only show if there's a player
    visible: Mpris.players.count > 0

    property var player: Mpris.players.count > 0 ? Mpris.players.get(0) : null
    property string trackTitle: player ? (player.trackTitle || "") : ""
    property string trackArtist: player ? (player.trackArtist || "") : ""
    property bool isPlaying: player ? player.isPlaying : false

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 8

        // Play/Pause indicator
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: musicModule.isPlaying ? "▶" : "⏸"
            font.pixelSize: 12
            color: Colors.foreground
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
            font.pixelSize: 11
            color: Colors.foreground
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (musicModule.player && musicModule.player.canTogglePlaying) {
                musicModule.player.togglePlaying()
            }
        }
    }
}
