pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: recordingState

    // Recording state
    property bool isRecording: false

    // Recording mode: "record", "record-hq", "record-gif"
    property string recordingMode: "record"

    // Script path - using home directory
    property string homeDir: Quickshell.env("HOME") || "/home/faiyt"
    property string scriptPath: homeDir + "/codebase/faiyt-qs/scripts/screen-capture.sh"

    Component.onCompleted: {
        console.log("RecordingState initialized, script path:", scriptPath)
    }

    // IPC Handler for external control
    IpcHandler {
        target: "recording"

        function toggle(): string {
            recordingState.toggle()
            return recordingState.isRecording ? "recording" : "stopped"
        }

        function start(target: string): string {
            recordingState.start(target || "selection")
            return "started: " + (target || "selection")
        }

        function stop(): string {
            recordingState.stop()
            return "stopped"
        }

        function status(): string {
            return recordingState.isRecording ? "recording" : "idle"
        }

        function setMode(mode: string): string {
            if (mode === "record" || mode === "record-hq" || mode === "record-gif") {
                recordingState.recordingMode = mode
                return "mode set to: " + mode
            }
            return "invalid mode: " + mode
        }

        function getMode(): string {
            return recordingState.recordingMode
        }
    }

    // Poll recording status every 500ms
    Timer {
        id: statusTimer
        interval: 500
        running: true
        repeat: true
        onTriggered: recordingState.checkStatus()
    }

    // Status check process (using pgrep directly for speed)
    Process {
        id: statusProc
        command: ["pgrep", "-x", "wf-recorder"]

        onExited: function(exitCode, exitStatus) {
            // exitCode 0 means process found (recording active)
            // exitCode 1 means process not found (not recording)
            recordingState.isRecording = (exitCode === 0)
        }
    }

    // Recording control process - uses hyprctl dispatch exec to run script
    // This ensures slurp runs in the proper Hyprland context
    Process {
        id: recordProc

        stdout: SplitParser {
            onRead: data => console.log("recordProc stdout:", data)
        }

        stderr: SplitParser {
            onRead: data => console.log("recordProc stderr:", data)
        }

        onStarted: {
            console.log("recordProc started")
        }

        onExited: function(exitCode, exitStatus) {
            console.log("Recording dispatch exited:", exitCode, exitStatus)
        }
    }

    function launchRecording(target) {
        var cmd = scriptPath + " " + recordingMode + " " + target
        console.log("Launching recording command:", cmd)
        recordProc.command = ["hyprctl", "dispatch", "exec", cmd]
        recordProc.running = true
    }

    // Check if recording is active
    function checkStatus() {
        if (!statusProc.running) {
            statusProc.running = true
        }
    }

    // Toggle recording (start selection if not recording, stop if recording)
    function toggle() {
        if (isRecording) {
            stop()
        } else {
            start("selection")
        }
    }

    // Start recording with specified target
    function start(target) {
        if (isRecording) {
            console.log("Already recording, ignoring start")
            return
        }

        var t = target || "selection"
        console.log("Starting recording:", recordingMode, t)
        launchRecording(t)
    }

    // Stop recording process
    Process {
        id: stopProc
        command: ["pkill", "-INT", "-x", "wf-recorder"]

        onExited: function(exitCode, exitStatus) {
            console.log("Stop process exited:", exitCode)
        }
    }

    // Stop recording
    function stop() {
        if (!isRecording) {
            console.log("Not recording, ignoring stop")
            return
        }

        console.log("Stopping recording")
        stopProc.running = true
    }
}
