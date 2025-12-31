import QtQuick
import "../../theme"
import "."

Rectangle {
    id: canvas

    color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.2)
    radius: 12

    Rectangle {
        anchors.fill: parent
        anchors.margins: 20
        color: "transparent"

        // Grid pattern (simulated with lines)
        Canvas {
            id: gridCanvas
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                ctx.strokeStyle = Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.08)
                ctx.lineWidth = 1

                const gridSize = 20

                // Vertical lines
                for (let x = 0; x <= width; x += gridSize) {
                    ctx.beginPath()
                    ctx.moveTo(x, 0)
                    ctx.lineTo(x, height)
                    ctx.stroke()
                }

                // Horizontal lines
                for (let y = 0; y <= height; y += gridSize) {
                    ctx.beginPath()
                    ctx.moveTo(0, y)
                    ctx.lineTo(width, y)
                    ctx.stroke()
                }
            }

            Component.onCompleted: requestPaint()
        }

        // Dashed boundary
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: 8
            border.width: 2
            border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

            // Note: QML doesn't have native dashed borders, using solid as fallback
        }

        // Monitor items container
        Item {
            id: monitorsContainer
            anchors.fill: parent

            Repeater {
                model: MonitorsState.monitors

                MonitorItem {
                    required property var modelData
                    required property int index

                    monitor: modelData
                    canvasWidth: monitorsContainer.width
                    canvasHeight: monitorsContainer.height
                }
            }
        }

        // Drag handling for the entire canvas
        MouseArea {
            id: canvasDragArea
            anchors.fill: parent
            z: -1  // Behind monitor items

            property string draggingMonitor: ""
            property real dragStartX: 0
            property real dragStartY: 0
            property real monitorStartX: 0
            property real monitorStartY: 0

            onPressed: (mouse) => {
                // Find which monitor was clicked
                for (let i = 0; i < MonitorsState.monitors.length; i++) {
                    const mon = MonitorsState.monitors[i]
                    const pos = MonitorsState.getMonitorPosition(mon.name)
                    const canvasPos = MonitorsState.toCanvasCoords(pos.x, pos.y)

                    const monWidth = mon.width * MonitorsState.canvasScale
                    const monHeight = mon.height * MonitorsState.canvasScale

                    if (mouse.x >= canvasPos.x && mouse.x <= canvasPos.x + monWidth &&
                        mouse.y >= canvasPos.y && mouse.y <= canvasPos.y + monHeight) {
                        draggingMonitor = mon.name
                        MonitorsState.selectedMonitor = mon.name
                        dragStartX = mouse.x
                        dragStartY = mouse.y
                        monitorStartX = canvasPos.x
                        monitorStartY = canvasPos.y
                        break
                    }
                }
            }

            onPositionChanged: (mouse) => {
                if (draggingMonitor !== "") {
                    const deltaX = mouse.x - dragStartX
                    const deltaY = mouse.y - dragStartY

                    const newCanvasX = monitorStartX + deltaX
                    const newCanvasY = monitorStartY + deltaY

                    const realPos = MonitorsState.toRealCoords(newCanvasX, newCanvasY)
                    const snappedPos = MonitorsState.getSnapPosition(draggingMonitor, realPos.x, realPos.y)

                    MonitorsState.setTempPosition(draggingMonitor, snappedPos.x, snappedPos.y)
                }
            }

            onReleased: {
                draggingMonitor = ""
            }
        }
    }
}
