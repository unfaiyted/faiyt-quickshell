import QtQuick
import "../../../theme"

Item {
    id: tabBar

    property var tabs: []
    property int currentIndex: 0

    implicitHeight: 36
    implicitWidth: tabRow.width

    Row {
        id: tabRow
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: tabBar.tabs

            Rectangle {
                width: 40
                height: 32
                radius: 8
                color: tabBar.currentIndex === index
                    ? Colors.primary
                    : Colors.surface

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Text {
                    id: tabText
                    anchors.centerIn: parent
                    text: modelData
                    color: tabBar.currentIndex === index
                        ? Colors.background
                        : Colors.foreground
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tabBar.currentIndex = index
                }
            }
        }
    }
}
