pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: monitorsState

    // UI State
    property bool monitorsOpen: false
    property string selectedMonitor: ""
    property bool hasChanges: false

    // Monitor data from hyprctl
    property var monitors: []

    // Temporary positions during drag (map: monitorName -> {x, y})
    property var tempPositions: ({})

    // Temporary settings pending apply (map: monitorName -> {mode, scale, transform})
    property var tempSettings: ({})

    // Constants
    readonly property real canvasScale: 0.10
    readonly property int snapThreshold: 100
    readonly property int gridSize: 10
    readonly property int canvasPadding: 20

    // Toggle visibility
    function toggle() {
        if (monitorsOpen) {
            close()
        } else {
            open()
        }
    }

    function open() {
        monitorsOpen = true
        refreshMonitors()
    }

    function close() {
        monitorsOpen = false
        selectedMonitor = ""
    }

    // Refresh monitor data from Hyprland
    function refreshMonitors() {
        getMonitorsProcess.running = true
    }

    // Get position for a monitor (temp or actual)
    function getMonitorPosition(monitorName) {
        if (tempPositions[monitorName]) {
            return tempPositions[monitorName]
        }
        const mon = monitors.find(m => m.name === monitorName)
        if (mon) {
            return { x: mon.x, y: mon.y }
        }
        return { x: 0, y: 0 }
    }

    // Set temporary position
    function setTempPosition(monitorName, x, y) {
        let newPositions = Object.assign({}, tempPositions)
        newPositions[monitorName] = { x: x, y: y }
        tempPositions = newPositions
        hasChanges = true
    }

    // Set temporary setting
    function setTempSetting(monitorName, key, value) {
        let newSettings = Object.assign({}, tempSettings)
        if (!newSettings[monitorName]) {
            newSettings[monitorName] = {}
        }
        newSettings[monitorName][key] = value
        tempSettings = newSettings
        hasChanges = true
    }

    // Get temp setting or current value
    function getTempSetting(monitorName, key) {
        if (tempSettings[monitorName] && tempSettings[monitorName][key] !== undefined) {
            return tempSettings[monitorName][key]
        }
        const mon = monitors.find(m => m.name === monitorName)
        if (mon) {
            return mon[key]
        }
        return undefined
    }

    // Reset all changes
    function resetChanges() {
        tempPositions = {}
        tempSettings = {}
        hasChanges = false
    }

    // Apply changes
    function applyChanges() {
        applyIndex = 0
        applyNextChange()
    }

    property int applyIndex: 0
    property var applyQueue: []

    function applyNextChange() {
        // Build queue of changes on first call
        if (applyIndex === 0) {
            applyQueue = []

            for (const mon of monitors) {
                const pos = tempPositions[mon.name]
                const settings = tempSettings[mon.name] || {}

                // Position change
                if (pos && (pos.x !== mon.x || pos.y !== mon.y)) {
                    const mode = settings.mode || `${mon.width}x${mon.height}@${mon.refreshRate.toFixed(2)}Hz`
                    const scale = settings.scale !== undefined ? settings.scale : mon.scale
                    // Format: hyprctl keyword monitor name,resolution,position,scale
                    applyQueue.push({
                        type: "position",
                        command: ["hyprctl", "keyword", "monitor",
                            `${mon.name},${mode},${pos.x}x${pos.y},${scale}`]
                    })
                }
                // Mode change only (no position change)
                else if (settings.mode) {
                    const scale = settings.scale !== undefined ? settings.scale : mon.scale
                    applyQueue.push({
                        type: "mode",
                        command: ["hyprctl", "keyword", "monitor",
                            `${mon.name},${settings.mode},${mon.x}x${mon.y},${scale}`]
                    })
                }
                // Scale change only
                else if (settings.scale !== undefined && Math.abs(settings.scale - mon.scale) > 0.01) {
                    const mode = `${mon.width}x${mon.height}@${mon.refreshRate.toFixed(2)}Hz`
                    applyQueue.push({
                        type: "scale",
                        command: ["hyprctl", "keyword", "monitor",
                            `${mon.name},${mode},${mon.x}x${mon.y},${settings.scale}`]
                    })
                }

                // Transform change
                if (settings.transform !== undefined && settings.transform !== mon.transform) {
                    applyQueue.push({
                        type: "transform",
                        command: ["hyprctl", "keyword", "monitor",
                            `${mon.name},transform,${settings.transform}`]
                    })
                }
            }
        }

        // Execute next command in queue
        if (applyIndex < applyQueue.length) {
            applyProcess.command = applyQueue[applyIndex].command
            applyProcess.running = true
        } else {
            // All done - refresh and reset
            resetChanges()
            Qt.callLater(refreshMonitors)
        }
    }

    // Auto-align monitors in a row
    function autoAlign() {
        if (monitors.length < 2) return

        // Find primary monitor (or first)
        const primary = monitors.find(m => m.focused) || monitors[0]
        let newPositions = {}
        newPositions[primary.name] = { x: 0, y: 0 }

        // Position other monitors to the right
        let currentX = primary.width
        for (const mon of monitors) {
            if (mon.name !== primary.name) {
                newPositions[mon.name] = { x: currentX, y: 0 }
                currentX += mon.width
            }
        }

        tempPositions = newPositions
        hasChanges = true
    }

    // Convert real coords to canvas coords
    function toCanvasCoords(x, y) {
        return {
            x: x * canvasScale + canvasPadding,
            y: y * canvasScale + canvasPadding
        }
    }

    // Convert canvas coords to real coords
    function toRealCoords(x, y) {
        return {
            x: Math.round((x - canvasPadding) / canvasScale),
            y: Math.round((y - canvasPadding) / canvasScale)
        }
    }

    // Snap to grid
    function snapToGrid(value) {
        return Math.round(value / gridSize) * gridSize
    }

    // Get snap position considering other monitors
    function getSnapPosition(monitorName, x, y) {
        const mon = monitors.find(m => m.name === monitorName)
        if (!mon) return { x: x, y: y }

        let snapX = x
        let snapY = y

        for (const other of monitors) {
            if (other.name === monitorName) continue

            const otherPos = getMonitorPosition(other.name)

            // Snap to right edge of other monitor
            if (Math.abs(x - (otherPos.x + other.width)) < snapThreshold) {
                snapX = otherPos.x + other.width
            }
            // Snap to left edge of other monitor
            if (Math.abs(x + mon.width - otherPos.x) < snapThreshold) {
                snapX = otherPos.x - mon.width
            }
            // Snap to bottom edge of other monitor
            if (Math.abs(y - (otherPos.y + other.height)) < snapThreshold) {
                snapY = otherPos.y + other.height
            }
            // Snap to top edge of other monitor
            if (Math.abs(y + mon.height - otherPos.y) < snapThreshold) {
                snapY = otherPos.y - mon.height
            }

            // Align tops
            if (Math.abs(y - otherPos.y) < snapThreshold) {
                snapY = otherPos.y
            }
            // Align lefts
            if (Math.abs(x - otherPos.x) < snapThreshold) {
                snapX = otherPos.x
            }
        }

        // Grid snap fallback
        if (snapX === x) snapX = snapToGrid(x)
        if (snapY === y) snapY = snapToGrid(y)

        return { x: snapX, y: snapY }
    }

    // Get valid scale factors for a resolution
    function getValidScales(width, height) {
        const scales = []
        const testScales = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0]

        for (const scale of testScales) {
            const scaledWidth = width / scale
            const scaledHeight = height / scale
            if (scaledWidth === Math.floor(scaledWidth) &&
                scaledHeight === Math.floor(scaledHeight)) {
                scales.push(scale)
            }
        }
        return scales
    }

    // Buffer for accumulating stdout data
    property string monitorDataBuffer: ""

    // Process to get monitor data
    Process {
        id: getMonitorsProcess
        command: ["hyprctl", "monitors", "-j"]

        stdout: SplitParser {
            onRead: data => {
                monitorsState.monitorDataBuffer += data
            }
        }

        onRunningChanged: {
            if (!running && monitorDataBuffer.length > 0) {
                try {
                    const parsed = JSON.parse(monitorDataBuffer)
                    monitorsState.monitors = parsed
                    console.log("MonitorsState: Loaded", parsed.length, "monitors")
                } catch (e) {
                    console.log("MonitorsState: Failed to parse monitor data:", e)
                }
                monitorDataBuffer = ""
            }
        }
    }

    // Process to apply changes
    Process {
        id: applyProcess
        onRunningChanged: {
            if (!running) {
                applyIndex++
                applyNextChange()
            }
        }
    }

    // IPC handler for external control
    IpcHandler {
        target: "monitors"

        function toggle() {
            monitorsState.toggle()
        }

        function open() {
            monitorsState.open()
        }

        function close() {
            monitorsState.close()
        }
    }
}
