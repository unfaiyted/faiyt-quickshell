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

    // Category state
    property var categories: []
    property bool categoriesLoaded: false
    property bool categoriesLoading: false

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

    // Process for fetching categories
    Process {
        id: categoryProcess
        property string output: ""

        stdout: SplitParser {
            onRead: data => {
                categoryProcess.output += data
            }
        }

        onRunningChanged: {
            if (!running && output) {
                parseCategoryResponse(output)
                output = ""
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

        // Empty query with prefix - show categories
        if (!queryTrimmed && isPrefixSearch) {
            // If categories are loaded, return them
            if (categoriesLoaded && categories.length > 0) {
                return categories
            }

            // If not loading yet, start fetching categories
            if (!categoriesLoading) {
                fetchCategories()
            }

            // Return loading state
            return [{
                type: "gif-loading",
                title: "Loading Categories",
                description: "Fetching GIF categories from Tenor...",
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

    // Fetch categories from Tenor API
    function fetchCategories() {
        if (categoriesLoading || !hasApiKey) return

        categoriesLoading = true

        let url = "https://tenor.googleapis.com/v2/categories"
            + "?key=" + apiKey
            + "&type=featured"
            + "&contentfilter=medium"

        categoryProcess.output = ""
        categoryProcess.command = ["curl", "-s", url]
        categoryProcess.running = true
    }

    // Parse category response from Tenor API
    function parseCategoryResponse(response) {
        categoriesLoading = false

        try {
            let data = JSON.parse(response)

            if (data.tags && data.tags.length > 0) {
                categories = data.tags.map(function(cat) {
                    // Extract search term from the path (e.g., "https://...?q=happy" -> "happy")
                    let searchTerm = cat.searchterm || cat.name || ""

                    return {
                        type: "gif-category",
                        title: cat.name || "Category",
                        icon: "󰷊",
                        data: {
                            name: cat.name,
                            image: cat.image,
                            searchTerm: searchTerm
                        },
                        action: function() {
                            // This will be handled by GifGridView to trigger a search
                        }
                    }
                })

                categoriesLoaded = true
                resultsReady()
            } else {
                console.log("GifResults: No categories in response")
                categoriesLoaded = true
                categories = []
                resultsReady()
            }
        } catch (e) {
            console.log("GifResults: Failed to parse categories:", e)
            categoriesLoaded = true
            categories = []
            resultsReady()
        }
    }

    // Search by category - called when user selects a category
    function searchCategory(searchTerm) {
        if (!searchTerm) return

        // Clear category state so we show GIF results
        lastQuery = ""
        lastResults = []

        // Queue the search
        queueSearch(searchTerm)

        // Return the search term so LauncherState can update searchText
        return searchTerm
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
