import QtQuick
import Quickshell
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
    margins.top: 8     // Below the bar
    exclusiveZone: 0
    color: "transparent"

    // Hide window when not expanded (after animation completes)
    visible: expanded || slideAnimation.running

    // Dark background to match overlay (fills entire window including padding)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.3)
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

                // Quick toggles (WiFi, Bluetooth, Caffeine)
                QuickToggles {
                    width: parent.width
                }

                // Tab bar
                Item {
                    width: parent.width
                    height: 48

                    TabBar {
                        id: tabs
                        anchors.centerIn: parent
                        tabs: ["󰂚", "󰕾", "󰂯", "󰤨", "󰃭"]  // Icons: Bell, Volume, Bluetooth, WiFi, Calendar
                    }
                }

                // Tab content
                Item {
                    width: parent.width
                    height: parent.height - 176  // Header(72) + QuickToggles(56) + TabBar(48)

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
}
