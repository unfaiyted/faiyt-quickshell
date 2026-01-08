import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../../../theme"
import "../../../components/settings"
import "../../common"
import ".."

Item {
    id: header

    implicitHeight: 72
    implicitWidth: parent.width

    property string username: "User"
    property string hostname: "localhost"
    property string uptime: ""
    property int userId: 1000
    property string profilePicture: ""

    // Get username
    Process {
        id: userProcess
        command: ["whoami"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                header.username = data.trim()
            }
        }
    }

    // Get user ID for AccountsService query
    Process {
        id: uidProcess
        command: ["id", "-u"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                header.userId = parseInt(data.trim())
                iconProcess.running = true
            }
        }
    }

    // Get profile picture from AccountsService via D-Bus
    Process {
        id: iconProcess
        command: ["bash", "-c",
            "busctl --system get-property org.freedesktop.Accounts " +
            "/org/freedesktop/Accounts/User" + header.userId + " " +
            "org.freedesktop.Accounts.User IconFile 2>/dev/null | " +
            "sed 's/s //' | tr -d '\"'"
        ]

        stdout: SplitParser {
            onRead: data => {
                let path = data.trim()
                if (path && path.length > 0) {
                    header.profilePicture = "file://" + path
                }
            }
        }
    }

    // Get hostname
    Process {
        id: hostProcess
        command: ["hostname"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                header.hostname = data.trim()
            }
        }
    }

    // Get uptime
    Process {
        id: uptimeProcess
        command: ["uptime", "-p"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                // Remove "up " prefix and clean up
                let result = data.trim().replace(/^up\s+/, "")
                // Shorten: "2 hours, 30 minutes" -> "2h 30m"
                result = result.replace(/\s*hours?/, "h")
                result = result.replace(/\s*minutes?/, "m")
                result = result.replace(/\s*days?/, "d")
                result = result.replace(/,\s*/g, " ")
                header.uptime = result
            }
        }
    }

    // Refresh uptime every 60s
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: uptimeProcess.running = true
    }

    Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Avatar with border
        Rectangle {
            width: 48
            height: 48
            radius: 24
            color: "transparent"
            border.width: 2
            border.color: Colors.primary

            // Profile picture with circular mask
            Item {
                id: avatarContainer
                anchors.centerIn: parent
                width: 42
                height: 42
                visible: header.profilePicture !== "" && profileImage.status === Image.Ready

                Image {
                    id: profileImage
                    anchors.fill: parent
                    source: header.profilePicture
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    sourceSize.width: 84
                    sourceSize.height: 84
                    visible: false  // Hidden, rendered through mask
                    layer.enabled: true
                }

                // Circular mask
                Rectangle {
                    id: avatarMask
                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                    layer.enabled: true
                }

                OpacityMask {
                    anchors.fill: parent
                    source: profileImage
                    maskSource: avatarMask
                }
            }

            // Letter fallback (when no profile picture)
            Rectangle {
                anchors.centerIn: parent
                width: 42
                height: 42
                radius: 21
                color: Colors.primary
                visible: header.profilePicture === "" || profileImage.status !== Image.Ready

                Text {
                    anchors.centerIn: parent
                    text: header.username.charAt(0).toUpperCase()
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.xlarge
                    font.bold: true
                    color: Colors.background
                }
            }
        }

        // User info
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: header.username
                font.family: Fonts.ui
                font.pixelSize: Fonts.medium
                font.bold: true
                color: Colors.foreground
            }

            Text {
                text: "@" + header.hostname
                font.family: Fonts.ui
                font.pixelSize: Fonts.small
                color: Colors.foregroundAlt
            }

            Text {
                text: header.uptime
                font.family: Fonts.ui
                font.pixelSize: Fonts.tiny
                color: Colors.foregroundMuted
                visible: header.uptime !== ""
            }
        }

        // Spacer
        Item {
            width: parent.width - 240
            height: 1
        }

        // Action buttons
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Settings button
            Rectangle {
                id: settingsBtn
                width: 36
                height: 36
                radius: 8
                color: settingsArea.containsMouse ? Colors.surface : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰒓"
                    font.family: Fonts.icon
                    font.pixelSize: Fonts.xlarge
                    color: Colors.foreground
                }

                MouseArea {
                    id: settingsArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SettingsState.toggle()
                }

                HintTarget {
                    targetElement: settingsBtn
                    scope: "sidebar-right"
                    action: () => SettingsState.toggle()
                }
            }

            // Power button
            Rectangle {
                id: powerBtn
                width: 36
                height: 36
                radius: 8
                color: powerArea.containsMouse ? Colors.surface : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰐥"
                    font.family: Fonts.icon
                    font.pixelSize: Fonts.xlarge
                    color: Colors.error
                }

                MouseArea {
                    id: powerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SidebarState.togglePowerMenu()
                }

                HintTarget {
                    targetElement: powerBtn
                    scope: "sidebar-right"
                    action: () => SidebarState.togglePowerMenu()
                }
            }
        }
    }

    // Power menu popup (at root level for proper window anchoring)
    PowerMenu {
        id: powerMenu
        anchor.window: QsWindow.window
        anchor.onAnchoring: {
            const pos = powerBtn.mapToItem(QsWindow.window.contentItem, 0, powerBtn.height)
            anchor.rect = Qt.rect(pos.x - 120, pos.y + 4, powerBtn.width, 1)
        }
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Top
        anchorItem: powerBtn
    }

    // Bottom border
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Colors.border
    }
}
