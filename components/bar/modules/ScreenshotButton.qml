import QtQuick
import Quickshell
import "../../../theme"
import "../../../services"
import "../../common"

Item {
    id: screenshotBtn

    width: 20
    height: 20

    // Listen for popup scope cleared signal to close menu
    Connections {
        target: HintNavigationService
        function onPopupScopeCleared(scope) {
            if (scope === "screenshot-menu") {
                modeMenu.visible = false
            }
        }
    }

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

    HintTarget {
        targetElement: screenshotBtn
        scope: "bar"
        action: () => ScreenshotState.capture()
        secondaryAction: () => {
            // Shift+key opens the screenshot mode menu
            contextMenu.visible = true
            HintNavigationService.setPopupScope("screenshot-menu")
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
                    id: menuItem1
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

                    HintTarget {
                        targetElement: menuItem1
                        scope: "screenshot-menu"
                        enabled: contextMenu.visible
                        action: () => {
                            ScreenshotState.annotateEnabled = false
                            contextMenu.visible = false
                            HintNavigationService.clearPopupScope()
                            ScreenshotState.capture()
                        }
                    }
                }

                // Screenshot + Annotate
                Rectangle {
                    id: menuItem2
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

                    HintTarget {
                        targetElement: menuItem2
                        scope: "screenshot-menu"
                        enabled: contextMenu.visible
                        action: () => {
                            ScreenshotState.annotateEnabled = true
                            contextMenu.visible = false
                            HintNavigationService.clearPopupScope()
                            ScreenshotState.capture()
                        }
                    }
                }
            }
        }

        // Clear popup scope when menu closes
        onVisibleChanged: {
            if (!visible && HintNavigationService.activePopupScope === "screenshot-menu") {
                HintNavigationService.clearPopupScope()
            }
        }

        // Hint overlay for screenshot menu
        PopupWindow {
            id: hintPopup
            anchor.window: contextMenu
            anchor.rect: Qt.rect(0, 0, menuContent.width, menuContent.height)
            anchor.edges: Edges.Top | Edges.Left

            visible: contextMenu.visible && HintNavigationService.active
            color: "transparent"

            implicitWidth: menuContent.width
            implicitHeight: menuContent.height

            HintOverlay {
                anchors.fill: parent
                scope: "screenshot-menu"
                mapRoot: menuContent
            }
        }

        // Keyboard handling for hints in menu
        FocusScope {
            id: menuKeyHandler
            anchors.fill: parent
            focus: contextMenu.visible && HintNavigationService.active

            Keys.onPressed: function(event) {
                // Escape closes the menu
                if (event.key === Qt.Key_Escape) {
                    contextMenu.visible = false
                    HintNavigationService.clearPopupScope()
                    event.accepted = true
                    return
                }

                if (HintNavigationService.active) {
                    let key = ""
                    if (event.key === Qt.Key_Backspace) key = "Backspace"
                    else if (event.text && event.text.length === 1) key = event.text

                    if (key && HintNavigationService.handleKey(key, "screenshot-menu", event.modifiers)) {
                        event.accepted = true
                    }
                }
            }
        }
    }
}
