import QtQuick
import Quickshell
import "../../theme"

// Container for notification popup windows
Item {
    id: popupContainer

    // Create popup windows for each notification
    Repeater {
        model: NotificationState.popupNotifications

        PanelWindow {
            id: popupWindow

            property var notification: modelData
            property int popupIndex: index

            anchors {
                top: true
                right: true
            }

            margins {
                top: 48 + (popupIndex * 90)  // Stack vertically, below bar
                right: 12
            }

            implicitWidth: 380
            implicitHeight: 80
            exclusiveZone: 0
            color: "transparent"

            property real progress: 1.0
            property int dismissDuration: 5000

            // Auto-dismiss timer
            Timer {
                id: dismissTimer
                interval: dismissDuration
                running: true
                onTriggered: {
                    NotificationState.dismissPopup(notification)
                }
            }

            // Progress animation timer
            Timer {
                id: progressTimer
                interval: 50
                running: dismissTimer.running
                repeat: true
                onTriggered: {
                    popupWindow.progress = Math.max(0, popupWindow.progress - (50 / dismissDuration))
                }
            }

            // Reset timer on hover
            function resetTimer() {
                popupWindow.progress = 1.0
                dismissTimer.restart()
            }

            Rectangle {
                id: popupContent
                anchors.fill: parent
                radius: 12
                color: Colors.background
                border.width: 1
                border.color: Colors.border

                // Slide in animation
                x: popupWindow.visible ? 0 : width + 20
                opacity: popupWindow.visible ? 1 : 0

                Behavior on x {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // App icon
                    Rectangle {
                        width: 40
                        height: 40
                        radius: 10
                        color: Colors.primary
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: getAppIcon(notification ? notification.appName : "")
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 20
                            color: Colors.background
                        }
                    }

                    // Content
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        width: parent.width - 120

                        // App name
                        Text {
                            text: notification ? (notification.appName || "Notification") : "Notification"
                            font.pixelSize: 10
                            color: Colors.foregroundAlt
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        // Summary/title
                        Text {
                            text: notification ? (notification.summary || "") : ""
                            font.pixelSize: 13
                            font.bold: true
                            color: Colors.foreground
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        // Body preview
                        Text {
                            text: notification ? (notification.body || "") : ""
                            font.pixelSize: 11
                            color: Colors.foregroundAlt
                            elide: Text.ElideRight
                            width: parent.width
                            maximumLineCount: 1
                        }
                    }

                    // Dismiss button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: dismissArea.containsMouse ? Colors.error : Colors.surface
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 14
                            color: dismissArea.containsMouse ? Colors.background : Colors.foreground
                        }

                        MouseArea {
                            id: dismissArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (notification) {
                                    NotificationState.dismissPopup(notification)
                                }
                            }
                        }
                    }
                }

                // Hover to pause dismiss
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true

                    onEntered: {
                        dismissTimer.stop()
                        progressTimer.stop()
                    }
                    onExited: {
                        popupWindow.progress = 1.0
                        dismissTimer.restart()
                    }

                    // Click to open sidebar (optional)
                    onClicked: function(mouse) {
                        mouse.accepted = false
                    }
                }

                // Progress bar for auto-dismiss
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 2
                    height: 3
                    radius: 2
                    color: Colors.overlay

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * popupWindow.progress
                        radius: 2
                        color: Colors.primary
                        opacity: 0.6
                    }
                }
            }
        }
    }

    // Helper function for app icons
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
}
