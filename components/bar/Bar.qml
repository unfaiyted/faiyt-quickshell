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
    implicitHeight: 32

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

        // Center section
        Row {
            anchors.centerIn: parent
            spacing: 8

            // Center-Left: System Resources + Music
            SystemResources {}
            Music {}

            // Center-Middle: Workspaces
            Workspaces {}

            // Center-Right: Utilities
            Utilities {}
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
