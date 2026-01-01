import QtQuick
import Quickshell
import "../../../theme"
import "../../../services"
import "../../sidebar"

PanelWindow {
    id: cornerRight

    visible: ConfigService.windowBarEnabled && ConfigService.windowBarCorners

    anchors {
        top: true
        right: true
    }

    // Position below the bar
    margins.top:0

    implicitWidth: 24
    implicitHeight: 24
    color: "transparent"
    exclusiveZone: 0

    Canvas {
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            // Draw the rounded corner arc (mirrored)
            ctx.fillStyle = Colors.background
            ctx.beginPath()
            ctx.moveTo(24, 0)
            ctx.lineTo(0, 0)
            ctx.arc(0, 24, 24, -Math.PI / 2, 0, false)
            ctx.lineTo(24, 0)
            ctx.closePath()
            ctx.fill()
        }

        Component.onCompleted: requestPaint()
    }

    // Click to toggle right sidebar
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: SidebarState.toggleRight()
    }
}
