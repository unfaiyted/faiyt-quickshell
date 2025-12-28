import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../../../theme"
import ".."

BarGroup {
    id: musicModule

    implicitWidth: content.width + 16
    implicitHeight: 24

    // Only show if there's a player
    visible: Mpris.players.values.length > 0

    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property string trackTitle: player ? (player.trackTitle || "") : ""
    property string trackArtist: player ? (player.trackArtist || "") : ""
    property string trackAlbum: player ? (player.trackAlbum || "") : ""
    property string playerName: player ? (player.identity || "") : ""
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
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (musicModule.player && musicModule.player.canTogglePlaying) {
                musicModule.player.togglePlaying()
            }
        }
    }

    // Custom tooltip popup
    PopupWindow {
        id: tooltip
        anchor.window: QsWindow.window
        anchor.onAnchoring: {
            const pos = musicModule.mapToItem(QsWindow.window.contentItem, 0, musicModule.height)
            anchor.rect = Qt.rect(pos.x, pos.y, musicModule.width, 1)
        }
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        visible: mouseArea.containsMouse && musicModule.trackTitle.length > 0

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
                    text: musicModule.trackTitle
                    color: Colors.foreground
                    font.pixelSize: 12
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    visible: musicModule.trackArtist.length > 0
                    text: "󰠃 " + musicModule.trackArtist
                    color: Colors.subtle
                    font.pixelSize: 11
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    visible: musicModule.trackAlbum.length > 0
                    text: "󰀥 " + musicModule.trackAlbum
                    color: Colors.muted
                    font.pixelSize: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    width: tooltipColumn.width
                    height: 1
                    color: Colors.overlay
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: musicModule.playerName.length > 0
                }

                Text {
                    visible: musicModule.playerName.length > 0
                    text: musicModule.isPlaying ? "󰐊 " + musicModule.playerName : "󰏤 " + musicModule.playerName
                    color: Colors.muted
                    font.pixelSize: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
