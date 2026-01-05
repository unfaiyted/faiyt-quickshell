import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"
import "."
import "../common"

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

            // Hint navigation overlay
            PopupWindow {
                id: hintPopup
                anchor.window: monitorsWindow
                anchor.rect: Qt.rect(
                    (monitorsWindow.width - panel.width) / 2,
                    (monitorsWindow.height - panel.height) / 2,
                    panel.width,
                    panel.height
                )
                anchor.edges: Edges.Top | Edges.Left

                visible: MonitorsState.monitorsOpen && HintNavigationService.active
                color: "transparent"

                implicitWidth: panel.width
                implicitHeight: panel.height

                HintOverlay {
                    anchors.fill: parent
                    scope: "monitors"
                    mapRoot: panel
                }
            }

            // Keyboard handling
            FocusScope {
                id: keyboardHandler
                anchors.fill: parent
                focus: MonitorsState.monitorsOpen

                Connections {
                    target: HintNavigationService
                    function onActiveChanged() {
                        if (HintNavigationService.active && MonitorsState.monitorsOpen) {
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

                        if (key && HintNavigationService.handleKey(key, "monitors", event.modifiers)) {
                            event.accepted = true
                            return
                        }
                    }

                    if (event.key === Qt.Key_Escape) {
                        MonitorsState.close()
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
