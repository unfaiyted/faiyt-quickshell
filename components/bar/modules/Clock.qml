import QtQuick
import Quickshell
import Quickshell.Io
import "../../../theme"
import ".."

BarGroup {
    id: clockContainer

    implicitWidth: timeText.width + 20
    implicitHeight: 24

    property date now: new Date()
    property string currentTime: Qt.formatTime(now, "HH:mm")
    property string fullDate: Qt.formatDateTime(now, "dddd, MMMM d, yyyy")
    property string fullTime: Qt.formatDateTime(now, "hh:mm:ss AP")
    property string timestamp: Math.floor(now.getTime() / 1000).toString()

    Process {
        id: copyProcess
        command: ["wl-copy", clockContainer.timestamp]
    }

    Text {
        id: timeText
        anchors.centerIn: parent
        text: clockContainer.currentTime
        color: Colors.foreground
        font.pixelSize: 12
        font.bold: true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                copyProcess.running = true
            }
        }
    }

    // Custom tooltip popup window
    PopupWindow {
        id: tooltip
        anchor.window: QsWindow.window
        anchor.onAnchoring: {
            const pos = clockContainer.mapToItem(QsWindow.window.contentItem, 0, clockContainer.height)
            anchor.rect = Qt.rect(pos.x, pos.y, clockContainer.width, 1)
        }
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        visible: mouseArea.containsMouse

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
                    text: clockContainer.fullDate
                    color: Colors.foreground
                    font.pixelSize: 12
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: clockContainer.fullTime
                    color: Colors.subtle
                    font.pixelSize: 11
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    width: tooltipColumn.width
                    height: 1
                    color: Colors.overlay
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "󰆏 " + clockContainer.timestamp
                    color: Colors.muted
                    font.pixelSize: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockContainer.now = new Date()
    }
}
