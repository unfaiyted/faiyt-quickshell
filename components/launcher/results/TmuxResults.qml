import QtQuick
import Quickshell.Io
import "../../../theme"
import "../../../services" as Services

QtObject {
    id: tmuxResults

    property var windows: []
    property bool loaded: false
    property string pendingQuery: ""
    property bool pendingPrefixSearch: false

    // Process for listing tmux windows (all sessions)
    // Using tab as delimiter to avoid issues with colons in session/window names
    property var listProcess: Process {
        command: ["tmux", "list-windows", "-a", "-F", "#{session_name}\t#{window_index}\t#{window_name}\t#{window_active}\t#{session_attached}"]

        stdout: SplitParser {
            onRead: data => {
                let line = data.trim()
                if (!line) return

                let parts = line.split("\t")
                if (parts.length >= 5) {
                    let win = {
                        sessionName: parts[0],
                        windowIndex: parseInt(parts[1]) || 0,
                        windowName: parts[2],
                        isActive: parts[3] === "1",
                        sessionAttached: parts[4] === "1"
                    }
                    tmuxResults.windows.push(win)
                }
            }
        }

        onExited: (code, status) => {
            tmuxResults.loaded = true
            // Trigger a re-search with the pending query
            if (tmuxResults.pendingQuery !== "" || tmuxResults.pendingPrefixSearch) {
                tmuxResults.searchReady()
            }
        }
    }

    // Process for launching kitty with tmux
    property var launchProcess: Process {
        // Command set dynamically before running
    }

    signal searchReady()

    function refresh() {
        windows = []
        loaded = false
        listProcess.running = true
    }

    function search(query, isPrefixSearch) {
        // Always refresh window list on search
        if (!loaded) {
            pendingQuery = query
            pendingPrefixSearch = isPrefixSearch
            refresh()
            return []
        }

        // Reset pending state
        pendingQuery = ""
        pendingPrefixSearch = false

        let results = []
        let lowerQuery = query.toLowerCase().trim()
        let hasExactSessionMatch = false
        let seenSessions = new Set()

        // Filter and map windows to results
        for (let i = 0; i < windows.length; i++) {
            let win = windows[i]
            let sessionLower = win.sessionName.toLowerCase()
            let windowLower = win.windowName.toLowerCase()
            let combinedLower = sessionLower + " " + windowLower

            // Track unique sessions for exact match check
            seenSessions.add(sessionLower)
            if (sessionLower === lowerQuery) {
                hasExactSessionMatch = true
            }

            // Filter by query if provided - match session or window name
            if (lowerQuery && !combinedLower.includes(lowerQuery)) {
                continue
            }

            let sessionName = win.sessionName
            let windowIndex = win.windowIndex
            let target = sessionName + ":" + windowIndex

            // Determine icon and color
            let icon = win.isActive ? "󰖯" : "󰖮"  // active window vs inactive
            let iconColor = win.sessionAttached ? Colors.pine : Colors.foam

            // Capture target in closure
            let capturedTarget = target
            results.push({
                type: "tmux",
                title: win.windowName,
                description: sessionName + " → window " + windowIndex + (win.sessionAttached ? " (attached)" : ""),
                icon: icon,
                iconColor: iconColor,
                data: { target: target, sessionName: sessionName, windowIndex: windowIndex, isNew: false },
                action: function() {
                    launchProcess.command = [Services.ConfigService.terminalCommand, Services.ConfigService.terminalExecFlag, "tmux", "attach", "-t", capturedTarget]
                    launchProcess.running = true
                }
            })
        }

        // Sort existing windows by usage boost (before adding "create new")
        results.sort((a, b) => {
            let aId = "tmux:" + a.data.sessionName + ":" + a.data.windowIndex
            let bId = "tmux:" + b.data.sessionName + ":" + b.data.windowIndex
            let aBoost = Services.UsageStatsService.getBoostScore(aId)
            let bBoost = Services.UsageStatsService.getBoostScore(bId)
            return bBoost - aBoost
        })

        // Add "Create new session" option if query is valid and no exact session match
        if (lowerQuery && !hasExactSessionMatch && isValidSessionName(query.trim())) {
            let newSessionName = query.trim()
            // Capture in closure
            let capturedName = newSessionName
            results.push({
                type: "tmux",
                title: "Create: " + newSessionName,
                description: "New tmux session",
                icon: "󰐕",
                iconColor: Colors.iris,
                data: { sessionName: newSessionName, isNew: true },
                action: function() {
                    launchProcess.command = [Services.ConfigService.terminalCommand, Services.ConfigService.terminalExecFlag, "tmux", "new", "-s", capturedName]
                    launchProcess.running = true
                }
            })
        }

        // If no windows and no query, show helpful message
        if (results.length === 0 && !lowerQuery) {
            results.push({
                type: "tmux",
                title: "No tmux sessions",
                description: "Type a name to create a new session",
                icon: "󰆍",
                iconColor: Colors.foregroundMuted,
                data: {},
                action: function() {}
            })
        }

        return results
    }

    function isValidSessionName(name) {
        // tmux session names can't contain colons or periods, and shouldn't be empty
        if (!name || name.length === 0) return false
        if (name.includes(":") || name.includes(".")) return false
        // Also disallow names starting with dash (could be interpreted as flag)
        if (name.startsWith("-")) return false
        return true
    }
}
