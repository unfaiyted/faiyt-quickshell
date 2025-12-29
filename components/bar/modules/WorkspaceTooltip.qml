import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../../theme"

Rectangle {
    id: tooltip

    property int workspaceId: 1
    property bool isVisible: false
    property var windowList: []

    // Get monitor dimensions from Hyprland
    property var currentMonitor: {
        for (let mon of Hyprland.monitors.values) {
            // Use the first monitor or find the active one
            return mon
        }
        return null
    }
    property real monitorWidth: currentMonitor ? currentMonitor.width : 1920
    property real monitorHeight: currentMonitor ? currentMonitor.height : 1080
    property real aspectRatio: monitorWidth / monitorHeight

    // Find toplevel by matching window address
    function findToplevel(address) {
        // Hyprland addresses are like "0x5678abcd", Wayland might differ
        for (let toplevel of ToplevelManager.toplevels.values) {
            // Try matching by address (format may vary)
            if (toplevel.appId && address) {
                // Compare last part of address
                let hyprAddr = address.replace("0x", "").toLowerCase()
                let waylandAddr = String(toplevel).toLowerCase()
                if (waylandAddr.includes(hyprAddr)) {
                    return toplevel
                }
            }
        }
        return null
    }

    // Find toplevel by matching class/appId
    function findToplevelByClass(windowClass, title) {
        for (let toplevel of ToplevelManager.toplevels.values) {
            if (toplevel.appId === windowClass) {
                // If there are multiple windows of same class, try to match by title too
                if (toplevel.title === title) {
                    return toplevel
                }
            }
        }
        // Fallback: return first match by appId
        for (let toplevel of ToplevelManager.toplevels.values) {
            if (toplevel.appId === windowClass) {
                return toplevel
            }
        }
        return null
    }

    // Preview dimensions - match monitor aspect ratio
    property real previewHeight: 140
    property real previewWidth: previewHeight * aspectRatio

    width: Math.max(200, Math.min(500, previewWidth + 20))  // Clamp width with padding
    height: previewHeight + 50  // Add space for header

    color: Colors.surface
    radius: 8
    border.width: 1
    border.color: Colors.overlay

    // Fetch clients when visible changes
    onIsVisibleChanged: {
        if (isVisible) {
            clientsProc.running = true
        }
    }

    // Get windows via hyprctl
    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        property string output: ""

        stdout: SplitParser {
            onRead: data => {
                clientsProc.output += data
            }
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0 && clientsProc.output) {
                try {
                    var clients = JSON.parse(clientsProc.output)
                    tooltip.windowList = clients.filter(function(w) {
                        return w.workspace && w.workspace.id === tooltip.workspaceId
                    })
                    console.log("Workspace", tooltip.workspaceId, "has", tooltip.windowList.length, "windows")
                } catch (e) {
                    console.log("Failed to parse clients:", e)
                    tooltip.windowList = []
                }
            }
            clientsProc.output = ""
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
        text: tooltip.windowList.length + " window" + (tooltip.windowList.length !== 1 ? "s" : "")
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
            visible: tooltip.windowList.length === 0
            text: "Empty workspace"
            color: Colors.muted
            font.pixelSize: 10
        }

        // Window previews
        Repeater {
            model: tooltip.windowList

            Rectangle {
                id: windowRect
                required property var modelData
                required property int index

                // Scaled position and size from hyprctl data
                x: (modelData.at ? modelData.at[0] : 0) * previewArea.scaleX
                y: (modelData.at ? modelData.at[1] : 0) * previewArea.scaleY
                width: Math.max(30, (modelData.size ? modelData.size[0] : 100) * previewArea.scaleX)
                height: Math.max(20, (modelData.size ? modelData.size[1] : 100) * previewArea.scaleY)

                color: Colors.overlay
                radius: 3
                border.width: 1
                border.color: Colors.rose
                clip: true

                // Try to get toplevel for this window
                property var toplevel: tooltip.findToplevelByClass(modelData.class, modelData.title)

                // Live window capture
                ScreencopyView {
                    id: screenCapture
                    anchors.fill: parent
                    captureSource: windowRect.toplevel
                    live: true
                    visible: windowRect.toplevel !== null
                }

                // App name label overlay
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 20 
                    color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, 0.8)
                    visible: parent.height > 20

                    Text {
                        id: appLabel
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: windowRect.modelData.class || windowRect.modelData.title || "?"
                        color: Colors.foreground
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
