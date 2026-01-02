import QtQuick
import Quickshell
import "../../../theme"
import "../../../services"
import "../../sidebar"

PanelWindow {
    id: cornerLeft

    visible: ConfigService.windowBarEnabled && ConfigService.windowBarCorners

    anchors {
        top: true
        left: true
    }

    // Position below the bar
    margins.top:0

    implicitWidth: 24
    implicitHeight: 24
    color: "transparent"
    exclusiveZone: 0

    Canvas {
        id: cornerCanvas
        anchors.fill: parent

        // Repaint when theme changes
        property color bgColor: Colors.background
        onBgColorChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            // Draw the rounded corner arc
            ctx.fillStyle = bgColor
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(24, 0)
            ctx.arc(24, 24, 24, -Math.PI / 2, Math.PI, true)
            ctx.lineTo(0, 0)
            ctx.closePath()
            ctx.fill()
        }

        Component.onCompleted: requestPaint()
    }

    // Click to toggle left sidebar
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: SidebarState.toggleLeft()
    }
}
