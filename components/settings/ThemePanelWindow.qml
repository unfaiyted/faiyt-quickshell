import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "."

Scope {
    id: themePanelScope

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: themePanelWindow
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

            visible: ThemePanelState.panelOpen
            color: "transparent"

            // Semi-transparent backdrop
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.3)

                MouseArea {
                    anchors.fill: parent
                    onClicked: ThemePanelState.close()
                }

                // Backdrop blur effect simulation (darker overlay in corners)
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.1) }
                        GradientStop { position: 0.5; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.1) }
                    }
                }
            }

            // Centered theme panel
            Item {
                anchors.fill: parent

                ThemePanel {
                    id: panel
                    anchors.centerIn: parent

                    // Animation
                    scale: ThemePanelState.panelOpen ? 1.0 : 0.95
                    opacity: ThemePanelState.panelOpen ? 1.0 : 0

                    Behavior on scale {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    // Focus the panel when visible
                    Component.onCompleted: {
                        if (ThemePanelState.panelOpen) {
                            panel.forceActiveFocus()
                        }
                    }
                }
            }

            // Keyboard handling
            Item {
                anchors.fill: parent
                focus: ThemePanelState.panelOpen

                Keys.onEscapePressed: ThemePanelState.close()
            }

            onVisibleChanged: {
                if (visible) {
                    panel.forceActiveFocus()
                }
            }
        }
    }
}
