pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: screenshotState

    // Annotation mode enabled
    property bool annotateEnabled: false

    // Script path
    property string homeDir: Quickshell.env("HOME") || "/home/faiyt"
    property string scriptPath: homeDir + "/codebase/faiyt-qs/scripts/screen-capture.sh"

    // Screenshot process
    Process {
        id: captureProc

        onExited: function(exitCode, exitStatus) {
            console.log("Screenshot exited:", exitCode)
        }
    }

    // Take screenshot with current mode
    function capture() {
        var mode = annotateEnabled ? "annotate" : "screenshot"
        var cmd = scriptPath + " " + mode + " selection"
        console.log("Capturing screenshot:", cmd)
        captureProc.command = ["hyprctl", "dispatch", "exec", cmd]
        captureProc.running = true
    }
}
