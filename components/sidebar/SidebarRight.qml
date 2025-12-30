import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
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

    // Keyboard focus for Escape key
    WlrLayershell.keyboardFocus: expanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Hide window when not expanded (after animation completes)
    visible: expanded || slideAnimation.running || bgFadeAnim.running

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

    // Keyboard handler for Escape (at window level for reliable focus)
    FocusScope {
        anchors.fill: parent
        focus: rightSidebar.expanded

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                SidebarState.rightOpen = false
                event.accepted = true
            }
        }
    }
}
