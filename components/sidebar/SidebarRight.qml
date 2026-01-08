import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../theme"
import "../../services"
import "../common"
import "modules"

PanelWindow {
    id: rightSidebar

    anchors {
        top: true
        bottom: true
        right: true
    }

    property bool expanded: SidebarState.rightOpen

    // Fixed width - includes padding space
    implicitWidth: 396  // 380 + 8 left + 8 right padding
    margins.top: 0     // Below the bar
    exclusiveZone: 0
    color: "transparent"

    // Layer and keyboard focus - using OnDemand instead of Exclusive to allow focus grab to work
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Focus grab to close sidebar when clicking outside
    HyprlandFocusGrab {
        id: focusGrab
        windows: [rightSidebar]
        active: false

        onCleared: {
            console.log("[SidebarRight] Focus grab cleared, active:", active)
            if (!active) {
                SidebarState.closeAll()
            }
        }
    }

    // Activate focus grab with small delay after sidebar opens
    Timer {
        id: grabActivateTimer
        interval: 100
        onTriggered: {
            if (rightSidebar.expanded) {
                focusGrab.active = true
                console.log("[SidebarRight] Focus grab activated")
            }
        }
    }

    onExpandedChanged: {
        if (expanded) {
            grabActivateTimer.start()
        } else {
            focusGrab.active = false
        }
    }

    // Hide window when not expanded (after animation completes) or disabled in config
    visible: ConfigService.windowSidebarRightEnabled && (expanded || slideAnimation.running || bgFadeAnim.running)

    // Dark background to match overlay (curved top-right to avoid bar corner)
    Canvas {
        id: bgCanvas
        anchors.fill: parent
        opacity: rightSidebar.expanded ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                id: bgFadeAnim
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var w = width
            var h = height
            var r = 24  // Match bar corner radius

            ctx.fillStyle = Qt.rgba(0, 0, 0, 0.3)
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(w - r, 0)
            ctx.arc(w - r, r, r, -Math.PI / 2, 0, false)
            ctx.lineTo(w, h)
            ctx.lineTo(0, h)
            ctx.lineTo(0, 0)
            ctx.closePath()
            ctx.fill()
        }

        Component.onCompleted: requestPaint()
    }

    // Clip container for smooth slide animation
    Item {
        anchors.fill: parent
        anchors.margins: 8  // Internal padding
        clip: true

        // Sliding content panel
        Rectangle {
            id: contentPanel
            width: parent.width
            height: parent.height
            radius: 16
            color: Colors.background

            // Slide from right: width (hidden) to 0 (visible)
            x: rightSidebar.expanded ? 0 : width

            Behavior on x {
                NumberAnimation {
                    id: slideAnimation
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            // Click handler to close popups (like power menu) when clicking sidebar background
            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                onClicked: function(mouse) {
                    if (SidebarState.powerMenuOpen) {
                        SidebarState.closePopups()
                        mouse.accepted = true
                    } else {
                        mouse.accepted = false
                    }
                }
                onPressed: function(mouse) {
                    mouse.accepted = SidebarState.powerMenuOpen
                }
            }

            // Sidebar content with fade
            Column {
                anchors.fill: parent
                opacity: rightSidebar.expanded ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }

                // Header with user info
                Header {
                    width: parent.width
                }

                // Spacer between header and toggles
                Item {
                    width: parent.width
                    height: 8
                }

                // Quick toggles (WiFi, Bluetooth, Caffeine)
                QuickToggles {
                    width: parent.width
                }

                // Spacer between toggles and tabs
                Item {
                    width: parent.width
                    height: 8
                }

                // Tab bar
                TabBar {
                    id: tabs
                    width: parent.width
                    tabs: ["󰂚", "󰕾", "󰂯", "󰤨", "󰃭"]  // Icons: Bell, Volume, Bluetooth, WiFi, Calendar
                }

                // Tab content
                Item {
                    width: parent.width
                    height: parent.height - 228  // Header(72) + Spacer(8) + QuickToggles(88) + Spacer(8) + TabBar(52)

                    // Use Loader for efficient tab switching
                    Loader {
                        anchors.fill: parent
                        sourceComponent: {
                            switch(tabs.currentIndex) {
                                case 0: return notificationsComponent
                                case 1: return audioComponent
                                case 2: return bluetoothComponent
                                case 3: return wifiComponent
                                case 4: return calendarComponent
                                default: return notificationsComponent
                            }
                        }
                    }

                    Component {
                        id: notificationsComponent
                        Notifications {}
                    }

                    Component {
                        id: audioComponent
                        AudioControl {}
                    }

                    Component {
                        id: bluetoothComponent
                        BluetoothPanel {}
                    }

                    Component {
                        id: wifiComponent
                        WiFiPanel {}
                    }

                    Component {
                        id: calendarComponent
                        Calendar {}
                    }
                }
            }

            // Subtle border
            Rectangle {
                anchors.fill: parent
                radius: 16
                color: "transparent"
                border.width: 1
                border.color: Colors.border
            }

        }
    }

    // Hint navigation overlay in a popup to avoid clipping issues
    PopupWindow {
        id: hintPopup
        anchor.window: rightSidebar
        anchor.rect: Qt.rect(8, 8, rightSidebar.width - 16, rightSidebar.height - 16)
        anchor.edges: Edges.Top | Edges.Left

        visible: rightSidebar.expanded && HintNavigationService.active
        color: "transparent"

        implicitWidth: rightSidebar.width - 16
        implicitHeight: rightSidebar.height - 16

        HintOverlay {
            anchors.fill: parent
            scope: "sidebar-right"
            mapRoot: contentPanel
        }
    }

    // Keyboard handler for Escape and hint navigation (at window level for reliable focus)
    FocusScope {
        anchors.fill: parent
        focus: rightSidebar.expanded || HintNavigationService.active

        Keys.onPressed: function(event) {
            // Handle hint navigation first when active
            if (HintNavigationService.active) {
                let key = ""
                if (event.key === Qt.Key_Escape) {
                    key = "Escape"
                } else if (event.key === Qt.Key_Backspace) {
                    key = "Backspace"
                } else if (event.text && event.text.length === 1) {
                    key = event.text
                }

                if (key && HintNavigationService.handleKey(key, "sidebar-right", event.modifiers)) {
                    event.accepted = true
                    return
                }
            }

            // Standard escape - close power menu first, then sidebar
            if (event.key === Qt.Key_Escape) {
                if (SidebarState.powerMenuOpen) {
                    SidebarState.closePopups()
                } else {
                    SidebarState.rightOpen = false
                }
                event.accepted = true
            }
        }
    }
}
