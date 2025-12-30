import QtQuick
import QtQuick.Controls
import "../../../theme"
import "../../notifications"

Item {
    id: notifications

    // Use shared notification state
    property bool doNotDisturb: NotificationState.doNotDisturb

    // Helper to get notification count
    function notificationCount() {
        return NotificationState.count()
    }

    // Helper to clear all notifications
    function clearAll() {
        NotificationState.clearAll()
    }

    // Helper to dismiss a single notification
    function dismissNotification(notification) {
        if (notification) {
            notification.tracked = false
            notification.dismiss()
        }
    }

    // Helper to format timestamp
    function formatTime(timestamp) {
        if (!timestamp) return ""
        let now = new Date()
        let diff = Math.floor((now - timestamp) / 1000)

        if (diff < 60) return "Just now"
        if (diff < 3600) return Math.floor(diff / 60) + "m ago"
        if (diff < 86400) return Math.floor(diff / 3600) + "h ago"
        return Math.floor(diff / 86400) + "d ago"
    }

    // Get app icon based on app name
    function getAppIcon(appName) {
        let n = (appName || "").toLowerCase()
        if (n.includes("firefox")) return "󰈹"
        if (n.includes("chrome") || n.includes("chromium")) return ""
        if (n.includes("discord")) return "󰙯"
        if (n.includes("spotify")) return "󰓇"
        if (n.includes("telegram")) return ""
        if (n.includes("slack")) return "󰒱"
        if (n.includes("mail") || n.includes("thunderbird")) return "󰇮"
        if (n.includes("terminal") || n.includes("kitty") || n.includes("alacritty")) return ""
        if (n.includes("code") || n.includes("vscode")) return "󰨞"
        if (n.includes("file") || n.includes("nautilus") || n.includes("thunar")) return "󰉋"
        if (n.includes("screenshot")) return "󰹑"
        if (n.includes("volume") || n.includes("audio") || n.includes("sound")) return "󰕾"
        if (n.includes("brightness")) return "󰃟"
        if (n.includes("battery")) return "󰁹"
        if (n.includes("network") || n.includes("wifi")) return "󰤨"
        if (n.includes("bluetooth")) return "󰂯"
        if (n.includes("update")) return "󰚰"
        return "󰂚"
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Controls bar
        Row {
            width: parent.width
            height: 36
            spacing: 8

            // Notification count
            Text {
                text: notificationCount() > 0 ? notificationCount() + " Notification" + (notificationCount() > 1 ? "s" : "") : "Notifications"
                font.pixelSize: 14
                font.bold: true
                color: Colors.foreground
                anchors.verticalCenter: parent.verticalCenter
            }

            // Spacer
            Item { width: parent.width - 180; height: 1 }

            // Do Not Disturb toggle
            Rectangle {
                width: 32
                height: 32
                radius: 8
                color: dndArea.containsMouse ? Colors.surface : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: notifications.doNotDisturb ? "󰂛" : "󰂚"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 16
                    color: notifications.doNotDisturb ? Colors.error : Colors.foreground
                }

                MouseArea {
                    id: dndArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationState.doNotDisturb = !NotificationState.doNotDisturb
                }
            }

            // Clear all button
            Rectangle {
                width: 32
                height: 32
                radius: 8
                color: clearArea.containsMouse ? Colors.surface : "transparent"
                visible: notificationCount() > 0
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "󰆴"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 16
                    color: Colors.foreground
                }

                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: clearAll()
                }
            }
        }

        // Empty state
        Item {
            width: parent.width
            height: parent.height - 60
            visible: notificationCount() === 0

            Column {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰂚"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 48
                    color: Colors.foregroundMuted
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No notifications"
                    font.pixelSize: 14
                    color: Colors.foregroundMuted
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "You're all caught up!"
                    font.pixelSize: 11
                    color: Colors.foregroundAlt
                }
            }
        }

        // Notification list
        Flickable {
            width: parent.width
            height: parent.height - 50
            clip: true
            contentHeight: notifColumn.height
            boundsBehavior: Flickable.StopAtBounds
            visible: notificationCount() > 0

            ScrollBar.vertical: ScrollBar {
                active: true
                policy: ScrollBar.AsNeeded
            }

            Column {
                id: notifColumn
                width: parent.width
                spacing: 8

                Repeater {
                    model: NotificationState.trackedNotifications

                    Rectangle {
                        id: notifItem
                        width: notifColumn.width
                        height: expanded ? expandedHeight : collapsedHeight
                        radius: 12
                        color: notifArea.containsMouse ? Colors.overlay : Colors.surface
                        clip: true

                        property var notification: modelData
                        property bool expanded: false
                        property int collapsedHeight: 90
                        property int expandedHeight: bodyText.implicitHeight + actionsRow.height + 120

                        Behavior on height {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }

                        // Background click area with z: -1 to stay behind content
                        MouseArea {
                            id: notifArea
                            anchors.fill: parent
                            hoverEnabled: true
                            z: -1
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (notification && (notification.body || (notification.actions && notification.actions.length > 0))) {
                                    notifItem.expanded = !notifItem.expanded
                                }
                            }
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            // Header row
                            Row {
                                width: parent.width
                                spacing: 10

                                // App icon
                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 8
                                    color: Colors.primary

                                    Text {
                                        anchors.centerIn: parent
                                        text: getAppIcon(notification ? notification.appName : "")
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: 18
                                        color: Colors.background
                                    }
                                }

                                // App name and time
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    width: parent.width - 90

                                    Row {
                                        width: parent.width
                                        spacing: 8

                                        Text {
                                            text: notification ? (notification.appName || "App") : "App"
                                            font.pixelSize: 11
                                            color: Colors.foregroundAlt
                                            elide: Text.ElideRight
                                            width: parent.width - 60
                                        }

                                        Text {
                                            text: formatTime(notification ? notification.time : null)
                                            font.pixelSize: 10
                                            color: Colors.foregroundMuted
                                        }
                                    }

                                    Text {
                                        text: notification ? (notification.summary || "") : ""
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: Colors.foreground
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }

                                // Dismiss button
                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 6
                                    color: dismissArea.containsMouse ? Colors.error : "transparent"
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: 14
                                        color: dismissArea.containsMouse ? Colors.background : Colors.foregroundMuted
                                    }

                                    MouseArea {
                                        id: dismissArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            dismissNotification(notification)
                                        }
                                    }
                                }
                            }

                            // Body preview (collapsed)
                            Text {
                                width: parent.width
                                text: notification ? (notification.body || "") : ""
                                font.pixelSize: 11
                                color: Colors.foregroundAlt
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.WordWrap
                                visible: !expanded && (notification ? notification.body : false)
                            }

                            // Full body (expanded)
                            Text {
                                id: bodyText
                                width: parent.width
                                text: notification ? (notification.body || "") : ""
                                font.pixelSize: 11
                                color: Colors.foregroundAlt
                                wrapMode: Text.WordWrap
                                visible: expanded
                            }

                            // Notification image (if present)
                            Image {
                                width: Math.min(parent.width, 200)
                                height: width * 0.6
                                fillMode: Image.PreserveAspectFit
                                source: notification && notification.image ? notification.image : ""
                                visible: expanded && notification && notification.image
                            }

                            // Action buttons
                            Row {
                                id: actionsRow
                                width: parent.width
                                spacing: 8
                                visible: expanded && notification && notification.actions && notification.actions.length > 0

                                Repeater {
                                    model: notification ? notification.actions : []

                                    Rectangle {
                                        width: actionText.width + 20
                                        height: 28
                                        radius: 6
                                        color: actionArea.containsMouse ? Colors.primary : Colors.overlay

                                        Text {
                                            id: actionText
                                            anchors.centerIn: parent
                                            text: modelData ? modelData.text : ""
                                            font.pixelSize: 11
                                            color: actionArea.containsMouse ? Colors.background : Colors.foreground
                                        }

                                        MouseArea {
                                            id: actionArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData) modelData.invoke()
                                            }
                                        }
                                    }
                                }
                            }

                            // Expand indicator
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: expanded ? "󰅃" : "󰅀"
                                font.family: "Symbols Nerd Font"
                                font.pixelSize: 12
                                color: Colors.foregroundMuted
                                visible: notification && (notification.body || (notification.actions && notification.actions.length > 0))
                            }
                        }

                    }
                }
            }
        }
    }
}
