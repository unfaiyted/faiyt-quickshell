import QtQuick
import Quickshell.Io

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
