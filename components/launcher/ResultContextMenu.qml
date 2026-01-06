import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../theme"
import "../../services"
import "../common"

PopupWindow {
    id: contextMenu

    property var result: null
    property Item anchorItem: null

    signal menuClosed()

    // Listen for popup scope cleared signal to close menu
    Connections {
        target: HintNavigationService
        function onPopupScopeCleared(scope) {
            if (scope === "launcher-menu") {
                contextMenu.visible = false
            }
        }
    }

    // Notify when menu is hidden and clear popup scope
    onVisibleChanged: {
        if (!visible) {
            if (HintNavigationService.activePopupScope === "launcher-menu") {
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

        visible: contextMenu.visible

        implicitWidth: Screen.width
        implicitHeight: Screen.height
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: contextMenu.visible = false
        }
    }

    // Process for running commands
    Process {
        id: commandProcess
        command: ["bash", "-c", ""]
    }

    // Get menu items based on result type
    function getMenuItems() {
        if (!result) return []

        const type = result.type || ""

        switch (type) {
            case "app":
                return [
                    { text: "Open", icon: "󰏌", action: () => activateResult() },
                    { text: "Open containing folder", icon: "󰉋", action: () => openFolder() },
                    { text: "Copy path", icon: "󰆏", action: () => copyPath() }
                ]
            case "window":
                return [
                    { text: "Focus", icon: "󰖯", action: () => activateResult() },
                    { text: "Close", icon: "󰅖", action: () => closeWindow() },
                    { separator: true },
                    { text: "Move to workspace...", icon: "󰍹", submenu: true }
                ]
            case "cmd":
                return [
                    { text: "Run", icon: "󰐊", action: () => activateResult() },
                    { text: "Copy command", icon: "󰆏", action: () => copyCommand() }
                ]
            case "system":
                return [
                    { text: "Execute", icon: "󰐊", action: () => activateResult() }
                ]
            case "quickaction":
                return [
                    { text: "Execute", icon: "󰐊", action: () => activateResult() }
                ]
            default:
                return [
                    { text: "Open", icon: "󰏌", action: () => activateResult() }
                ]
        }
    }

    function activateResult() {
        contextMenu.visible = false
        LauncherState.activateResult(result)
    }

    function openFolder() {
        contextMenu.visible = false
        if (result.data?.desktop) {
            const path = result.data.desktop.replace(/\/[^\/]+$/, "")
            commandProcess.command = [ConfigService.fileManagerCommand, path]
            commandProcess.running = true
        }
        LauncherState.hide()
    }

    function copyPath() {
        contextMenu.visible = false
        if (result.data?.desktop) {
            commandProcess.command = ["wl-copy", result.data.desktop]
            commandProcess.running = true
        }
        LauncherState.hide()
    }

    function closeWindow() {
        contextMenu.visible = false
        if (result.data?.winData?.address) {
            Hyprland.dispatch("closewindow address:" + result.data.winData.address)
        }
        LauncherState.hide()
    }

    function copyCommand() {
        contextMenu.visible = false
        if (result.title) {
            commandProcess.command = ["wl-copy", result.title]
            commandProcess.running = true
        }
        LauncherState.hide()
    }

    property var menuItems: getMenuItems()

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
                model: contextMenu.menuItems

                Loader {
                    property var entry: modelData
                    sourceComponent: (entry?.separator ?? false) ? separatorComponent : menuItemComponent
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
            width: Math.max(itemRow.width + 24, 180)
            height: 32
            radius: 4
            color: itemMouse.containsMouse ? Colors.overlay : "transparent"

            Row {
                id: itemRow
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                // Icon
                Text {
                    text: entry?.icon ?? ""
                    font.family: Fonts.icon
                    font.pixelSize: 14
                    color: Colors.foreground
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Text
                Text {
                    text: entry?.text ?? ""
                    color: Colors.foreground
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Submenu indicator
                Text {
                    visible: entry?.submenu ?? false
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
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    if (entry?.action && !(entry?.submenu ?? false)) {
                        entry.action()
                    }
                }
            }

            HintTarget {
                targetElement: itemRect
                scope: "launcher-menu"
                enabled: contextMenu.visible && !(entry?.submenu ?? false)
                action: () => {
                    if (entry?.action) {
                        entry.action()
                    }
                    HintNavigationService.clearPopupScope()
                }
            }
        }
    }

    // Hint overlay for context menu
    PopupWindow {
        id: hintPopup
        anchor.window: contextMenu
        anchor.rect: Qt.rect(0, 0, menuContent.width, menuContent.height)
        anchor.edges: Edges.Top | Edges.Left

        visible: contextMenu.visible && HintNavigationService.active
        color: "transparent"

        implicitWidth: menuContent.width
        implicitHeight: menuContent.height

        HintOverlay {
            anchors.fill: parent
            scope: "launcher-menu"
            mapRoot: menuContent
        }
    }

    // Keyboard handling for hints in menu
    FocusScope {
        id: menuKeyHandler
        anchors.fill: parent
        focus: contextMenu.visible && HintNavigationService.active

        Keys.onPressed: function(event) {
            // Escape closes the menu
            if (event.key === Qt.Key_Escape) {
                contextMenu.visible = false
                HintNavigationService.clearPopupScope()
                event.accepted = true
                return
            }

            if (HintNavigationService.active) {
                let key = ""
                if (event.key === Qt.Key_Backspace) key = "Backspace"
                else if (event.text && event.text.length === 1) key = event.text

                if (key && HintNavigationService.handleKey(key, "launcher-menu", event.modifiers)) {
                    event.accepted = true
                }
            }
        }
    }
}
