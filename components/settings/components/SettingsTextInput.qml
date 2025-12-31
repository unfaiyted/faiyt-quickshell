import QtQuick
import "../../../theme"

Rectangle {
    id: settingsTextInput

    property alias text: inputField.text
    property string placeholder: ""
    signal textEdited(string value)

    width: 150
    height: 32
    radius: 8
    color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
    border.width: 1
    border.color: inputField.activeFocus
        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.5)
        : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)

    Behavior on border.color { ColorAnimation { duration: 150 } }
    Behavior on color { ColorAnimation { duration: 150 } }

    // Focus highlight
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.width: inputField.activeFocus ? 2 : 0
        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2)
        Behavior on border.width { NumberAnimation { duration: 150 } }
    }

    TextInput {
        id: inputField
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 13
        color: Colors.foreground
        selectByMouse: true
        clip: true

        onTextChanged: settingsTextInput.textEdited(text)

        // Placeholder text
        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: settingsTextInput.placeholder
            font.pixelSize: 13
            color: Colors.foregroundMuted
            visible: inputField.text.length === 0 && !inputField.activeFocus
        }
    }
}
