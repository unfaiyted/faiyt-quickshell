import QtQuick
import Quickshell
import "../../services"

PanelWindow {
    id: overlay

    // Only consider sidebars open if they're enabled in config
    property bool leftEffectivelyOpen: SidebarState.leftOpen && ConfigService.windowSidebarLeftEnabled
    property bool rightEffectivelyOpen: SidebarState.rightOpen && ConfigService.windowSidebarRightEnabled
    property bool isOpen: leftEffectivelyOpen || rightEffectivelyOpen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Start below the bar
    margins.top: 0

    // Exclude sidebar areas so they remain clickable
    margins.left: leftEffectivelyOpen ? 475 : 0   // left sidebar width
    margins.right: rightEffectivelyOpen ? 396 : 0  // right sidebar width

    // Stay visible while fading out
    visible: isOpen || fadeAnim.running
    exclusiveZone: 0
    color: "transparent"

    // Dark background with fade animation
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.3)
        opacity: overlay.isOpen ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                id: fadeAnim
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }

    // Click anywhere to close sidebars
    MouseArea {
        anchors.fill: parent
        focus: true
        onClicked: SidebarState.closeAll()
        Keys.onEscapePressed: SidebarState.closeAll()
    }
}
