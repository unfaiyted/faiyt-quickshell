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

    // Persisted notifications (restored from history)
    property var persistedNotifications: []

    // Combined list for sidebar: live tracked + persisted-only
    readonly property var allNotifications: {
        let combined = []
        let liveIds = new Set()

        // First add all live tracked notifications
        if (server.trackedNotifications && server.trackedNotifications.values) {
            for (let notif of server.trackedNotifications.values) {
                combined.push({
                    id: notif.historyId || "",
                    notification: notif,
                    isLive: true,
                    isPersisted: false,
                    summary: notif.summary,
                    body: notif.body,
                    appName: notif.appName,
                    appIcon: notif.appIcon,
                    image: notif.image,
                    urgency: notif.urgency,
                    actions: notif.actions,
                    time: notif.time,
                    dismiss: () => {
                        notif.tracked = false
                        notif.dismiss()
                    }
                })
                // Track by content for deduplication
                liveIds.add(notif.appName + "|" + notif.summary + "|" + notif.body)
            }
        }

        // Then add persisted notifications that aren't live
        for (let persisted of persistedNotifications) {
            let key = persisted.appName + "|" + persisted.summary + "|" + persisted.body
            if (!liveIds.has(key)) {
                combined.push({
                    id: persisted.id,
                    notification: null,
                    isLive: false,
                    isPersisted: true,
                    summary: persisted.summary,
                    body: persisted.body,
                    appName: persisted.appName,
                    appIcon: persisted.appIcon,
                    image: persisted.image,
                    urgency: persisted.urgency,
                    actions: [],
                    time: new Date(persisted.timestamp),
                    dismiss: () => {
                        Services.NotificationHistoryService.removeNotification(persisted.id)
                    }
                })
            }
        }

        return combined
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

            // Persist the notification to history
            const historyId = Services.NotificationHistoryService.addNotification({
                appName: notification.appName,
                summary: notification.summary,
                body: notification.body,
                appIcon: notification.appIcon,
                image: notification.image,
                urgency: notification.urgency
            })
            notification.historyId = historyId

            // Skip popups if DND is enabled (but still track)
            if (root.doNotDisturb) return

            const notifObj = notifComponent.createObject(root, {
                notification: notification
            })
            root.notifications.push(notifObj)
        }
    }

    // Expose tracked notifications for sidebar
    property alias trackedNotifications: server.trackedNotifications

    // Load persisted notifications on startup
    Connections {
        target: Services.NotificationHistoryService
        function onNotificationsLoaded() {
            root.persistedNotifications = Services.NotificationHistoryService.notifications
        }
        function onNotificationAdded(notification) {
            root.persistedNotifications = Services.NotificationHistoryService.notifications
        }
        function onNotificationRemoved(id) {
            root.persistedNotifications = Services.NotificationHistoryService.notifications
        }
    }

    Component.onCompleted: {
        // If history is already loaded, sync it
        if (Services.NotificationHistoryService.isLoaded) {
            persistedNotifications = Services.NotificationHistoryService.notifications
        }
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

        function remove() {
            const idx = root.notifications.indexOf(notif)
            if (idx !== -1) {
                root.notifications.splice(idx, 1)
            }
        }

        function dismiss() {
            // Remove from history if it has a history ID
            if (notification.historyId) {
                Services.NotificationHistoryService.removeNotification(notification.historyId)
            }
            notification.dismiss()
            remove()
        }

        readonly property Timer timer: Timer {
            // Critical notifications don't auto-expire
            running: notif.urgency !== NotificationUrgency.Critical
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
        return allNotifications.length
    }

    function clearAll() {
        // Clear live notifications
        let notifs = server.trackedNotifications.values
        for (let i = notifs.length - 1; i >= 0; i--) {
            notifs[i].dismiss()
        }
        // Clear persisted history
        Services.NotificationHistoryService.clearAll()
    }

    function clearPopups() {
        while (notifications.length > 0) {
            notifications[0].remove()
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
