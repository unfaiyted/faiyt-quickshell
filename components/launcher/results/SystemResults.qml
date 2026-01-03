import QtQuick
import Quickshell.Io
import "../../../services" as Services

Item {
    id: systemResults
    visible: false

    property string typeName: "system"
    property var prefixes: ["sys:", "system:"]
    property int maxResults: 10

    // System actions
    property var actions: [
        {
            name: "Shutdown",
            description: "Power off the system",
            icon: "󰐥",
            command: ["systemctl", "poweroff"]
        },
        {
            name: "Reboot",
            description: "Restart the system",
            icon: "󰜉",
            command: ["systemctl", "reboot"]
        },
        {
            name: "Suspend",
            description: "Suspend to RAM",
            icon: "󰤄",
            command: ["systemctl", "suspend"]
        },
        {
            name: "Hibernate",
            description: "Hibernate to disk",
            icon: "󰋊",
            command: ["systemctl", "hibernate"]
        },
        {
            name: "Lock",
            description: "Lock the screen",
            icon: "󰌾",
            command: ["hyprlock"]
        },
        {
            name: "Logout",
            description: "End Hyprland session",
            icon: "󰍃",
            command: ["hyprctl", "dispatch", "exit"]
        }
    ]

    // Execute process
    Process {
        id: actionProcess
        property var cmd: []
        command: cmd
    }

    function search(query, isPrefixSearch) {
        let queryLower = query.toLowerCase().trim()

        let filtered = actions.filter(action => {
            if (!queryLower) return isPrefixSearch

            let searchText = (action.name + " " + action.description).toLowerCase()
            return searchText.includes(queryLower)
        })

        // Sort by relevance + usage boost
        filtered.sort((a, b) => {
            let aStarts = a.name.toLowerCase().startsWith(queryLower)
            let bStarts = b.name.toLowerCase().startsWith(queryLower)

            let aBase = aStarts ? 100 : 50
            let bBase = bStarts ? 100 : 50

            let aBoost = Services.UsageStatsService.getBoostScore("system:" + a.name)
            let bBoost = Services.UsageStatsService.getBoostScore("system:" + b.name)

            let aTotal = aBase + aBoost
            let bTotal = bBase + bBoost

            if (aTotal !== bTotal) return bTotal - aTotal
            return a.name.localeCompare(b.name)
        })

        return filtered.slice(0, maxResults).map((action, index) => ({
            type: "system",
            title: action.name,
            description: action.description,
            icon: action.icon,
            data: action,
            action: function() {
                actionProcess.cmd = action.command
                actionProcess.running = true
            }
        }))
    }
}
