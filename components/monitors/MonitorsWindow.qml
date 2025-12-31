import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "."

Scope {
    id: monitorsScope

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: monitorsWindow
            property var modelData
            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusiveZone: 0
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            visible: MonitorsState.monitorsOpen
            color: "transparent"

            // Semi-transparent backdrop
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.5)

                MouseArea {
                    anchors.fill: parent
                    onClicked: MonitorsState.close()
                }
            }

            // Centered monitors panel
            Item {
                anchors.fill: parent

                MonitorsPanel {
                    id: panel
                    anchors.centerIn: parent

                    // Animation
                    scale: MonitorsState.monitorsOpen ? 1.0 : 0.95
                    opacity: MonitorsState.monitorsOpen ? 1.0 : 0

                    Behavior on scale {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }
                }
            }

            // Keyboard handling
            Item {
                anchors.fill: parent
                focus: MonitorsState.monitorsOpen

                Keys.onEscapePressed: MonitorsState.close()
            }

            onVisibleChanged: {
                if (visible) {
                    panel.forceActiveFocus()
                }
            }
        }
    }
}
