pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "." as Services

Singleton {
    id: nightLightService

    // Current state
    property bool nightLightEnabled: false
    property bool isInWindow: false

    // Check if hyprsunset is running
    Process {
        id: statusProcess
        command: ["pgrep", "-x", "hyprsunset"]
        property bool foundProcess: false

        stdout: SplitParser {
            onRead: data => {
                if (data.trim().length > 0) {
                    statusProcess.foundProcess = true
                }
            }
        }

        onRunningChanged: {
            if (!running) {
                nightLightService.nightLightEnabled = foundProcess
                foundProcess = false
            }
        }
    }

    // Enable night light
    Process {
        id: enableProcess
        command: ["hyprsunset", "-t", Services.ConfigService.quickToggleNightTemp.toString()]
        onRunningChanged: {
            if (!running) {
                statusProcess.running = true
            }
        }
    }

    // Disable night light
    Process {
        id: disableProcess
        command: ["pkill", "-x", "hyprsunset"]
        onRunningChanged: {
            if (!running) {
                statusProcess.running = true
            }
        }
    }

    // Parse time string "HH:MM" to minutes since midnight
    function parseTime(timeStr) {
        const parts = timeStr.split(":")
        if (parts.length !== 2) return -1
        const hours = parseInt(parts[0], 10)
        const minutes = parseInt(parts[1], 10)
        if (isNaN(hours) || isNaN(minutes)) return -1
        if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) return -1
        return hours * 60 + minutes
    }

    // Check if current time is within the night window
    function checkIfInWindow() {
        if (!Services.ConfigService.nightLightAutoEnabled) {
            isInWindow = false
            return false
        }

        const now = new Date()
        const currentMinutes = now.getHours() * 60 + now.getMinutes()

        const startMinutes = parseTime(Services.ConfigService.nightLightStartTime)
        const endMinutes = parseTime(Services.ConfigService.nightLightEndTime)

        if (startMinutes < 0 || endMinutes < 0) {
            isInWindow = false
            return false
        }

        let inWindow
        if (startMinutes <= endMinutes) {
            // Same day window (e.g., 08:00 - 18:00)
            inWindow = currentMinutes >= startMinutes && currentMinutes < endMinutes
        } else {
            // Overnight window (e.g., 20:00 - 06:00)
            inWindow = currentMinutes >= startMinutes || currentMinutes < endMinutes
        }

        isInWindow = inWindow
        return inWindow
    }

    // Calculate next window start time as ISO string
    function calculateNextWindowStart() {
        const now = new Date()
        const startMinutes = parseTime(Services.ConfigService.nightLightStartTime)
        if (startMinutes < 0) return null

        const startHours = Math.floor(startMinutes / 60)
        const startMins = startMinutes % 60

        let nextStart = new Date(now)
        nextStart.setHours(startHours, startMins, 0, 0)

        // If start time has already passed today, move to tomorrow
        if (nextStart <= now) {
            nextStart.setDate(nextStart.getDate() + 1)
        }

        return nextStart.toISOString()
    }

    // Check if manual override is still active
    function isManuallyDisabled() {
        const disabledUntil = Services.ConfigService.nightLightManuallyDisabledUntil
        if (!disabledUntil) return false

        const until = new Date(disabledUntil)
        const now = new Date()
        return until > now
    }

    // Clear manual override
    function clearManualOverride() {
        Services.ConfigService.setValue("sidebar.quickToggles.nightLight.manuallyDisabledUntil", null)
        Services.ConfigService.saveConfig()
    }

    // Enable night light (internal)
    function enableNightLight() {
        if (!nightLightEnabled) {
            nightLightEnabled = true // Optimistic update
            enableProcess.running = true
        }
    }

    // Disable night light (internal)
    function disableNightLight() {
        if (nightLightEnabled) {
            nightLightEnabled = false // Optimistic update
            disableProcess.running = true
        }
    }

    // Called when user manually toggles night light
    function onManualToggle(wantsEnabled) {
        if (wantsEnabled) {
            // User manually enabling - clear any override and enable
            clearManualOverride()
            enableNightLight()
        } else {
            // User manually disabling
            disableNightLight()

            // If we're in the auto window, set override until next window start
            if (Services.ConfigService.nightLightAutoEnabled && isInWindow) {
                const nextStart = calculateNextWindowStart()
                if (nextStart) {
                    Services.ConfigService.setValue("sidebar.quickToggles.nightLight.manuallyDisabledUntil", nextStart)
                    Services.ConfigService.saveConfig()
                }
            }
        }
    }

    // Main scheduling check - called periodically
    function checkSchedule() {
        const inWindow = checkIfInWindow()

        if (!Services.ConfigService.nightLightAutoEnabled) {
            // Auto mode disabled, don't interfere with current state
            return
        }

        if (inWindow) {
            // We're in the night window
            if (isManuallyDisabled()) {
                // User manually disabled, respect that
                return
            }
            // Enable if not already
            enableNightLight()
        } else {
            // Outside window - disable if enabled and clear any override
            if (nightLightEnabled) {
                disableNightLight()
            }
            // Clear manual override when leaving window
            if (Services.ConfigService.nightLightManuallyDisabledUntil) {
                clearManualOverride()
            }
        }
    }

    // Timer to check schedule every minute
    Timer {
        id: scheduleTimer
        interval: 60000  // 1 minute
        running: true
        repeat: true
        onTriggered: nightLightService.checkSchedule()
    }

    // Also refresh status periodically
    Timer {
        id: statusTimer
        interval: 5000
        running: true
        repeat: true
        onTriggered: statusProcess.running = true
    }

    // React to config changes
    Connections {
        target: Services.ConfigService
        function onNightLightAutoEnabledChanged() {
            nightLightService.checkSchedule()
        }
        function onNightLightStartTimeChanged() {
            nightLightService.checkSchedule()
        }
        function onNightLightEndTimeChanged() {
            nightLightService.checkSchedule()
        }
    }

    // Initialize on startup
    Component.onCompleted: {
        // Wait for config to load, then check schedule
        Qt.callLater(() => {
            statusProcess.running = true
            checkSchedule()
        })
    }
}
