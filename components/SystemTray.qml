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

            Item {
                width: 16
                height: 16

                Image {
                    id: trayIcon
                    anchors.fill: parent
                    source: modelData.icon
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            if (modelData.onlyMenu && modelData.hasMenu) {
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

                // Tooltip popup
                PopupWindow {
                    id: tooltip
                    anchor.window: QsWindow.window
                    anchor.onAnchoring: {
                        const pos = trayIcon.mapToItem(QsWindow.window.contentItem, 0, trayIcon.height + 4)
                        anchor.rect = Qt.rect(pos.x, pos.y, trayIcon.width, 1)
                    }
                    anchor.edges: Edges.Bottom
                    anchor.gravity: Edges.Bottom

                    visible: mouseArea.containsMouse

                    implicitWidth: tooltipContent.width
                    implicitHeight: tooltipContent.height
                    color: "transparent"

                    Rectangle {
                        id: tooltipContent
                        width: tooltipColumn.width + 16
                        height: tooltipColumn.height + 12
                        color: Colors.surface
                        radius: 6
                        border.width: 1
                        border.color: Colors.overlay

                        Column {
                            id: tooltipColumn
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                text: modelData.title || modelData.id || "Unknown"
                                color: Colors.foreground
                                font.pixelSize: 11
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                visible: modelData.tooltipTitle && modelData.tooltipTitle.length > 0
                                text: modelData.tooltipTitle
                                color: Colors.muted
                                font.pixelSize: 10
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
