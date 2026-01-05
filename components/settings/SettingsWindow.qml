import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"
import "."
import "../common"

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

            // Hint navigation overlay
            PopupWindow {
                id: hintPopup
                anchor.window: settingsWindow
                anchor.rect: Qt.rect(
                    (settingsWindow.width - panel.width) / 2,
                    (settingsWindow.height - panel.height) / 2,
                    panel.width,
                    panel.height
                )
                anchor.edges: Edges.Top | Edges.Left

                visible: SettingsState.settingsOpen && HintNavigationService.active
                color: "transparent"

                implicitWidth: panel.width
                implicitHeight: panel.height

                HintOverlay {
                    anchors.fill: parent
                    scope: "settings"
                    mapRoot: panel
                }
            }

            // Keyboard handling
            FocusScope {
                id: keyboardHandler
                anchors.fill: parent
                focus: SettingsState.settingsOpen

                Connections {
                    target: HintNavigationService
                    function onActiveChanged() {
                        if (HintNavigationService.active && SettingsState.settingsOpen) {
                            keyboardHandler.forceActiveFocus()
                        }
                    }
                }

                Keys.onPressed: function(event) {
                    if (HintNavigationService.active) {
                        let key = ""
                        if (event.key === Qt.Key_Escape) key = "Escape"
                        else if (event.key === Qt.Key_Backspace) key = "Backspace"
                        else if (event.text && event.text.length === 1) key = event.text

                        if (key && HintNavigationService.handleKey(key, "settings", event.modifiers)) {
                            event.accepted = true
                            return
                        }
                    }

                    // Arrow key scrolling
                    if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                        panel.scrollUp()
                        event.accepted = true
                        return
                    }
                    if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                        panel.scrollDown()
                        event.accepted = true
                        return
                    }
                    // Page up/down
                    if (event.key === Qt.Key_PageUp) {
                        panel.scrollPageUp()
                        event.accepted = true
                        return
                    }
                    if (event.key === Qt.Key_PageDown) {
                        panel.scrollPageDown()
                        event.accepted = true
                        return
                    }
                    // Home/End - go to top/bottom
                    if (event.key === Qt.Key_Home) {
                        panel.scrollToTop()
                        event.accepted = true
                        return
                    }
                    if (event.key === Qt.Key_End) {
                        panel.scrollToBottom()
                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_Escape) {
                        SettingsState.close()
                        event.accepted = true
                    }
                }
            }

            onVisibleChanged: {
                if (visible) {
                    panel.forceActiveFocus()
                }
            }
        }
    }
}
