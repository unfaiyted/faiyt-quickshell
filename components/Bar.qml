import QtQuick
import Quickshell
import "../theme"

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

    // Bar height matching AGS bar
    implicitHeight: 32

    // Background color
    color: Colors.background

    // Main layout container
    Item {
        anchors.fill: parent

        // Left section (empty for now)
        Item {
            id: leftSection
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width / 3
        }

        // Center section - Workspaces
        Workspaces {
            anchors.centerIn: parent
        }

        // Right section - Clock
        Clock {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
        }

        // Bottom border line
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Colors.border
        }
    }
}
