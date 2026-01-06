pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: brightnessService

    // Brightness value (0-100)
    property real brightness: 0
    property real maxBrightness: 100
    property string device: ""
    property bool available: device !== ""

    // Internal state
    property real _lastBrightness: -1
    property bool _initializing: true
    property string _devicePath: ""

    // Polling timer (100ms)
    Timer {
        id: pollTimer
        interval: 100
        running: brightnessService.available
        repeat: true
        onTriggered: brightnessService.readBrightness()
    }

    // Detect backlight device on startup
    Component.onCompleted: {
        detectDevice()
    }

    // Device detection process
    Process {
        id: detectProcess
        command: ["ls", "/sys/class/backlight/"]
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() && !brightnessService.device) {
                    brightnessService.device = data.trim()
                    brightnessService._devicePath = "/sys/class/backlight/" + brightnessService.device
                    console.log("BrightnessService: Found backlight device:", brightnessService.device)
                    brightnessService.readMaxBrightness()
                }
            }
        }
        onRunningChanged: {
            if (!running && !brightnessService.device) {
                console.log("BrightnessService: No backlight device found")
                brightnessService._initializing = false
            }
        }
    }

    // Read max brightness process
    Process {
        id: maxBrightnessProcess
        command: ["cat", brightnessService._devicePath + "/max_brightness"]
        stdout: SplitParser {
            onRead: data => {
                const val = parseInt(data.trim())
                if (!isNaN(val) && val > 0) {
                    brightnessService.maxBrightness = val
                    console.log("BrightnessService: Max brightness:", val)
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                brightnessService.readBrightness()
                brightnessService._initializing = false
                // Restore saved brightness after initialization
                Qt.callLater(brightnessService.restoreSavedBrightness)
            }
        }
    }

    // Read current brightness process
    Process {
        id: readProcess
        command: ["cat", brightnessService._devicePath + "/brightness"]
        stdout: SplitParser {
            onRead: data => {
                const val = parseInt(data.trim())
                if (!isNaN(val)) {
                    const percent = Math.round((val / brightnessService.maxBrightness) * 100)
                    if (percent !== brightnessService._lastBrightness) {
                        brightnessService._lastBrightness = percent
                        brightnessService.brightness = percent
                    }
                }
            }
        }
    }

    // Set brightness process
    Process {
        id: setProcess
        property string targetValue: ""
        command: ["brightnessctl", "set", targetValue]
        onRunningChanged: {
            if (!running) {
                brightnessService.readBrightness()
            }
        }
    }

    function detectDevice() {
        detectProcess.running = true
    }

    function readMaxBrightness() {
        if (_devicePath) {
            maxBrightnessProcess.running = true
        }
    }

    function readBrightness() {
        if (_devicePath && !readProcess.running) {
            readProcess.running = true
        }
    }

    function setBrightness(percent) {
        if (!available) return

        // Clamp to 0-100
        percent = Math.max(0, Math.min(100, percent))
        setProcess.targetValue = percent + "%"
        setProcess.command = ["brightnessctl", "set", setProcess.targetValue]
        setProcess.running = true
    }

    function increase(amount) {
        if (amount === undefined) amount = 5
        setBrightness(brightness + amount)
    }

    function decrease(amount) {
        if (amount === undefined) amount = 5
        setBrightness(brightness - amount)
    }

    function restoreSavedBrightness() {
        // Import ConfigService to get saved value
        // This will be called after device detection
        if (!available || _initializing) return

        try {
            const saved = Qt.binding(function() { return null }) // Will be connected via IndicatorState
        } catch (e) {
            console.log("BrightnessService: Could not restore brightness:", e)
        }
    }

    // Icon based on brightness level
    function getIcon() {
        if (brightness < 20) return "󰃞"      // brightness-low
        if (brightness < 50) return "󰃟"      // brightness-medium
        return "󰃠"                           // brightness-high
    }
}
