import QtQuick
import Quickshell
import Quickshell.Io
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

    // Query D-Bus to get app names for tray items based on their process cmdline
    // This is the most reliable way to identify Electron apps
    property var trayAppMapping: ({})

    Process {
        id: trayMapperProc
        command: ["bash", "-c", `
            busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems 2>/dev/null | grep -oE ':[0-9]+\\.[0-9]+' | while read service; do
                pid=$(busctl --user list 2>/dev/null | grep "^$service " | awk '{print $2}')
                if [ -n "$pid" ] && [ -d "/proc/$pid" ]; then
                    cmdline=$(tr '\\0' ' ' < /proc/$pid/cmdline 2>/dev/null | tr '[:upper:]' '[:lower:]')
                    exe=$(readlink /proc/$pid/exe 2>/dev/null | xargs basename 2>/dev/null | tr '[:upper:]' '[:lower:]')
                    # Extract app name from cmdline or exe
                    if echo "$cmdline" | grep -q "goofcord"; then app="goofcord"
                    elif echo "$cmdline" | grep -q "legcord"; then app="legcord"
                    elif echo "$cmdline" | grep -q "webcord"; then app="webcord"
                    elif echo "$cmdline" | grep -q "discord"; then app="discord"
                    elif echo "$cmdline" | grep -q "slack"; then app="slack"
                    elif echo "$cmdline" | grep -q "teams"; then app="teams"
                    elif echo "$cmdline" | grep -q "element"; then app="element"
                    elif echo "$cmdline" | grep -q "signal"; then app="signal"
                    elif echo "$cmdline" | grep -q "spotify"; then app="spotify"
                    else app="$exe"
                    fi
                    echo "$app"
                else
                    echo "unknown"
                fi
            done
        `]

        property string outputBuffer: ""

        stdout: SplitParser {
            onRead: data => {
                trayMapperProc.outputBuffer += data + "\n"
            }
        }

        onExited: function(exitCode, exitStatus) {
            let lines = outputBuffer.trim().split("\n").filter(l => l.length > 0)
            // Map by index since multiple Electron apps can have the same ID
            tray.trayAppMapping = lines
            outputBuffer = ""
        }
    }

    // Refresh mapping when tray items change
    Connections {
        target: SystemTray.items
        function onValuesChanged() {
            trayMapperProc.running = true
        }
    }

    // Initial mapping on load
    Component.onCompleted: {
        trayMapperProc.running = true
    }

    // Get app name for a tray item by index
    function getAppForTrayIndex(index) {
        if (Array.isArray(trayAppMapping) && index >= 0 && index < trayAppMapping.length) {
            return trayAppMapping[index]
        }
        return ""
    }

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

                // Pretty display names for known apps
                readonly property var prettyNames: ({
                    "spotify": "Spotify",
                    "spotify-client": "Spotify",
                    "spotify_client": "Spotify",
                    "slack": "Slack",
                    "discord": "Discord",
                    "goofcord": "Goofcord",
                    "legcord": "Legcord",
                    "webcord": "Webcord",
                    "teams": "Microsoft Teams",
                    "element": "Element",
                    "signal": "Signal",
                    "steam": "Steam",
                    "nm-applet": "Network Manager",
                    "blueman": "Bluetooth",
                    "blueman-applet": "Bluetooth",
                    "pavucontrol": "Volume Control",
                    "flameshot": "Flameshot",
                    "copyq": "CopyQ",
                    "kdeconnect": "KDE Connect",
                    "dropbox": "Dropbox",
                    "nextcloud": "Nextcloud",
                    "syncthing": "Syncthing",
                    "1password": "1Password",
                    "bitwarden": "Bitwarden"
                })

                // Get the app name from D-Bus process mapping (most reliable for Electron apps)
                property string dbusAppName: {
                    // Force re-evaluation when mapping changes
                    let _ = tray.trayAppMapping
                    return tray.getAppForTrayIndex(index)
                }

                // Check if this is an Electron app (chrome_status_icon)
                property bool isElectronTray: (trayData.id || "").startsWith("chrome_status_icon")

                // Get the effective app name for this tray item
                property string effectiveAppName: {
                    // For Electron apps, use D-Bus mapping (based on process cmdline)
                    if (isElectronTray && dbusAppName && dbusAppName !== "unknown") {
                        return dbusAppName
                    }
                    // Fall back to tray id
                    return trayData.id || trayData.title || ""
                }

                // Track if this is an unidentified Electron app (use system icon)
                property bool isUnidentifiedElectron: isElectronTray && (!dbusAppName || dbusAppName === "unknown" || dbusAppName === "electron")

                // Get the tray ID (used for icon lookup)
                property string trayId: effectiveAppName

                // Get a nice display name for the tray item
                function getDisplayName() {
                    let name = effectiveAppName.toLowerCase()

                    // Check pretty names first (exact match)
                    if (prettyNames[name]) {
                        return prettyNames[name]
                    }

                    // Check pretty names (partial match)
                    for (let key in prettyNames) {
                        if (name.includes(key) || key.includes(name)) {
                            return prettyNames[key]
                        }
                    }

                    // Clean up the name
                    name = effectiveAppName
                    name = name.replace(/[-_]client$/i, "")
                    name = name.replace(/[-_]applet$/i, "")

                    // If still chrome_status_icon or unknown, show generic name
                    if (name.match(/^chrome_status_icon/i) || name === "unknown" || name === "electron") {
                        return "Application"
                    }

                    // Capitalize first letter of each word
                    return name.split(/[-_\s]+/).map(word =>
                        word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
                    ).join(" ")
                }

                property string displayName: getDisplayName()
                // Check if we have a NerdFont icon for this tray item
                // Don't use NerdFont for unidentified Electron apps - use their actual icon
                property bool hasNerdIcon: IconService.hasIcon(trayId) && !isUnidentifiedElectron

                // NerdFont icon (preferred - use if we have a mapping and can identify the app)
                Text {
                    anchors.centerIn: parent
                    visible: trayItemContainer.hasNerdIcon
                    text: IconService.getIcon(trayItemContainer.trayId)
                    font.family: Fonts.icon
                    font.pixelSize: 14
                    color: Colors.foreground
                }

                // System tray icon (fallback for items without NerdFont mapping, or unidentified Electron apps)
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
                    font.family: Fonts.icon
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
                                text: trayItemContainer.displayName || "Unknown"
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
