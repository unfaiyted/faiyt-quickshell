import QtQuick
import Quickshell
import "../../../theme"

Item {
    id: dropdown

    property var model: []  // [{label: "Option", value: "value"}, ...]
    property int currentIndex: 0
    property var currentValue: model.length > 0 ? model[currentIndex].value : null
    property string currentLabel: model.length > 0 ? model[currentIndex].label : ""
    signal selected(int index, var value)

    width: 150
    height: 32

    // Main button
    Rectangle {
        id: button
        anchors.fill: parent
        radius: 8
        color: buttonArea.containsMouse || popup.visible
            ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.4)
            : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
        border.width: 1
        border.color: popup.visible
            ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.5)
            : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 8

            Text {
                width: parent.width - arrow.width - 8
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                text: dropdown.currentLabel
                font.pixelSize: 13
                color: Colors.foreground
                elide: Text.ElideRight
            }

            Text {
                id: arrow
                width: 16
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: popup.visible ? "󰅃" : "󰅀"
                font.family: "Symbols Nerd Font"
                font.pixelSize: 12
                color: Colors.foregroundAlt
            }
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.visible = !popup.visible
        }
    }

    // Dropdown popup
    PopupWindow {
        id: popup
        anchor.window: QsWindow.window
        anchor.onAnchoring: {
            const pos = button.mapToItem(QsWindow.window.contentItem, 0, button.height + 4)
            anchor.rect = Qt.rect(pos.x, pos.y, button.width, 1)
        }
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Top

        visible: false

        implicitWidth: popupContent.width
        implicitHeight: popupContent.height
        color: "transparent"

        // Click outside to close
        PopupWindow {
            id: clickCatcher
            anchor.window: QsWindow.window
            anchor.rect: Qt.rect(0, 0, 1, 1)
            anchor.edges: Edges.Top | Edges.Left

            visible: popup.visible

            implicitWidth: Screen.width
            implicitHeight: Screen.height
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: popup.visible = false
            }
        }

        Rectangle {
            id: popupContent
            width: Math.max(dropdown.width, optionsColumn.width + 8)
            height: optionsColumn.height + 8
            radius: 8
            color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.95)
            border.width: 1
            border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.2)

            // Shadow effect
            layer.enabled: true
            layer.effect: null

            Column {
                id: optionsColumn
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: dropdown.model

                    Rectangle {
                        width: Math.max(dropdown.width - 8, optionText.implicitWidth + 24)
                        height: 32
                        radius: 6
                        color: optionArea.containsMouse
                            ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.4)
                            : (index === dropdown.currentIndex
                                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2)
                                : "transparent")

                        Text {
                            id: optionText
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: Text.AlignVCenter
                            text: modelData.label
                            font.pixelSize: 13
                            color: index === dropdown.currentIndex ? Colors.foreground : Colors.foregroundAlt
                        }

                        MouseArea {
                            id: optionArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                dropdown.currentIndex = index
                                dropdown.selected(index, modelData.value)
                                popup.visible = false
                            }
                        }
                    }
                }
            }
        }
    }
}
