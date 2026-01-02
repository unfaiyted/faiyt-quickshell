pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: themePanelState

    property bool panelOpen: false

    function toggle() {
        panelOpen = !panelOpen
    }

    function open() {
        panelOpen = true
    }

    function close() {
        panelOpen = false
    }

    // IPC handler for external control
    IpcHandler {
        target: "theme-panel"

        function toggle() {
            themePanelState.toggle()
        }

        function open() {
            themePanelState.open()
        }

        function close() {
            themePanelState.close()
        }
    }
}
