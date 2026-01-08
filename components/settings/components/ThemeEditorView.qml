import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"

Item {
    id: editorView

    property var theme
    signal colorChanged(string colorKey, string colorValue)
    signal themeMetadataChanged(string displayName, string description)
    signal pickerRequested(var rowItem, string colorKey, string colorValue)

    // Close all pickers in all sections
    function closeAllPickers() {
        for (let i = 0; i < sectionRepeater.count; i++) {
            let section = sectionRepeater.itemAt(i)
            if (section) {
                section.closeAllPickers()
            }
        }
    }

    // Color sections configuration
    readonly property var colorSections: [
        {
            title: "Base Colors",
            icon: "󰸌",
            colors: ["base", "surface", "overlay"]
        },
        {
            title: "Text Colors",
            icon: "󰊄",
            colors: ["text", "muted", "subtle"]
        },
        {
            title: "Accent Colors",
            icon: "󰏘",
            colors: ["love", "gold", "rose", "pine", "foam", "iris"]
        },
        {
            title: "Semantic Colors",
            icon: "󰀦",
            colors: ["primary", "secondary", "accent", "success", "warning", "error", "info"]
        },
        {
            title: "UI Component Colors",
            icon: "󰕮",
            colors: ["background", "backgroundAlt", "backgroundElevated", "foreground", "foregroundAlt", "foregroundMuted", "border", "borderAlt"]
        },
        {
            title: "State Colors",
            icon: "󰍹",
            colors: ["hover", "active", "focus", "disabled"]
        }
    ]

    Flickable {
        anchors.fill: parent
        contentHeight: editorColumn.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: editorColumn
            width: parent.width
            spacing: 16

            // Theme metadata editor
            Rectangle {
                width: parent.width
                height: metadataColumn.height + 24
                radius: 12
                color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.2)
                border.width: 1
                border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

                Column {
                    id: metadataColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 12

                    // Display Name
                    Column {
                        width: parent.width
                        spacing: 4

                        Text {
                            text: "Display Name"
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            font.weight: Font.DemiBold
                            color: Colors.foregroundAlt
                        }

                        Rectangle {
                            width: parent.width
                            height: 36
                            radius: 8
                            color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                            border.width: 1
                            border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

                            TextInput {
                                id: displayNameInput
                                anchors.fill: parent
                                anchors.margins: 10
                                font.family: Fonts.ui
                                font.pixelSize: Fonts.medium
                                color: Colors.foreground
                                text: editorView.theme?.displayName || ""
                                selectByMouse: true

                                onTextChanged: {
                                    if (editorView.theme && text !== editorView.theme.displayName) {
                                        editorView.themeMetadataChanged(text, descriptionInput.text)
                                    }
                                }
                            }
                        }
                    }

                    // Description
                    Column {
                        width: parent.width
                        spacing: 4

                        Text {
                            text: "Description"
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            font.weight: Font.DemiBold
                            color: Colors.foregroundAlt
                        }

                        Rectangle {
                            width: parent.width
                            height: 36
                            radius: 8
                            color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                            border.width: 1
                            border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

                            TextInput {
                                id: descriptionInput
                                anchors.fill: parent
                                anchors.margins: 10
                                font.family: Fonts.ui
                                font.pixelSize: Fonts.medium
                                color: Colors.foreground
                                text: editorView.theme?.description || ""
                                selectByMouse: true

                                onTextChanged: {
                                    if (editorView.theme && text !== editorView.theme.description) {
                                        editorView.themeMetadataChanged(displayNameInput.text, text)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Color sections
            Repeater {
                id: sectionRepeater
                model: editorView.colorSections

                ColorSection {
                    width: editorColumn.width
                    title: modelData.title
                    icon: modelData.icon
                    colorKeys: modelData.colors
                    theme: editorView.theme
                    onColorValueChanged: (key, value) => editorView.colorChanged(key, value)
                    onPickerRequested: (rowItem, colorKey, colorValue) => {
                        // Close pickers in all other sections
                        for (let i = 0; i < sectionRepeater.count; i++) {
                            let section = sectionRepeater.itemAt(i)
                            if (section && section !== this) {
                                section.closeAllPickers()
                            }
                        }
                        // Forward to parent
                        editorView.pickerRequested(rowItem, colorKey, colorValue)
                    }
                }
            }

            // Bottom padding
            Item { width: 1; height: 20 }
        }
    }
}
