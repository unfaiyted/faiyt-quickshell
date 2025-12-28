pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "results"

Singleton {
    id: launcherState

    // IPC Handler for external triggering
    IpcHandler {
        target: "launcher"

        function toggle(): string {
            launcherState.toggle()
            return launcherState.visible ? "shown" : "hidden"
        }

        function show(): string {
            launcherState.show()
            return "shown"
        }

        function hide(): string {
            launcherState.hide()
            return "hidden"
        }

        function search(query: string): string {
            launcherState.show()
            launcherState.searchText = query
            return "searching: " + query
        }
    }

    // Evaluator for instant calculations
    Evaluator { id: evaluator }

    // Result providers
    AppResults { id: appResults }
    CommandResults { id: commandResults }
    SystemResults { id: systemResults }

    // Visibility state
    property bool visible: false

    // Search state
    property string searchText: ""
    property int selectedIndex: 0  // 0 = first result
    property string searchType: "ALL"

    // Evaluator result (exposed for LauncherEntry)
    property var evalResult: null

    // Results
    property var results: []
    property int maxResults: 15

    // Debounce timer
    property int debounceDelay: 100

    Timer {
        id: debounceTimer
        interval: launcherState.debounceDelay
        onTriggered: launcherState.performSearch()
    }

    // Search type prefixes
    property var prefixes: {
        "app": ["app:", "apps:", "a:"],
        "command": ["cmd:", "command:", "$:", ">:"],
        "system": ["sys:", "system:"],
        "hyprland": ["h:", "hypr:", "win:", "window:"],
        "directory": ["d:", "dir:", "directory:"],
        "clipboard": ["clip:", "clipboard:", "cb:"],
        "search": ["search:", "!g", "!d", "!c"],
        "screen": ["sc:", "screen:", "screenshot:"],
        "kill": ["kill:", "k:"],
        "prefix": ["?"]
    }

    // Parse search text for prefix
    function parseSearchText(text) {
        let textLower = text.toLowerCase()

        for (let type in prefixes) {
            for (let prefix of prefixes[type]) {
                if (textLower.startsWith(prefix)) {
                    return {
                        type: type.toUpperCase(),
                        query: text.slice(prefix.length).trim(),
                        isPrefixSearch: true
                    }
                }
            }
        }

        return {
            type: "ALL",
            query: text,
            isPrefixSearch: false
        }
    }

    // Trigger debounced search
    onSearchTextChanged: {
        // Evaluate immediately (no debounce for evaluators)
        evalResult = evaluator.evaluate(searchText)
        debounceTimer.restart()
    }

    // Perform actual search
    function performSearch() {
        let parsed = parseSearchText(searchText)
        searchType = parsed.type
        let query = parsed.query
        let isPrefixSearch = parsed.isPrefixSearch

        let allResults = []

        // Search based on type
        if (searchType === "ALL") {
            // Unified search - search all types
            if (query.length >= 1) {
                // Apps first
                let appRes = appResults.search(query, false)
                allResults = allResults.concat(appRes)

                // System actions
                let sysRes = systemResults.search(query, false)
                allResults = allResults.concat(sysRes)
            }

            // Commands - only show if no evaluator result and query looks like a command
            if (query.length > 0 && !evalResult) {
                let cmdRes = commandResults.search(query, false)
                // Only add command if query looks like a command
                if (query.includes(" ") || query.startsWith("!") || query.startsWith("/")) {
                    allResults = allResults.concat(cmdRes)
                }
            }
        } else if (searchType === "APP") {
            allResults = appResults.search(query, isPrefixSearch)
        } else if (searchType === "COMMAND") {
            // Always show commands in explicit command mode
            allResults = commandResults.search(query, isPrefixSearch)
        } else if (searchType === "SYSTEM") {
            allResults = systemResults.search(query, isPrefixSearch)
        }

        // Limit results
        results = allResults.slice(0, maxResults)
        selectedIndex = results.length > 0 ? 0 : -1
    }

    // Navigation
    function selectNext() {
        if (results.length > 0) {
            selectedIndex = (selectedIndex + 1) % results.length
        }
    }

    function selectPrevious() {
        if (results.length > 0) {
            selectedIndex = selectedIndex > 0 ? selectedIndex - 1 : results.length - 1
        }
    }

    function activateSelected() {
        if (selectedIndex >= 0 && selectedIndex < results.length) {
            let result = results[selectedIndex]
            if (result && result.action) {
                result.action()
                hide()
            }
        }
    }

    // Copy to clipboard process
    Process {
        id: copyProcess
        command: ["wl-copy", ""]
    }

    function copyToClipboard(text) {
        copyProcess.command = ["wl-copy", text]
        copyProcess.running = true
    }

    // Copy evaluator result to clipboard
    function copyEvalResult() {
        if (evalResult && evalResult.copyValue) {
            copyToClipboard(evalResult.copyValue)
            return true
        }
        return false
    }

    // Show/hide
    function show() {
        if (!visible) {
            visible = true
            searchText = ""
            selectedIndex = 0
            results = []
            evalResult = null
        }
    }

    function hide() {
        if (visible) {
            visible = false
            searchText = ""
            results = []
            evalResult = null
        }
    }

    function toggle() {
        if (visible) {
            hide()
        } else {
            show()
        }
    }
}
