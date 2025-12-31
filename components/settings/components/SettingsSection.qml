import QtQuick
import QtQuick.Layouts
import "../../../theme"

Rectangle {
    id: section

    property string title: ""
    default property alias content: contentColumn.children

    width: parent.width
    implicitHeight: sectionColumn.height + 32
    radius: 12
    color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.2)
    border.width: 1
    border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.08)

    // Hover effect
    property bool hovered: false

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: section.hovered ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.05) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: section.hovered = true
        onExited: section.hovered = false
        // Pass through clicks to children
        propagateComposedEvents: true
        onClicked: mouse.accepted = false
        onPressed: mouse.accepted = false
        onReleased: mouse.accepted = false
    }

    Column {
        id: sectionColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        spacing: 8

        // Section title
        Text {
            text: section.title
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 0.5
            color: Colors.primary
        }

        // Content container
        Column {
            id: contentColumn
            width: parent.width
            spacing: 4
        }
    }
}
