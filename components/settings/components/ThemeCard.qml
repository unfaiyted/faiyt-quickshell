import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import "../../common"

Rectangle {
    id: themeCard

    property var themeData
    property bool isActive: false
    property bool isBuiltin: true

    signal selected()
    signal edit()
    signal duplicate()
    signal deleteTheme()

    height: cardContent.height + 32
    radius: 12
    color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.2)
    border.width: 2
    border.color: isActive
        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.5)
        : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

    property bool hovered: false

    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    // Hover/active background
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: themeCard.isActive
            ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.1)
            : (themeCard.hovered
                ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.1)
                : "transparent")
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    // Active glow
    Rectangle {
        visible: themeCard.isActive
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.width: 3
        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.1)
    }

    Column {
        id: cardContent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        spacing: 12

        // Theme header row
        Row {
            width: parent.width
            spacing: 10

            Text {
                text: themeData?.icon || "󰏘"
                font.family: Fonts.icon
                font.pixelSize: 24
                color: Colors.foreground
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                width: parent.width - 150

                Text {
                    text: themeData?.displayName || "Unknown Theme"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: Colors.foreground
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: themeData?.description || ""
                    font.pixelSize: 13
                    color: Colors.foregroundAlt
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            Item { Layout.fillWidth: true; width: 1 }

            // Active checkmark
            Text {
                visible: themeCard.isActive
                text: "󰄬"
                font.family: Fonts.icon
                font.pixelSize: 20
                color: Colors.primary
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Color swatches
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 5
            height: 24

            Repeater {
                model: ["base", "surface", "overlay", "primary", "accent", "text"]

                Rectangle {
                    width: 28
                    height: 28
                    radius: 6
                    color: themeData?.colors?.[modelData] || "#000000"
                    border.width: 1
                    border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.2)
                }
            }
        }

        // Action buttons
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            // Duplicate button (always visible)
            Rectangle {
                width: duplicateContent.width + 16
                height: 28
                radius: 6
                color: duplicateArea.containsMouse ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.5) : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                border.width: 1
                border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

                Row {
                    id: duplicateContent
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "󰆏"
                        font.family: Fonts.icon
                        font.pixelSize: 12
                        color: Colors.foregroundAlt
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Duplicate"
                        font.pixelSize: 12
                        color: Colors.foregroundAlt
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: duplicateArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: themeCard.duplicate()
                }

                HintTarget {
                    targetElement: parent
                    scope: "theme"
                    action: () => themeCard.duplicate()
                }
            }

            // Edit button (only for custom themes)
            Rectangle {
                visible: !themeCard.isBuiltin
                width: editContent.width + 16
                height: 28
                radius: 6
                color: editArea.containsMouse ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2) : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                border.width: 1
                border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2)

                Row {
                    id: editContent
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "󰏫"
                        font.family: Fonts.icon
                        font.pixelSize: 12
                        color: Colors.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Edit"
                        font.pixelSize: 12
                        color: Colors.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: editArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: themeCard.edit()
                }

                HintTarget {
                    targetElement: parent
                    scope: "theme"
                    enabled: !themeCard.isBuiltin
                    action: () => themeCard.edit()
                }
            }

            // Delete button (only for custom themes)
            Rectangle {
                visible: !themeCard.isBuiltin
                width: deleteContent.width + 16
                height: 28
                radius: 6
                color: deleteArea.containsMouse ? Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.2) : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                border.width: 1
                border.color: Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.2)

                Row {
                    id: deleteContent
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "󰆴"
                        font.family: Fonts.icon
                        font.pixelSize: 12
                        color: Colors.error
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Delete"
                        font.pixelSize: 12
                        color: Colors.error
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: deleteArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: themeCard.deleteTheme()
                }

                HintTarget {
                    targetElement: parent
                    scope: "theme"
                    enabled: !themeCard.isBuiltin
                    action: () => themeCard.deleteTheme()
                }
            }
        }
    }

    // Main click area for selecting theme
    MouseArea {
        id: cardArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: -1
        onEntered: themeCard.hovered = true
        onExited: themeCard.hovered = false
        onClicked: themeCard.selected()
    }

    HintTarget {
        targetElement: themeCard
        scope: "theme"
        action: () => themeCard.selected()
    }
}
