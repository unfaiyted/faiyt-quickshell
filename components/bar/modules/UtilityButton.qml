import QtQuick
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
    }
}
