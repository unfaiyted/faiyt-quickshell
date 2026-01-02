import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"

Column {
    id: themeSelector
    width: parent.width
    spacing: 12

    property string currentTheme: ThemeService.currentThemeName

    // Header
    Row {
        width: parent.width
        spacing: 10

        Text {
            text: "󰏘"
            font.family: "Symbols Nerd Font"
            font.pixelSize: 20
            color: Colors.foreground
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: "Theme"
            font.pixelSize: 16
            font.weight: Font.DemiBold
            color: Colors.foreground
            anchors.verticalCenter: parent.verticalCenter
        }

        Item { Layout.fillWidth: true; width: 1 }

        // Customize button
        Rectangle {
            width: customizeContent.width + 16
            height: 28
            radius: 8
            color: customizeArea.containsMouse ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2) : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
            border.width: 1
            border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2)
            anchors.verticalCenter: parent.verticalCenter

            Row {
                id: customizeContent
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "󰏫"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 12
                    color: Colors.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Customize"
                    font.pixelSize: 12
                    color: Colors.primary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: customizeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    SettingsState.close()
                    ThemePanelState.open()
                }
            }
        }
    }

    // Theme options
    Column {
        width: parent.width
        spacing: 10

        Repeater {
            model: ThemeService.availableThemes.filter(t => t.isBuiltin)

            Rectangle {
                id: themeOption
                width: parent.width
                height: themeContent.height + 32
                radius: 12
                color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.2)
                border.width: 2
                border.color: themeSelector.currentTheme === modelData.name
                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.5)
                    : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

                property var themeData: modelData
                property bool hovered: false
                property bool isActive: themeSelector.currentTheme === modelData.name

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                // Hover/active background
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: themeOption.isActive
                        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.1)
                        : (themeOption.hovered
                            ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.1)
                            : "transparent")
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                // Active glow
                Rectangle {
                    visible: themeOption.isActive
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: 3
                    border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.1)
                }

                Column {
                    id: themeContent
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
                            text: modelData.icon
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 24
                            color: Colors.foreground
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: modelData.displayName
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                color: Colors.foreground
                            }

                            Text {
                                text: modelData.description
                                font.pixelSize: 13
                                color: Colors.foregroundAlt
                            }
                        }

                        Item { width: 1; Layout.fillWidth: true }

                        // Active checkmark
                        Text {
                            visible: themeOption.isActive
                            text: "󰄬"
                            font.family: "Symbols Nerd Font"
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
                                width: 24; height: 24; radius: 6
                                color: themeOption.themeData.colors[modelData] || "#000"
                                border.width: 1
                                border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.2)
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: themeOption.hovered = true
                    onExited: themeOption.hovered = false
                    onClicked: {
                        ThemeService.setTheme(modelData.name)
                    }
                }
            }
        }
    }

    // Custom themes indicator (if any)
    Rectangle {
        visible: ThemeService.availableThemes.filter(t => !t.isBuiltin).length > 0
        width: parent.width
        height: customThemesRow.height + 24
        radius: 8
        color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.15)
        border.width: 1
        border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.08)

        Row {
            id: customThemesRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "󰏘"
                font.family: "Symbols Nerd Font"
                font.pixelSize: 14
                color: Colors.foregroundAlt
            }

            Text {
                text: ThemeService.availableThemes.filter(t => !t.isBuiltin).length + " custom theme(s) available"
                font.pixelSize: 13
                color: Colors.foregroundAlt
            }

            Text {
                text: "→"
                font.pixelSize: 13
                color: Colors.primary
            }

            Text {
                text: "Open Theme Manager"
                font.pixelSize: 13
                color: Colors.primary

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SettingsState.close()
                        ThemePanelState.open()
                    }
                }
            }
        }
    }
}
