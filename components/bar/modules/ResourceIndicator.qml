import QtQuick
import Quickshell
import "../../../theme"
import ".."

Item {
    id: indicator

    property string label: ""
    property string icon: ""  // Nerd font icon
    property int value: 0
    property color indicatorColor: Colors.foreground
    property string tooltipText: ""  // Optional extra info for tooltip

    width: 24
    height: 24

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }

    // Tooltip popup
    PopupWindow {
        id: tooltip
        anchor.window: QsWindow.window
        anchor.onAnchoring: {
            const pos = indicator.mapToItem(QsWindow.window.contentItem, 0, indicator.height)
            anchor.rect = Qt.rect(pos.x, pos.y, indicator.width, 7)
        }
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        visible: mouseArea.containsMouse

        implicitWidth: tooltipContent.width
        implicitHeight: tooltipContent.height
        color: "transparent"

        Rectangle {
            id: tooltipContent
            width: Math.max(tooltipColumn.width + 25, 80)
            height: tooltipColumn.height + 12
            color: Colors.surface
            radius: 6
            border.width: 1
            border.color: Colors.overlay

            Column {
                id: tooltipColumn
                anchors.centerIn: parent
                spacing: 2

                Text {
                    text: indicator.label
                    color: indicator.indicatorColor
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: indicator.value + "%"
                    color: Colors.foreground
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    visible: indicator.tooltipText !== ""
                    text: indicator.tooltipText
                    color: Colors.muted
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.tiny
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    lineHeight: 1.2
                }
            }
        }
    }

    // Background ring
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: "transparent"
        border.width: 2
        border.color: Qt.rgba(
            indicator.indicatorColor.r,
            indicator.indicatorColor.g,
            indicator.indicatorColor.b,
            0.25
        )
    }

    // Progress arc (filled ring segment)
    Canvas {
        id: progressCanvas
        anchors.fill: parent
        antialiasing: true

        property real progress: indicator.value / 100

        onProgressChanged: requestPaint()

        Connections {
            target: indicator
            function onIndicatorColorChanged() { progressCanvas.requestPaint() }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var centerX = width / 2
            var centerY = height / 2
            var outerRadius = width / 2
            var innerRadius = outerRadius - 3  // Ring thickness

            // Start from top (-90 degrees = -PI/2), go clockwise
            var startAngle = -Math.PI / 2
            var endAngle = startAngle + (2 * Math.PI * progress)

            // Draw filled arc (donut segment)
            ctx.beginPath()
            ctx.fillStyle = indicator.indicatorColor

            // Outer arc (clockwise)
            ctx.arc(centerX, centerY, outerRadius, startAngle, endAngle, false)
            // Inner arc (counter-clockwise to close the shape)
            ctx.arc(centerX, centerY, innerRadius, endAngle, startAngle, true)
            ctx.closePath()
            ctx.fill()
        }

        Component.onCompleted: requestPaint()
    }

    // Icon text (nerd font)
    Text {
        anchors.centerIn: parent
        text: indicator.icon
        font.pixelSize: Fonts.iconSmall
        font.family: Fonts.icon
        color: indicator.indicatorColor
    }
}
