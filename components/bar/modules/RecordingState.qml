pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: recordingState

    // Recording state
    property bool isRecording: false

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

    // Helper script path for slurp
    property string slurpScriptPath: homeDir + "/codebase/faiyt-qs/scripts/slurp-to-file.sh"

    // Clear temp file before running slurp
    Process {
        id: clearTempFile
        command: ["rm", "-f", "/tmp/qs-slurp-geometry.txt"]

        onExited: function(exitCode, exitStatus) {
            console.log("Cleared temp file, launching slurp via hyprctl...")
            slurpProc.running = true
        }
    }

    // Use hyprctl to run slurp in Hyprland's context
    Process {
        id: slurpProc
        command: ["hyprctl", "dispatch", "exec", slurpScriptPath]

        onExited: function(exitCode, exitStatus) {
            console.log("hyprctl dispatch exited:", exitCode)
            // Wait a moment for slurp to complete and write file
            slurpWaitTimer.start()
        }
    }

    Timer {
        id: slurpWaitTimer
        interval: 100
        repeat: true
        property int attempts: 0

        onTriggered: {
            attempts++
            // Check if geometry file exists and has content
            geometryReader.running = true
            if (attempts > 100) { // 10 second timeout
                console.log("Slurp timeout")
                stop()
            }
        }
    }

    // Read the geometry from temp file
    Process {
        id: geometryReader
        command: ["cat", "/tmp/qs-slurp-geometry.txt"]

        stdout: SplitParser {
            onRead: data => {
                var geo = data.trim()
                if (geo !== "" && geo.indexOf(",") !== -1) {
                    console.log("Got geometry:", geo)
                    slurpWaitTimer.stop()
                    slurpWaitTimer.attempts = 0
                    recordProc.geometry = geo
                }
            }
        }
    }

    // Recording control process
    Process {
        id: recordProc
        property string geometry: ""
        property string action: ""
        // Use wf-recorder directly with geometry, or script for other actions
        command: {
            if (geometry !== "") {
                return ["wf-recorder", "-g", geometry, "-f",
                    homeDir + "/Videos/Recordings/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss") + ".mkv",
                    "-c", "libvpx-vp9", "--pixel-format", "yuv420p"]
            } else if (action !== "") {
                return [scriptPath, "record", action]
            }
            return []
        }

        stdout: SplitParser {
            onRead: data => console.log("recordProc stdout:", data)
        }

        stderr: SplitParser {
            onRead: data => console.log("recordProc stderr:", data)
        }

        onGeometryChanged: {
            if (geometry !== "") {
                console.log("Starting wf-recorder with geometry:", geometry)
                running = true
            }
        }

        onActionChanged: {
            if (action !== "") {
                console.log("Starting recording with action:", action)
                running = true
            }
        }

        onStarted: {
            console.log("recordProc started successfully")
        }

        onExited: function(exitCode, exitStatus) {
            console.log("Recording process exited:", exitCode, exitStatus)
            geometry = ""
            action = ""
        }
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
        console.log("Starting recording:", t)

        if (t === "selection") {
            // Clear temp file and use slurp to get geometry
            console.log("Launching slurp for selection...")
            clearTempFile.running = true
        } else {
            // For monitor targets, use the script directly
            recordProc.action = t
        }
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
