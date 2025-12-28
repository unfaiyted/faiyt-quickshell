import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../theme"

BarGroup {
    id: clockContainer

    implicitWidth: timeText.width + 20
    implicitHeight: 24

    property date now: new Date()
    property string currentTime: Qt.formatTime(now, "HH:mm")
    property string fullDateTime: Qt.formatDateTime(now, "dddd, MMMM d, yyyy\nhh:mm:ss AP")
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
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        ToolTip.visible: containsMouse
        ToolTip.text: clockContainer.fullDateTime
        ToolTip.delay: 500

        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                copyProcess.running = true
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
