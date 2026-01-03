import QtQuick
import Quickshell
import "../../../theme"

Item {
    id: screenshotBtn

    width: 20
    height: 20

    // Icon
    Text {
        id: iconText
        anchors.centerIn: parent
        text: "󰄀"
        font.pixelSize: 14
        font.family: Fonts.icon
        color: mouseArea.containsMouse ? Colors.rose : Colors.foreground

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                ScreenshotState.capture()
            } else if (mouse.button === Qt.RightButton) {
                if (contextMenu.visible) {
                    contextMenu.visible = false
                } else {
                    contextMenu.visible = true
                }
            }
        }
        onContainsMouseChanged: {
            if (containsMouse) {
                tooltipTimer.start()
            } else {
                tooltipTimer.stop()
                tooltipPopup.visible = false
            }
        }
    }

    Timer {
        id: tooltipTimer
        interval: 500
        onTriggered: if (!contextMenu.visible) tooltipPopup.visible = true
    }

    PopupWindow {
        id: tooltipPopup
        anchor.window: QsWindow.window
        anchor.onAnchoring: {
            const pos = screenshotBtn.mapToItem(QsWindow.window.contentItem, 0, screenshotBtn.height + 4)
            anchor.rect = Qt.rect(pos.x - tooltipContent.width / 2 + screenshotBtn.width / 2, pos.y, 1, 1)
        }
        anchor.edges: Edges.Top | Edges.Left

        visible: false
        implicitWidth: tooltipContent.width
        implicitHeight: tooltipContent.height
        color: "transparent"

        Rectangle {
            id: tooltipContent
            width: tooltipText.width + 16
            height: tooltipText.height + 8
            radius: 6
            color: Colors.surface
            border.width: 1
            border.color: Colors.overlay

            Text {
                id: tooltipText
                anchors.centerIn: parent
                text: "Screenshot"
                font.pixelSize: 11
                color: Colors.foreground
            }
        }
    }

    // Context menu for screenshot options
    PopupWindow {
        id: contextMenu

        anchor.window: QsWindow.window
        anchor.onAnchoring: {
            const pos = screenshotBtn.mapToItem(QsWindow.window.contentItem, 0, screenshotBtn.height + 4)
            anchor.rect = Qt.rect(pos.x, pos.y, screenshotBtn.width, 1)
        }
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        visible: false

        implicitWidth: menuContent.width
        implicitHeight: menuContent.height
        color: "transparent"

        // Click catcher to close menu when clicking outside
        PopupWindow {
            id: clickCatcher
            anchor.window: QsWindow.window
            anchor.rect: Qt.rect(0, 0, 1, 1)
            anchor.edges: Edges.Top | Edges.Left

            visible: contextMenu.visible

            implicitWidth: Screen.width
            implicitHeight: Screen.height
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: contextMenu.visible = false
            }
        }

        Rectangle {
            id: menuContent
            width: menuColumn.width + 16
            height: menuColumn.height + 12
            color: Colors.surface
            radius: 8
            border.width: 1
            border.color: Colors.overlay

            Column {
                id: menuColumn
                anchors.centerIn: parent
                spacing: 2

                // Screenshot (regular)
                Rectangle {
                    width: Math.max(itemRow1.width + 24, 180)
                    height: 28
                    radius: 4
                    color: item1Mouse.containsMouse ? Colors.overlay : "transparent"

                    Row {
                        id: itemRow1
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            text: !ScreenshotState.annotateEnabled ? "󰄵" : "󰄱"
                            color: Colors.foreground
                            font.pixelSize: 12
                            font.family: Fonts.icon
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "󰄀"
                            color: Colors.foreground
                            font.pixelSize: 12
                            font.family: Fonts.icon
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Screenshot"
                            color: Colors.foreground
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: item1Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ScreenshotState.annotateEnabled = false
                            contextMenu.visible = false
                            ScreenshotState.capture()
                        }
                    }
                }

                // Screenshot + Annotate
                Rectangle {
                    width: Math.max(itemRow2.width + 24, 180)
                    height: 28
                    radius: 4
                    color: item2Mouse.containsMouse ? Colors.overlay : "transparent"

                    Row {
                        id: itemRow2
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            text: ScreenshotState.annotateEnabled ? "󰄵" : "󰄱"
                            color: Colors.foreground
                            font.pixelSize: 12
                            font.family: Fonts.icon
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "󰏫"
                            color: Colors.iris
                            font.pixelSize: 12
                            font.family: Fonts.icon
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Annotate"
                            color: Colors.foreground
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: item2Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ScreenshotState.annotateEnabled = true
                            contextMenu.visible = false
                            ScreenshotState.capture()
                        }
                    }
                }
            }
        }
    }
}
