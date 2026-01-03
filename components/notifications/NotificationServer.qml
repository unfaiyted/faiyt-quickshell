pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Hyprland
import Quickshell.Wayland
import "../overview"

Singleton {
    id: root

    property bool doNotDisturb: false
    property list<Notif> notifications

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
        return server.trackedNotifications.values.length
    }

    function clearAll() {
        let notifs = server.trackedNotifications.values
        for (let i = notifs.length - 1; i >= 0; i--) {
            notifs[i].dismiss()
        }
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
