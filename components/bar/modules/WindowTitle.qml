import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../../theme"
import ".."

BarGroup {
    id: windowTitle

    implicitWidth: content.width + 20
    implicitHeight: 30

    // Use ToplevelManager to get the focused window
    property var focusedToplevel: {
        for (var toplevel of ToplevelManager.toplevels.values) {
            if (toplevel.activated) {
                return toplevel
            }
        }
        return null
    }

    property string title: focusedToplevel?.title ?? "Desktop"
    property string appClass: focusedToplevel?.appId ?? ""

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 6

        Image {
            id: appIcon
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            source: windowTitle.appClass !== "" ? Quickshell.iconPath(windowTitle.appClass, "image-missing") : ""
            sourceSize: Qt.size(14, 14)
            visible: status === Image.Ready
        }

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
            font.pixelSize: 12
        }
    }
}
