import QtQuick
import "../../../theme"
import "../../common"

Item {
    id: scaleSlider

    property real scaleValue: 1.0
    property real minValue: 0.75
    property real maxValue: 1.5
    property real step: 0.05
    signal scaleUpdated(real newValue)

    width: parent.width
    height: 80

    Column {
        anchors.fill: parent
        spacing: 12

        // Slider track with handle
        Item {
            width: parent.width
            height: 32

            // Track background
            Rectangle {
                id: track
                width: parent.width
                height: 6
                anchors.verticalCenter: parent.verticalCenter
                radius: 3
                color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.5)
                border.width: 1
                border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)

                // Filled portion
                Rectangle {
                    width: handle.x + handle.width / 2
                    height: parent.height
                    radius: 3
                    color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.5)
                }

                // Tick marks
                Repeater {
                    model: [0.75, 1.0, 1.25, 1.5]

                    Rectangle {
                        x: ((modelData - scaleSlider.minValue) / (scaleSlider.maxValue - scaleSlider.minValue)) * (track.width - 4) + 2 - 1
                        y: -4
                        width: 2
                        height: track.height + 8
                        radius: 1
                        color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.3)
                    }
                }
            }

            // Handle
            Rectangle {
                id: handle
                width: 18
                height: 18
                radius: 9
                anchors.verticalCenter: parent.verticalCenter
                x: ((scaleSlider.scaleValue - scaleSlider.minValue) / (scaleSlider.maxValue - scaleSlider.minValue)) * (parent.width - width)
                color: handleArea.pressed ? Colors.primary : (handleArea.containsMouse ? Qt.lighter(Colors.primary, 1.1) : Colors.foreground)
                border.width: 2
                border.color: Colors.background

                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: handleArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onPressed: updateValue(mouse.x)
                onPositionChanged: if (pressed) updateValue(mouse.x)

                function updateValue(mouseX) {
                    let ratio = Math.max(0, Math.min(1, mouseX / width))
                    let rawValue = scaleSlider.minValue + ratio * (scaleSlider.maxValue - scaleSlider.minValue)
                    // Snap to step
                    let snapped = Math.round(rawValue / scaleSlider.step) * scaleSlider.step
                    snapped = Math.max(scaleSlider.minValue, Math.min(scaleSlider.maxValue, snapped))
                    if (snapped !== scaleSlider.scaleValue) {
                        scaleSlider.scaleValue = snapped
                        scaleSlider.scaleUpdated(snapped)
                    }
                }
            }

            // Value tooltip
            Rectangle {
                visible: handleArea.containsMouse || handleArea.pressed
                x: handle.x + handle.width / 2 - width / 2
                y: handle.y - height - 8
                width: tooltipText.width + 12
                height: 22
                radius: 6
                color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.95)
                border.width: 1
                border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.2)

                Text {
                    id: tooltipText
                    anchors.centerIn: parent
                    text: Math.round(scaleSlider.scaleValue * 100) + "%"
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    font.weight: Font.Medium
                    color: Colors.foreground
                }
            }
        }

        // Preset buttons
        Row {
            width: parent.width
            spacing: 8

            Repeater {
                model: [
                    { label: "75%", value: 0.75 },
                    { label: "100%", value: 1.0 },
                    { label: "125%", value: 1.25 },
                    { label: "150%", value: 1.5 }
                ]

                Rectangle {
                    width: (parent.width - 24) / 4
                    height: 28
                    radius: 6
                    color: scaleSlider.scaleValue === modelData.value
                        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2)
                        : (presetArea.containsMouse
                            ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.4)
                            : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.2))
                    border.width: 1
                    border.color: scaleSlider.scaleValue === modelData.value
                        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.4)
                        : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.small
                        font.weight: scaleSlider.scaleValue === modelData.value ? Font.Medium : Font.Normal
                        color: scaleSlider.scaleValue === modelData.value ? Colors.primary : Colors.foregroundAlt
                    }

                    MouseArea {
                        id: presetArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            scaleSlider.scaleValue = modelData.value
                            scaleSlider.scaleUpdated(modelData.value)
                        }
                    }

                    HintTarget {
                        targetElement: parent
                        scope: "theme"
                        action: () => {
                            scaleSlider.scaleValue = modelData.value
                            scaleSlider.scaleUpdated(modelData.value)
                        }
                    }
                }
            }
        }
    }
}
