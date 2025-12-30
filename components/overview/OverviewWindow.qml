pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"
import "."

Item {
    id: root

    property var toplevel
    property var windowData
    property var monitorData
    property real scale: 0.15
    property real availableWorkspaceWidth: 300
    property real availableWorkspaceHeight: 200
    property real xOffset: 0
    property real yOffset: 0
    property int widgetMonitorId: 0

    property real initX: Math.max(((windowData?.at[0] ?? 0) - (monitorData?.x ?? 0)) * root.scale, 0) + xOffset
    property real initY: Math.max(((windowData?.at[1] ?? 0) - (monitorData?.y ?? 0)) * root.scale, 0) + yOffset
    property real targetWindowWidth: (windowData?.size[0] ?? 100) * scale
    property real targetWindowHeight: (windowData?.size[1] ?? 100) * scale

    property bool hovered: false
    property bool pressed: false

    x: initX
    y: initY
    width: Math.min((windowData?.size[0] ?? 100) * root.scale, availableWorkspaceWidth)
    height: Math.min((windowData?.size[1] ?? 100) * root.scale, availableWorkspaceHeight)
    opacity: (windowData?.monitor ?? -1) == widgetMonitorId ? 1 : 0.5

    clip: true

    Behavior on x {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on y {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on width {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: windowFrame
        anchors.fill: parent
        radius: 6 * root.scale
        color: root.pressed ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3) :
               root.hovered ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.8) :
               Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.6)
        border.color: root.hovered ? Colors.primary : Colors.border
        border.width: 1

        // Live window capture
        ScreencopyView {
            id: windowPreview
            anchors.fill: parent
            anchors.margins: 1
            captureSource: OverviewState.overviewOpen ? root.toplevel : null
            live: true
        }

        // Check if we have a NerdFont icon for this app
        property string appClass: windowData?.class ?? ""
        property bool hasNerdIcon: IconService.hasIcon(appClass)
        // Only try system icon if we don't have a NerdFont mapping
        property string iconPath: (!hasNerdIcon && appClass !== "") ? Quickshell.iconPath(appClass, "") : ""

        // NerdFont icon (preferred - use if we have a mapping)
        Text {
            anchors.centerIn: parent
            property real iconSize: Math.min(root.targetWindowWidth, root.targetWindowHeight) * 0.3
            visible: windowFrame.hasNerdIcon
            text: IconService.getIcon(windowFrame.appClass)
            font.family: "Symbols Nerd Font"
            font.pixelSize: iconSize
            color: Colors.foreground
            opacity: 0.8
        }

        // System icon (fallback for apps without NerdFont mapping)
        Image {
            id: appIcon
            anchors.centerIn: parent
            property real iconSize: Math.min(root.targetWindowWidth, root.targetWindowHeight) * 0.3
            width: iconSize
            height: iconSize
            source: windowFrame.iconPath
            sourceSize: Qt.size(iconSize, iconSize)
            opacity: 0.8
            visible: !windowFrame.hasNerdIcon && status === Image.Ready
        }

        // Default NerdFont icon (when system icon also fails)
        Text {
            anchors.centerIn: parent
            property real iconSize: Math.min(root.targetWindowWidth, root.targetWindowHeight) * 0.3
            visible: !windowFrame.hasNerdIcon && appIcon.status !== Image.Ready
            text: IconService.getIcon("")
            font.family: "Symbols Nerd Font"
            font.pixelSize: iconSize
            color: Colors.foreground
            opacity: 0.8
        }

        // Window title tooltip on hover
        Rectangle {
            id: tooltip
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: tooltipText.height + 8
            color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.9)
            visible: root.hovered
            radius: 4

            Text {
                id: tooltipText
                anchors.centerIn: parent
                width: parent.width - 8
                text: windowData?.title ?? "Unknown"
                color: Colors.foreground
                font.pixelSize: 9
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
