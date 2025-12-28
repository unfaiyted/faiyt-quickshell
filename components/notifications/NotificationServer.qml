pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Singleton notification server - only one can exist
Singleton {
    id: notificationState

    property bool doNotDisturb: false
    property var popupNotifications: []

    // The actual notification server
    NotificationServer {
        id: server

        onNotification: notification => {
            // Always track notifications for the panel
            notification.tracked = true

            // Add to popup queue if not in DND mode
            if (!notificationState.doNotDisturb) {
                let popups = notificationState.popupNotifications.slice()
                popups.unshift(notification)
                // Limit to 5 popups at a time
                if (popups.length > 5) {
                    popups = popups.slice(0, 5)
                }
                notificationState.popupNotifications = popups
            }
        }
    }

    // Expose the tracked notifications
    property alias trackedNotifications: server.trackedNotifications

    // Remove a notification from popup list
    function dismissPopup(notification) {
        let popups = notificationState.popupNotifications.filter(n => n !== notification)
        notificationState.popupNotifications = popups
    }

    // Clear all popups
    function clearPopups() {
        notificationState.popupNotifications = []
    }

    // Get notification count
    function count() {
        return server.trackedNotifications.values.length
    }

    // Clear all tracked notifications
    function clearAll() {
        let notifs = server.trackedNotifications.values
        for (let i = notifs.length - 1; i >= 0; i--) {
            notifs[i].dismiss()
        }
    }
}
