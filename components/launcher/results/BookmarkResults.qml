import QtQuick
import Quickshell.Io
import "../../../services" as Services

Item {
    id: bookmarkResults
    visible: false

    property string typeName: "bookmark"
    property var prefixes: ["bookmark:", "bm:", "b:"]
    property int maxResults: 15

    // Trigger bookmark loading on component creation
    Component.onCompleted: {
        // Access the service to trigger its initialization
        let _ = Services.BookmarkService.isLoaded
    }

    // Open URL process
    Process {
        id: openUrlProcess
        property string url: ""
        command: ["bash", "-c", "setsid " + Services.ConfigService.browserCommand + " '" + url + "' &"]
    }

    function search(query, isPrefixSearch) {
        // Check if bookmark search is enabled
        if (!(Services.ConfigService.getValue("search.enableFeatures.bookmarkSearch") ?? true)) {
            return []
        }

        // Ensure bookmarks are loaded
        if (!Services.BookmarkService.isLoaded) {
            // Trigger load if not already loading
            if (!Services.BookmarkService.isLoading) {
                Services.BookmarkService.loadBookmarks()
            }
            return []
        }

        let queryLower = (query || "").toLowerCase().trim()

        // Get filtered bookmarks from service
        let filtered
        if (!queryLower && isPrefixSearch) {
            // Show recent bookmarks when using prefix with empty query
            filtered = Services.BookmarkService.bookmarks.slice(0, maxResults)
        } else if (!queryLower) {
            return []
        } else {
            filtered = Services.BookmarkService.searchBookmarks(queryLower)
        }

        // Limit results
        filtered = filtered.slice(0, maxResults)

        // Map to result format
        return filtered.map((bookmark, index) => {
            let faviconPath = bookmark.faviconPath || ""
            let showFavicons = Services.ConfigService.getValue("bookmarks.showFavicons") ?? true

            return {
                type: "bookmark",
                title: bookmark.title || bookmark.url,
                description: bookmark.url,
                icon: "󰃀",  // Bookmark icon fallback
                iconImage: showFavicons ? faviconPath : "",
                data: {
                    url: bookmark.url,
                    domain: bookmark.domain,
                    description: bookmark.description
                },
                action: function() {
                    openUrlProcess.url = bookmark.url
                    openUrlProcess.running = true
                }
            }
        })
    }
}
