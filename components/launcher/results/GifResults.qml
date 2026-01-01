import QtQuick
import Quickshell
import Quickshell.Io
import "../../../theme"

Item {
    id: gifResults
    visible: false

    property string typeName: "gif"
    property int maxResults: 12

    // API key from environment variable
    property string apiKey: Quickshell.env("TENOR_API_KEY") || ""
    property bool hasApiKey: apiKey.length > 0

    // State
    property var cache: ({})
    property string lastQuery: ""
    property var lastResults: []
    property bool isLoading: false
    property string pendingQuery: ""

    // Signal when results are ready (triggers re-search in LauncherState)
    signal resultsReady()

    // Process for API calls
    Process {
        id: fetchProcess
        property string output: ""
        property string queryKey: ""

        stdout: SplitParser {
            onRead: data => {
                fetchProcess.output += data
            }
        }

        onRunningChanged: {
            if (!running && output) {
                parseResponse(output, queryKey)
                output = ""
                isLoading = false
            }
        }
    }

    // Debounce timer for API calls
    Timer {
        id: debounceTimer
        interval: 300
        onTriggered: {
            if (pendingQuery) {
                executeSearch(pendingQuery)
                pendingQuery = ""
            }
        }
    }

    // Copy processes
    Process {
        id: copyUrlProcess
        property string url: ""
        command: ["wl-copy", url]
    }

    Process {
        id: copyImageProcess
        property string url: ""
        command: ["bash", "-c", "curl -s '" + url + "' | wl-copy -t image/gif --fork"]
    }

    // Notification process
    Process {
        id: notifyProcess
        command: ["notify-send", "GIF Copied", ""]
    }

    function search(query, isPrefixSearch) {
        let queryTrimmed = query.trim().toLowerCase()

        // No API key - return helpful setup message
        if (!hasApiKey) {
            return [{
                type: "gif-info",
                title: "GIF Search Setup Required",
                description: "Add a free Tenor API key to search and copy GIFs",
                icon: "󰵸",
                data: { needsSetup: true },
                action: function() {
                    Qt.openUrlExternally("https://developers.google.com/tenor/guides/quickstart")
                }
            }]
        }

        // Empty query with prefix - show trending
        if (!queryTrimmed && isPrefixSearch) {
            if (lastResults.length > 0) {
                return lastResults
            }
            queueSearch("trending")
            return [{
                type: "gif-loading",
                title: "Loading Trending GIFs",
                description: "Fetching popular GIFs from Tenor...",
                icon: "󰋚",
                data: { isLoading: true },
                action: function() {}
            }]
        }

        if (!queryTrimmed) return []

        // Check cache
        let cacheKey = queryTrimmed
        if (cache[cacheKey] && (Date.now() - cache[cacheKey].timestamp) < 300000) {
            return cache[cacheKey].results
        }

        // Return cached results while fetching new
        if (lastQuery === cacheKey && lastResults.length > 0) {
            queueSearch(queryTrimmed)
            return lastResults
        }

        // Queue the search
        queueSearch(queryTrimmed)

        // Return loading state
        return [{
            type: "gif-loading",
            title: "Searching for \"" + query + "\"",
            description: "Looking for matching GIFs...",
            icon: "󰋚",
            data: { isLoading: true },
            action: function() {}
        }]
    }

    function queueSearch(query) {
        pendingQuery = query
        debounceTimer.restart()
    }

    function executeSearch(query) {
        if (isLoading) return

        isLoading = true

        // Build Tenor API URL
        let endpoint = query === "trending"
            ? "https://tenor.googleapis.com/v2/featured"
            : "https://tenor.googleapis.com/v2/search"

        let url = endpoint + "?key=" + apiKey
            + "&q=" + encodeURIComponent(query)
            + "&limit=" + maxResults
            + "&media_filter=gif,tinygif"
            + "&contentfilter=medium"

        fetchProcess.queryKey = query
        fetchProcess.output = ""
        fetchProcess.command = ["curl", "-s", url]
        fetchProcess.running = true
    }

    function parseResponse(response, queryKey) {
        try {
            let data = JSON.parse(response)

            if (data.results && data.results.length > 0) {
                let results = data.results.map(function(gif) {
                    return createResult(gif)
                })

                // Cache results
                cache[queryKey] = {
                    results: results,
                    timestamp: Date.now()
                }

                lastQuery = queryKey
                lastResults = results
                resultsReady()  // Notify that results are ready
            } else {
                lastResults = [{
                    type: "gif-info",
                    title: "No GIFs Found",
                    description: "Try a different search term",
                    icon: "󰋙",
                    data: { isEmpty: true },
                    action: function() {}
                }]
                resultsReady()
            }
        } catch (e) {
            console.log("GifResults: Failed to parse response:", e)
            lastResults = [{
                type: "gif-info",
                title: "Failed to Load GIFs",
                description: "Check your internet connection and try again",
                icon: "󰀦",
                data: { isError: true },
                action: function() {}
            }]
            resultsReady()
        }
    }

    function createResult(gif) {
        let fullUrl = gif.media_formats?.gif?.url || ""
        let previewUrl = gif.media_formats?.tinygif?.url || gif.media_formats?.gif?.url || ""
        let title = gif.content_description || gif.title || "GIF"

        return {
            type: "gif",
            title: title,
            icon: "󰵸",
            data: {
                id: gif.id,
                fullUrl: fullUrl,
                previewUrl: previewUrl,
                title: title
            },
            action: function() {
                // Default action - copy URL
                copyUrl(fullUrl)
            }
        }
    }

    function copyUrl(url) {
        copyUrlProcess.url = url
        copyUrlProcess.command = ["wl-copy", url]
        copyUrlProcess.running = true

        notifyProcess.command = ["notify-send", "GIF Copied", "URL copied to clipboard"]
        notifyProcess.running = true
    }

    function copyImage(url) {
        copyImageProcess.url = url
        copyImageProcess.command = ["bash", "-c", "curl -s '" + url + "' | wl-copy -t image/gif --fork"]
        copyImageProcess.running = true

        notifyProcess.command = ["notify-send", "GIF Copied", "Image copied to clipboard"]
        notifyProcess.running = true
    }
}
