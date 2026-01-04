import QtQuick
import QtQuick.Layouts
import "../../theme"
import "."

Rectangle {
    id: monitorsPanel

    width: 900
    height: 600
    radius: 20
    color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.85)
    border.width: 1
    border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)

    focus: true
    Keys.onEscapePressed: MonitorsState.close()

    // Prevent click-through
    MouseArea {
        anchors.fill: parent
        onClicked: (mouse) => mouse.accepted = true
    }

    // Shadow layers
    Rectangle {
        anchors.fill: parent
        anchors.margins: -30
        z: -1
        radius: parent.radius + 10
        color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.3)
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -15
        z: -1
        radius: parent.radius + 5
        color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.4)
    }

    Column {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            width: parent.width
            height: 56
            color: "transparent"

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20

                Text {
                    text: "Display Configuration"
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    color: Colors.foreground
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: 1; Layout.fillWidth: true }

                // Close button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: closeArea.containsMouse ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.5) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 16
                        color: closeArea.containsMouse ? Colors.foreground : Colors.foregroundAlt
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MonitorsState.close()
                    }
                }
            }
        }

        // Monitor Canvas
        MonitorCanvas {
            id: canvas
            width: parent.width
            height: 340
        }

        // Monitor Settings (collapsible)
        MonitorSettings {
            id: settingsPanel
            width: parent.width
        }

        // Action buttons
        Rectangle {
            width: parent.width
            height: 64
            color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.05)

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)
            }

            Row {
                anchors.centerIn: parent
                anchors.right: parent.right
                anchors.rightMargin: 20
                spacing: 12
                layoutDirection: Qt.RightToLeft

                // Apply button (primary)
                Rectangle {
                    width: applyRow.width + 24
                    height: 36
                    radius: 8
                    color: MonitorsState.hasChanges
                        ? (applyArea.containsMouse ? Colors.primary : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.8))
                        : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                    opacity: MonitorsState.hasChanges ? 1.0 : 0.5

                    Row {
                        id: applyRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "Apply"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: MonitorsState.hasChanges ? Colors.background : Colors.foregroundMuted
                        }
                    }

                    MouseArea {
                        id: applyArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: MonitorsState.hasChanges ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (MonitorsState.hasChanges) {
                                MonitorsState.applyChanges()
                            }
                        }
                    }
                }

                // Reset button
                Rectangle {
                    width: resetRow.width + 24
                    height: 36
                    radius: 8
                    color: resetArea.containsMouse
                        ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.4)
                        : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.2)
                    opacity: MonitorsState.hasChanges ? 1.0 : 0.5

                    Row {
                        id: resetRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "Reset"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Colors.foreground
                        }
                    }

                    MouseArea {
                        id: resetArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: MonitorsState.hasChanges ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (MonitorsState.hasChanges) {
                                MonitorsState.resetChanges()
                            }
                        }
                    }
                }

                // Auto-align button
                Rectangle {
                    width: autoAlignRow.width + 24
                    height: 36
                    radius: 8
                    color: autoAlignArea.containsMouse
                        ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.4)
                        : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.2)

                    Row {
                        id: autoAlignRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "Auto-Align"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Colors.foreground
                        }
                    }

                    MouseArea {
                        id: autoAlignArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MonitorsState.autoAlign()
                    }
                }
            }
        }
    }
}
