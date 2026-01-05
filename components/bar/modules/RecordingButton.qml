import QtQuick
import Quickshell
import "../../../theme"
import "../../../services"
import "../../common"

Item {
    id: recordBtn

    width: 20
    height: 20

    // Icon text element
    Text {
        id: iconText
        anchors.centerIn: parent
        // Video camera when idle, record dot when recording
        text: RecordingState.isRecording ? "󰑋" : "󰕧"
        font.pixelSize: 14
        font.family: Fonts.icon
        color: RecordingState.isRecording ? Colors.error :
               (mouseArea.containsMouse ? Colors.rose : Colors.foreground)

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    // Pulsing animation when recording
    SequentialAnimation {
        id: pulseAnimation
        running: RecordingState.isRecording
        loops: Animation.Infinite

        NumberAnimation {
            target: iconText
            property: "opacity"
            to: 0.4
            duration: 500
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: iconText
            property: "opacity"
            to: 1.0
            duration: 500
            easing.type: Easing.InOutQuad
        }
    }

    // Reset opacity when not recording
    Connections {
        target: RecordingState
        function onIsRecordingChanged() {
            if (!RecordingState.isRecording) {
                iconText.opacity = 1.0
            }
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
                RecordingState.toggle()
            } else if (mouse.button === Qt.RightButton) {
                if (modeMenu.visible) {
                    modeMenu.visible = false
                } else {
                    modeMenu.visible = true
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

    HintTarget {
        targetElement: recordBtn
        scope: "bar"
        action: () => RecordingState.toggle()
    }

    Timer {
        id: tooltipTimer
        interval: 500
        onTriggered: if (!modeMenu.visible) tooltipPopup.visible = true
    }

    PopupWindow {
        id: tooltipPopup
        anchor.window: QsWindow.window
        anchor.onAnchoring: {
            const pos = recordBtn.mapToItem(QsWindow.window.contentItem, 0, recordBtn.height + 4)
            anchor.rect = Qt.rect(pos.x - tooltipContent.width / 2 + recordBtn.width / 2, pos.y, 1, 1)
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
                text: RecordingState.isRecording ? "Stop Recording" : "Screen Recording"
                font.pixelSize: 11
                color: Colors.foreground
            }
        }
    }

    // Context menu for recording mode selection
    PopupWindow {
        id: modeMenu

        anchor.window: QsWindow.window
        anchor.onAnchoring: {
            const pos = recordBtn.mapToItem(QsWindow.window.contentItem, 0, recordBtn.height + 4)
            anchor.rect = Qt.rect(pos.x, pos.y, recordBtn.width, 1)
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

            visible: modeMenu.visible

            implicitWidth: Screen.width
            implicitHeight: Screen.height
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: modeMenu.visible = false
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

                // Standard Recording
                Rectangle {
                    id: menuItem1
                    width: Math.max(itemRow1.width + 24, 160)
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
                            text: RecordingState.recordingMode === "record" ? "󰄵" : "󰄱"
                            color: Colors.foreground
                            font.pixelSize: 12
                            font.family: Fonts.icon
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "󰕧"
                            color: Colors.foreground
                            font.pixelSize: 12
                            font.family: Fonts.icon
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Standard"
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
                            RecordingState.recordingMode = "record"
                            modeMenu.visible = false
                            RecordingState.start("selection")
                        }
                    }

                    HintTarget {
                        targetElement: menuItem1
                        scope: "bar"
                        enabled: modeMenu.visible
                        action: () => {
                            RecordingState.recordingMode = "record"
                            modeMenu.visible = false
                            RecordingState.start("selection")
                        }
                    }
                }

                // High Quality Recording
                Rectangle {
                    id: menuItem2
                    width: Math.max(itemRow2.width + 24, 160)
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
                            text: RecordingState.recordingMode === "record-hq" ? "󰄵" : "󰄱"
                            color: Colors.foreground
                            font.pixelSize: 12
                            font.family: Fonts.icon
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "󰗃"
                            color: Colors.love
                            font.pixelSize: 12
                            font.family: Fonts.icon
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "High Quality"
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
                            RecordingState.recordingMode = "record-hq"
                            modeMenu.visible = false
                            RecordingState.start("selection")
                        }
                    }

                    HintTarget {
                        targetElement: menuItem2
                        scope: "bar"
                        enabled: modeMenu.visible
                        action: () => {
                            RecordingState.recordingMode = "record-hq"
                            modeMenu.visible = false
                            RecordingState.start("selection")
                        }
                    }
                }

                // GIF Recording
                Rectangle {
                    id: menuItem3
                    width: Math.max(itemRow3.width + 24, 160)
                    height: 28
                    radius: 4
                    color: item3Mouse.containsMouse ? Colors.overlay : "transparent"

                    Row {
                        id: itemRow3
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            text: RecordingState.recordingMode === "record-gif" ? "󰄵" : "󰄱"
                            color: Colors.foreground
                            font.pixelSize: 12
                            font.family: Fonts.icon
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "󰵸"
                            color: Colors.foam
                            font.pixelSize: 12
                            font.family: Fonts.icon
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "GIF"
                            color: Colors.foreground
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: item3Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            RecordingState.recordingMode = "record-gif"
                            modeMenu.visible = false
                            RecordingState.start("selection")
                        }
                    }

                    HintTarget {
                        targetElement: menuItem3
                        scope: "bar"
                        enabled: modeMenu.visible
                        action: () => {
                            RecordingState.recordingMode = "record-gif"
                            modeMenu.visible = false
                            RecordingState.start("selection")
                        }
                    }
                }
            }
        }
    }
}
