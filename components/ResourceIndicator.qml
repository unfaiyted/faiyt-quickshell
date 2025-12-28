import QtQuick
import "../theme"

Item {
    id: indicator

    property string label: ""
    property int value: 0
    property color indicatorColor: Colors.foreground

    width: 24
    height: 24

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

    // Value text
    Text {
        anchors.centerIn: parent
        text: indicator.value
        font.pixelSize: 8
        font.bold: true
        color: indicator.indicatorColor
    }
}
