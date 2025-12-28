import QtQuick
import Quickshell
import "../../../theme"
import ".."

PopupWindow {
    id: menuPopup

    property var menu: null
    property var trayItem: null

    signal menuClosed()

    // Notify when menu is hidden
    onVisibleChanged: {
        if (!visible) {
            menuClosed()
        }
    }

    implicitWidth: menuContent.width
    implicitHeight: menuContent.height
    color: "transparent"

    // Fullscreen click catcher overlay
    PopupWindow {
        id: clickCatcher
        anchor.window: QsWindow.window
        anchor.rect: Qt.rect(0, 0, 1, 1)
        anchor.edges: Edges.Top | Edges.Left

        visible: menuPopup.visible

        // Cover entire screen
        implicitWidth: Screen.width
        implicitHeight: Screen.height
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: menuPopup.visible = false
        }
    }

    QsMenuOpener {
        id: menuOpener
        menu: menuPopup.menu
    }

    Rectangle {
        id: menuContent
        width: menuColumn.width + 16
        height: menuColumn.height + 12
        color: Colors.surface
        radius: 8
        border.width: 1
        border.color: Colors.overlay

        Column {
            id: menuColumn
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: menuOpener.children.values

                Loader {
                    property var entry: modelData
                    sourceComponent: entry.isSeparator ? separatorComponent : menuItemComponent
                }
            }
        }
    }

    Component {
        id: separatorComponent

        Rectangle {
            width: menuColumn.width
            height: 1
            color: Colors.overlay
        }
    }

    Component {
        id: menuItemComponent

        Rectangle {
            id: itemRect
            width: Math.max(itemRow.width + 24, 150)
            height: 28
            radius: 4
            color: itemMouse.containsMouse && entry.enabled ? Colors.overlay : "transparent"

            Row {
                id: itemRow
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // Checkbox/Radio indicator
                Text {
                    visible: entry.buttonType !== 0
                    text: {
                        if (entry.checkState === Qt.Checked) return "󰄵"
                        if (entry.checkState === Qt.PartiallyChecked) return "󰡖"
                        return "󰄱"
                    }
                    color: entry.enabled ? Colors.foreground : Colors.muted
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Icon
                Image {
                    visible: entry.icon && entry.icon.length > 0
                    source: entry.icon || ""
                    width: 14
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Text
                Text {
                    text: entry.text || ""
                    color: entry.enabled ? Colors.foreground : Colors.muted
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Submenu indicator
                Text {
                    visible: entry.hasChildren
                    text: "󰅂"
                    color: Colors.muted
                    font.pixelSize: 10
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: entry.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                onClicked: {
                    if (entry.enabled && !entry.hasChildren) {
                        entry.triggered()
                        menuPopup.visible = false
                    }
                }
            }
        }
    }

}
