import QtQuick
import "../../theme"

Rectangle {
    id: resultItem

    property var result: null
    property bool isSelected: false

    signal clicked()

    height: 52
    radius: 10
    color: isSelected ? Colors.overlay : (itemArea.containsMouse ? Colors.surface : "transparent")
    border.width: isSelected ? 1 : 0
    border.color: Colors.primary

    Behavior on color {
        ColorAnimation { duration: 100 }
    }

    Row {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // Icon container
        Rectangle {
            width: 32
            height: 32
            radius: 8
            color: Colors.surface
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: result ? (result.icon || "󰀻") : "󰀻"
                font.family: "Symbols Nerd Font"
                font.pixelSize: 18
                color: isSelected ? Colors.primary : Colors.foreground
            }
        }

        // Text content
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 56
            spacing: 2

            // Title
            Text {
                width: parent.width
                text: result ? (result.title || "") : ""
                font.pixelSize: 14
                font.bold: isSelected
                color: Colors.foreground
                elide: Text.ElideRight
            }

            // Description
            Text {
                width: parent.width
                text: result ? (result.description || "") : ""
                font.pixelSize: 11
                color: Colors.foregroundAlt
                elide: Text.ElideRight
                visible: text.length > 0
            }
        }
    }

    // Type badge (optional)
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: typeBadgeText.width + 12
        height: 20
        radius: 4
        color: Colors.surface
        visible: result && result.type && result.type !== "app"

        Text {
            id: typeBadgeText
            anchors.centerIn: parent
            text: result ? (result.type || "") : ""
            font.pixelSize: 9
            font.bold: true
            color: Colors.foregroundMuted
            textFormat: Text.PlainText
        }
    }

    MouseArea {
        id: itemArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: resultItem.clicked()
    }
}
