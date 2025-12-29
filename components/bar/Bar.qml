import QtQuick
import Quickshell
import "../../theme"
import "modules"

PanelWindow {
    id: bar

    // Position at top, span full width
    anchors {
        top: true
        left: true
        right: true
    }

    // Reserve space so windows don't overlap
    exclusiveZone: implicitHeight

    // Bar height
    implicitHeight: 40 

    // Background color
    color: Colors.background

    // Main layout container
    Item {
        anchors.fill: parent

        // Left section - Window Title
        WindowTitle {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
        }

        // Center-Middle: Workspaces (always perfectly centered)
        Workspaces {
            id: workspaces
            anchors.centerIn: parent
        }

        // Center-Left: System Resources (anchored to left of Workspaces)
        Row {
            anchors.right: workspaces.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            SystemResources {}
        }

        // Center-Right: Utilities + Music (anchored to right of Workspaces)
        Row {
            anchors.left: workspaces.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Utilities {}
            Music {}
        }

        // Right section
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            SystemTray {}
            Network {}
            Battery {}
            Clock {}
            Weather {}
        }

        // Bottom border line
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 0
            color: Colors.border
        }
    }
}
