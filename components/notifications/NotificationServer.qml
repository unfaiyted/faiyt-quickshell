pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Hyprland
import Quickshell.Wayland
import "../overview"
import "../../services" as Services

Singleton {
    id: root

    property bool doNotDisturb: false
    property list<Notif> notifications

    // Persisted notifications (restored from history) - newest first.
    // Every incoming notification is written here, so this doubles as the
    // canonical chronological list for the sidebar. Bound directly rather than
    // mirrored through signals, which previously missed clearAll() entirely.
    readonly property var persistedNotifications: Services.NotificationHistoryService.notifications

    // Maps a live Notification's numeric id to its history record id.
    // Notification is a C++ type, so we can't stash the id on the object itself.
    property var historyIds: ({})

    // ---- Display limits -----------------------------------------------------
    // The sidebar only ever builds `displayLimit` delegates. "Show More" grows
    // the window in steps rather than materializing the whole history.
    readonly property int baseLimit: Math.max(1, Services.ConfigService.notificationSidebarLimit)
    property int extraShown: 0
    readonly property int displayLimit: baseLimit + extraShown

    readonly property int totalCount: persistedNotifications.length + orphanLive.length
    readonly property bool hasMore: totalCount > displayLimit

    function showMore() {
        extraShown += Math.max(1, Services.ConfigService.notificationShowMoreStep)
    }

    function resetDisplayLimit() {
        extraShown = 0
    }

    // ---- List construction --------------------------------------------------

    // History id -> live Notification, for the entries that still have actions
    readonly property var liveByHistoryId: {
        const map = ({})
        const tracked = server.trackedNotifications
        if (tracked && tracked.values) {
            for (const notif of tracked.values) {
                const hid = root.historyIds[notif.id]
                if (hid) map[hid] = notif
            }
        }
        return map
    }

    // Live notifications with no history record (only possible if history is
    // unavailable or configured smaller than the tracked limit). Newest first.
    readonly property var orphanLive: {
        const tracked = server.trackedNotifications
        if (!tracked || !tracked.values || tracked.values.length === 0) return []

        const persistedIds = new Set()
        for (const p of root.persistedNotifications) persistedIds.add(p.id)

        const out = []
        for (const notif of tracked.values) {
            const hid = root.historyIds[notif.id]
            if (!hid || !persistedIds.has(hid)) out.push(notif)
        }
        return out.reverse()
    }

    // Only the visible window is turned into delegate-facing objects. This is
    // what keeps a burst of notifications from rebuilding hundreds of them.
    readonly property var visibleNotifications: {
        const limit = root.displayLimit
        const out = []

        for (const notif of root.orphanLive) {
            if (out.length >= limit) return out
            out.push(root.buildLiveEntry(notif))
        }

        const live = root.liveByHistoryId
        for (const record of root.persistedNotifications) {
            if (out.length >= limit) return out
            out.push(root.buildEntry(record, live[record.id] || null))
        }

        return out
    }

    function buildEntry(record, live) {
        return {
            key: record.id,
            id: record.id,
            notification: live,
            isLive: live !== null,
            isPersisted: live === null,
            summary: live ? live.summary : record.summary,
            body: live ? live.body : record.body,
            appName: live ? live.appName : record.appName,
            appIcon: live ? live.appIcon : record.appIcon,
            image: live ? live.image : record.image,
            urgency: live ? live.urgency : record.urgency,
            actions: live ? root.displayActions(live.actions) : [],
            repeatCount: record.count || 1,
            time: new Date(record.timestamp)
        }
    }

    function buildLiveEntry(notif) {
        return {
            key: "live:" + notif.id,
            id: root.historyIds[notif.id] || "",
            notification: notif,
            isLive: true,
            isPersisted: false,
            summary: notif.summary,
            body: notif.body,
            appName: notif.appName,
            appIcon: notif.appIcon,
            image: notif.image,
            urgency: notif.urgency,
            actions: root.displayActions(notif.actions),
            repeatCount: 1,
            time: new Date()
        }
    }

    // Actions worth drawing as buttons. The spec's "default" action is what
    // fires when the notification body itself is clicked - it is not meant to
    // be a button, and senders like Ghostty give it an empty label, which
    // rendered as a blank pill.
    function displayActions(actions) {
        if (!actions) return []
        const out = []
        for (let i = 0; i < actions.length; i++) {
            const a = actions[i]
            if (!a) continue
            if (a.identifier === "default") continue
            if (!a.text || a.text.trim().length === 0) continue
            out.push(a)
        }
        return out
    }

    // Dismiss an entry produced by visibleNotifications
    function dismissEntry(entry) {
        if (!entry) return
        if (entry.id) Services.NotificationHistoryService.removeNotification(entry.id)
        if (entry.notification) {
            entry.notification.tracked = false
            entry.notification.dismiss()
        }
    }

    // Default timeout settings
    readonly property int defaultTimeoutMs: 5000
    readonly property int defaultUrgentTimeoutMs: 10000

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true

            // Persist first: identical notifications inside the dedupe window
            // reuse an existing record instead of adding another row.
            const historyId = Services.NotificationHistoryService.addNotification({
                appName: notification.appName,
                summary: notification.summary,
                body: notification.body,
                appIcon: notification.appIcon,
                image: notification.image,
                urgency: notification.urgency
            })
            root.historyIds[notification.id] = historyId
            root.syncLiveState(notification.id)

            // Skip popups if DND is enabled (but still track)
            if (root.doNotDisturb) return

            // Bound the popup stack - older popups are already in history.
            // Spliced directly rather than looping on remove(), so a stale
            // index can never turn this into a spin.
            const maxPopups = Math.max(1, Services.ConfigService.notificationMaxPopups)
            const overflow = root.notifications.length - maxPopups + 1
            if (overflow > 0) {
                root.notifications.splice(0, overflow)
            }

            const notifObj = notifComponent.createObject(root, {
                notification: notification
            })
            root.notifications.push(notifObj)
        }
    }

    // Expose tracked notifications for sidebar
    property alias trackedNotifications: server.trackedNotifications

    // Drop stale history-id mappings and untrack notifications past the resident
    // limit. Untracked notifications stay visible via their history record, they
    // just stop holding a live object (and their actions) in memory.
    function syncLiveState(keepId) {
        const tracked = server.trackedNotifications
        // Snapshot: untracking mutates trackedNotifications while we walk it
        const values = (tracked && tracked.values) ? [...tracked.values] : []
        const max = Math.max(1, Services.ConfigService.notificationMaxTracked)

        // trackedNotifications is oldest-first, so the head is what ages out
        const excess = values.length - max
        const surviving = ({})

        for (let i = 0; i < values.length; i++) {
            const notif = values[i]
            if (i < excess) {
                notif.tracked = false
                continue
            }
            const hid = root.historyIds[notif.id]
            if (hid) surviving[notif.id] = hid
        }

        // The notification being registered right now may not have landed in
        // trackedNotifications yet - never prune the mapping we just made.
        if (keepId !== undefined && surviving[keepId] === undefined && root.historyIds[keepId]) {
            surviving[keepId] = root.historyIds[keepId]
        }

        root.historyIds = surviving
    }

    // Notification wrapper component
    component Notif: QtObject {
        id: notif
        required property Notification notification

        readonly property string summary: notification.summary
        readonly property string body: notification.body
        readonly property string appIcon: notification.appIcon
        readonly property string appName: notification.appName
        readonly property string image: notification.image
        readonly property int urgency: notification.urgency
        readonly property var actions: notification.actions

        readonly property string imageSource: {
            const img = notification.image ?? ""
            if (!img) return ""
            return img.startsWith("/") ? "file://" + img : img
        }

        // Resolve the image BEFORE the popup is shown. Probing inside the
        // delegate meant the card appeared at one size and resized a beat later,
        // once the decode finished. Same sourceSize as the card's preview so the
        // pixmap is already cached when the delegate asks for it.
        readonly property Image imageProbe: Image {
            source: notif.imageSource
            sourceSize.width: 400
            sourceSize.height: 400
            asynchronous: true
            visible: false
        }

        readonly property real imageAspect: (imageProbe.status === Image.Ready && imageProbe.implicitHeight > 0)
            ? imageProbe.implicitWidth / imageProbe.implicitHeight
            : 0

        property bool probeExpired: false

        // Popups wait for this so they render correct on their first frame
        readonly property bool ready: imageSource === ""
            || imageAspect > 0
            || imageProbe.status === Image.Error
            || probeExpired

        // Never let a slow or broken image hold a notification back for long
        readonly property Timer probeTimer: Timer {
            running: notif.imageSource !== "" && !notif.ready
            interval: 600
            onTriggered: notif.probeExpired = true
        }

        // Flagged first so the card can animate out, then actually dropped.
        // The Column that renders popups has no remove transition of its own.
        property bool removing: false

        function remove() {
            if (notif.removing) return
            notif.removing = true
            removeTimer.start()
        }

        readonly property Timer removeTimer: Timer {
            interval: 200
            onTriggered: {
                const idx = root.notifications.indexOf(notif)
                if (idx !== -1) {
                    root.notifications.splice(idx, 1)
                }
            }
        }

        function dismiss() {
            // Remove from history if it has a history ID
            const historyId = root.historyIds[notification.id]
            if (historyId) {
                Services.NotificationHistoryService.removeNotification(historyId)
            }
            notification.dismiss()
            remove()
        }

        readonly property Timer timer: Timer {
            // Critical notifications don't auto-expire. Held until ready so the
            // dismiss countdown does not run while the popup is still hidden.
            running: notif.ready && notif.urgency !== NotificationUrgency.Critical
            interval: {
                if (notif.notification.expireTimeout > 0) {
                    return notif.notification.expireTimeout
                }
                return root.defaultTimeoutMs
            }
            onTriggered: {
                notif.remove()
            }
        }

        readonly property Connections conn: Connections {
            target: notif.notification.Retainable
            function onDropped(): void {
                const idx = root.notifications.indexOf(notif)
                if (idx !== -1) {
                    root.notifications.splice(idx, 1)
                }
            }
            function onAboutToDestroy(): void {
                notif.destroy()
            }
        }
    }

    Component {
        id: notifComponent
        Notif {}
    }

    // Helper functions
    function count() {
        return totalCount
    }

    function clearAll() {
        // Clear live notifications (snapshot first - dismissing mutates the list)
        const tracked = server.trackedNotifications
        if (tracked && tracked.values) {
            const snapshot = [...tracked.values]
            for (let i = snapshot.length - 1; i >= 0; i--) {
                snapshot[i].dismiss()
            }
        }
        historyIds = ({})
        // Clear persisted history
        Services.NotificationHistoryService.clearAll()
        resetDisplayLimit()
    }

    function clearPopups() {
        if (notifications.length > 0) {
            notifications.splice(0, notifications.length)
        }
    }

    // Focus window by app name/class (reused from SystemTray pattern)
    function focusAppWindow(appName) {
        if (!appName) return false

        HyprlandData.updateWindowList()
        let appLower = appName.toLowerCase().trim()

        let words = appLower.split(/[\s\-_]+/)
        let firstWord = words[0] || appLower
        let lastWord = words[words.length - 1] || appLower

        for (let toplevel of ToplevelManager.toplevels.values) {
            if (!toplevel.HyprlandToplevel) continue
            const address = "0x" + toplevel.HyprlandToplevel.address
            const winData = HyprlandData.windowByAddress[address]
            if (!winData) continue

            let winClass = (winData.class || "").toLowerCase()
            let winTitle = (winData.title || "").toLowerCase()

            if (winClass.includes(appLower) || appLower.includes(winClass) ||
                winClass.includes(firstWord) || winClass.includes(lastWord) ||
                winTitle.includes(appLower) || winTitle.includes(firstWord) ||
                firstWord.includes(winClass) || lastWord.includes(winClass)) {
                Hyprland.dispatch("focuswindow address:" + winData.address)
                return true
            }
        }
        return false
    }
}
