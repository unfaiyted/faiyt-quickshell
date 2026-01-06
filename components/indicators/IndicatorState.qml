pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../services" as Services

Singleton {
    id: state

    // CRITICAL: PwObjectTracker binds nodes so audio properties work
    PwObjectTracker {
        id: nodeTracker
        objects: Pipewire.nodes.values
    }

    // Current active indicator (only one at a time)
    property string activeIndicator: ""  // "volume", "brightness", "keyboard"
    property bool visible: activeIndicator !== ""

    // Values - use safe getters for volume
    property real volumeValue: {
        const sink = Pipewire.defaultAudioSink
        if (sink && sink.audio && !isNaN(sink.audio.volume)) {
            return sink.audio.volume * 100
        }
        return 0
    }
    property bool volumeMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false
    property real brightnessValue: 0
    property real kbBrightnessValue: 0

    // Track previous values to detect changes
    property real _lastVolume: -1
    property bool _lastMuted: false
    property real _lastBrightness: -1
    property real _lastKbBrightness: -1

    // Initialization flag to prevent showing indicators on startup
    property bool _initialized: false

    // Timeout timer (3 seconds default, configurable)
    Timer {
        id: hideTimer
        interval: Services.ConfigService.getValue("indicators.timeout") ?? 3000
        onTriggered: state.activeIndicator = ""
    }

    // Delayed initialization to let services settle
    Timer {
        id: initTimer
        interval: 1000
        running: true
        onTriggered: {
            state._initialized = true
            // Initialize tracking values without triggering indicators
            // volumeValue and volumeMuted are now bindings, just sync tracking
            state._lastVolume = state.volumeValue
            state._lastMuted = state.volumeMuted
            state._lastBrightness = Services.BrightnessService.brightness
            state.brightnessValue = state._lastBrightness
            state._lastKbBrightness = Services.KeyboardBacklightService.brightness
            state.kbBrightnessValue = state._lastKbBrightness
            console.log("IndicatorState: Initialized, volume:", state.volumeValue)
        }
    }

    Component.onCompleted: {
        // Restore saved values
        Qt.callLater(restoreSavedValues)
    }

    function restoreSavedValues() {
        // Restore volume
        const savedVolume = Services.ConfigService.getValue("systemState.lastVolume")
        if (savedVolume !== null && savedVolume !== undefined && Pipewire.defaultAudioSink?.audio) {
            console.log("IndicatorState: Restoring volume to", savedVolume)
            Pipewire.defaultAudioSink.audio.volume = savedVolume / 100
        }

        // Restore brightness
        const savedBrightness = Services.ConfigService.getValue("systemState.lastBrightness")
        if (savedBrightness !== null && savedBrightness !== undefined && Services.BrightnessService.available) {
            console.log("IndicatorState: Restoring brightness to", savedBrightness)
            Services.BrightnessService.setBrightness(savedBrightness)
        }

        // Restore keyboard backlight
        const savedKbBrightness = Services.ConfigService.getValue("systemState.lastKbBrightness")
        if (savedKbBrightness !== null && savedKbBrightness !== undefined && Services.KeyboardBacklightService.available) {
            console.log("IndicatorState: Restoring KB backlight to", savedKbBrightness)
            Services.KeyboardBacklightService.setBrightness(savedKbBrightness)
        }
    }

    // Show volume indicator
    function showVolume() {
        if (!_initialized) return
        if (!(Services.ConfigService.getValue("indicators.showVolume") ?? true)) return

        activeIndicator = "volume"
        hideTimer.restart()
    }

    // Show brightness indicator
    function showBrightness() {
        if (!_initialized) return
        if (!(Services.ConfigService.getValue("indicators.showBrightness") ?? true)) return

        activeIndicator = "brightness"
        hideTimer.restart()
    }

    // Show keyboard backlight indicator
    function showKeyboard() {
        if (!_initialized) return
        if (!(Services.ConfigService.getValue("indicators.showKeyboardBacklight") ?? true)) return

        activeIndicator = "keyboard"
        hideTimer.restart()
    }

    // Hide all indicators
    function hide() {
        activeIndicator = ""
        hideTimer.stop()
    }

    // Watch Pipewire volume changes
    Connections {
        target: Pipewire.defaultAudioSink?.audio ?? null

        function onVolumeChanged() {
            const newVolume = state.volumeValue  // Use the binding

            if (state._initialized && Math.abs(newVolume - state._lastVolume) > 0.5) {
                state._lastVolume = newVolume
                // Save to config
                Services.ConfigService.setValue("systemState.lastVolume", Math.round(newVolume))
                Services.ConfigService.saveConfig()
                state.showVolume()
            }
        }

        function onMutedChanged() {
            const newMuted = state.volumeMuted  // Use the binding

            if (state._initialized && newMuted !== state._lastMuted) {
                state._lastMuted = newMuted
                state.showVolume()
            }
        }
    }

    // Watch for default sink changes
    Connections {
        target: Pipewire

        function onDefaultAudioSinkChanged() {
            // Bindings auto-update, just sync tracking values
            state._lastVolume = state.volumeValue
            state._lastMuted = state.volumeMuted
        }
    }

    // Watch brightness changes
    Connections {
        target: Services.BrightnessService

        function onBrightnessChanged() {
            const newBrightness = Services.BrightnessService.brightness
            state.brightnessValue = newBrightness

            if (state._initialized && Math.abs(newBrightness - state._lastBrightness) > 0.5) {
                state._lastBrightness = newBrightness
                // Save to config
                Services.ConfigService.setValue("systemState.lastBrightness", Math.round(newBrightness))
                Services.ConfigService.saveConfig()
                state.showBrightness()
            }
        }
    }

    // Watch keyboard backlight changes
    Connections {
        target: Services.KeyboardBacklightService

        function onBrightnessChanged() {
            const newKbBrightness = Services.KeyboardBacklightService.brightness
            state.kbBrightnessValue = newKbBrightness

            if (state._initialized && Math.abs(newKbBrightness - state._lastKbBrightness) > 0.5) {
                state._lastKbBrightness = newKbBrightness
                // Save to config
                Services.ConfigService.setValue("systemState.lastKbBrightness", Math.round(newKbBrightness))
                Services.ConfigService.saveConfig()
                state.showKeyboard()
            }
        }
    }

    // IPC Handler
    IpcHandler {
        target: "indicators"

        function showIndicator(type: string): string {
            switch(type) {
                case "volume":
                    state.showVolume()
                    return "showing volume"
                case "brightness":
                    state.showBrightness()
                    return "showing brightness"
                case "keyboard":
                    state.showKeyboard()
                    return "showing keyboard"
                default:
                    return "unknown indicator type: " + type
            }
        }

        function hide(): string {
            state.hide()
            return "hidden"
        }

        function status(): string {
            return JSON.stringify({
                active: state.activeIndicator,
                visible: state.visible,
                volume: state.volumeValue,
                volumeMuted: state.volumeMuted,
                brightness: state.brightnessValue,
                kbBrightness: state.kbBrightnessValue
            })
        }
    }

    // Volume icon based on level and mute state
    function getVolumeIcon() {
        if (volumeMuted || volumeValue === 0) return "󰝟"  // speaker-off
        if (volumeValue < 33) return "󰕿"                  // speaker-low
        if (volumeValue < 67) return "󰖀"                  // speaker-medium
        return "󰕾"                                        // speaker-high
    }

    // Brightness icon based on level
    function getBrightnessIcon() {
        return Services.BrightnessService.getIcon()
    }

    // Keyboard backlight icon
    function getKeyboardIcon() {
        return Services.KeyboardBacklightService.getIcon()
    }
}
