pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../theme"
import "."

Item {
    id: root

    required property var panelWindow
    readonly property var monitor: Hyprland.monitorFor(panelWindow.screen)
    readonly property var toplevels: ToplevelManager.toplevels

    // Configuration
    readonly property int rows: 2
    readonly property int columns: 5
    readonly property int workspacesShown: rows * columns
    readonly property int workspaceGroup: Math.floor((monitor.activeWorkspace?.id - 1) / workspacesShown)

    property var windows: HyprlandData.windowList
    property var windowByAddress: HyprlandData.windowByAddress
    property var monitorData: HyprlandData.monitors.find(m => m.id === root.monitor?.id)

    property real scale: 0.12
    property real workspaceSpacing: 8

    // Calculate workspace dimensions based on monitor
    property real workspaceImplicitWidth: (monitor.width / monitor.scale) * root.scale
    property real workspaceImplicitHeight: (monitor.height / monitor.scale) * root.scale

    // Drag state
    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1

    implicitWidth: overviewBackground.implicitWidth
    implicitHeight: overviewBackground.implicitHeight

    // Background panel
    Rectangle {
        id: overviewBackground
        property real padding: 16

        anchors.fill: parent
        implicitWidth: workspaceGrid.implicitWidth + padding * 2
        implicitHeight: workspaceGrid.implicitHeight + padding * 2

        radius: 16
        color: Colors.background
        border.width: 1
        border.color: Colors.border

        // Workspace grid
        ColumnLayout {
            id: workspaceGrid
            anchors.centerIn: parent
            spacing: workspaceSpacing

            Repeater {
                model: root.rows

                RowLayout {
                    id: row
                    required property int index
                    property int rowIndex: index
                    spacing: workspaceSpacing

                    Repeater {
                        model: root.columns

                        Rectangle {
                            id: workspace
                            required property int index
                            property int colIndex: index
                            property int workspaceValue: root.workspaceGroup * root.workspacesShown + row.rowIndex * root.columns + colIndex + 1
                            property bool isActive: monitor.activeWorkspace?.id === workspaceValue
                            property bool hoveredWhileDragging: false

                            implicitWidth: root.workspaceImplicitWidth | 0
                            implicitHeight: root.workspaceImplicitHeight | 0

                            color: hoveredWhileDragging ? Colors.overlay : Colors.surface
                            radius: 8
                            border.width: isActive ? 2 : 1
                            border.color: isActive ? Colors.primary : (hoveredWhileDragging ? Colors.rose : Colors.border)

                            // Workspace number
                            Text {
                                anchors.centerIn: parent
                                text: workspace.workspaceValue
                                font.pixelSize: (root.workspaceImplicitHeight * 0.4) | 0
                                font.bold: true
                                color: Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.15)
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                onClicked: {
                                    if (root.draggingTargetWorkspace === -1) {
                                        OverviewState.overviewOpen = false
                                        Hyprland.dispatch("workspace " + workspace.workspaceValue)
                                    }
                                }
                            }

                            DropArea {
                                anchors.fill: parent
                                onEntered: {
                                    root.draggingTargetWorkspace = workspace.workspaceValue
                                    if (root.draggingFromWorkspace !== root.draggingTargetWorkspace) {
                                        workspace.hoveredWhileDragging = true
                                    }
                                }
                                onExited: {
                                    workspace.hoveredWhileDragging = false
                                    if (root.draggingTargetWorkspace === workspace.workspaceValue) {
                                        root.draggingTargetWorkspace = -1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Windows layer
        Item {
            id: windowSpace
            anchors.centerIn: parent
            implicitWidth: workspaceGrid.implicitWidth
            implicitHeight: workspaceGrid.implicitHeight

            Repeater {
                model: ScriptModel {
                    values: {
                        return ToplevelManager.toplevels.values.filter((toplevel) => {
                            const address = "0x" + toplevel.HyprlandToplevel.address
                            var win = root.windowByAddress[address]
                            const inWorkspaceGroup = (root.workspaceGroup * root.workspacesShown < win?.workspace?.id && win?.workspace?.id <= (root.workspaceGroup + 1) * root.workspacesShown)
                            return inWorkspaceGroup
                        }).sort((a, b) => {
                            const addrA = "0x" + a.HyprlandToplevel.address
                            const addrB = "0x" + b.HyprlandToplevel.address
                            const winA = root.windowByAddress[addrA]
                            const winB = root.windowByAddress[addrB]

                            // Floating windows on top
                            if (winA?.floating !== winB?.floating) {
                                return winA?.floating ? 1 : -1
                            }

                            // Sort by focus history
                            return (winB?.focusHistoryID ?? 0) - (winA?.focusHistoryID ?? 0)
                        })
                    }
                }

                delegate: OverviewWindow {
                    id: window
                    required property var modelData
                    required property int index

                    property var address: "0x" + modelData.HyprlandToplevel.address
                    property var winData: root.windowByAddress[address]
                    property int monitorId: winData?.monitor
                    property var winMonitor: HyprlandData.monitors.find(m => m.id === monitorId)

                    windowData: winData
                    toplevel: modelData
                    monitorData: winMonitor
                    scale: root.scale
                    availableWorkspaceWidth: root.workspaceImplicitWidth
                    availableWorkspaceHeight: root.workspaceImplicitHeight
                    widgetMonitorId: root.monitor.id

                    property int workspaceColIndex: (winData?.workspace.id - 1) % root.columns
                    property int workspaceRowIndex: Math.floor((winData?.workspace.id - 1) % root.workspacesShown / root.columns)
                    xOffset: (root.workspaceImplicitWidth + root.workspaceSpacing) * workspaceColIndex
                    yOffset: (root.workspaceImplicitHeight + root.workspaceSpacing) * workspaceRowIndex

                    z: index

                    Drag.hotSpot.x: targetWindowWidth / 2
                    Drag.hotSpot.y: targetWindowHeight / 2

                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        drag.target: parent

                        onEntered: window.hovered = true
                        onExited: window.hovered = false

                        onPressed: (mouse) => {
                            root.draggingFromWorkspace = winData?.workspace.id
                            window.pressed = true
                            window.Drag.active = true
                            window.Drag.source = window
                            window.Drag.hotSpot.x = mouse.x
                            window.Drag.hotSpot.y = mouse.y
                        }

                        onReleased: {
                            const targetWorkspace = root.draggingTargetWorkspace
                            window.pressed = false
                            window.Drag.active = false
                            root.draggingFromWorkspace = -1

                            if (targetWorkspace !== -1 && targetWorkspace !== winData?.workspace.id) {
                                Hyprland.dispatch("movetoworkspacesilent " + targetWorkspace + ", address:" + winData?.address)
                            } else {
                                window.x = window.initX
                                window.y = window.initY
                            }
                        }

                        onClicked: (event) => {
                            if (!winData) return

                            if (event.button === Qt.LeftButton) {
                                OverviewState.overviewOpen = false
                                Hyprland.dispatch("focuswindow address:" + winData.address)
                            } else if (event.button === Qt.MiddleButton) {
                                Hyprland.dispatch("closewindow address:" + winData.address)
                            }
                        }
                    }
                }
            }

            // Active workspace indicator
            Rectangle {
                id: focusedIndicator
                property int activeWorkspaceInGroup: root.monitor.activeWorkspace?.id - (root.workspaceGroup * root.workspacesShown)
                property int activeRowIndex: Math.floor((activeWorkspaceInGroup - 1) / root.columns)
                property int activeColIndex: (activeWorkspaceInGroup - 1) % root.columns

                x: (root.workspaceImplicitWidth + root.workspaceSpacing) * activeColIndex
                y: (root.workspaceImplicitHeight + root.workspaceSpacing) * activeRowIndex
                width: root.workspaceImplicitWidth | 0
                height: root.workspaceImplicitHeight | 0
                color: "transparent"
                radius: 8
                border.width: 3
                border.color: Colors.primary

                Behavior on x {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
                Behavior on y {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
