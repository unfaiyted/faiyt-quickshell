import QtQuick
import Quickshell.Services.SystemTray
import "../theme"

BarGroup {
    id: tray

    implicitWidth: trayRow.width + 16
    implicitHeight: 24

    // Only show if there are tray items
    visible: SystemTray.items.count > 0

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: SystemTray.items

            Image {
                width: 16
                height: 16
                source: modelData.icon
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            modelData.activate()
                        } else if (mouse.button === Qt.MiddleButton) {
                            modelData.secondaryActivate()
                        }
                    }
                }
            }
        }
    }
}
