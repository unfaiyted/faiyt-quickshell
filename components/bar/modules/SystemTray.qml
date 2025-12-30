import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../../theme"
import "../../../services"
import "../../overview"
import ".."

BarGroup {
    id: tray

    implicitWidth: trayRow.width + 16
    implicitHeight: 30

    // Track currently open menu
    property var activeMenu: null

    // Focus window by app name/class
    function focusAppWindow(appName) {
        if (!appName) return false

        HyprlandData.updateWindowList()
        let appLower = appName.toLowerCase().trim()

        // Extract first word and last word for better matching
        let words = appLower.split(/[\s\-_]+/)
        let firstWord = words[0] || appLower
        let lastWord = words[words.length - 1] || appLower

        for (let toplevel of ToplevelManager.toplevels.values) {
            if (!toplevel.HyprlandToplevel) continue
            const address = "0x" + toplevel.HyprlandToplevel.address
            const winData = HyprlandData.windowByAddress[address]
            if (!winData) continue

            let winClass = (winData.class || "").toLowerCase()
            let winTitle = (winData.title || "").toLowerCase()


            // Match by class or title containing the app name (or vice versa)
            if (winClass.includes(appLower) || appLower.includes(winClass) ||
                winClass.includes(firstWord) || winClass.includes(lastWord) ||
                winTitle.includes(appLower) || winTitle.includes(firstWord) ||
                firstWord.includes(winClass) || lastWord.includes(winClass)) {
                Hyprland.dispatch("focuswindow address:" + winData.address)
                return true
            }
        }
        return false
    }

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

                // Known Electron apps mapping (id pattern -> app name)
                readonly property var electronApps: ({
                    "slack": "slack",
                    "discord": "discord",
                    "teams": "teams",
                    "element": "element",
                    "signal": "signal",
                    "goofcord": "goofcord",
                    "legcord": "legcord",
                    "webcord": "webcord"
                })

                // For Electron apps, identify which app this tray icon belongs to
                function findElectronApp() {
                    // First, check the icon path - it usually contains the app name
                    let iconStr = String(trayData.icon || "")
                    let iconLower = iconStr.toLowerCase()
                    for (let appName in electronApps) {
                        if (iconLower.includes(appName)) {
                            return electronApps[appName]
                        }
                    }

                    // Fallback: check if any known electron app is running
                    for (let appName in electronApps) {
                        for (let toplevel of ToplevelManager.toplevels.values) {
                            if (!toplevel.HyprlandToplevel) continue
                            const address = "0x" + toplevel.HyprlandToplevel.address
                            const winData = HyprlandData.windowByAddress[address]
                            if (!winData) continue
                            let winClass = (winData.class || "").toLowerCase()
                            if (winClass === appName || winClass.includes(appName)) {
                                return electronApps[appName]
                            }
                        }
                    }
                    return ""
                }

                // Use title/tooltipTitle for icon lookup when id is a chrome status icon (Electron apps)
                property string trayId: {
                    let id = trayData.id || ""
                    if (id.startsWith("chrome_status_icon")) {
                        // For Electron apps, try to match against known apps with open windows
                        let found = findElectronApp()
                        if (found) return found

                        // Check title/tooltipTitle only if they look like app names (not status messages)
                        let title = trayData.title || ""
                        let tooltip = trayData.tooltipTitle || ""
                        let statusWords = ["unread", "message", "notification", "online", "offline", "away", "busy", "idle", "connecting"]
                        let titleLower = title.toLowerCase()
                        let isStatus = statusWords.some(w => titleLower.includes(w))

                        if (title.length > 0 && title.length < 30 && !isStatus) {
                            return title
                        }
                        if (tooltip.length > 0 && tooltip.length < 30 && !statusWords.some(w => tooltip.toLowerCase().includes(w))) {
                            return tooltip
                        }
                        return id
                    }
                    return id || trayData.title || ""
                }
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
                                // Try to focus the app window, fall back to activate
                                if (!tray.focusAppWindow(trayItemContainer.trayId)) {
                                    trayData.activate()
                                }
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
                                text: trayItemContainer.trayId || "Unknown"
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
                    focusAppFunction: tray.focusAppWindow
                    appId: trayItemContainer.trayId

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
