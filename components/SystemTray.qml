import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../theme"

BarGroup {
    id: tray

    implicitWidth: trayRow.width + 16
    implicitHeight: 24

    // Only show if there are tray items
    visible: SystemTray.items.values.length > 0

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: SystemTray.items.values

            Image {
                id: trayIcon
                width: 16
                height: 16
                source: modelData.icon
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            if (modelData.onlyMenu && modelData.hasMenu) {
                                // Some tray items only have a menu
                                let pos = QsWindow.window.contentItem.mapFromItem(trayIcon, mouse.x, mouse.y)
                                modelData.display(QsWindow.window, pos.x, pos.y)
                            } else {
                                modelData.activate()
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            modelData.secondaryActivate()
                        } else if (mouse.button === Qt.RightButton) {
                            if (modelData.hasMenu) {
                                let pos = QsWindow.window.contentItem.mapFromItem(trayIcon, mouse.x, mouse.y)
                                modelData.display(QsWindow.window, pos.x, pos.y)
                            }
                        }
                    }
                }
            }
        }
    }
}
