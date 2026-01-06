pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: kbBacklightService

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
        running: kbBacklightService.available
        repeat: true
        onTriggered: kbBacklightService.readBrightness()
    }

    // Detect keyboard backlight device on startup
    Component.onCompleted: {
        detectDevice()
    }

    // Device detection via brightnessctl
    Process {
        id: detectProcess
        command: ["brightnessctl", "-l", "-c", "leds"]
        property string output: ""
        stdout: SplitParser {
            onRead: data => {
                detectProcess.output += data + "\n"
            }
        }
        onRunningChanged: {
            if (!running) {
                // Look for keyboard backlight device
                const lines = detectProcess.output.split('\n')
                for (let line of lines) {
                    // Look for kbd_backlight or similar patterns
                    const match = line.match(/Device '([^']*kbd[^']*)'/i)
                    if (match) {
                        kbBacklightService.device = match[1]
                        kbBacklightService._devicePath = "/sys/class/leds/" + kbBacklightService.device
                        console.log("KeyboardBacklightService: Found device:", kbBacklightService.device)
                        kbBacklightService.readMaxBrightness()
                        return
                    }
                }
                // Fallback: try ls /sys/class/leds/
                detectFallbackProcess.running = true
            }
        }
    }

    // Fallback detection via sysfs
    Process {
        id: detectFallbackProcess
        command: ["ls", "/sys/class/leds/"]
        property string output: ""
        stdout: SplitParser {
            onRead: data => {
                detectFallbackProcess.output += data + "\n"
            }
        }
        onRunningChanged: {
            if (!running) {
                const devices = detectFallbackProcess.output.split('\n')
                for (let dev of devices) {
                    dev = dev.trim()
                    if (dev && (dev.includes('kbd') || dev.includes('keyboard') || dev.includes('backlight'))) {
                        // Filter out non-keyboard backlights
                        if (!dev.includes('capslock') && !dev.includes('numlock') && !dev.includes('scrolllock')) {
                            kbBacklightService.device = dev
                            kbBacklightService._devicePath = "/sys/class/leds/" + dev
                            console.log("KeyboardBacklightService: Found device via fallback:", dev)
                            kbBacklightService.readMaxBrightness()
                            return
                        }
                    }
                }
                console.log("KeyboardBacklightService: No keyboard backlight device found")
                kbBacklightService._initializing = false
            }
        }
    }

    // Read max brightness process
    Process {
        id: maxBrightnessProcess
        command: ["cat", kbBacklightService._devicePath + "/max_brightness"]
        stdout: SplitParser {
            onRead: data => {
                const val = parseInt(data.trim())
                if (!isNaN(val) && val > 0) {
                    kbBacklightService.maxBrightness = val
                    console.log("KeyboardBacklightService: Max brightness:", val)
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                kbBacklightService.readBrightness()
                kbBacklightService._initializing = false
                // Restore saved brightness after initialization
                Qt.callLater(kbBacklightService.restoreSavedBrightness)
            }
        }
    }

    // Read current brightness process
    Process {
        id: readProcess
        command: ["cat", kbBacklightService._devicePath + "/brightness"]
        stdout: SplitParser {
            onRead: data => {
                const val = parseInt(data.trim())
                if (!isNaN(val)) {
                    const percent = Math.round((val / kbBacklightService.maxBrightness) * 100)
                    if (percent !== kbBacklightService._lastBrightness) {
                        kbBacklightService._lastBrightness = percent
                        kbBacklightService.brightness = percent
                    }
                }
            }
        }
    }

    // Set brightness process
    Process {
        id: setProcess
        property string targetDevice: ""
        property string targetValue: ""
        command: ["brightnessctl", "-d", targetDevice, "set", targetValue]
        onRunningChanged: {
            if (!running) {
                kbBacklightService.readBrightness()
            }
        }
    }

    function detectDevice() {
        detectProcess.output = ""
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
        setProcess.targetDevice = device
        setProcess.targetValue = percent + "%"
        setProcess.command = ["brightnessctl", "-d", setProcess.targetDevice, "set", setProcess.targetValue]
        setProcess.running = true
    }

    function increase(amount) {
        if (amount === undefined) amount = 10
        setBrightness(brightness + amount)
    }

    function decrease(amount) {
        if (amount === undefined) amount = 10
        setBrightness(brightness - amount)
    }

    function restoreSavedBrightness() {
        // Will be connected via IndicatorState
        if (!available || _initializing) return
    }

    // Icon for keyboard backlight (static)
    function getIcon() {
        return "󰌌"  // keyboard
    }
}
