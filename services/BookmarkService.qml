pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: bookmarkService

    // State
    property var bookmarks: []              // [{title, url, description, domain, faviconPath}]
    property bool isLoading: false
    property bool isLoaded: false
    property string detectedBrowser: ""     // "zen", "firefox", or ""
    property string detectedProfilePath: ""

    // Paths
    readonly property string homeDir: Quickshell.env("HOME") || "/home"
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || homeDir + "/.cache") + "/faiyt-qs/favicons"
    readonly property string tempDir: "/tmp/faiyt-qs-bookmarks"

    // Browser profile paths
    readonly property string zenProfilesIni: homeDir + "/.zen/profiles.ini"
    readonly property string firefoxProfilesIni: homeDir + "/.mozilla/firefox/profiles.ini"

    // Favicon fetching
    property var faviconQueue: []           // Domains waiting to be fetched
    property var faviconCache: ({})         // {domain: faviconPath}
    property bool isFetchingFavicon: false

    Component.onCompleted: {
        ensureDirs()
        detectBrowser()
    }

    // Ensure cache directories exist
    function ensureDirs() {
        mkdirProcess.running = true
    }

    Process {
        id: mkdirProcess
        command: ["mkdir", "-p", bookmarkService.cacheDir, bookmarkService.tempDir]
    }

    // Detect browser profile
    function detectBrowser() {
        let browserType = ConfigService.getValue("bookmarks.browserType") || "auto"
        let customPath = ConfigService.getValue("bookmarks.profilePath") || ""

        if (customPath) {
            // Use custom profile path
            detectedProfilePath = customPath
            detectedBrowser = customPath.includes(".zen") ? "zen" : "firefox"
            loadBookmarks()
            return
        }

        if (browserType === "zen" || browserType === "auto") {
            // Try Zen first
            detectZenProfile()
        } else if (browserType === "firefox") {
            detectFirefoxProfile()
        }
    }

    // Read Zen profiles.ini
    Process {
        id: zenProfilesProcess
        property string output: ""
        command: ["cat", bookmarkService.zenProfilesIni]

        stdout: SplitParser {
            onRead: data => zenProfilesProcess.output += data + "\n"
        }

        onRunningChanged: {
            if (!running) {
                if (output.trim()) {
                    let profilePath = parseProfilesIni(output, homeDir + "/.zen")
                    if (profilePath) {
                        bookmarkService.detectedBrowser = "zen"
                        bookmarkService.detectedProfilePath = profilePath
                        bookmarkService.loadBookmarks()
                    } else {
                        // Zen not found, try Firefox
                        detectFirefoxProfile()
                    }
                } else {
                    // Zen not found, try Firefox
                    detectFirefoxProfile()
                }
                output = ""
            }
        }
    }

    function detectZenProfile() {
        zenProfilesProcess.output = ""
        zenProfilesProcess.running = true
    }

    // Read Firefox profiles.ini
    Process {
        id: firefoxProfilesProcess
        property string output: ""
        command: ["cat", bookmarkService.firefoxProfilesIni]

        stdout: SplitParser {
            onRead: data => firefoxProfilesProcess.output += data + "\n"
        }

        onRunningChanged: {
            if (!running) {
                if (output.trim()) {
                    let profilePath = parseProfilesIni(output, homeDir + "/.mozilla/firefox")
                    if (profilePath) {
                        bookmarkService.detectedBrowser = "firefox"
                        bookmarkService.detectedProfilePath = profilePath
                        bookmarkService.loadBookmarks()
                    } else {
                        console.log("BookmarkService: No valid Firefox profile found")
                    }
                } else {
                    console.log("BookmarkService: No Firefox profiles.ini found")
                }
                output = ""
            }
        }
    }

    function detectFirefoxProfile() {
        firefoxProfilesProcess.output = ""
        firefoxProfilesProcess.running = true
    }

    // Parse profiles.ini to find default profile path
    function parseProfilesIni(content, basePath) {
        let lines = content.split("\n")
        let profiles = []
        let currentProfile = null
        let installDefault = ""  // Path from [Install*] section

        for (let line of lines) {
            line = line.trim()

            if (line.startsWith("[Profile")) {
                if (currentProfile) {
                    profiles.push(currentProfile)
                }
                currentProfile = {}
            } else if (line.startsWith("[Install")) {
                // Save current profile before switching to Install section
                if (currentProfile) {
                    profiles.push(currentProfile)
                }
                currentProfile = null
            } else if (line.startsWith("[")) {
                // Any other section
                if (currentProfile) {
                    profiles.push(currentProfile)
                }
                currentProfile = null
            } else if (line.includes("=")) {
                let eqIdx = line.indexOf("=")
                let key = line.substring(0, eqIdx).trim()
                let value = line.substring(eqIdx + 1).trim()

                if (currentProfile) {
                    currentProfile[key] = value
                } else if (key === "Default") {
                    // This is likely from [Install*] section - it contains the actual default path
                    installDefault = value
                }
            }
        }

        if (currentProfile) {
            profiles.push(currentProfile)
        }

        // Priority 1: Use Install section's Default path (most reliable)
        if (installDefault) {
            return basePath + "/" + installDefault
        }

        // Priority 2: Find profile with Default=1
        for (let profile of profiles) {
            if (profile.Default === "1" && profile.Path) {
                let path = profile.IsRelative === "1"
                    ? basePath + "/" + profile.Path
                    : profile.Path
                return path
            }
        }

        // Fallback: find profile with .default in path
        for (let profile of profiles) {
            if (profile.Path && (profile.Path.includes(".default") || profile.Path.includes("Default"))) {
                let path = profile.IsRelative === "1"
                    ? basePath + "/" + profile.Path
                    : profile.Path
                return path
            }
        }

        return null
    }

    // Load bookmarks from database
    function loadBookmarks() {
        if (isLoading || !detectedProfilePath) return

        isLoading = true
        console.log("BookmarkService: Loading bookmarks from", detectedProfilePath)

        // Copy database to temp location to avoid lock
        copyDbProcess.running = true
    }

    // Refresh bookmarks (force reload)
    function refreshBookmarks() {
        isLoaded = false
        loadBookmarks()
    }

    // Copy places.sqlite to temp location
    Process {
        id: copyDbProcess
        command: ["cp", bookmarkService.detectedProfilePath + "/places.sqlite",
                  bookmarkService.tempDir + "/places.sqlite"]

        onRunningChanged: {
            if (!running) {
                // Query the copied database
                queryBookmarksProcess.running = true
            }
        }
    }

    // Query bookmarks from SQLite
    Process {
        id: queryBookmarksProcess
        property string output: ""
        command: ["sqlite3", "-separator", "|||",
                  bookmarkService.tempDir + "/places.sqlite",
                  "SELECT b.title, p.url, p.description FROM moz_bookmarks b " +
                  "JOIN moz_places p ON b.fk = p.id " +
                  "WHERE b.type = 1 AND p.url NOT LIKE 'place:%' " +
                  "ORDER BY b.dateAdded DESC"]

        stdout: SplitParser {
            onRead: data => queryBookmarksProcess.output += data + "\n"
        }

        onRunningChanged: {
            if (!running) {
                parseBookmarkResults(output)
                output = ""
            }
        }
    }

    // Parse SQLite results
    function parseBookmarkResults(output) {
        let results = []
        let lines = output.trim().split("\n")

        for (let line of lines) {
            if (!line.trim()) continue

            let parts = line.split("|||")
            if (parts.length >= 2) {
                let title = parts[0] || ""
                let url = parts[1] || ""
                let description = parts[2] || ""

                if (url && url.startsWith("http")) {
                    let domain = extractDomain(url)
                    results.push({
                        title: title || url,
                        url: url,
                        description: description,
                        domain: domain,
                        faviconPath: getFaviconPath(domain)
                    })
                }
            }
        }

        bookmarks = results
        isLoading = false
        isLoaded = true
        console.log("BookmarkService: Loaded", bookmarks.length, "bookmarks")

        // Queue favicon fetches for bookmarks
        if (ConfigService.getValue("bookmarks.showFavicons") ?? true) {
            queueFaviconFetches()
        }
    }

    // Extract domain from URL
    function extractDomain(url) {
        try {
            let match = url.match(/^https?:\/\/([^\/]+)/)
            return match ? match[1].replace(/^www\./, "") : ""
        } catch (e) {
            return ""
        }
    }

    // Get favicon path for domain
    function getFaviconPath(domain) {
        if (!domain) return ""

        // Check cache
        if (faviconCache[domain]) {
            return faviconCache[domain]
        }

        // Generate expected path
        let hash = hashDomain(domain)
        let path = cacheDir + "/" + hash + ".ico"
        return path
    }

    // Simple hash for domain
    function hashDomain(domain) {
        let hash = 0
        for (let i = 0; i < domain.length; i++) {
            hash = ((hash << 5) - hash) + domain.charCodeAt(i)
            hash |= 0
        }
        return Math.abs(hash).toString(16)
    }

    // Queue favicon fetches for all bookmarks
    function queueFaviconFetches() {
        let domains = new Set()
        for (let bookmark of bookmarks) {
            if (bookmark.domain && !faviconCache[bookmark.domain]) {
                domains.add(bookmark.domain)
            }
        }

        faviconQueue = Array.from(domains)
        processNextFavicon()
    }

    // Process favicon queue
    function processNextFavicon() {
        if (isFetchingFavicon || faviconQueue.length === 0) return

        let domain = faviconQueue.shift()
        fetchFavicon(domain)
    }

    // Fetch favicon for a domain
    function fetchFavicon(domain) {
        isFetchingFavicon = true
        faviconFetchProcess.domain = domain
        faviconFetchProcess.outputPath = cacheDir + "/" + hashDomain(domain) + ".ico"
        faviconFetchProcess.running = true
    }

    Process {
        id: faviconFetchProcess
        property string domain: ""
        property string outputPath: ""
        command: ["curl", "-s", "-m", "5", "-L", "-o", outputPath,
                  "https://icons.duckduckgo.com/ip3/" + domain + ".ico"]

        onRunningChanged: {
            if (!running) {
                // Cache the path
                bookmarkService.faviconCache[domain] = outputPath

                // Update bookmarks with new favicon path
                let updated = bookmarkService.bookmarks.map(b => {
                    if (b.domain === domain) {
                        return Object.assign({}, b, {faviconPath: outputPath})
                    }
                    return b
                })
                bookmarkService.bookmarks = updated

                bookmarkService.isFetchingFavicon = false

                // Process next in queue with small delay
                faviconTimer.start()
            }
        }
    }

    Timer {
        id: faviconTimer
        interval: 100
        onTriggered: processNextFavicon()
    }

    // Check if favicon exists
    function checkFaviconExists(domain) {
        if (!domain) return false
        return faviconCache.hasOwnProperty(domain)
    }

    // Search bookmarks
    function searchBookmarks(query) {
        if (!isLoaded || !query) return bookmarks.slice(0, 20)

        let queryLower = query.toLowerCase()
        let results = []

        for (let bookmark of bookmarks) {
            let score = 0
            let titleLower = (bookmark.title || "").toLowerCase()
            let urlLower = (bookmark.url || "").toLowerCase()
            let descLower = (bookmark.description || "").toLowerCase()

            // Scoring
            if (titleLower === queryLower) {
                score = 100
            } else if (titleLower.startsWith(queryLower)) {
                score = 80
            } else if (titleLower.includes(queryLower)) {
                score = 60
            } else if (urlLower.includes(queryLower)) {
                score = 40
            } else if (descLower.includes(queryLower)) {
                score = 20
            }

            if (score > 0) {
                results.push({bookmark: bookmark, score: score})
            }
        }

        // Sort by score descending
        results.sort((a, b) => b.score - a.score)

        return results.map(r => r.bookmark)
    }
}
