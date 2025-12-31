import QtQuick
import "../../theme"
import "."

Rectangle {
    id: monitorItem

    property var monitor: null
    property real canvasWidth: 400
    property real canvasHeight: 300

    // Calculate position
    property var position: monitor ? MonitorsState.getMonitorPosition(monitor.name) : { x: 0, y: 0 }
    property var canvasPos: MonitorsState.toCanvasCoords(position.x, position.y)

    // State
    property bool isSelected: MonitorsState.selectedMonitor === (monitor ? monitor.name : "")
    property bool isPrimary: monitor ? monitor.focused : false
    property bool isHovered: mouseArea.containsMouse
    property bool isDragging: false

    // Position and size
    x: canvasPos.x
    y: canvasPos.y
    width: monitor ? monitor.width * MonitorsState.canvasScale : 100
    height: monitor ? monitor.height * MonitorsState.canvasScale : 60

    radius: 8
    color: isSelected
        ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.95)
        : (isHovered
            ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.9)
            : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.8))

    border.width: isSelected ? 3 : 2
    border.color: isSelected
        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.8)
        : (isPrimary
            ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.6)
            : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.3))

    Behavior on x {
        NumberAnimation { duration: isDragging ? 0 : 150; easing.type: Easing.OutCubic }
    }
    Behavior on y {
        NumberAnimation { duration: isDragging ? 0 : 150; easing.type: Easing.OutCubic }
    }
    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    Behavior on border.color {
        ColorAnimation { duration: 150 }
    }

    // Selection glow
    Rectangle {
        visible: isSelected
        anchors.fill: parent
        anchors.margins: -4
        z: -1
        radius: parent.radius + 4
        color: "transparent"
        border.width: 3
        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2)
    }

    // Primary badge
    Rectangle {
        visible: isPrimary
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 4
        width: primaryLabel.width + 12
        height: 18
        radius: 4
        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.8)

        Text {
            id: primaryLabel
            anchors.centerIn: parent
            text: "PRIMARY"
            font.pixelSize: 9
            font.weight: Font.DemiBold
            font.letterSpacing: 0.5
            color: Colors.background
        }
    }

    // Monitor info
    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 4

        Text {
            text: monitor ? monitor.name : ""
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Colors.foreground
            elide: Text.ElideRight
            width: parent.width
        }

        Text {
            text: monitor ? `${monitor.width}x${monitor.height}@${monitor.refreshRate.toFixed(0)}Hz` : ""
            font.pixelSize: 10
            font.family: "monospace"
            color: Colors.foregroundAlt
            elide: Text.ElideRight
            width: parent.width
        }

        Text {
            text: monitor ? `${position.x}, ${position.y}` : ""
            font.pixelSize: 9
            font.family: "monospace"
            color: Colors.foregroundMuted
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.SizeAllCursor

        property real startX: 0
        property real startY: 0
        property real monitorStartX: 0
        property real monitorStartY: 0

        onClicked: {
            MonitorsState.selectedMonitor = monitor.name
        }

        onPressed: (mouse) => {
            MonitorsState.selectedMonitor = monitor.name
            isDragging = true
            startX = mouse.x
            startY = mouse.y
            monitorStartX = monitorItem.x
            monitorStartY = monitorItem.y
        }

        onPositionChanged: (mouse) => {
            if (pressed && isDragging) {
                const deltaX = mouse.x - startX
                const deltaY = mouse.y - startY

                const newCanvasX = monitorStartX + deltaX
                const newCanvasY = monitorStartY + deltaY

                const realPos = MonitorsState.toRealCoords(newCanvasX, newCanvasY)
                const snappedPos = MonitorsState.getSnapPosition(monitor.name, realPos.x, realPos.y)

                MonitorsState.setTempPosition(monitor.name, snappedPos.x, snappedPos.y)
            }
        }

        onReleased: {
            isDragging = false
        }
    }
}
