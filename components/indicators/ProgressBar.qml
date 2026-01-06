import QtQuick
import "../../theme"

Item {
    id: progressBar

    property real value: 0  // 0-100
    property int barHeight: 8
    property int barRadius: 4

    implicitWidth: 200
    implicitHeight: barHeight

    // Background
    Rectangle {
        id: background
        anchors.fill: parent
        radius: progressBar.barRadius
        color: Qt.rgba(Colors.muted.r, Colors.muted.g, Colors.muted.b, 0.4)
    }

    // Fill
    Rectangle {
        id: fill
        property real safeValue: isNaN(progressBar.value) ? 0 : progressBar.value
        height: parent.height
        width: Math.max(0, Math.min(parent.width, parent.width * (safeValue / 100)))
        radius: progressBar.barRadius
        color: Colors.primary

        Behavior on width {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }
}
