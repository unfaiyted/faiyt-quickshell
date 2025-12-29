pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../theme"
import "."

Scope {
    id: overviewScope

    Variants {
        id: overviewVariants
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            readonly property var monitor: Hyprland.monitorFor(root.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id === monitor?.id)

            screen: modelData
            visible: OverviewState.overviewOpen

            WlrLayershell.namespace: "quickshell:overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: Qt.rgba(0, 0, 0, 0.5)

            mask: Region {
                item: OverviewState.overviewOpen ? keyHandler : null
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            HyprlandFocusGrab {
                id: grab
                windows: [root]
                property bool canBeActive: root.monitorIsFocused
                active: false
                onCleared: () => {
                    if (!active) {
                        OverviewState.overviewOpen = false
                    }
                }
            }

            Connections {
                target: OverviewState
                function onOverviewOpenChanged() {
                    if (OverviewState.overviewOpen) {
                        delayedGrabTimer.start()
                    }
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: 50
                repeat: false
                onTriggered: {
                    if (!grab.canBeActive) return
                    grab.active = OverviewState.overviewOpen
                }
            }

            // Keyboard handler
            Item {
                id: keyHandler
                anchors.fill: parent
                visible: OverviewState.overviewOpen
                focus: OverviewState.overviewOpen

                Keys.onPressed: event => {
                    // Close on Escape or Enter
                    if (event.key === Qt.Key_Escape || event.key === Qt.Key_Return) {
                        OverviewState.overviewOpen = false
                        event.accepted = true
                        return
                    }

                    const rows = 2
                    const columns = 5
                    const workspacesPerGroup = rows * columns
                    const currentId = Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1
                    const currentGroup = Math.floor((currentId - 1) / workspacesPerGroup)
                    const minWorkspaceId = currentGroup * workspacesPerGroup + 1
                    const maxWorkspaceId = minWorkspaceId + workspacesPerGroup - 1

                    let targetId = null

                    // Arrow keys and vim-style hjkl
                    if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                        targetId = currentId - 1
                        if (targetId < minWorkspaceId) targetId = maxWorkspaceId
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                        targetId = currentId + 1
                        if (targetId > maxWorkspaceId) targetId = minWorkspaceId
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                        targetId = currentId - columns
                        if (targetId < minWorkspaceId) targetId += workspacesPerGroup
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                        targetId = currentId + columns
                        if (targetId > maxWorkspaceId) targetId -= workspacesPerGroup
                    }
                    // Number keys 1-9 and 0
                    else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                        const position = event.key - Qt.Key_0
                        if (position <= workspacesPerGroup) {
                            targetId = minWorkspaceId + position - 1
                        }
                    } else if (event.key === Qt.Key_0) {
                        if (workspacesPerGroup >= 10) {
                            targetId = minWorkspaceId + 9
                        }
                    }

                    if (targetId !== null) {
                        Hyprland.dispatch("workspace " + targetId)
                        event.accepted = true
                    }
                }
            }

            // Center the overview widget
            Item {
                anchors.fill: parent

                OverviewWidget {
                    id: overviewWidget
                    anchors.centerIn: parent
                    panelWindow: root
                    visible: OverviewState.overviewOpen
                }
            }

            // Click outside to close
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: {
                    OverviewState.overviewOpen = false
                }
            }
        }
    }

    // IPC Handler
    IpcHandler {
        target: "overview"

        function toggle() {
            OverviewState.overviewOpen = !OverviewState.overviewOpen
        }
        function close() {
            OverviewState.overviewOpen = false
        }
        function open() {
            OverviewState.overviewOpen = true
        }
    }
}
