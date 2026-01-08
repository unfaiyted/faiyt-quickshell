import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"
import "../../theme"

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

    // Layer shell config - Top layer (above windows, below Overlay where sidebars are)
    WlrLayershell.namespace: "quickshell:sidebar-overlay"
    WlrLayershell.layer: WlrLayer.Top

    // Dark background with rounded corners
    Canvas {
        id: bgCanvas
        anchors.fill: parent
        opacity: overlay.isOpen ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                id: fadeAnim
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var w = width
            var h = height
            var r = 24  // Corner radius to match bar/sidebar

            ctx.fillStyle = Qt.rgba(0, 0, 0, 0.3)
            ctx.beginPath()

            // Start from top-left
            if (overlay.rightEffectivelyOpen && !overlay.leftEffectivelyOpen) {
                // Round top-left corner (right sidebar open, left closed)
                ctx.moveTo(r, 0)
                ctx.lineTo(w, 0)
                ctx.lineTo(w, h)
                ctx.lineTo(0, h)
                ctx.lineTo(0, r)
                ctx.arc(r, r, r, Math.PI, Math.PI * 1.5, false)
            } else if (overlay.leftEffectivelyOpen && !overlay.rightEffectivelyOpen) {
                // Round top-right corner (left sidebar open, right closed)
                ctx.moveTo(0, 0)
                ctx.lineTo(w - r, 0)
                ctx.arc(w - r, r, r, -Math.PI / 2, 0, false)
                ctx.lineTo(w, h)
                ctx.lineTo(0, h)
            } else if (overlay.leftEffectivelyOpen && overlay.rightEffectivelyOpen) {
                // Both sidebars open - no rounded corners on overlay
                ctx.rect(0, 0, w, h)
            } else {
                // Both corners rounded (neither sidebar open - shouldn't happen but handle it)
                ctx.moveTo(r, 0)
                ctx.lineTo(w - r, 0)
                ctx.arc(w - r, r, r, -Math.PI / 2, 0, false)
                ctx.lineTo(w, h)
                ctx.lineTo(0, h)
                ctx.lineTo(0, r)
                ctx.arc(r, r, r, Math.PI, Math.PI * 1.5, false)
            }

            ctx.closePath()
            ctx.fill()
        }

        // Repaint when sidebar state changes
        Connections {
            target: SidebarState
            function onLeftOpenChanged() { bgCanvas.requestPaint() }
            function onRightOpenChanged() { bgCanvas.requestPaint() }
        }

        Component.onCompleted: requestPaint()
    }

    // Also repaint on size change
    onWidthChanged: bgCanvas.requestPaint()
    onHeightChanged: bgCanvas.requestPaint()
}
