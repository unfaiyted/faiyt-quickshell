pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: wallpaperState

    // IPC handler for external triggering via `qs ipc call wallpaper <function>`
    IpcHandler {
        target: "wallpaper"

        function toggle(): string {
            wallpaperState.toggle()
            return wallpaperState.visible ? "shown" : "hidden"
        }

        function show(): string {
            wallpaperState.show()
            return "shown"
        }

        function hide(): string {
            wallpaperState.hide()
            return "hidden"
        }
    }

    // Visibility state
    property bool visible: false

    // Configuration
    property string wallpaperDir: "/home/faiyt/Pictures/Wallpapers"
    property var supportedFormats: ["jpg", "jpeg", "png", "webp", "gif", "bmp"]
    property string cacheDir: "/tmp/quickshell/wallpaper-thumbnails"

    // Responsive sizing - set by WallpaperWindow
    property real availableWidth: 1000  // Default, will be set by window
    property int itemSpacing: 12
    property int navButtonWidth: 40
    property int itemPadding: 8  // Padding inside each WallpaperItem

    // Calculate how many items fit and their size
    property int minThumbnailWidth: 180
    property int maxThumbnailWidth: 300
    property int itemsPerPage: {
        // Available space for items = total - nav buttons - margins
        let usableWidth = availableWidth - (navButtonWidth * 2) - 32
        // Each item takes thumbnailWidth + itemPadding + spacing
        let itemWidth = maxThumbnailWidth + itemPadding + itemSpacing
        let count = Math.floor(usableWidth / itemWidth)
        return Math.max(2, Math.min(count, 6))  // Between 2 and 6 items
    }

    property int thumbnailWidth: {
        let usableWidth = availableWidth - (navButtonWidth * 2) - 32
        let totalSpacing = (itemsPerPage - 1) * itemSpacing
        let totalPadding = itemsPerPage * itemPadding
        let availableForThumbs = usableWidth - totalSpacing - totalPadding
        let width = Math.floor(availableForThumbs / itemsPerPage)
        return Math.max(minThumbnailWidth, Math.min(width, maxThumbnailWidth))
    }

    property int thumbnailHeight: Math.round(thumbnailWidth * 9 / 16)  // 16:9 aspect ratio

    // State
    property var wallpapers: []
    property int currentPage: 0
    property int selectedIndex: 0
    property bool isLoading: false

    // Original Hyprland opacity values
    property real originalActiveOpacity: 1.0
    property real originalInactiveOpacity: 1.0

    // Computed properties
    property int totalPages: Math.ceil(wallpapers.length / itemsPerPage)
    property var pageItems: {
        let start = currentPage * itemsPerPage
        return wallpapers.slice(start, start + itemsPerPage)
    }
    property string pageIndicator: totalPages > 0 ? "Page " + (currentPage + 1) + " of " + totalPages : "No wallpapers"

    // Ensure cache directory exists
    Process {
        id: mkdirProcess
        command: ["mkdir", "-p", cacheDir]
    }

    // Load wallpapers from directory
    Process {
        id: loadProcess
        command: ["bash", "-c",
            "find '" + wallpaperDir + "' -maxdepth 1 -type f \\( " +
            supportedFormats.map(f => "-iname '*." + f + "'").join(" -o ") +
            " \\) | sort"
        ]

        property string output: ""

        stdout: SplitParser {
            onRead: data => {
                if (data.trim()) {
                    loadProcess.output += data.trim() + "\n"
                }
            }
        }

        onRunningChanged: {
            if (!running) {
                let paths = loadProcess.output.trim().split("\n").filter(p => p)
                let items = paths.map(path => ({
                    path: path,
                    name: path.split("/").pop(),
                    thumbnail: getThumbnailPath(path)
                }))
                wallpaperState.wallpapers = items
                wallpaperState.isLoading = false
                loadProcess.output = ""

                // Generate thumbnails for current page
                generateThumbnailsForPage()
            }
        }
    }

    // Apply wallpaper with swww
    Process {
        id: swwwProcess
        property string targetPath: ""
        command: ["swww", "img", targetPath,
                  "--transition-type", "fade",
                  "--transition-duration", "0.5",
                  "--resize", "crop"]
    }

    // Get Hyprland active opacity
    Process {
        id: getActiveOpacity
        command: ["hyprctl", "getoption", "decoration:active_opacity"]
        property string output: ""

        stdout: SplitParser {
            onRead: data => {
                getActiveOpacity.output += data
            }
        }

        onRunningChanged: {
            if (!running) {
                let match = getActiveOpacity.output.match(/float:\s*([\d.]+)/)
                if (match) {
                    wallpaperState.originalActiveOpacity = parseFloat(match[1])
                }
                getActiveOpacity.output = ""
            }
        }
    }

    // Get Hyprland inactive opacity
    Process {
        id: getInactiveOpacity
        command: ["hyprctl", "getoption", "decoration:inactive_opacity"]
        property string output: ""

        stdout: SplitParser {
            onRead: data => {
                getInactiveOpacity.output += data
            }
        }

        onRunningChanged: {
            if (!running) {
                let match = getInactiveOpacity.output.match(/float:\s*([\d.]+)/)
                if (match) {
                    wallpaperState.originalInactiveOpacity = parseFloat(match[1])
                }
                getInactiveOpacity.output = ""
            }
        }
    }

    // Set Hyprland opacity
    Process {
        id: setActiveOpacity
        property real value: 1.0
        command: ["hyprctl", "keyword", "decoration:active_opacity", value.toString()]
    }

    Process {
        id: setInactiveOpacity
        property real value: 1.0
        command: ["hyprctl", "keyword", "decoration:inactive_opacity", value.toString()]
    }

    // Thumbnail generation process
    Process {
        id: thumbnailProcess
        property string sourcePath: ""
        property string destPath: ""
        command: ["convert", sourcePath,
                  "-resize", thumbnailWidth + "x" + thumbnailHeight + "^",
                  "-gravity", "center",
                  "-extent", thumbnailWidth + "x" + thumbnailHeight,
                  "-quality", "85",
                  destPath]
    }

    // Helper: Get thumbnail path for a wallpaper
    function getThumbnailPath(wallpaperPath) {
        // Create a simple hash from the path
        let hash = 0
        for (let i = 0; i < wallpaperPath.length; i++) {
            hash = ((hash << 5) - hash) + wallpaperPath.charCodeAt(i)
            hash |= 0
        }
        return cacheDir + "/" + Math.abs(hash).toString(16) + ".jpg"
    }

    // Generate thumbnails for current page
    function generateThumbnailsForPage() {
        mkdirProcess.running = true
        // Thumbnails will be generated on-demand in WallpaperItem
    }

    // Load wallpapers
    function loadWallpapers() {
        isLoading = true
        mkdirProcess.running = true
        loadProcess.running = true
    }

    // Set wallpaper
    function setWallpaper(path) {
        swwwProcess.targetPath = path
        swwwProcess.running = true
    }

    // Navigation functions
    function nextPage() {
        if (currentPage < totalPages - 1) {
            currentPage++
            selectedIndex = currentPage * itemsPerPage
        } else {
            currentPage = 0
            selectedIndex = 0
        }
    }

    function prevPage() {
        if (currentPage > 0) {
            currentPage--
            selectedIndex = currentPage * itemsPerPage
        } else {
            currentPage = totalPages - 1
            selectedIndex = currentPage * itemsPerPage
        }
    }

    function selectNext() {
        if (selectedIndex < wallpapers.length - 1) {
            selectedIndex++
            // Check if we need to go to next page
            if (selectedIndex >= (currentPage + 1) * itemsPerPage) {
                currentPage++
            }
        } else {
            // Wrap to first
            selectedIndex = 0
            currentPage = 0
        }
    }

    function selectPrev() {
        if (selectedIndex > 0) {
            selectedIndex--
            // Check if we need to go to prev page
            if (selectedIndex < currentPage * itemsPerPage) {
                currentPage--
            }
        } else {
            // Wrap to last
            selectedIndex = wallpapers.length - 1
            currentPage = totalPages - 1
        }
    }

    function selectFirst() {
        selectedIndex = 0
        currentPage = 0
    }

    function selectLast() {
        if (wallpapers.length > 0) {
            selectedIndex = wallpapers.length - 1
            currentPage = totalPages - 1
        }
    }

    function applySelected() {
        if (wallpapers.length > 0 && selectedIndex < wallpapers.length) {
            setWallpaper(wallpapers[selectedIndex].path)
        }
    }

    // Timer for delayed opacity dimming
    Timer {
        id: dimOpacityTimer
        interval: 100
        onTriggered: {
            setActiveOpacity.value = 0.2
            setActiveOpacity.running = true
            setInactiveOpacity.value = 0.1
            setInactiveOpacity.running = true
        }
    }

    // Opacity management
    function saveAndDimOpacity() {
        getActiveOpacity.running = true
        getInactiveOpacity.running = true
        // Use timer to ensure hyprctl get commands complete first
        dimOpacityTimer.start()
    }

    function restoreOpacity() {
        dimOpacityTimer.stop()  // Cancel any pending dim
        setActiveOpacity.value = originalActiveOpacity
        setActiveOpacity.running = true
        setInactiveOpacity.value = originalInactiveOpacity
        setInactiveOpacity.running = true
    }

    // Show/hide window
    function show() {
        if (!visible) {
            visible = true
            loadWallpapers()
            saveAndDimOpacity()
        }
    }

    function hide() {
        if (visible) {
            visible = false
            restoreOpacity()
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
