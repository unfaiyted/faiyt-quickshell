import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../../theme"
import "../../../services"
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

        // Check if we have a NerdFont icon for this app
        property bool hasNerdIcon: IconService.hasIcon(windowTitle.appClass)
        // Only try system icon if we don't have a NerdFont mapping
        property string iconPath: (!hasNerdIcon && windowTitle.appClass !== "") ? Quickshell.iconPath(windowTitle.appClass, "") : ""

        // NerdFont icon (preferred - use if we have a mapping)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: windowTitle.appClass !== "" && content.hasNerdIcon
            text: IconService.getIcon(windowTitle.appClass)
            font.family: Fonts.icon
            font.pixelSize: Fonts.iconMedium
            color: Colors.foreground
        }

        // System icon (fallback for apps without NerdFont mapping)
        Image {
            id: appIcon
            anchors.verticalCenter: parent.verticalCenter
            width: Fonts.iconMedium
            height: Fonts.iconMedium
            source: content.iconPath
            sourceSize: Qt.size(Fonts.iconMedium, Fonts.iconMedium)
            visible: !content.hasNerdIcon && status === Image.Ready
        }

        // Default NerdFont icon (when system icon also fails)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: windowTitle.appClass !== "" && !content.hasNerdIcon && appIcon.status !== Image.Ready
            text: IconService.getIcon("")
            font.family: Fonts.icon
            font.pixelSize: Fonts.iconMedium
            color: Colors.foreground
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
            font.family: Fonts.ui
            font.pixelSize: Fonts.small
        }
    }
}
