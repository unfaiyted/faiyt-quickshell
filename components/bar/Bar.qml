import QtQuick
import Quickshell
import "../../theme"
import "../../services"
import "modules"

PanelWindow {
    id: bar

    visible: ConfigService.windowBarEnabled

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

    // Main layout container
    Item {
        anchors.fill: parent

        // Distro icon (leftmost element)
        Text {
            id: distroIcon
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: IconService.getDistroIcon()
            font.family: "Symbols Nerd Font"
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

        // Center-Left: System Resources (anchored to left of Workspaces)
        Row {
            anchors.right: workspaces.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            visible: ConfigService.barModuleSystemResources

            SystemResources {}
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
                visible: ConfigService.barModuleMusic
            }
        }

        // Right section
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            SystemTray {
                visible: ConfigService.barModuleSystemTray
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
    }
}
