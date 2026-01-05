import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"
import "."
import "../common"

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

            // Hint navigation overlay
            PopupWindow {
                id: hintPopup
                anchor.window: themePanelWindow
                anchor.rect: Qt.rect(
                    (themePanelWindow.width - panel.width) / 2,
                    (themePanelWindow.height - panel.height) / 2,
                    panel.width,
                    panel.height
                )
                anchor.edges: Edges.Top | Edges.Left

                visible: ThemePanelState.panelOpen && HintNavigationService.active
                color: "transparent"

                implicitWidth: panel.width
                implicitHeight: panel.height

                HintOverlay {
                    anchors.fill: parent
                    scope: "theme"
                    mapRoot: panel
                }
            }

            // Keyboard handling
            FocusScope {
                id: keyboardHandler
                anchors.fill: parent
                focus: ThemePanelState.panelOpen

                Connections {
                    target: HintNavigationService
                    function onActiveChanged() {
                        if (HintNavigationService.active && ThemePanelState.panelOpen) {
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

                        if (key && HintNavigationService.handleKey(key, "theme")) {
                            event.accepted = true
                            return
                        }
                    }

                    if (event.key === Qt.Key_Escape) {
                        ThemePanelState.close()
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
