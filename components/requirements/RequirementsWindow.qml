import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"
import "."
import "../common"

Scope {
    id: requirementsScope

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: requirementsWindow
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

            visible: RequirementsState.panelOpen
            color: "transparent"

            // Semi-transparent backdrop
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.3)

                MouseArea {
                    anchors.fill: parent
                    onClicked: RequirementsState.close()
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

            // Centered requirements panel
            Item {
                anchors.fill: parent

                RequirementsPanel {
                    id: panel
                    anchors.centerIn: parent

                    // Animation
                    scale: RequirementsState.panelOpen ? 1.0 : 0.95
                    opacity: RequirementsState.panelOpen ? 1.0 : 0

                    Behavior on scale {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    // Focus the panel when visible
                    Component.onCompleted: {
                        if (RequirementsState.panelOpen) {
                            panel.forceActiveFocus()
                        }
                    }
                }
            }

            // Hint navigation overlay
            PopupWindow {
                id: hintPopup
                anchor.window: requirementsWindow
                anchor.rect: Qt.rect(
                    (requirementsWindow.width - panel.width) / 2,
                    (requirementsWindow.height - panel.height) / 2,
                    panel.width,
                    panel.height
                )
                anchor.edges: Edges.Top | Edges.Left

                visible: RequirementsState.panelOpen && HintNavigationService.active
                color: "transparent"

                implicitWidth: panel.width
                implicitHeight: panel.height

                HintOverlay {
                    anchors.fill: parent
                    scope: "requirements"
                    mapRoot: panel
                }
            }

            // Keyboard handling
            FocusScope {
                id: keyboardHandler
                anchors.fill: parent
                focus: RequirementsState.panelOpen

                Connections {
                    target: HintNavigationService
                    function onActiveChanged() {
                        if (HintNavigationService.active && RequirementsState.panelOpen) {
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

                        if (key && HintNavigationService.handleKey(key, "requirements", event.modifiers)) {
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
                        RequirementsState.close()
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
