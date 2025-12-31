import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "."

Scope {
    id: settingsScope

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: settingsWindow
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

            visible: SettingsState.settingsOpen
            color: "transparent"

            // Semi-transparent backdrop
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.3)

                MouseArea {
                    anchors.fill: parent
                    onClicked: SettingsState.close()
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

            // Centered settings panel
            Item {
                anchors.fill: parent

                SettingsPanel {
                    id: panel
                    anchors.centerIn: parent

                    // Animation
                    scale: SettingsState.settingsOpen ? 1.0 : 0.95
                    opacity: SettingsState.settingsOpen ? 1.0 : 0

                    Behavior on scale {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    // Focus the panel when visible
                    Component.onCompleted: {
                        if (SettingsState.settingsOpen) {
                            panel.forceActiveFocus()
                        }
                    }
                }
            }

            // Keyboard handling
            Item {
                anchors.fill: parent
                focus: SettingsState.settingsOpen

                Keys.onEscapePressed: SettingsState.close()
            }

            onVisibleChanged: {
                if (visible) {
                    panel.forceActiveFocus()
                }
            }
        }
    }
}
