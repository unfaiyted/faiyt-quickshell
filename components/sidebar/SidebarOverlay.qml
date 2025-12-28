import QtQuick
import Quickshell

PanelWindow {
    id: overlay

    property bool isOpen: SidebarState.leftOpen || SidebarState.rightOpen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Start below the bar
    margins.top:8 

    // Exclude sidebar areas so they remain clickable
    margins.left: SidebarState.leftOpen ? 396 : 0   // sidebar width
    margins.right: SidebarState.rightOpen ? 396 : 0  // sidebar width

    // Only visible when a sidebar is open
    visible: isOpen
    exclusiveZone: 0

    // Semi-transparent dark background
    color: Qt.rgba(0, 0, 0, isOpen ? 0.3 : 0)

    Behavior on color {
        ColorAnimation { duration: 200 }
    }

    // Click anywhere to close sidebars
    MouseArea {
        anchors.fill: parent
        focus: true
        onClicked: SidebarState.closeAll()
        Keys.onEscapePressed: SidebarState.closeAll()
    }
}
