import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"

Column {
    id: themeSelector
    width: parent.width
    spacing: 12

    // Available themes
    property var themes: [
        {
            name: "rose-pine",
            displayName: "Rosé Pine",
            description: "Dark theme with muted colors",
            icon: "󰽥",
            colors: {
                base: "#191724",
                surface: "#1f1d2e",
                overlay: "#26233a",
                primary: "#c4a7e7",
                accent: "#eb6f92",
                text: "#e0def4"
            }
        },
        {
            name: "rose-pine-moon",
            displayName: "Rosé Pine Moon",
            description: "Darker variant with softer tones",
            icon: "󰽦",
            colors: {
                base: "#232136",
                surface: "#2a273f",
                overlay: "#393552",
                primary: "#c4a7e7",
                accent: "#eb6f92",
                text: "#e0def4"
            }
        },
        {
            name: "rose-pine-dawn",
            displayName: "Rosé Pine Dawn",
            description: "Light theme for daytime use",
            icon: "󰖨",
            colors: {
                base: "#faf4ed",
                surface: "#fffaf3",
                overlay: "#f2e9e1",
                primary: "#907aa9",
                accent: "#b4637a",
                text: "#575279"
            }
        }
    ]

    property string currentTheme: ConfigService.theme

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
    }

    // Theme options
    Column {
        width: parent.width
        spacing: 10

        Repeater {
            model: themeSelector.themes

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

                        Rectangle {
                            width: 24; height: 24; radius: 6
                            color: modelData.colors.base
                            border.width: 1
                            border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.2)
                        }
                        Rectangle {
                            width: 24; height: 24; radius: 6
                            color: modelData.colors.surface
                            border.width: 1
                            border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.2)
                        }
                        Rectangle {
                            width: 24; height: 24; radius: 6
                            color: modelData.colors.overlay
                            border.width: 1
                            border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.2)
                        }
                        Rectangle {
                            width: 24; height: 24; radius: 6
                            color: modelData.colors.primary
                            border.width: 1
                            border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.2)
                        }
                        Rectangle {
                            width: 24; height: 24; radius: 6
                            color: modelData.colors.accent
                            border.width: 1
                            border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.2)
                        }
                        Rectangle {
                            width: 24; height: 24; radius: 6
                            color: modelData.colors.text
                            border.width: 1
                            border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.2)
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
                        themeSelector.currentTheme = modelData.name
                        ConfigService.setValue("theme", modelData.name)
                        ConfigService.saveConfig()
                    }
                }
            }
        }
    }

    // Hint text
    Rectangle {
        width: parent.width
        height: hintRow.height + 24
        radius: 8
        color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.15)
        border.width: 1
        border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.08)

        Row {
            id: hintRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: "󰋼"
                font.family: "Symbols Nerd Font"
                font.pixelSize: 14
                color: Colors.foregroundAlt
            }

            Text {
                text: "Theme changes require a restart to take effect"
                font.pixelSize: 13
                color: Colors.foregroundAlt
            }
        }
    }
}
