pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "." as Services

Singleton {
    id: historyService

    // Paths - use XDG_DATA_HOME for user data (not config)
    readonly property string dataDir: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/faiyt-qs"
    readonly property string dataFile: dataDir + "/notifications.json"

    // State
    property var notifications: []
    property bool isLoaded: false
    property bool isLoading: false
    property bool isSaving: false

    // Hard cap on persisted records. Keeping this small is what keeps the
    // sidebar list, the JSON payload and the save cost bounded.
    readonly property int maxHistory: Math.max(10, Services.ConfigService.notificationHistoryLimit)

    // Identical notifications arriving inside this window are collapsed into a
    // single record with a repeat count instead of piling up.
    readonly property int dedupeWindowMs: Services.ConfigService.notificationDedupeWindowMs

    // Signals
    signal notificationsLoaded()
    signal notificationAdded(var notification)
    signal notificationUpdated(var notification)
    signal notificationRemoved(string id)

    // Initialize
    Component.onCompleted: {
        ensureDataDir()
    }

    // Re-trim if the configured limit shrinks at runtime
    onMaxHistoryChanged: {
        if (isLoaded && notifications.length > maxHistory) {
            notifications = notifications.slice(0, maxHistory)
            queueSave()
        }
    }

    // Ensure data directory exists
    function ensureDataDir() {
        mkdirProcess.running = true
    }

    Process {
        id: mkdirProcess
        command: ["mkdir", "-p", historyService.dataDir]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                historyService.loadNotifications()
            } else {
                // Without a data dir we still want the shell usable, just unpersisted
                historyService.isLoaded = true
                historyService.notificationsLoaded()
            }
        }
    }

    // Generate UUID
    function generateUUID() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            const r = Math.random() * 16 | 0
            const v = c === 'x' ? r : (r & 0x3 | 0x8)
            return v.toString(16)
        })
    }

    // Load notifications from file
    function loadNotifications() {
        isLoading = true
        loadProcess.buffer = ""
        loadProcess.running = true
    }

    Process {
        id: loadProcess
        command: ["cat", historyService.dataFile]
        property string buffer: ""

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                loadProcess.buffer += data
            }
        }

        onExited: (exitCode, exitStatus) => {
            historyService.isLoading = false

            let loaded = []
            if (exitCode === 0 && loadProcess.buffer.trim()) {
                try {
                    const data = JSON.parse(loadProcess.buffer)
                    loaded = data.notifications || []
                } catch (e) {
                    console.log("NotificationHistoryService: Parse error, starting fresh")
                    loaded = []
                }
            }

            // Notifications that arrived while the file was being read are newer
            // than anything on disk, so they stay in front.
            const pending = historyService.notifications
            if (pending.length > 0) loaded = pending.concat(loaded)

            let trimmed = false
            if (loaded.length > historyService.maxHistory) {
                loaded = loaded.slice(0, historyService.maxHistory)
                trimmed = true
            }

            historyService.notifications = loaded
            historyService.isLoaded = true
            historyService.notificationsLoaded()

            loadProcess.buffer = ""
            // Write the trim back so an oversized file isn't re-parsed every start
            if (trimmed || pending.length > 0) historyService.queueSave()
        }
    }

    // Debounced save - a burst of notifications results in a single write
    Timer {
        id: saveDebounce
        interval: 1000
        repeat: false
        onTriggered: {
            historyService.executeSave()
        }
    }

    function queueSave() {
        saveDebounce.restart()
    }

    function executeSave() {
        if (isSaving) {
            queueSave()
            return
        }

        // Compact JSON piped over stdin: avoids building a multi-megabyte
        // shell command line and re-escaping the whole payload on every save.
        saveProcess.payload = JSON.stringify({
            notifications: notifications,
            savedAt: Date.now()
        })

        isSaving = true
        saveProcess.stdinEnabled = true
        saveProcess.running = true
    }

    Process {
        id: saveProcess
        property string payload: ""
        property string errorOutput: ""

        // Write to a temp file and rename so a crash mid-write can't truncate history
        command: ["bash", "-c", 'cat > "$0.tmp" && mv -f "$0.tmp" "$0"', historyService.dataFile]

        stderr: SplitParser {
            onRead: data => saveProcess.errorOutput += data
        }

        onStarted: {
            write(payload)
            payload = ""
            stdinEnabled = false  // EOF so `cat` finishes
        }

        onExited: (exitCode, exitStatus) => {
            historyService.isSaving = false
            if (exitCode !== 0) {
                console.log("NotificationHistoryService: Save failed -", errorOutput || "exit code " + exitCode)
            }
            errorOutput = ""
        }
    }

    // Add a notification to history.
    // Identical notifications inside the dedupe window bump the existing record
    // instead of creating a new one. Returns the record id either way.
    function addNotification(notifData) {
        const appName = notifData.appName || ""
        const summary = notifData.summary || ""
        const body = notifData.body || ""
        const now = Date.now()

        const dupIdx = findRecentDuplicateIndex(appName, summary, body, now)
        if (dupIdx >= 0) {
            const newList = notifications.slice()
            const existing = newList[dupIdx]
            const updated = Object.assign({}, existing, {
                timestamp: now,
                count: (existing.count || 1) + 1,
                image: notifData.image || existing.image,
                urgency: notifData.urgency !== undefined ? notifData.urgency : existing.urgency
            })
            newList.splice(dupIdx, 1)
            newList.unshift(updated)
            notifications = newList

            notificationUpdated(updated)
            queueSave()
            return updated.id
        }

        const record = {
            id: generateUUID(),
            appName: appName,
            summary: summary,
            body: body,
            appIcon: notifData.appIcon || "",
            image: notifData.image || "",
            urgency: notifData.urgency || 0,
            timestamp: now,
            count: 1,
            persistent: true
        }

        let newList = notifications.slice()
        newList.unshift(record)
        if (newList.length > maxHistory) {
            newList = newList.slice(0, maxHistory)
        }
        notifications = newList

        notificationAdded(record)
        queueSave()

        return record.id
    }

    // Newest-first scan that stops once records fall outside the dedupe window
    function findRecentDuplicateIndex(appName, summary, body, now) {
        if (dedupeWindowMs <= 0) return -1
        for (let i = 0; i < notifications.length; i++) {
            const n = notifications[i]
            if (now - (n.timestamp || 0) > dedupeWindowMs) return -1
            if (n.appName === appName && n.summary === summary && n.body === body) return i
        }
        return -1
    }

    // Remove a notification by ID
    function removeNotification(id) {
        if (!id) return false
        const idx = notifications.findIndex(n => n.id === id)
        if (idx >= 0) {
            let newList = notifications.slice()
            newList.splice(idx, 1)
            notifications = newList
            notificationRemoved(id)
            queueSave()
            return true
        }
        return false
    }

    // Remove several notifications with a single list rebuild and a single save
    function removeNotifications(ids) {
        if (!ids || ids.length === 0) return 0
        const drop = new Set(ids)
        const newList = notifications.filter(n => !drop.has(n.id))
        const removed = notifications.length - newList.length
        if (removed === 0) return 0

        notifications = newList
        for (const id of drop) notificationRemoved(id)
        queueSave()
        return removed
    }

    // Find notification by matching content (for deduplication)
    function findByContent(appName, summary, body) {
        return notifications.find(n =>
            n.appName === appName &&
            n.summary === summary &&
            n.body === body
        )
    }

    // Clear all notifications
    function clearAll() {
        if (notifications.length === 0) return
        notifications = []
        queueSave()
    }

    // Get notification count
    function count() {
        return notifications.length
    }
}
