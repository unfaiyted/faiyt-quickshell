import QtQuick
import Quickshell
import Quickshell.Io
import "../../../theme"
import "../../../services"
import ".."
import "../../common"

BarGroup {
    id: micIndicator

    implicitWidth: micIcon.width + 16
    implicitHeight: 30

    property bool micMuted: false

    // Only show when mic is muted AND module is enabled
    visible: micMuted && ConfigService.barModuleMicIndicator

    // Check mic mute status via wpctl
    Process {
        id: micStatusProcess
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                // Output is like "Volume: 1.00" or "Volume: 1.00 [MUTED]"
                micIndicator.micMuted = data.includes("[MUTED]")
            }
        }
    }

    // Toggle mic mute via wpctl
    Process {
        id: micToggleProcess
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "0"]  // Unmute
        onRunningChanged: {
            if (!running) {
                micStatusProcess.running = true
            }
        }
    }

    // Refresh status periodically
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: micStatusProcess.running = true
    }

    // Subtle background with love accent
    color: Qt.rgba(Colors.love.r, Colors.love.g, Colors.love.b, 0.15)
    border.width: 1
    border.color: Qt.rgba(Colors.love.r, Colors.love.g, Colors.love.b, 0.3)

    Text {
        id: micIcon
        anchors.centerIn: parent
        text: "󰍭"
        color: Colors.love
        font.pixelSize: Fonts.iconMedium
        font.family: Fonts.icon
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            micIndicator.micMuted = false  // Optimistic update
            micToggleProcess.running = true
        }
    }

    HintTarget {
        targetElement: micIndicator
        scope: "bar"
        action: () => {
            micIndicator.micMuted = false
            micToggleProcess.running = true
        }
    }

    // Tooltip popup
    PopupWindow {
        id: tooltip
        anchor.window: QsWindow.window
        anchor.onAnchoring: {
            const pos = micIndicator.mapToItem(QsWindow.window.contentItem, 0, micIndicator.height)
            anchor.rect = Qt.rect(pos.x, pos.y, micIndicator.width, 7)
        }
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        visible: mouseArea.containsMouse

        implicitWidth: tooltipContent.width
        implicitHeight: tooltipContent.height
        color: "transparent"

        Rectangle {
            id: tooltipContent
            width: tooltipText.width + 16
            height: tooltipText.height + 12
            color: Colors.surface
            radius: 6
            border.width: 1
            border.color: Colors.border

            Text {
                id: tooltipText
                anchors.centerIn: parent
                text: "Click to unmute"
                color: Colors.foreground
                font.family: Fonts.ui
                font.pixelSize: Fonts.small
            }
        }
    }
}
