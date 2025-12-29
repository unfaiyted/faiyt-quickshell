pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

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
            running: true
            interval: {
                if (notif.notification.expireTimeout > 0) {
                    return notif.notification.expireTimeout
                }
                if (notif.urgency === NotificationUrgency.Critical) {
                    return root.defaultUrgentTimeoutMs
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
}
