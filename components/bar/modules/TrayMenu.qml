import QtQuick
import Quickshell
import "../../../theme"
import "../../../services"
import ".."
import "../../common"

PopupWindow {
    id: menuPopup

    property var menu: null
    property var trayItem: null
    property var focusAppFunction: null
    property string appId: ""

    signal menuClosed()

    // Listen for popup scope cleared signal to close menu
    Connections {
        target: HintNavigationService
        function onPopupScopeCleared(scope) {
            if (scope === "tray-menu") {
                menuPopup.visible = false
            }
        }
    }

    // Notify when menu is hidden and clear popup scope
    onVisibleChanged: {
        if (!visible) {
            if (HintNavigationService.activePopupScope === "tray-menu") {
                HintNavigationService.clearPopupScope()
            }
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
                    sourceComponent: (entry?.isSeparator ?? false) ? separatorComponent : menuItemComponent
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
            color: itemMouse.containsMouse && (entry?.enabled ?? false) ? Colors.overlay : "transparent"

            Row {
                id: itemRow
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // Checkbox/Radio indicator
                Text {
                    visible: (entry?.buttonType ?? 0) !== 0
                    text: {
                        if ((entry?.checkState ?? Qt.Unchecked) === Qt.Checked) return "󰄵"
                        if ((entry?.checkState ?? Qt.Unchecked) === Qt.PartiallyChecked) return "󰡖"
                        return "󰄱"
                    }
                    color: (entry?.enabled ?? false) ? Colors.foreground : Colors.muted
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Icon - NerdFont preferred, system icon fallback
                Text {
                    id: nerdIcon
                    visible: !!(entry?.icon) && entry.icon.length > 0 && IconService.hasIcon(entry.icon)
                    text: IconService.getIcon(entry?.icon ?? "")
                    font.family: Fonts.icon
                    font.pixelSize: 14
                    color: (entry?.enabled ?? false) ? Colors.foreground : Colors.muted
                    anchors.verticalCenter: parent.verticalCenter
                }

                Image {
                    id: menuIcon
                    visible: !!(entry?.icon) && entry.icon.length > 0 && !IconService.hasIcon(entry.icon) && status === Image.Ready
                    source: (entry?.icon && !IconService.hasIcon(entry.icon)) ? entry.icon : ""
                    width: 14
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Default icon when system icon fails
                Text {
                    visible: !!(entry?.icon) && entry.icon.length > 0 && !IconService.hasIcon(entry.icon) && menuIcon.status !== Image.Ready
                    text: IconService.getIcon("")
                    font.family: Fonts.icon
                    font.pixelSize: 14
                    color: (entry?.enabled ?? false) ? Colors.foreground : Colors.muted
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Text
                Text {
                    text: entry?.text ?? ""
                    color: (entry?.enabled ?? false) ? Colors.foreground : Colors.muted
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Submenu indicator
                Text {
                    visible: entry?.hasChildren ?? false
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
                cursorShape: (entry?.enabled ?? false) ? Qt.PointingHandCursor : Qt.ArrowCursor

                onClicked: {
                    if ((entry?.enabled ?? false) && !(entry?.hasChildren ?? false)) {
                        // Focus app window before executing menu action
                        if (menuPopup.focusAppFunction && menuPopup.appId) {
                            menuPopup.focusAppFunction(menuPopup.appId)
                        }
                        entry?.triggered()
                        menuPopup.visible = false
                    }
                }
            }

            HintTarget {
                targetElement: itemRect
                scope: "tray-menu"
                enabled: menuPopup.visible && (entry?.enabled ?? false) && !(entry?.hasChildren ?? false)
                action: () => {
                    if (menuPopup.focusAppFunction && menuPopup.appId) {
                        menuPopup.focusAppFunction(menuPopup.appId)
                    }
                    entry?.triggered()
                    menuPopup.visible = false
                    HintNavigationService.clearPopupScope()
                }
            }
        }
    }

    // Hint overlay for tray menu
    PopupWindow {
        id: hintPopup
        anchor.window: menuPopup
        anchor.rect: Qt.rect(0, 0, menuContent.width, menuContent.height)
        anchor.edges: Edges.Top | Edges.Left

        visible: menuPopup.visible && HintNavigationService.active
        color: "transparent"

        implicitWidth: menuContent.width
        implicitHeight: menuContent.height

        HintOverlay {
            anchors.fill: parent
            scope: "tray-menu"
            mapRoot: menuContent
        }
    }

    // Keyboard handling for hints in menu
    FocusScope {
        id: menuKeyHandler
        anchors.fill: parent
        focus: menuPopup.visible && HintNavigationService.active

        Keys.onPressed: function(event) {
            // Escape closes the menu
            if (event.key === Qt.Key_Escape) {
                menuPopup.visible = false
                HintNavigationService.clearPopupScope()
                event.accepted = true
                return
            }

            if (HintNavigationService.active) {
                let key = ""
                if (event.key === Qt.Key_Backspace) key = "Backspace"
                else if (event.text && event.text.length === 1) key = event.text

                if (key && HintNavigationService.handleKey(key, "tray-menu", event.modifiers)) {
                    event.accepted = true
                }
            }
        }
    }
}
