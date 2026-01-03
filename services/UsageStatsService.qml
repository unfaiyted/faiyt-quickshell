pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: usageStatsService

    // Paths - use XDG_DATA_HOME for user data (not config)
    readonly property string dataDir: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/faiyt-qs"
    readonly property string statsFile: dataDir + "/usage-stats.json"

    // In-memory stats (fast lookups during search)
    property var stats: ({})
    property bool isLoaded: false
    property bool isSaving: false

    // Scoring configuration
    readonly property real recencyHalfLifeHours: 168  // 1 week - time for recency score to decay to 50%
    readonly property real maxFrequencyBoost: 50      // Maximum boost from frequency
    readonly property real maxRecencyBoost: 50        // Maximum boost from recency
    readonly property real frequencyWeight: 0.6       // Weight for frequency vs recency
    readonly property real recencyWeight: 0.4         // Weight for recency vs frequency

    // Initialize
    Component.onCompleted: {
        ensureDataDir()
    }

    // Ensure data directory exists
    function ensureDataDir() {
        mkdirProcess.running = true
    }

    Process {
        id: mkdirProcess
        command: ["mkdir", "-p", usageStatsService.dataDir]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                usageStatsService.loadStats()
            }
        }
    }

    // Load stats from file
    function loadStats() {
        loadProcess.buffer = ""
        loadProcess.running = true
    }

    Process {
        id: loadProcess
        command: ["cat", usageStatsService.statsFile]
        property string buffer: ""

        stdout: SplitParser {
            splitMarker: ""  // Read all data
            onRead: data => {
                loadProcess.buffer += data
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && loadProcess.buffer.trim()) {
                try {
                    const data = JSON.parse(loadProcess.buffer)
                    usageStatsService.stats = data || {}
                    usageStatsService.isLoaded = true
                    console.log("UsageStatsService: Loaded", Object.keys(usageStatsService.stats).length, "items")
                } catch (e) {
                    console.log("UsageStatsService: Parse error, starting fresh")
                    usageStatsService.stats = {}
                    usageStatsService.isLoaded = true
                }
            } else {
                // No file or empty, start fresh
                usageStatsService.stats = {}
                usageStatsService.isLoaded = true
            }

            loadProcess.buffer = ""
        }
    }

    // Record usage of an item
    function recordUsage(itemId) {
        if (!itemId) return

        let now = Date.now()
        let newStats = Object.assign({}, stats)

        if (!newStats[itemId]) {
            newStats[itemId] = {
                count: 0,
                lastUsed: now,
                firstUsed: now
            }
        }

        newStats[itemId].count++
        newStats[itemId].lastUsed = now

        // Trigger property change for bindings
        stats = newStats

        // Queue debounced save
        queueSave()
    }

    // Calculate boost score for an item (0-100)
    function getBoostScore(itemId) {
        if (!itemId || !stats[itemId]) return 0

        let item = stats[itemId]
        let now = Date.now()

        // Frequency score: logarithmic scaling to prevent runaway scores
        // log2(count + 1) normalized to maxFrequencyBoost
        let freqScore = Math.min(Math.log2(item.count + 1) * 10, maxFrequencyBoost)

        // Recency score: exponential decay based on time since last use
        let hoursSinceUse = (now - item.lastUsed) / (1000 * 60 * 60)
        let recencyScore = maxRecencyBoost * Math.pow(0.5, hoursSinceUse / recencyHalfLifeHours)

        // Combined weighted score
        return (freqScore * frequencyWeight) + (recencyScore * recencyWeight)
    }

    // Debounced save
    Timer {
        id: saveDebounce
        interval: 2000  // Save every 2 seconds max
        repeat: false
        onTriggered: {
            usageStatsService.executeSave()
        }
    }

    function queueSave() {
        saveDebounce.restart()
    }

    function executeSave() {
        if (isSaving) {
            // Re-queue if already saving
            queueSave()
            return
        }

        const jsonStr = JSON.stringify(stats, null, 2)
        // Escape for shell
        const escaped = jsonStr.replace(/'/g, "'\\''")

        saveProcess.command = ["bash", "-c", "echo '" + escaped + "' > '" + statsFile + "'"]
        isSaving = true
        saveProcess.running = true
    }

    Process {
        id: saveProcess
        property string errorOutput: ""
        stderr: SplitParser {
            onRead: data => saveProcess.errorOutput += data
        }
        onExited: (exitCode, exitStatus) => {
            usageStatsService.isSaving = false
            if (exitCode !== 0) {
                console.log("UsageStatsService: Save failed -", errorOutput || "exit code " + exitCode)
            }
            errorOutput = ""
        }
    }

    // Get usage count for an item (for debugging/display)
    function getUsageCount(itemId) {
        if (!itemId || !stats[itemId]) return 0
        return stats[itemId].count
    }

    // Clear all stats (for debugging)
    function clearStats() {
        stats = {}
        queueSave()
    }
}
