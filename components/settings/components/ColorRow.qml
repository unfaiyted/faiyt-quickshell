import QtQuick
import Qt5Compat.GraphicalEffects
import "../../../theme"
import "../../common"

Item {
    id: colorRow

    property string colorKey: ""
    property string colorValue: "#000000"
    property bool pickerOpen: false

    signal valueChanged(string newValue)
    signal requestPicker(var rowItem)

    height: 36
    width: parent.width

    // Format color key for display (camelCase to Title Case)
    function formatColorName(key) {
        return key
            .replace(/([A-Z])/g, ' $1')
            .replace(/^./, str => str.toUpperCase())
            .trim()
    }

    // Validate hex color
    function isValidHexColor(str) {
        return /^#[0-9A-Fa-f]{6}$/.test(str)
    }

    Row {
        anchors.fill: parent
        spacing: 12

        // Color swatch preview with proper rounding
        Item {
            id: swatchContainer
            width: 36
            height: 36
            anchors.verticalCenter: parent.verticalCenter

            // Checkered background for transparency preview
            Rectangle {
                id: checkerBg
                anchors.fill: parent
                radius: 8
                color: "#ffffff"
                visible: false
                layer.enabled: true

                Grid {
                    anchors.fill: parent
                    columns: 4
                    rows: 4
                    clip: true

                    Repeater {
                        model: 16
                        Rectangle {
                            width: parent.width / 4
                            height: parent.height / 4
                            color: (Math.floor(index / 4) + index) % 2 === 0 ? "#cccccc" : "#ffffff"
                        }
                    }
                }
            }

            // Color fill
            Rectangle {
                id: colorFill
                anchors.fill: parent
                radius: 8
                color: colorRow.colorValue
                visible: false
                layer.enabled: true
            }

            // Mask shape
            Rectangle {
                id: swatchMask
                anchors.fill: parent
                radius: 8
                visible: false
                layer.enabled: true
            }

            // Apply mask to checker background
            OpacityMask {
                anchors.fill: parent
                source: checkerBg
                maskSource: swatchMask
            }

            // Apply mask to color
            OpacityMask {
                anchors.fill: parent
                source: colorFill
                maskSource: swatchMask
            }

            // Border
            Rectangle {
                anchors.fill: parent
                radius: 8
                color: "transparent"
                border.width: 2
                border.color: colorRow.pickerOpen
                    ? Colors.primary
                    : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.3)
            }

            MouseArea {
                id: swatchArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    colorRow.requestPicker(colorRow)
                }
            }

            HintTarget {
                targetElement: swatchContainer
                scope: "theme"
                action: () => colorRow.requestPicker(colorRow)
            }
        }

        // Color name
        Text {
            text: formatColorName(colorRow.colorKey)
            font.pixelSize: 13
            color: Colors.foreground
            width: 140
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
        }

        // Hex input
        Rectangle {
            width: 100
            height: 32
            radius: 6
            color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
            border.width: 1
            border.color: hexInput.activeFocus
                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.5)
                : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)
            anchors.verticalCenter: parent.verticalCenter

            TextInput {
                id: hexInput
                anchors.fill: parent
                anchors.margins: 8
                font.pixelSize: 13
                font.family: Fonts.mono
                color: Colors.foreground
                selectByMouse: true
                maximumLength: 7

                // Update text when colorValue changes externally (but not while editing)
                Binding {
                    target: hexInput
                    property: "text"
                    value: colorRow.colorValue.toUpperCase()
                    when: !hexInput.activeFocus
                }

                Component.onCompleted: text = colorRow.colorValue.toUpperCase()

                onEditingFinished: {
                    let val = text.trim()
                    if (!val.startsWith("#")) {
                        val = "#" + val
                    }
                    if (isValidHexColor(val)) {
                        colorRow.valueChanged(val)
                    } else {
                        text = colorRow.colorValue.toUpperCase()
                    }
                }

                onTextChanged: {
                    let val = text.trim()
                    if (!val.startsWith("#") && val.length === 6) {
                        val = "#" + val
                    }
                    if (isValidHexColor(val) && val.toUpperCase() !== colorRow.colorValue.toUpperCase()) {
                        colorRow.valueChanged(val)
                    }
                }
            }
        }
    }
}
