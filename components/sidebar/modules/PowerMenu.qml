import QtQuick
import Quickshell
import Quickshell.Io
import "../../../theme"
import "../../../services"
import "../../common"
import ".."

PopupWindow {
    id: powerMenu

    property Item anchorItem: null

    signal menuClosed()

    // Bind visibility to SidebarState
    visible: SidebarState.powerMenuOpen

    // Listen for popup scope cleared signal to close menu
    Connections {
        target: HintNavigationService
        function onPopupScopeCleared(scope) {
            if (scope === "power-menu") {
                SidebarState.powerMenuOpen = false
            }
        }
    }

    // Manage popup scope when visibility changes
    onVisibleChanged: {
        if (!visible) {
            if (HintNavigationService.activePopupScope === "power-menu") {
                HintNavigationService.clearPopupScope()
            }
            menuClosed()
        } else {
            HintNavigationService.setPopupScope("power-menu")
        }
    }

    implicitWidth: menuContent.width
    implicitHeight: menuContent.height
    color: "transparent"

    // Process for running power commands
    Process {
        id: powerProcess
        command: ["bash", "-c", ""]
    }

    property var menuItems: [
        { text: "Lock", icon: "󰌾", command: "loginctl lock-session" },
        { text: "Logout", icon: "󰍃", command: "hyprctl dispatch exit" },
        { separator: true },
        { text: "Suspend", icon: "󰤄", command: "systemctl suspend" },
        { text: "Hibernate", icon: "󰒲", command: "systemctl hibernate" },
        { separator: true },
        { text: "Restart", icon: "󰜉", command: "systemctl reboot" },
        { text: "Shutdown", icon: "󰐥", command: "systemctl poweroff", dangerous: true }
    ]

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
                model: powerMenu.menuItems

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
            width: 160
            height: 1
            color: Colors.overlay
        }
    }

    Component {
        id: menuItemComponent

        Rectangle {
            id: itemRect
            width: 160
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
                    font.pixelSize: Fonts.iconMedium
                    color: entry?.dangerous ? Colors.error : Colors.foreground
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Text
                Text {
                    text: entry?.text ?? ""
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    color: entry?.dangerous ? Colors.error : Colors.foreground
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    if (entry?.command) {
                        SidebarState.powerMenuOpen = false
                        powerProcess.command = ["bash", "-c", entry.command]
                        powerProcess.running = true
                    }
                }
            }

            HintTarget {
                targetElement: itemRect
                scope: "power-menu"
                enabled: powerMenu.visible
                action: () => {
                    if (entry?.command) {
                        SidebarState.powerMenuOpen = false
                        powerProcess.command = ["bash", "-c", entry.command]
                        powerProcess.running = true
                    }
                }
            }
        }
    }

    // Hint overlay for power menu
    PopupWindow {
        id: hintPopup
        anchor.window: powerMenu
        anchor.rect: Qt.rect(0, 0, menuContent.width, menuContent.height)
        anchor.edges: Edges.Top | Edges.Left

        visible: powerMenu.visible && HintNavigationService.active
        color: "transparent"

        implicitWidth: menuContent.width
        implicitHeight: menuContent.height

        HintOverlay {
            anchors.fill: parent
            scope: "power-menu"
            mapRoot: menuContent
        }
    }

    // Keyboard handling for hints in menu
    FocusScope {
        id: menuKeyHandler
        anchors.fill: parent
        focus: powerMenu.visible

        Keys.onPressed: function(event) {
            // Escape closes the menu
            if (event.key === Qt.Key_Escape) {
                SidebarState.powerMenuOpen = false
                event.accepted = true
                return
            }

            if (HintNavigationService.active) {
                let key = ""
                if (event.key === Qt.Key_Backspace) key = "Backspace"
                else if (event.text && event.text.length === 1) key = event.text

                if (key && HintNavigationService.handleKey(key, "power-menu", event.modifiers)) {
                    event.accepted = true
                }
            }
        }
    }
}
