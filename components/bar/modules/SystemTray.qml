import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../../../theme"
import "../../../services"
import ".."

BarGroup {
    id: tray

    implicitWidth: trayRow.width + 16
    implicitHeight: 30 

    // Track currently open menu
    property var activeMenu: null

    function closeAllMenus() {
        if (activeMenu) {
            activeMenu.visible = false
            activeMenu = null
        }
    }

    function openMenu(menu) {
        if (activeMenu && activeMenu !== menu) {
            activeMenu.visible = false
        }
        activeMenu = menu
        menu.visible = true
    }

    // Only show if there are tray items
    visible: SystemTray.items.values.length > 0

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: SystemTray.items.values

            Item {
                id: trayItemContainer
                width: 16
                height: 16

                property var trayData: modelData
                property string trayId: trayData.id || trayData.title || ""
                // Check if we have a NerdFont icon for this tray item
                property bool hasNerdIcon: IconService.hasIcon(trayId)

                // NerdFont icon (preferred - use if we have a mapping)
                Text {
                    anchors.centerIn: parent
                    visible: trayItemContainer.hasNerdIcon
                    text: IconService.getIcon(trayItemContainer.trayId)
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 14
                    color: Colors.foreground
                }

                // System tray icon (fallback for items without NerdFont mapping)
                Image {
                    id: trayIcon
                    anchors.fill: parent
                    source: trayItemContainer.hasNerdIcon ? "" : modelData.icon
                    visible: !trayItemContainer.hasNerdIcon && status === Image.Ready
                }

                // Default NerdFont icon (when system icon also fails)
                Text {
                    anchors.centerIn: parent
                    visible: !trayItemContainer.hasNerdIcon && trayIcon.status !== Image.Ready
                    text: IconService.getIcon("")
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 14
                    color: Colors.foreground
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            if (trayData.onlyMenu && trayData.hasMenu) {
                                if (trayMenu.visible) {
                                    tray.closeAllMenus()
                                } else {
                                    tray.openMenu(trayMenu)
                                }
                            } else {
                                tray.closeAllMenus()
                                trayData.activate()
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            tray.closeAllMenus()
                            trayData.secondaryActivate()
                        } else if (mouse.button === Qt.RightButton) {
                            if (trayData.hasMenu) {
                                if (trayMenu.visible) {
                                    tray.closeAllMenus()
                                } else {
                                    tray.openMenu(trayMenu)
                                }
                            }
                        }
                    }
                }

                // Tooltip popup (only show when menu is not visible)
                PopupWindow {
                    id: tooltip
                    anchor.window: QsWindow.window
                    anchor.onAnchoring: {
                        const pos = trayIcon.mapToItem(QsWindow.window.contentItem, 0, trayIcon.height + 4)
                        anchor.rect = Qt.rect(pos.x, pos.y, trayIcon.width, 1)
                    }
                    anchor.edges: Edges.Bottom
                    anchor.gravity: Edges.Bottom

                    visible: mouseArea.containsMouse && !trayMenu.visible

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
                                text: trayData.title || trayData.id || "Unknown"
                                color: Colors.foreground
                                font.pixelSize: 11
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                visible: trayData.tooltipTitle && trayData.tooltipTitle.length > 0
                                text: trayData.tooltipTitle
                                color: Colors.muted
                                font.pixelSize: 10
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }

                // Custom styled menu
                TrayMenu {
                    id: trayMenu
                    menu: trayData.menu
                    trayItem: trayData

                    anchor.window: QsWindow.window
                    anchor.onAnchoring: {
                        const pos = trayIcon.mapToItem(QsWindow.window.contentItem, 0, trayIcon.height + 4)
                        anchor.rect = Qt.rect(pos.x, pos.y, trayIcon.width, 1)
                    }
                    anchor.edges: Edges.Bottom
                    anchor.gravity: Edges.Bottom

                    onMenuClosed: {
                        if (tray.activeMenu === trayMenu) {
                            tray.activeMenu = null
                        }
                    }
                }
            }
        }
    }
}
