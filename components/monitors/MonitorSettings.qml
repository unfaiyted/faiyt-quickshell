import QtQuick
import QtQuick.Layouts
import "../../theme"
import "."
import "../common"

Rectangle {
    id: settingsContainer

    property var selectedMonitor: MonitorsState.monitors.find(m => m.name === MonitorsState.selectedMonitor)
    property bool expanded: false

    implicitHeight: headerRow.height + (expanded && selectedMonitor ? settingsContent.height : 0)
    color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.05)

    Behavior on implicitHeight {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    clip: true

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)
    }

    Column {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            id: headerRow
            width: parent.width
            height: 48
            color: headerArea.containsMouse
                ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.15)
                : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.1)

            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 8

                Text {
                    text: selectedMonitor ? `${selectedMonitor.name} Settings` : "Monitor Settings"
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.medium
                    font.weight: Font.DemiBold
                    color: Colors.foreground
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: 1; Layout.fillWidth: true }

                Text {
                    text: selectedMonitor ? (expanded ? "▼" : "▶") : "Select a monitor"
                    font.pixelSize: selectedMonitor ? 12 : 12
                    color: selectedMonitor ? Colors.foregroundAlt : Colors.foregroundMuted
                    font.italic: !selectedMonitor
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: headerArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: selectedMonitor ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (selectedMonitor) {
                        expanded = !expanded
                    }
                }
            }

            HintTarget {
                targetElement: headerRow
                scope: "monitors"
                enabled: selectedMonitor !== null && selectedMonitor !== undefined
                action: () => expanded = !expanded
            }
        }

        // Settings content
        Item {
            id: settingsContent
            width: parent.width
            height: settingsColumn.height + 32
            visible: expanded && selectedMonitor
            opacity: expanded ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            Column {
                id: settingsColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 16

                // Resolution/Mode
                Column {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Resolution"
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.body
                        font.weight: Font.Medium
                        color: Colors.foreground
                    }

                    Flow {
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: selectedMonitor ? selectedMonitor.availableModes.slice(0, 8) : []

                            Rectangle {
                                property string mode: modelData
                                property bool isActive: {
                                    if (!selectedMonitor) return false
                                    const tempMode = MonitorsState.getTempSetting(selectedMonitor.name, "mode")
                                    if (tempMode) return tempMode === mode
                                    return mode.startsWith(`${selectedMonitor.width}x${selectedMonitor.height}`)
                                }

                                width: modeText.width + 16
                                height: 28
                                radius: 6
                                color: isActive
                                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2)
                                    : (modeArea.containsMouse
                                        ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.4)
                                        : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.2))
                                border.width: 1
                                border.color: isActive
                                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.4)
                                    : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

                                Text {
                                    id: modeText
                                    anchors.centerIn: parent
                                    text: mode
                                    font.family: Fonts.ui
                                    font.pixelSize: Fonts.small
                                    color: isActive ? Colors.primary : Colors.foreground
                                }

                                MouseArea {
                                    id: modeArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        MonitorsState.setTempSetting(selectedMonitor.name, "mode", mode)
                                    }
                                }

                                HintTarget {
                                    targetElement: parent
                                    scope: "monitors"
                                    enabled: settingsContainer.expanded && settingsContainer.selectedMonitor
                                    action: () => MonitorsState.setTempSetting(selectedMonitor.name, "mode", mode)
                                }
                            }
                        }
                    }
                }

                // Scale
                Column {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Scale"
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.body
                        font.weight: Font.Medium
                        color: Colors.foreground
                    }

                    Row {
                        spacing: 8

                        Repeater {
                            model: selectedMonitor ? MonitorsState.getValidScales(selectedMonitor.width, selectedMonitor.height) : []

                            Rectangle {
                                property real scaleValue: modelData
                                property bool isActive: {
                                    if (!selectedMonitor) return false
                                    const tempScale = MonitorsState.getTempSetting(selectedMonitor.name, "scale")
                                    if (tempScale !== undefined) return Math.abs(tempScale - scaleValue) < 0.01
                                    return Math.abs(selectedMonitor.scale - scaleValue) < 0.01
                                }

                                width: 48
                                height: 32
                                radius: 6
                                color: isActive
                                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2)
                                    : (scaleArea.containsMouse
                                        ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.4)
                                        : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.2))
                                border.width: 1
                                border.color: isActive
                                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.4)
                                    : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

                                Text {
                                    anchors.centerIn: parent
                                    text: scaleValue + "x"
                                    font.family: Fonts.ui
                                    font.pixelSize: Fonts.small
                                    color: isActive ? Colors.primary : Colors.foreground
                                }

                                MouseArea {
                                    id: scaleArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        MonitorsState.setTempSetting(selectedMonitor.name, "scale", scaleValue)
                                    }
                                }

                                HintTarget {
                                    targetElement: parent
                                    scope: "monitors"
                                    enabled: settingsContainer.expanded && settingsContainer.selectedMonitor
                                    action: () => MonitorsState.setTempSetting(selectedMonitor.name, "scale", scaleValue)
                                }
                            }
                        }
                    }
                }

                // Transform
                Column {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Transform"
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.body
                        font.weight: Font.Medium
                        color: Colors.foreground
                    }

                    Flow {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: [
                                { label: "Normal", value: 0 },
                                { label: "90°", value: 1 },
                                { label: "180°", value: 2 },
                                { label: "270°", value: 3 },
                                { label: "Flipped", value: 4 },
                                { label: "Flipped 90°", value: 5 },
                                { label: "Flipped 180°", value: 6 },
                                { label: "Flipped 270°", value: 7 }
                            ]

                            Rectangle {
                                property int transformValue: modelData.value
                                property bool isActive: {
                                    if (!selectedMonitor) return false
                                    const tempTransform = MonitorsState.getTempSetting(selectedMonitor.name, "transform")
                                    if (tempTransform !== undefined) return tempTransform === transformValue
                                    return selectedMonitor.transform === transformValue
                                }

                                width: transformText.width + 16
                                height: 28
                                radius: 6
                                color: isActive
                                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2)
                                    : (transformArea.containsMouse
                                        ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.4)
                                        : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.2))
                                border.width: 1
                                border.color: isActive
                                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.4)
                                    : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

                                Text {
                                    id: transformText
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: Fonts.ui
                                    font.pixelSize: Fonts.small
                                    color: isActive ? Colors.primary : Colors.foreground
                                }

                                MouseArea {
                                    id: transformArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        MonitorsState.setTempSetting(selectedMonitor.name, "transform", transformValue)
                                    }
                                }

                                HintTarget {
                                    targetElement: parent
                                    scope: "monitors"
                                    enabled: settingsContainer.expanded && settingsContainer.selectedMonitor
                                    action: () => MonitorsState.setTempSetting(selectedMonitor.name, "transform", transformValue)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
