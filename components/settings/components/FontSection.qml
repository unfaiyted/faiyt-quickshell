import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import "../../common"

Item {
    id: fontSection

    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentColumn
            width: parent.width
            spacing: 16

            // UI Scale Section
            Column {
                width: parent.width
                spacing: 8

                Row {
                    spacing: 8

                    Text {
                        text: "󰆦"
                        font.family: Fonts.icon
                        font.pixelSize: Fonts.iconMedium
                        color: Colors.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "UI Scale"
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.medium
                        font.weight: Font.DemiBold
                        color: Colors.foreground
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: Math.round(ThemeService.fonts.scale * 100) + "%"
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.body
                        color: Colors.foregroundAlt
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    width: parent.width
                    text: "Adjust the size of all text and icons in the interface"
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    color: Colors.foregroundAlt
                    wrapMode: Text.WordWrap
                }

                ScaleSlider {
                    width: parent.width
                    scaleValue: ThemeService.fonts.scale
                    onScaleUpdated: (newValue) => {
                        ThemeService.setFontScale(newValue)
                    }
                }
            }

            // Separator
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)
            }

            // Font Family Section
            Column {
                width: parent.width
                spacing: 12

                Row {
                    spacing: 8

                    Text {
                        text: "󰛖"
                        font.family: Fonts.icon
                        font.pixelSize: Fonts.iconMedium
                        color: Colors.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Font Families"
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.medium
                        font.weight: Font.DemiBold
                        color: Colors.foreground
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    width: parent.width
                    text: "Customize fonts for different parts of the interface"
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    color: Colors.foregroundAlt
                    wrapMode: Text.WordWrap
                }

                // Loading state
                Rectangle {
                    visible: !FontService.loaded
                    width: parent.width
                    height: 60
                    radius: 8
                    color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "󰔟"
                            font.family: Fonts.icon
                            font.pixelSize: Fonts.iconMedium
                            color: Colors.foregroundAlt
                            anchors.verticalCenter: parent.verticalCenter

                            RotationAnimation on rotation {
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 1000
                                running: !FontService.loaded
                            }
                        }

                        Text {
                            text: "Loading fonts..."
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.body
                            color: Colors.foregroundAlt
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Font pickers (visible when loaded)
                Column {
                    visible: FontService.loaded
                    width: parent.width
                    spacing: 8

                    // UI Font
                    FontRow {
                        label: "UI Text"
                        description: "General interface text"
                        icon: "󰊄"
                        model: FontService.uiFontModel
                        currentValue: ThemeService.fonts.ui
                        onFontSelected: (value) => ThemeService.setFont("ui", value)
                    }

                    // Monospace Font
                    FontRow {
                        label: "Monospace"
                        description: "Code and technical text"
                        icon: "󰘦"
                        model: FontService.monoFontModel
                        currentValue: ThemeService.fonts.mono
                        previewText: "0123 ABC"
                        onFontSelected: (value) => ThemeService.setFont("mono", value)
                    }

                    // Icon Font
                    FontRow {
                        label: "Icons"
                        description: "Nerd Font symbols and icons"
                        icon: "󰊪"
                        model: FontService.nerdFontModel
                        currentValue: ThemeService.fonts.icon
                        previewText: "     "
                        onFontSelected: (value) => ThemeService.setFont("icon", value)
                    }

                    // Emoji Font
                    FontRow {
                        label: "Emoji"
                        description: "Emoji and color symbols"
                        icon: "󰱨"
                        model: FontService.emojiFontModel
                        currentValue: ThemeService.fonts.emoji
                        previewText: "Emoji"
                        onFontSelected: (value) => ThemeService.setFont("emoji", value)
                    }
                }
            }

            // Separator
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)
            }

            // Preview Section
            Column {
                width: parent.width
                spacing: 12

                Row {
                    spacing: 8

                    Text {
                        text: "󰄬"
                        font.family: Fonts.icon
                        font.pixelSize: Fonts.iconMedium
                        color: Colors.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Preview"
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.medium
                        font.weight: Font.DemiBold
                        color: Colors.foreground
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    width: parent.width
                    height: previewColumn.height + 24
                    radius: 8
                    color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                    border.width: 1
                    border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

                    Column {
                        id: previewColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 12

                        // UI Text preview
                        Column {
                            width: parent.width
                            spacing: 4

                            Text {
                                text: "UI Text"
                                font.family: Fonts.ui
                                font.pixelSize: Fonts.tiny
                                color: Colors.foregroundMuted
                            }

                            Text {
                                width: parent.width
                                text: "The quick brown fox jumps over the lazy dog"
                                font.family: Fonts.ui !== "" ? Fonts.ui : Qt.application.font.family
                                font.pixelSize: Fonts.body
                                color: Colors.foreground
                            }
                        }

                        // Monospace preview
                        Column {
                            width: parent.width
                            spacing: 4

                            Text {
                                text: "Monospace"
                                font.family: Fonts.ui
                                font.pixelSize: Fonts.tiny
                                color: Colors.foregroundMuted
                            }

                            Rectangle {
                                width: parent.width
                                height: monoText.height + 8
                                radius: 4
                                color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.5)

                                Text {
                                    id: monoText
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 4
                                    text: "const greeting = \"Hello, World!\";"
                                    font.family: Fonts.mono
                                    font.pixelSize: Fonts.small
                                    color: Colors.foreground
                                }
                            }
                        }

                        // Icons preview
                        Column {
                            width: parent.width
                            spacing: 4

                            Text {
                                text: "Icons"
                                font.family: Fonts.ui
                                font.pixelSize: Fonts.tiny
                                color: Colors.foregroundMuted
                            }

                            Row {
                                spacing: 16

                                Text {
                                    text: "  󰕾    󰖩  󰝚  󰋼"
                                    font.family: Fonts.icon
                                    font.pixelSize: Fonts.iconLarge
                                    color: Colors.foreground
                                }
                            }
                        }

                        // Emoji preview
                        Column {
                            width: parent.width
                            spacing: 4

                            Text {
                                text: "Emoji"
                                font.family: Fonts.ui
                                font.pixelSize: Fonts.tiny
                                color: Colors.foregroundMuted
                            }

                            Text {
                                text: "Hello World! 😀🎉🔥✨"
                                font.family: Fonts.emoji
                                font.pixelSize: Fonts.body
                                color: Colors.foreground
                            }
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
                border.width: 1
                border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)

                Row {
                    id: resetRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "󰑓"
                        font.family: Fonts.icon
                        font.pixelSize: Fonts.iconMedium
                        color: Colors.foregroundAlt
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Reset to Defaults"
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.body
                        color: Colors.foregroundAlt
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: resetArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ThemeService.resetFonts()
                }

                HintTarget {
                    targetElement: parent
                    scope: "theme"
                    action: () => ThemeService.resetFonts()
                }
            }

            // Bottom padding
            Item { width: 1; height: 20 }
        }
    }

    // FontRow component
    component FontRow: Rectangle {
        id: fontRow

        property string label: ""
        property string description: ""
        property string icon: ""
        property var model: []
        property string currentValue: ""
        property string previewText: "Aa Bb Cc"
        signal fontSelected(string value)

        width: parent.width
        height: 56
        radius: 8
        color: rowHover.containsMouse ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3) : "transparent"

        Behavior on color { ColorAnimation { duration: 150 } }

        MouseArea {
            id: rowHover
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onClicked: mouse.accepted = false
            onPressed: mouse.accepted = false
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 12

            // Icon
            Text {
                text: fontRow.icon
                font.family: Fonts.icon
                font.pixelSize: Fonts.iconLarge
                color: Colors.primary
                Layout.preferredWidth: 24
            }

            // Label and description
            Column {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: fontRow.label
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.body
                    font.weight: Font.Medium
                    color: Colors.foreground
                }

                Text {
                    text: fontRow.description
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    color: Colors.foregroundAlt
                }
            }

            // Font picker
            FontPicker {
                Layout.preferredWidth: 200
                model: fontRow.model
                previewText: fontRow.previewText
                Component.onCompleted: setValueByName(fontRow.currentValue)
                onSelected: (index, value) => fontRow.fontSelected(value)
            }
        }
    }
}
