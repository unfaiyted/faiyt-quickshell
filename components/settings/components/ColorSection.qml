import QtQuick
import QtQuick.Layouts
import "../../../theme"

Rectangle {
    id: colorSection

    property string title: ""
    property string icon: ""
    property var colorKeys: []
    property var theme
    property bool collapsed: false

    signal colorValueChanged(string key, string value)
    signal pickerRequested(var rowItem, string colorKey, string colorValue)

    // Close all pickers in this section
    function closeAllPickers() {
        for (let i = 0; i < colorRepeater.count; i++) {
            let item = colorRepeater.itemAt(i)
            if (item) {
                item.pickerOpen = false
            }
        }
    }

    height: collapsed ? headerRow.height + 24 : headerRow.height + colorColumn.height + 36
    radius: 12
    color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.2)
    border.width: 1
    border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12
        clip: true

        // Header row
        Row {
            id: headerRow
            width: parent.width
            spacing: 8

            Text {
                text: colorSection.icon
                font.family: Fonts.icon
                font.pixelSize: 16
                color: Colors.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: colorSection.title
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Colors.foreground
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { Layout.fillWidth: true; width: 1 }

            // Collapse/expand button
            Rectangle {
                width: 24
                height: 24
                radius: 6
                color: collapseArea.containsMouse ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.5) : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: colorSection.collapsed ? "󰅂" : "󰅀"
                    font.family: Fonts.icon
                    font.pixelSize: 14
                    color: Colors.foregroundAlt

                    Behavior on text { PropertyAnimation { duration: 0 } }
                }

                MouseArea {
                    id: collapseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: colorSection.collapsed = !colorSection.collapsed
                }
            }
        }

        // Color rows
        Column {
            id: colorColumn
            width: parent.width
            spacing: 8
            visible: !colorSection.collapsed
            opacity: colorSection.collapsed ? 0 : 1

            Behavior on opacity { NumberAnimation { duration: 200 } }

            Repeater {
                id: colorRepeater
                model: colorSection.colorKeys

                ColorRow {
                    width: parent.width
                    colorKey: modelData
                    colorValue: colorSection.theme?.colors?.[modelData] || "#000000"
                    onValueChanged: (newValue) => colorSection.colorValueChanged(modelData, newValue)
                    onRequestPicker: (rowItem) => {
                        // Close all other pickers in this section
                        for (let i = 0; i < colorRepeater.count; i++) {
                            let item = colorRepeater.itemAt(i)
                            if (item && item !== rowItem) {
                                item.pickerOpen = false
                            }
                        }
                        // Forward request to parent with color info
                        colorSection.pickerRequested(rowItem, modelData, colorSection.theme?.colors?.[modelData] || "#000000")
                    }
                }
            }
        }
    }
}
