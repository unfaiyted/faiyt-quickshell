pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "results"
import "../../services" as Services

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

    // Re-evaluate when async evaluator results are ready
    Connections {
        target: evaluator
        function onAsyncResultReady() {
            console.log("LauncherState: Received asyncResultReady, visible:", launcherState.visible, "searchText:", launcherState.searchText)
            if (launcherState.visible && launcherState.searchText.length > 0) {
                launcherState.evalResult = evaluator.evaluate(launcherState.searchText)
                console.log("LauncherState: Re-evaluated, result:", JSON.stringify(launcherState.evalResult))
            }
        }
    }

    // Result providers
    AppResults { id: appResults }
    CommandResults { id: commandResults }
    SystemResults { id: systemResults }
    WindowResults { id: windowResults }
    EmojiResults { id: emojiResults }
    StickerResults { id: stickerResults }
    GifResults { id: gifResults }
    TmuxResults { id: tmuxResults }
    QuickActionResults { id: quickActionResults }

    // Re-trigger search when GIF results are ready (async)
    Connections {
        target: gifResults
        function onResultsReady() {
            if (launcherState.searchType === "GIF" && launcherState.visible) {
                launcherState.performSearch()
            }
        }
    }

    // Re-trigger search when tmux results are ready (async)
    Connections {
        target: tmuxResults
        function onSearchReady() {
            if (launcherState.searchType === "TMUX" && launcherState.visible) {
                launcherState.performSearch()
            }
        }
    }

    // Visibility state
    property bool visible: false

    // Search state
    property string searchText: ""
    property string lastSearchText: ""  // Saved search for restoration on reopen
    property int selectedIndex: 0  // 0 = first result
    property string searchType: "ALL"

    // Evaluator result (exposed for LauncherEntry)
    property var evalResult: null

    // Results
    property var results: []
    property int maxResults: isGridMode ? 48 : 15  // More results for grid modes (emoji/sticker)

    // Debounce timer
    property int debounceDelay: 100

    Timer {
        id: debounceTimer
        interval: launcherState.debounceDelay
        onTriggered: launcherState.performSearch()
    }

    // Delayed action timer - allows keyboard focus to release before action
    Timer {
        id: actionTimer
        interval: 50
        property var pendingAction: null
        onTriggered: {
            if (pendingAction) pendingAction()
            pendingAction = null
        }
    }

    // Search type prefixes
    property var prefixes: {
        "app": ["app:", "apps:", "a:"],
        "command": ["cmd:", "command:", "$:", ">:"],
        "system": ["sys:", "system:"],
        "window": ["win:", "window:", "w:"],
        "emoji": ["emoji:", "em:", ":"],
        "sticker": ["sticker:", "st:", "s:"],
        "gif": ["gif:", "g:"],
        "tmux": ["tmux:", "t:"],
        "directory": ["d:", "dir:", "directory:"],
        "clipboard": ["clip:", "clipboard:", "cb:"],
        "search": ["search:", "!g", "!d", "!c"],
        "screen": ["sc:", "screen:", "screenshot:"],
        "kill": ["kill:", "k:"],
        "prefix": ["?"]
    }

    // Grid mode state (emoji, stickers, and gifs use grid view)
    property bool isEmojiMode: searchType === "EMOJI"
    property bool isStickerMode: searchType === "STICKER"
    property bool isGifMode: searchType === "GIF"
    property bool isGifCategoryMode: isGifMode && results.length > 0 && results[0].type === "gif-category"
    property bool isGridMode: isEmojiMode || isStickerMode || isGifMode
    property int gridColumns: isGifCategoryMode ? 3 : (isGifMode ? 4 : 6)  // 3 for gif categories, 4 for gifs, 6 for emoji/sticker
    property string viewMode: isGridMode ? "grid" : "list"

    // Sticker pack bar navigation state
    property bool packBarFocused: false
    property int selectedPackIndex: -1  // -1 = "All", 0+ = pack index

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

        // Reset pack bar focus when not in sticker mode
        if (searchType !== "STICKER") {
            packBarFocused = false
            selectedPackIndex = -1
        }

        let allResults = []

        // Search based on type
        if (searchType === "ALL") {
            // Unified search - search all types
            if (query.length >= 1) {
                // Apps first
                let appRes = appResults.search(query, false)
                allResults = allResults.concat(appRes)

                // Quick Actions (panels, toggles, media, bar modes)
                let quickRes = quickActionResults.search(query, false)
                allResults = allResults.concat(quickRes)

                // Windows
                let winRes = windowResults.search(query, false)
                allResults = allResults.concat(winRes)

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
        } else if (searchType === "WINDOW") {
            allResults = windowResults.search(query, isPrefixSearch)
        } else if (searchType === "EMOJI") {
            allResults = emojiResults.search(query, isPrefixSearch)
        } else if (searchType === "STICKER") {
            allResults = stickerResults.search(query, isPrefixSearch)
        } else if (searchType === "GIF") {
            allResults = gifResults.search(query, isPrefixSearch)
        } else if (searchType === "TMUX") {
            if (Services.ConfigService.getValue("search.enableFeatures.tmuxSearch") ?? true) {
                allResults = tmuxResults.search(query, isPrefixSearch)
            }
        }

        // Global sort by usage boost for unified search
        if (searchType === "ALL" && allResults.length > 1) {
            allResults.sort((a, b) => {
                let aId = getItemId(a)
                let bId = getItemId(b)
                let aBoost = aId ? Services.UsageStatsService.getBoostScore(aId) : 0
                let bBoost = bId ? Services.UsageStatsService.getBoostScore(bId) : 0
                return bBoost - aBoost
            })
        }

        // Limit results
        results = allResults.slice(0, maxResults)
        selectedIndex = results.length > 0 ? 0 : -1
    }

    // Navigation
    function selectNext() {
        if (packBarFocused && isStickerMode) {
            // Move from pack bar to grid
            packBarFocused = false
            selectedIndex = 0
            return
        }

        if (results.length > 0) {
            if (isGridMode) {
                // In grid mode, down moves to next row
                let newIndex = selectedIndex + gridColumns
                if (newIndex < results.length) {
                    selectedIndex = newIndex
                }
            } else {
                selectedIndex = (selectedIndex + 1) % results.length
            }
        }
    }

    function selectPrevious() {
        if (packBarFocused && isStickerMode) {
            // Already at pack bar, can't go up further
            return
        }

        if (results.length > 0) {
            if (isGridMode) {
                // In grid mode, up moves to previous row
                let newIndex = selectedIndex - gridColumns
                if (newIndex >= 0) {
                    selectedIndex = newIndex
                } else if (isStickerMode && Services.StickerService.stickerPacks.length > 0) {
                    // At top row in sticker mode, move to pack bar
                    packBarFocused = true
                }
            } else {
                selectedIndex = selectedIndex > 0 ? selectedIndex - 1 : results.length - 1
            }
        }
    }

    // Grid navigation for grid modes (emoji/sticker)
    function selectLeft() {
        if (packBarFocused && isStickerMode) {
            // Navigate left in pack bar (-1 = All, 0+ = pack index)
            if (selectedPackIndex > -1) {
                selectedPackIndex = selectedPackIndex - 1
            }
            return
        }

        if (results.length > 0 && selectedIndex > 0) {
            selectedIndex = selectedIndex - 1
        }
    }

    function selectRight() {
        if (packBarFocused && isStickerMode) {
            // Navigate right in pack bar
            const maxIndex = Services.StickerService.stickerPacks.length - 1
            if (selectedPackIndex < maxIndex) {
                selectedPackIndex = selectedPackIndex + 1
            }
            return
        }

        if (results.length > 0 && selectedIndex < results.length - 1) {
            selectedIndex = selectedIndex + 1
        }
    }

    // Activate pack in pack bar
    function activatePackBarSelection() {
        if (!packBarFocused || !isStickerMode) return

        const packId = selectedPackIndex === -1 ? "" : Services.StickerService.stickerPacks[selectedPackIndex]?.id || ""
        Services.StickerService.selectedPackId = packId
        Services.StickerService.selectPack(packId)
        performSearch()
        packBarFocused = false
        selectedIndex = 0
    }

    function activateSelected() {
        if (selectedIndex >= 0 && selectedIndex < results.length) {
            let result = results[selectedIndex]

            // Handle GIF category selection - don't hide, update search instead
            if (result?.type === "gif-category" && result?.data?.searchTerm) {
                searchText = "gif: " + result.data.searchTerm
                return
            }

            // Record usage for tracking (before action execution)
            let itemId = getItemId(result)
            if (itemId) {
                Services.UsageStatsService.recordUsage(itemId)
            }

            if (result && result.action) {
                actionTimer.pendingAction = result.action
                hide()  // Hide first to release keyboard focus
                actionTimer.start()  // Execute action after delay
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

    // Generate unique item ID for usage tracking
    function getItemId(result) {
        if (!result) return null

        switch (result.type) {
            case "app":
                return "app:" + (result.data?.filePath || result.title)
            case "quickaction":
                return "quickaction:" + (result.category || "unknown") + ":" + result.title
            case "system":
                return "system:" + result.title
            case "emoji":
                return "emoji:" + (result.emoji || result.title)
            case "sticker":
                return "sticker:" + (result.data?.packId || "") + ":" + (result.data?.id || result.title)
            case "gif":
                return "gif:" + (result.data?.id || result.title)
            case "tmux":
                // Don't track "create new session" option
                if (result.data?.isNew) return null
                return "tmux:" + (result.data?.sessionName || "") + ":" + (result.data?.windowIndex ?? 0)
            case "cmd":
                return "cmd:" + hashString(result.data?.command || result.title)
            case "window":
                return null  // Windows are ephemeral, don't track
            default:
                return null
        }
    }

    // Simple hash for command identification
    function hashString(str) {
        let hash = 0
        for (let i = 0; i < str.length; i++) {
            hash = ((hash << 5) - hash) + str.charCodeAt(i)
            hash |= 0
        }
        return hash.toString(16)
    }

    // Show/hide
    function show() {
        if (!visible) {
            visible = true
            // Restore last search text (will be selected in LauncherEntry)
            // This triggers onSearchTextChanged which re-evaluates automatically
            searchText = lastSearchText
            selectedIndex = 0
            // If we have a previous search, re-run it
            if (searchText.length > 0) {
                performSearch()
            } else {
                results = []
            }
        }
    }

    function hide() {
        if (visible) {
            // Save current search for restoration on next open
            lastSearchText = searchText
            visible = false
            searchText = ""
            results = []
            evalResult = null
            packBarFocused = false
            selectedPackIndex = -1
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
