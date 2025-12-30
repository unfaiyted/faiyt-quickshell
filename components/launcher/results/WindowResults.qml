import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../../services"
import "../../overview"

Item {
    id: windowResults
    visible: false

    property string typeName: "window"
    property var prefixes: ["win:", "window:", "w:"]
    property int maxResults: 10

    // Search open windows
    function search(query, isPrefixSearch) {
        // Refresh window data
        HyprlandData.updateWindowList()

        let results = []
        let queryLower = query.toLowerCase().trim()

        for (let toplevel of ToplevelManager.toplevels.values) {
            const address = "0x" + toplevel.HyprlandToplevel.address
            const winData = HyprlandData.windowByAddress[address]
            if (!winData) continue

            // Build search text from window properties
            let searchText = (
                (winData.title || "") + " " +
                (winData.class || "") + " " +
                "workspace " + (winData.workspace?.id || "")
            ).toLowerCase()

            // Filter by query (if query exists)
            if (queryLower && !searchText.includes(queryLower)) continue

            // If no query and not prefix search, skip (don't show all windows in general search)
            if (!queryLower && !isPrefixSearch) continue

            // Use winData.address directly from hyprctl output (correct format for dispatch)
            const windowAddress = winData.address

            results.push({
                type: "window",
                title: winData.title || "Untitled",
                description: (winData.class || "Unknown") + " • Workspace " + (winData.workspace?.id || "?"),
                icon: IconService.getIcon(winData.class || ""),
                data: {
                    toplevel: toplevel,
                    winData: winData,
                    address: windowAddress
                },
                action: function() {
                    focusWindow(windowAddress)
                }
            })
        }

        // Sort by focus history (most recently focused first)
        results.sort((a, b) => {
            const aFocus = a.data.winData.focusHistoryID || 999999
            const bFocus = b.data.winData.focusHistoryID || 999999
            return aFocus - bFocus
        })

        return results.slice(0, maxResults)
    }

    // Focus a window by address
    function focusWindow(address) {
        Hyprland.dispatch("focuswindow address:" + address)
    }
}
