import QtQuick
import Quickshell.Io
import "../../../services" as Services

Item {
    id: commandResults
    visible: false

    property string typeName: "command"
    property var prefixes: ["cmd:", "command:", "$:", ">:"]
    property int maxResults: 10

    // Command history (in-memory)
    property var history: []
    property int maxHistory: 20

    // Execute process
    Process {
        id: commandProcess
        property string cmd: ""
        property bool useTerminal: false
        command: useTerminal ?
            ["kitty", "-e", "bash", "-c", cmd + "; echo ''; echo 'Press Enter to close...'; read"] :
            ["bash", "-c", cmd]
    }

    function search(query, isPrefixSearch) {
        let queryTrimmed = query.trim()

        // Check for terminal prefix (!)
        let useTerminal = queryTrimmed.startsWith("!")
        let cmd = useTerminal ? queryTrimmed.slice(1).trim() : queryTrimmed

        let results = []

        // If we have a command, show it as the first result
        if (cmd) {
            results.push({
                type: "cmd",
                title: cmd,
                description: useTerminal ? "Run in terminal" : "Run command",
                icon: useTerminal ? "" : "󰘳",
                data: { command: cmd, terminal: useTerminal },
                action: function() {
                    executeCommand(cmd, useTerminal)
                }
            })
        }

        // Show matching history items
        if (history.length > 0) {
            let historyMatches = history.filter(h => {
                if (!cmd) return true
                return h.command.toLowerCase().includes(cmd.toLowerCase())
            })

            // Sort history by usage boost
            historyMatches.sort((a, b) => {
                let aBoost = Services.UsageStatsService.getBoostScore("cmd:" + hashString(a.command))
                let bBoost = Services.UsageStatsService.getBoostScore("cmd:" + hashString(b.command))
                return bBoost - aBoost
            })

            for (let h of historyMatches.slice(0, maxResults - results.length)) {
                // Don't duplicate the current command
                if (h.command === cmd) continue

                results.push({
                    type: "cmd",
                    title: h.command,
                    description: "From history" + (h.terminal ? " (terminal)" : ""),
                    icon: "󰋚",
                    data: h,
                    action: function() {
                        executeCommand(h.command, h.terminal)
                    }
                })
            }
        }

        return results.slice(0, maxResults)
    }

    function executeCommand(cmd, terminal) {
        // Add to history
        addToHistory(cmd, terminal)

        // Execute
        commandProcess.cmd = cmd
        commandProcess.useTerminal = terminal
        commandProcess.running = true
    }

    function addToHistory(cmd, terminal) {
        // Remove if already exists
        history = history.filter(h => h.command !== cmd)

        // Add to front
        history.unshift({ command: cmd, terminal: terminal })

        // Trim to max size
        if (history.length > maxHistory) {
            history = history.slice(0, maxHistory)
        }
    }

    // Simple hash for command identification (matches LauncherState.hashString)
    function hashString(str) {
        let hash = 0
        for (let i = 0; i < str.length; i++) {
            hash = ((hash << 5) - hash) + str.charCodeAt(i)
            hash |= 0
        }
        return hash.toString(16)
    }
}
