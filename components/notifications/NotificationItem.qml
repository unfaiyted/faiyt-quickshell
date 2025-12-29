pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Notifications
import "../../theme"
import "."

Item {
    id: root

    required property var notif
    required property int notifIndex
    required property bool isActivated

    implicitHeight: childrenRect.height
    implicitWidth: parent?.width ?? 380

    // Stack cards with z-index
    z: 100 - notifIndex

    // Scale down cards when stacked (inactive)
    scale: isActivated ? 1 : Math.max(0.8, 1 - (notifIndex * 0.05))
    clip: true

    Behavior on scale {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: card
        implicitHeight: contentColumn.height
        implicitWidth: parent.width
        radius: 12

        color: Colors.background
        border.color: Colors.border
        border.width: 1

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 0

            // Header row with app name and close button
            RowLayout {
                Layout.preferredHeight: 36
                Layout.margins: 12
                Layout.fillWidth: true

                // App icon
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    radius: 6
                    color: Colors.primary

                    Text {
                        anchors.centerIn: parent
                        text: getAppIcon(root.notif?.appName ?? "")
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 12
                        color: Colors.background
                    }
                }

                // App name
                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 8

                    text: root.notif?.appName ?? "Notification"
                    font.pixelSize: 12
                    font.bold: true
                    color: Colors.foreground
                    elide: Text.ElideRight
                }

                // Close button
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    radius: 6
                    color: closeArea.containsMouse ? Colors.error : Colors.surface

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 12
                        color: closeArea.containsMouse ? Colors.background : Colors.foreground
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.notif) {
                                root.notif.remove()
                            }
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                color: Colors.border
            }

            // Summary (title)
            Text {
                Layout.fillWidth: true
                Layout.margins: 12
                Layout.bottomMargin: root.notif?.body ? 4 : 12

                text: root.notif?.summary ?? ""
                font.pixelSize: 13
                font.bold: true
                color: Colors.foreground
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                visible: text.length > 0
            }

            // Body
            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.bottomMargin: 12
                visible: root.notif?.body?.length > 0

                text: root.notif?.body ?? ""
                font.pixelSize: 11
                color: Colors.foregroundAlt
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
                maximumLineCount: 4
            }

            // Action buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: root.notif?.actions?.length > 0 ? 12 : 0
                Layout.topMargin: 0
                Layout.preferredHeight: root.notif?.actions?.length > 0 ? 32 : 0
                spacing: 8
                visible: root.notif?.actions?.length > 0

                Repeater {
                    model: root.notif?.actions ?? []

                    Rectangle {
                        id: actionBtn
                        required property var modelData

                        Layout.preferredHeight: 28
                        Layout.preferredWidth: actionText.width + 16
                        radius: 6
                        color: actionArea.containsMouse ? Colors.primary : Colors.surface

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: actionBtn.modelData?.text ?? ""
                            font.pixelSize: 11
                            color: actionArea.containsMouse ? Colors.background : Colors.foreground
                        }

                        MouseArea {
                            id: actionArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (actionBtn.modelData) {
                                    actionBtn.modelData.invoke()
                                }
                            }
                        }
                    }
                }
            }

            // Progress bar for auto-dismiss
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 3
                Layout.leftMargin: 2
                Layout.rightMargin: 2
                Layout.bottomMargin: 2
                radius: 2
                color: Colors.overlay
                visible: root.notif?.timer?.running ?? false

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * progress
                    radius: 2
                    color: Colors.primary
                    opacity: 0.6

                    property real progress: 1.0

                    NumberAnimation on progress {
                        from: 1.0
                        to: 0.0
                        duration: root.notif?.timer?.interval ?? 5000
                        running: root.notif?.timer?.running ?? false
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
