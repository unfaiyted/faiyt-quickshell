import QtQuick
import Quickshell.Hyprland
import "../../../theme"
import ".."

BarGroup {
    id: windowTitle

    implicitWidth: content.width + 20
    implicitHeight: 20 

    property string title: Hyprland.activeToplevel
        ? Hyprland.activeToplevel.title
        : "Desktop"

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                let t = windowTitle.title
                if (t.length > 40) {
                    return t.substring(0, 37) + "..."
                }
                return t
            }
            color: Colors.foregroundAlt
            font.pixelSize: 11
        }
    }
}
