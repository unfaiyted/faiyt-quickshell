pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../../services"

Singleton {
    id: screenshotState

    // Annotation mode enabled - initialized from config
    property bool annotateEnabled: ConfigService.screenshotAnnotateEnabled

    // Script path
    property string homeDir: Quickshell.env("HOME") || "/home/faiyt"
    property string scriptPath: homeDir + "/codebase/faiyt-qs/scripts/screen-capture.sh"

    // Save annotate mode to config when changed
    onAnnotateEnabledChanged: {
        if (ConfigService.getValue("utilities.screenshot.annotateEnabled") !== annotateEnabled) {
            ConfigService.setValue("utilities.screenshot.annotateEnabled", annotateEnabled)
            ConfigService.saveConfig()
        }
    }

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
