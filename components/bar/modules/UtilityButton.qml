import QtQuick
import Quickshell.Io
import "../../../theme"
import ".."

Item {
    id: utilBtn

    property string icon: ""
    property string tooltip: ""
    property var command: []

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
        font.family: "Symbols Nerd Font"
        color: mouseArea.containsMouse ? Colors.rose : Colors.foreground
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: proc.running = true
    }
}
