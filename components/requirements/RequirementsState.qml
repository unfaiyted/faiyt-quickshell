pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"

Singleton {
    id: requirementsState

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

    // Check if startup popup should be shown
    function shouldShowOnStartup() {
        return RequirementsService.hasMissingRequired &&
               !ConfigService.getValue("requirements.dontShowOnStartup", false)
    }

    // IPC handler for external control
    IpcHandler {
        target: "requirements"

        function toggle() {
            requirementsState.toggle()
        }

        function open() {
            requirementsState.open()
        }

        function close() {
            requirementsState.close()
        }

        function check() {
            RequirementsService.refresh()
        }
    }
}
