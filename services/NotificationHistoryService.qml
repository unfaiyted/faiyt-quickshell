pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

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

    // Signals
    signal notificationsLoaded()
    signal notificationAdded(var notification)
    signal notificationRemoved(string id)

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
        command: ["mkdir", "-p", historyService.dataDir]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                historyService.loadNotifications()
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

            if (exitCode === 0 && loadProcess.buffer.trim()) {
                try {
                    const data = JSON.parse(loadProcess.buffer)
                    historyService.notifications = data.notifications || []
                    historyService.isLoaded = true
                    historyService.notificationsLoaded()
                } catch (e) {
                    console.log("NotificationHistoryService: Parse error, starting fresh")
                    historyService.notifications = []
                    historyService.isLoaded = true
                }
            } else {
                // No file or empty, start fresh
                historyService.notifications = []
                historyService.isLoaded = true
            }

            loadProcess.buffer = ""
        }
    }

    // Debounced save
    Timer {
        id: saveDebounce
        interval: 500
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

        const data = {
            notifications: notifications,
            savedAt: Date.now()
        }

        const jsonStr = JSON.stringify(data, null, 2)
        const escaped = jsonStr.replace(/'/g, "'\\''")

        saveProcess.command = ["bash", "-c", "echo '" + escaped + "' > '" + dataFile + "'"]
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
            historyService.isSaving = false
            if (exitCode !== 0) {
                console.log("NotificationHistoryService: Save failed -", errorOutput || "exit code " + exitCode)
            }
            errorOutput = ""
        }
    }

    // Add a notification to history
    function addNotification(notifData) {
        const record = {
            id: generateUUID(),
            appName: notifData.appName || "",
            summary: notifData.summary || "",
            body: notifData.body || "",
            appIcon: notifData.appIcon || "",
            image: notifData.image || "",
            urgency: notifData.urgency || 0,
            timestamp: Date.now(),
            persistent: true
        }

        let newList = notifications.slice()
        newList.unshift(record)
        notifications = newList

        notificationAdded(record)
        queueSave()

        return record.id
    }

    // Remove a notification by ID
    function removeNotification(id) {
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
        notifications = []
        queueSave()
    }

    // Get notification count
    function count() {
        return notifications.length
    }
}
