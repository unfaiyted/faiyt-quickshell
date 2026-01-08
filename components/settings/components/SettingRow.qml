import QtQuick
import QtQuick.Layouts
import "../../../theme"

Rectangle {
    id: row

    property string label: ""
    property string description: ""
    property bool indent: false
    default property alias control: controlContainer.children

    width: parent.width - (parent.leftPadding || 0) - (parent.rightPadding || 0)
    implicitHeight: Math.max(labelColumn.height, controlContainer.height) + 16
    radius: 8

    // Hover effect
    property bool hovered: false
    color: row.hovered ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3) : "transparent"

    Behavior on color { ColorAnimation { duration: 150 } }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: row.hovered = true
        onExited: row.hovered = false
        propagateComposedEvents: true
        onClicked: mouse.accepted = false
        onPressed: mouse.accepted = false
        onReleased: mouse.accepted = false
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: row.indent ? 28 : 8
        anchors.rightMargin: 8
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 12

        // Indent indicator
        Rectangle {
            visible: row.indent
            Layout.preferredWidth: 2
            Layout.fillHeight: true
            color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)
            radius: 1
        }

        // Label and description
        Column {
            id: labelColumn
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: row.label
                font.family: Fonts.ui
                font.pixelSize: Fonts.medium
                font.weight: Font.Medium
                color: Colors.foreground
            }

            Text {
                visible: row.description.length > 0
                text: row.description
                font.family: Fonts.ui
                font.pixelSize: Fonts.small
                color: Colors.foregroundAlt
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }

        // Control slot
        Item {
            id: controlContainer
            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: childrenRect.height
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
