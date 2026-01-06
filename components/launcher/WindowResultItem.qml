pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Wayland
import "../../theme"
import "../../services"
import "../common"

Rectangle {
    id: windowResultItem

    property var result: null
    property bool isSelected: false

    // Delayed capture flag - wait for component to stabilize
    property bool captureReady: false

    signal clicked()
    signal contextMenu(var result)

    // Delay capture to allow ScreencopyView to initialize
    Timer {
        id: captureDelayTimer
        interval: 100
        running: true
        repeat: false
        onTriggered: windowResultItem.captureReady = true
    }

    height: 70
    radius: 10
    color: isSelected ? Colors.overlay : (itemArea.containsMouse ? Colors.surface : "transparent")
    border.width: isSelected ? 1 : 0
    border.color: Colors.primary

    Behavior on color {
        ColorAnimation { duration: 100 }
    }

    Row {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // Live preview container
        Rectangle {
            width: 90
            height: 50
            radius: 6
            color: Colors.surface
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            // Live window preview
            ScreencopyView {
                id: windowPreview
                anchors.fill: parent
                anchors.margins: 2
                captureSource: windowResultItem.captureReady ? (result?.data?.toplevel ?? null) : null
                live: true
            }

            // Fallback icon when no preview
            Text {
                anchors.centerIn: parent
                visible: !windowPreview.captureSource
                text: result ? (result.icon || "󰖯") : "󰖯"
                font.family: Fonts.icon
                font.pixelSize: 24
                color: Colors.foregroundMuted
            }

            // Border overlay
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: 6
                border.width: 1
                border.color: isSelected ? Colors.primary : Colors.border
            }
        }

        // Text content
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 170
            spacing: 4

            // Title
            Text {
                width: parent.width
                text: result ? (result.title || "Untitled") : ""
                font.pixelSize: 13
                font.bold: isSelected
                color: Colors.foreground
                elide: Text.ElideRight
            }

            // Description (app class + workspace)
            Text {
                width: parent.width
                text: result ? (result.description || "") : ""
                font.pixelSize: 11
                color: Colors.foregroundAlt
                elide: Text.ElideRight
                visible: text.length > 0
            }
        }

        // Workspace badge
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: workspaceBadge.width + 16
            height: 24
            radius: 6
            color: isSelected ? Colors.primary : Colors.surface

            Text {
                id: workspaceBadge
                anchors.centerIn: parent
                text: {
                    let ws = result?.data?.winData?.workspace?.id
                    return ws !== undefined ? ws.toString() : "?"
                }
                font.pixelSize: 12
                font.bold: true
                color: isSelected ? Colors.background : Colors.foreground
            }
        }
    }

    // Type badge
    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 10
        anchors.bottomMargin: 8
        width: typeBadgeText.width + 10
        height: 18
        radius: 4
        color: Colors.surface

        Text {
            id: typeBadgeText
            anchors.centerIn: parent
            text: "window"
            font.pixelSize: 9
            font.bold: true
            color: Colors.foregroundMuted
        }
    }

    MouseArea {
        id: itemArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                windowResultItem.contextMenu(result)
            } else {
                windowResultItem.clicked()
            }
        }
    }

    HintTarget {
        targetElement: windowResultItem
        scope: "launcher"
        enabled: LauncherState.visible
        action: () => {
            HintNavigationService.deactivate()
            windowResultItem.clicked()
        }
        secondaryAction: () => {
            windowResultItem.contextMenu(result)
        }
    }
}
