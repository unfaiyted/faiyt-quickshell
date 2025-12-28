pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: sidebarState

    // IPC handler for external triggering via `qs ipc -p ~/codebase/faiyt-qs call sidebar <function>`
    IpcHandler {
        target: "sidebar"

        function toggleLeft(): string {
            sidebarState.toggleLeft()
            return sidebarState.leftOpen ? "left-open" : "left-closed"
        }

        function toggleRight(): string {
            sidebarState.toggleRight()
            return sidebarState.rightOpen ? "right-open" : "right-closed"
        }

        function showLeft(): string {
            sidebarState.rightOpen = false
            sidebarState.leftOpen = true
            return "left-open"
        }

        function showRight(): string {
            sidebarState.leftOpen = false
            sidebarState.rightOpen = true
            return "right-open"
        }

        function hideLeft(): string {
            sidebarState.leftOpen = false
            return "left-closed"
        }

        function hideRight(): string {
            sidebarState.rightOpen = false
            return "right-closed"
        }

        function closeAll(): string {
            sidebarState.closeAll()
            return "all-closed"
        }
    }

    property bool leftOpen: false
    property bool rightOpen: false

    function toggleLeft() {
        rightOpen = false  // Close other sidebar
        leftOpen = !leftOpen
    }

    function toggleRight() {
        leftOpen = false  // Close other sidebar
        rightOpen = !rightOpen
    }

    function closeAll() {
        leftOpen = false
        rightOpen = false
    }
}
