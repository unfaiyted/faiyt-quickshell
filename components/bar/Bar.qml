import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"
import "modules"
import "../common"
import "../sidebar"
import "../launcher"
import "../wallpaper"
import "../settings"
import "../monitors"
import "../overview"

PanelWindow {
    id: bar

    visible: ConfigService.windowBarEnabled

    // Check if any overlay window is open (disables bar hints)
    readonly property bool anyWindowOpen: SidebarState.leftOpen ||
                                          SidebarState.rightOpen ||
                                          LauncherState.visible ||
                                          WallpaperState.visible ||
                                          SettingsState.settingsOpen ||
                                          MonitorsState.monitorsOpen ||
                                          OverviewState.overviewOpen ||
                                          ThemePanelState.panelOpen

    // Bar hints only active when no other window is open and no popup scope is active
    property bool barHintsActive: false

    function updateBarHintsActive() {
        const popupScope = HintNavigationService.activePopupScope
        const shouldBeActive = HintNavigationService.active && !anyWindowOpen &&
                               (popupScope === "" || popupScope === "bar")
        if (barHintsActive !== shouldBeActive) {
            barHintsActive = shouldBeActive
        }
    }

    Connections {
        target: HintNavigationService
        function onActiveChanged() {
            bar.updateBarHintsActive()
        }
        function onActivePopupScopeChanged() {
            bar.updateBarHintsActive()
        }
    }

    onAnyWindowOpenChanged: updateBarHintsActive()

    // Position at top, span full width
    anchors {
        top: true
        left: true
        right: true
    }

    // Reserve space so windows don't overlap
    exclusiveZone: implicitHeight

    // Bar height
    implicitHeight: 40 

    // Background color
    color: Colors.background

    // Keyboard focus - Exclusive when hints active (bar handles routing to popup scopes)
    WlrLayershell.keyboardFocus: (HintNavigationService.active && !anyWindowOpen) ?
        WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Main layout container
    Item {
        id: barContent
        anchors.fill: parent

        // Distro icon (leftmost element)
        Text {
            id: distroIcon
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: IconService.getDistroIcon()
            font.family: Fonts.icon
            font.pixelSize: 22
            color: Colors.primary
            visible: ConfigService.barModuleDistroIcon
        }

        // Left section - Window Title
        WindowTitle {
            anchors.left: distroIcon.visible ? distroIcon.right : parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: ConfigService.barModuleWindowTitle
        }

        // Center-Middle: Workspaces (always perfectly centered)
        Workspaces {
            id: workspaces
            anchors.centerIn: parent
            visible: ConfigService.barModuleWorkspaces
        }

        // Center-Left: Mic Indicator + System Resources (anchored to left of Workspaces)
        Row {
            anchors.right: workspaces.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            MicIndicator {}

            SystemResources {
                visible: ConfigService.barModuleSystemResources
            }
        }

        // Center-Right: Utilities + Music (anchored to right of Workspaces)
        Row {
            anchors.left: workspaces.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            visible: ConfigService.barModuleUtilities || ConfigService.barModuleMusic

            Utilities {
                visible: ConfigService.barModuleUtilities
            }
            Music {
                // Visibility handled internally (checks config + track data)
            }
        }

        // Right section
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            SystemTray {
                // Visibility handled internally (checks config + tray items)
            }
            Network {
                visible: ConfigService.barModuleNetwork
            }
            Battery {
                // Visibility handled internally (checks config + battery presence)
            }
            Clock {
                visible: ConfigService.barModuleClock
            }
            Weather {
                visible: ConfigService.barModuleWeather
            }
        }

        // Bottom border line
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 0
            color: Colors.border
        }

        // Hint navigation overlay in a popup so hints can extend below bar
        PopupWindow {
            id: hintPopup
            anchor.window: bar
            anchor.rect: Qt.rect(0, 0, bar.width, bar.height)
            anchor.edges: Edges.Top | Edges.Left

            visible: bar.barHintsActive
            color: "transparent"

            // Extend height to allow hints to render below bar elements
            implicitWidth: bar.width
            implicitHeight: bar.height + 30

            HintOverlay {
                anchors.fill: parent
                scope: "bar"
                anchorPosition: "bottomCenter"
                mapRoot: barContent
            }
        }

        // Keyboard handler for hint navigation (routes to bar or active popup scope)
        FocusScope {
            id: keyboardHandler
            anchors.fill: parent
            focus: HintNavigationService.active && !bar.anyWindowOpen

            // Force focus when hints become active
            Connections {
                target: HintNavigationService
                function onActiveChanged() {
                    if (HintNavigationService.active && !bar.anyWindowOpen) {
                        keyboardHandler.forceActiveFocus()
                    }
                }
            }

            Keys.onPressed: function(event) {
                if (!HintNavigationService.active) return

                // Determine which scope to route keys to
                const scope = HintNavigationService.activePopupScope || "bar"

                // Handle Escape specially - close popup or deactivate hints
                if (event.key === Qt.Key_Escape) {
                    if (HintNavigationService.activePopupScope !== "") {
                        // Close popup via signal (components listen for popupScopeCleared)
                        HintNavigationService.clearPopupScope()
                    } else {
                        HintNavigationService.deactivate()
                    }
                    event.accepted = true
                    return
                }

                let key = ""
                if (event.key === Qt.Key_Backspace) {
                    key = "Backspace"
                } else if (event.text && event.text.length === 1) {
                    key = event.text
                }

                if (key && HintNavigationService.handleKey(key, scope, event.modifiers)) {
                    event.accepted = true
                }
            }
        }
    }
}
