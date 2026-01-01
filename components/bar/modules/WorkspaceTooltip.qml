pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../../theme"
import "../../../services"
import "../../overview"

Rectangle {
    id: tooltip

    property int workspaceId: 1
    property bool isVisible: false

    // Signals for parent to manage open/close
    signal requestClose()
    signal cancelClose()

    // Delayed capture flag - wait for popup to stabilize
    property bool captureReady: false

    // Track if mouse is inside tooltip or any window
    property bool mouseInside: false
    property int hoveredWindowCount: 0

    // Get monitor dimensions from Hyprland
    property var currentMonitor: {
        for (let mon of Hyprland.monitors.values) {
            return mon
        }
        return null
    }
    property real monitorWidth: currentMonitor ? currentMonitor.width : 1920
    property real monitorHeight: currentMonitor ? currentMonitor.height : 1080
    property real aspectRatio: monitorWidth / monitorHeight

    // Preview dimensions - match monitor aspect ratio
    property real previewHeight: 140
    property real previewWidth: previewHeight * aspectRatio

    // Close timer - gives time to move mouse to tooltip
    Timer {
        id: closeTimer
        interval: 150
        repeat: false
        onTriggered: {
            if (!tooltip.mouseInside) {
                tooltip.requestClose()
            }
        }
    }

    function startCloseTimer() {
        closeTimer.start()
    }

    function cancelCloseTimer() {
        closeTimer.stop()
        tooltip.cancelClose()
    }

    // Refresh data and start capture when becoming visible
    onIsVisibleChanged: {
        if (isVisible) {
            HyprlandData.updateWindowList()
            captureReady = false
            captureDelayTimer.start()
        } else {
            captureReady = false
            captureDelayTimer.stop()
            closeTimer.stop()
            exitCheckTimer.stop()
            hoveredWindowCount = 0
            mouseInside = false
        }
    }

    Timer {
        id: captureDelayTimer
        interval: 100
        repeat: false
        onTriggered: tooltip.captureReady = true
    }

    // Get windows for this workspace from HyprlandData
    property var windowsInWorkspace: {
        return ToplevelManager.toplevels.values.filter(toplevel => {
            if (!toplevel?.HyprlandToplevel) return false
            const address = "0x" + toplevel.HyprlandToplevel.address
            const win = HyprlandData.windowByAddress[address]
            return win?.workspace?.id === tooltip.workspaceId
        })
    }

    width: Math.max(200, Math.min(500, previewWidth + 20))
    height: previewHeight + 50

    color: Colors.surface
    radius: 8
    border.width: 1
    border.color: Colors.overlay

    // Main mouse area for the entire tooltip
    MouseArea {
        id: tooltipMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton  // Don't intercept clicks, let children handle them

        onEntered: {
            tooltip.mouseInside = true
            tooltip.cancelCloseTimer()
        }

        onExited: {
            // Use a short delay to check if we're actually leaving
            // This prevents false exits when moving to child elements
            exitCheckTimer.start()
        }
    }

    // Short timer to verify mouse has actually left the tooltip
    Timer {
        id: exitCheckTimer
        interval: 30
        repeat: false
        onTriggered: {
            // Check if mouse is still in tooltip area or hovering any window
            if (!tooltipMouseArea.containsMouse && tooltip.hoveredWindowCount === 0) {
                tooltip.mouseInside = false
                tooltip.startCloseTimer()
            }
        }
    }

    // Workspace label
    Text {
        id: wsLabel
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 8
        text: "Workspace " + tooltip.workspaceId
        color: Colors.foreground
        font.pixelSize: 12
        font.bold: true
    }

    // Window count
    Text {
        anchors.top: wsLabel.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 2
        text: tooltip.windowsInWorkspace.length + " window" + (tooltip.windowsInWorkspace.length !== 1 ? "s" : "")
        color: Colors.muted
        font.pixelSize: 9
    }

    // Preview area
    Rectangle {
        id: previewArea
        anchors.top: wsLabel.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        anchors.topMargin: 20

        color: Colors.background
        radius: 4
        clip: true

        // Scale factor for window positions
        property real scaleX: width / tooltip.monitorWidth
        property real scaleY: height / tooltip.monitorHeight

        // Empty state
        Text {
            anchors.centerIn: parent
            visible: tooltip.windowsInWorkspace.length === 0
            text: "Empty workspace"
            color: Colors.muted
            font.pixelSize: 10
        }

        // Window previews using ToplevelManager
        Repeater {
            model: ScriptModel {
                values: tooltip.windowsInWorkspace
            }

            Item {
                id: windowItem
                required property var modelData
                required property int index

                // Get window data from HyprlandData
                property var address: "0x" + modelData.HyprlandToplevel.address
                property var winData: HyprlandData.windowByAddress[address]
                property bool hovered: false

                // Scaled position and size
                x: ((winData?.at[0] ?? 0) - (tooltip.currentMonitor?.x ?? 0)) * previewArea.scaleX
                y: ((winData?.at[1] ?? 0) - (tooltip.currentMonitor?.y ?? 0)) * previewArea.scaleY
                width: Math.max(30, (winData?.size[0] ?? 100) * previewArea.scaleX)
                height: Math.max(20, (winData?.size[1] ?? 100) * previewArea.scaleY)

                Rectangle {
                    id: windowFrame
                    anchors.fill: parent
                    radius: 3
                    color: windowItem.hovered
                        ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.9)
                        : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.7)
                    border.width: windowItem.hovered ? 2 : 1
                    border.color: windowItem.hovered ? Colors.primary : Colors.rose
                    clip: true

                    // Check if we have a NerdFont icon for this app
                    property string appClass: windowItem.winData?.class ?? ""
                    property bool hasNerdIcon: IconService.hasIcon(appClass)
                    // Only try system icon if we don't have a NerdFont mapping
                    property string iconPath: (!hasNerdIcon && appClass !== "") ? Quickshell.iconPath(appClass, "") : ""

                    Behavior on border.width {
                        NumberAnimation { duration: 100 }
                    }

                    // Live window capture
                    ScreencopyView {
                        id: screenCapture
                        anchors.fill: parent
                        anchors.margins: 1
                        captureSource: tooltip.captureReady ? windowItem.modelData : null
                        live: true
                    }

                    // NerdFont icon (preferred - use if we have a mapping)
                    Text {
                        anchors.centerIn: parent
                        property real iconSize: Math.min(parent.width, parent.height) * 0.4
                        visible: iconSize >= 12 && windowFrame.hasNerdIcon
                        text: IconService.getIcon(windowFrame.appClass)
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: iconSize
                        color: Colors.foreground
                        opacity: windowItem.hovered ? 0.5 : 0.85

                        Behavior on opacity {
                            NumberAnimation { duration: 100 }
                        }
                    }

                    // System icon (fallback for apps without NerdFont mapping)
                    Image {
                        id: appIcon
                        anchors.centerIn: parent
                        property real iconSize: Math.min(parent.width, parent.height) * 0.4
                        width: iconSize
                        height: iconSize
                        source: windowFrame.iconPath
                        sourceSize: Qt.size(iconSize, iconSize)
                        opacity: windowItem.hovered ? 0.5 : 0.85
                        visible: iconSize >= 12 && !windowFrame.hasNerdIcon && status === Image.Ready

                        Behavior on opacity {
                            NumberAnimation { duration: 100 }
                        }
                    }

                    // Default NerdFont icon (when system icon also fails)
                    Text {
                        anchors.centerIn: parent
                        property real iconSize: Math.min(parent.width, parent.height) * 0.4
                        visible: iconSize >= 12 && !windowFrame.hasNerdIcon && appIcon.status !== Image.Ready
                        text: IconService.getIcon("")
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: iconSize
                        color: Colors.foreground
                        opacity: windowItem.hovered ? 0.5 : 0.85

                        Behavior on opacity {
                            NumberAnimation { duration: 100 }
                        }
                    }

                    // Window title on hover
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: titleText.height + 4
                        color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.9)
                        visible: windowItem.hovered && parent.height > 30
                        radius: 2

                        Text {
                            id: titleText
                            anchors.centerIn: parent
                            width: parent.width - 6
                            text: windowItem.winData?.title ?? "Unknown"
                            color: Colors.foreground
                            font.pixelSize: 8
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    // Click handler for window
                    MouseArea {
                        id: windowMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                        onEntered: {
                            windowItem.hovered = true
                            tooltip.hoveredWindowCount++
                            tooltip.mouseInside = true
                            tooltip.cancelCloseTimer()
                            exitCheckTimer.stop()
                        }

                        onExited: {
                            windowItem.hovered = false
                            tooltip.hoveredWindowCount = Math.max(0, tooltip.hoveredWindowCount - 1)
                        }

                        onClicked: (mouse) => {
                            if (!windowItem.winData) return

                            if (mouse.button === Qt.LeftButton) {
                                // Focus the window and close tooltip
                                tooltip.requestClose()
                                Hyprland.dispatch("focuswindow address:" + windowItem.winData.address)
                            } else if (mouse.button === Qt.MiddleButton) {
                                // Close the window
                                Hyprland.dispatch("closewindow address:" + windowItem.winData.address)
                            }
                        }
                    }
                }
            }
        }
    }
}
