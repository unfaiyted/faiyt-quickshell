import QtQuick
import Quickshell
import Quickshell.Io
import "../../../theme"
import ".."

Item {
    id: utilBtn

    property string icon: ""
    property string tooltip: ""
    property var command: []
    property var onActivate: null  // Optional function callback

    width: 20
    height: 20

    Process {
        id: proc
        command: utilBtn.command
    }

    Text {
        anchors.centerIn: parent
        text: utilBtn.icon
        font.pixelSize: 14
        font.family: Fonts.icon
        color: mouseArea.containsMouse ? Colors.rose : Colors.foreground
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (utilBtn.onActivate) {
                utilBtn.onActivate()
            } else if (utilBtn.command.length > 0) {
                proc.running = true
            }
        }
        onContainsMouseChanged: {
            if (containsMouse && utilBtn.tooltip) {
                tooltipTimer.start()
            } else {
                tooltipTimer.stop()
                tooltipPopup.visible = false
            }
        }
    }

    Timer {
        id: tooltipTimer
        interval: 500
        onTriggered: tooltipPopup.visible = true
    }

    PopupWindow {
        id: tooltipPopup
        anchor.window: QsWindow.window
        anchor.onAnchoring: {
            const pos = utilBtn.mapToItem(QsWindow.window.contentItem, 0, utilBtn.height + 4)
            anchor.rect = Qt.rect(pos.x - tooltipContent.width / 2 + utilBtn.width / 2, pos.y, 1, 1)
        }
        anchor.edges: Edges.Top | Edges.Left

        visible: false
        implicitWidth: tooltipContent.width
        implicitHeight: tooltipContent.height
        color: "transparent"

        Rectangle {
            id: tooltipContent
            width: tooltipText.width + 16
            height: tooltipText.height + 8
            radius: 6
            color: Colors.surface
            border.width: 1
            border.color: Colors.overlay

            Text {
                id: tooltipText
                anchors.centerIn: parent
                text: utilBtn.tooltip
                font.pixelSize: 11
                color: Colors.foreground
            }
        }
    }
}
