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
    implicitHeight: 40

    // Background color
    color: Colors.background

    // Bar content area
    Rectangle {
        anchors.fill: parent
        color: "transparent"

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
