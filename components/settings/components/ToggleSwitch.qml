import QtQuick
import "../../../theme"

Rectangle {
    id: toggle

    property bool checked: false
    signal toggled(bool value)

    width: 44
    height: 24
    radius: 12
    color: toggle.checked
        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.8)
        : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.5)
    border.width: 1
    border.color: toggle.checked
        ? Colors.primary
        : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.2)

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    // Slider knob
    Rectangle {
        id: knob
        width: 20
        height: 20
        radius: 10
        x: toggle.checked ? parent.width - width - 2 : 2
        anchors.verticalCenter: parent.verticalCenter
        color: toggle.checked ? Colors.foreground : Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.5)

        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            toggle.checked = !toggle.checked
            toggle.toggled(toggle.checked)
        }
    }
}
