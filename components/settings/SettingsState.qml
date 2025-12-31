pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: settingsState

    property bool settingsOpen: false

    function toggle() {
        settingsOpen = !settingsOpen
    }

    function open() {
        settingsOpen = true
    }

    function close() {
        settingsOpen = false
    }

    // IPC handler for external control
    IpcHandler {
        target: "settings"

        function toggle() {
            settingsState.toggle()
        }

        function open() {
            settingsState.open()
        }

        function close() {
            settingsState.close()
        }
    }
}
