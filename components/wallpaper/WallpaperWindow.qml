import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"
import "../common"

PanelWindow {
    id: wallpaperWindow

    anchors {
        bottom: true
        left: true
        right: true
    }

    property bool expanded: WallpaperState.visible
    property bool animating: false

    // Use 70% of screen width, capped at 1600px
    property real targetWidth: Math.min(screen.width * 0.75, 1800)
    property real sideMargin: Math.max((screen.width - targetWidth) / 2, 50)

    // Update WallpaperState with available width for responsive sizing
    onTargetWidthChanged: WallpaperState.availableWidth = targetWidth
    Component.onCompleted: WallpaperState.availableWidth = targetWidth

    implicitHeight: 300
    margins.bottom: 16
    margins.left: sideMargin
    margins.right: sideMargin
    exclusiveZone: 0
    color: "transparent"

    // Keyboard focus mode - Exclusive when hints active for reliable key capture
    WlrLayershell.keyboardFocus: (expanded || HintNavigationService.active) ?
        WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    visible: ConfigService.windowWallpaperEnabled && (expanded || animating)

    // Click-outside overlay
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.3)
        radius: 20

        MouseArea {
            anchors.fill: parent
            onClicked: WallpaperState.hide()
        }
    }

    // Main content panel with slide animation
    Rectangle {
        id: contentPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8
        height: parent.height - 16
        radius: 16
        color: Colors.background
        border.width: 1
        border.color: Colors.border

        // Slide up animation
        transform: Translate {
            id: slideTransform
            y: wallpaperWindow.expanded ? 0 : contentPanel.height + 50
        }

        opacity: wallpaperWindow.expanded ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        NumberAnimation {
            id: slideInAnimation
            target: slideTransform
            property: "y"
            to: 0
            duration: 300
            easing.type: Easing.OutCubic
            onStarted: wallpaperWindow.animating = true
            onFinished: wallpaperWindow.animating = false
        }

        NumberAnimation {
            id: slideOutAnimation
            target: slideTransform
            property: "y"
            to: contentPanel.height + 50
            duration: 250
            easing.type: Easing.InCubic
            onStarted: wallpaperWindow.animating = true
            onFinished: wallpaperWindow.animating = false
        }

        // Stop clicks from passing through to overlay
        MouseArea {
            anchors.fill: parent
            onClicked: {} // Absorb clicks
        }

        // Hint navigation overlay
        HintOverlay {
            anchors.fill: parent
            scope: "wallpaper"
        }

        Column {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 16
            anchors.bottomMargin: 34
            spacing: 12

            // Header
            Item {
                width: parent.width
                height: 16

                // Title
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Text {
                        text: "󰸉"
                        font.family: Fonts.icon
                        font.pixelSize: 20
                        color: Colors.primary
                    }

                    Text {
                        text: "Wallpapers"
                        font.pixelSize: 16
                        font.bold: true
                        color: Colors.foreground
                    }
                }

                // Close button
                Rectangle {
                    id: closeButton
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    radius: 8
                    color: closeArea.containsMouse ? Colors.error : Colors.surface

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Fonts.icon
                        font.pixelSize: 14
                        color: closeArea.containsMouse ? Colors.background : Colors.foreground
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WallpaperState.hide()
                    }

                    HintTarget {
                        targetElement: closeButton
                        scope: "wallpaper"
                        action: () => WallpaperState.hide()
                    }
                }
            }

            // Carousel
            Item {
                width: parent.width
                height: WallpaperState.thumbnailHeight + 24

                // Previous page button
                Rectangle {
                    id: prevButton
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 40
                    radius: 10
                    color: prevArea.containsMouse ? Colors.overlay : Colors.surface
                    visible: WallpaperState.wallpapers.length > WallpaperState.itemsPerPage

                    Text {
                        anchors.centerIn: parent
                        text: "󰅁"
                        font.family: Fonts.icon
                        font.pixelSize: 20
                        color: Colors.foreground
                    }

                    MouseArea {
                        id: prevArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WallpaperState.prevPage()
                    }

                    HintTarget {
                        targetElement: prevButton
                        scope: "wallpaper"
                        action: () => WallpaperState.prevPage()
                        enabled: WallpaperState.wallpapers.length > WallpaperState.itemsPerPage
                    }
                }

                // Wallpaper items
                Row {
                    anchors.centerIn: parent
                    spacing: WallpaperState.itemSpacing

                    Repeater {
                        model: WallpaperState.pageItems

                        WallpaperItem {
                            wallpaperPath: modelData.path
                            thumbnailPath: modelData.thumbnail
                            itemIndex: WallpaperState.currentPage * WallpaperState.itemsPerPage + index
                        }
                    }
                }

                // Empty state
                Item {
                    anchors.centerIn: parent
                    width: 300
                    height: WallpaperState.thumbnailHeight
                    visible: WallpaperState.wallpapers.length === 0 && !WallpaperState.isLoading

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰋩"
                            font.family: Fonts.icon
                            font.pixelSize: 48
                            color: Colors.foregroundMuted
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No wallpapers found"
                            font.pixelSize: 14
                            color: Colors.foregroundMuted
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Add images to " + WallpaperState.wallpaperDir
                            font.pixelSize: 11
                            color: Colors.foregroundAlt
                        }
                    }
                }

                // Loading state
                Item {
                    anchors.centerIn: parent
                    width: 200
                    height: WallpaperState.thumbnailHeight
                    visible: WallpaperState.isLoading

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰑓"
                            font.family: Fonts.icon
                            font.pixelSize: 32
                            color: Colors.primary

                            RotationAnimation on rotation {
                                running: WallpaperState.isLoading
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 1000
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Loading wallpapers..."
                            font.pixelSize: 12
                            color: Colors.foregroundAlt
                        }
                    }
                }

                // Next page button
                Rectangle {
                    id: nextButton
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 40
                    radius: 10
                    color: nextArea.containsMouse ? Colors.overlay : Colors.surface
                    visible: WallpaperState.wallpapers.length > WallpaperState.itemsPerPage

                    Text {
                        anchors.centerIn: parent
                        text: "󰅂"
                        font.family: Fonts.icon
                        font.pixelSize: 20
                        color: Colors.foreground
                    }

                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WallpaperState.nextPage()
                    }

                    HintTarget {
                        targetElement: nextButton
                        scope: "wallpaper"
                        action: () => WallpaperState.nextPage()
                        enabled: WallpaperState.wallpapers.length > WallpaperState.itemsPerPage
                    }
                }
            }

            // Spacer to push footer down
            Item {
                width: 1
                height: 1
            }

            // Footer
            Item {
                width: parent.width
                height: 1

                // Page indicator
                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: WallpaperState.pageIndicator
                    font.pixelSize: 12
                    color: Colors.foregroundAlt
                }

                // Keyboard hints
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    // Navigation hint
                    Row {
                        spacing: 6

                        Rectangle {
                            width: 24
                            height: 20
                            radius: 4
                            color: Colors.surface
                            border.width: 1
                            border.color: Colors.border

                            Text {
                                anchors.centerIn: parent
                                text: "h"
                                font.pixelSize: 10
                                font.bold: true
                                color: Colors.foreground
                            }
                        }

                        Text {
                            text: "/"
                            font.pixelSize: 11
                            color: Colors.foregroundMuted
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: 24
                            height: 20
                            radius: 4
                            color: Colors.surface
                            border.width: 1
                            border.color: Colors.border

                            Text {
                                anchors.centerIn: parent
                                text: "l"
                                font.pixelSize: 10
                                font.bold: true
                                color: Colors.foreground
                            }
                        }

                        Text {
                            text: "Navigate"
                            font.pixelSize: 11
                            color: Colors.foregroundAlt
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Select hint
                    Row {
                        spacing: 6

                        Rectangle {
                            width: 36
                            height: 20
                            radius: 4
                            color: Colors.surface
                            border.width: 1
                            border.color: Colors.border

                            Text {
                                anchors.centerIn: parent
                                text: "↵"
                                font.pixelSize: 12
                                color: Colors.foreground
                            }
                        }

                        Text {
                            text: "Apply"
                            font.pixelSize: 11
                            color: Colors.foregroundAlt
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Close hint
                    Row {
                        spacing: 6

                        Rectangle {
                            width: 36
                            height: 20
                            radius: 4
                            color: Colors.surface
                            border.width: 1
                            border.color: Colors.border

                            Text {
                                anchors.centerIn: parent
                                text: "Esc"
                                font.pixelSize: 9
                                font.bold: true
                                color: Colors.foreground
                            }
                        }

                        Text {
                            text: "Close"
                            font.pixelSize: 11
                            color: Colors.foregroundAlt
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        // Keyboard input handler
        FocusScope {
            id: keyboardHandler
            anchors.fill: parent
            focus: wallpaperWindow.expanded || HintNavigationService.active

            Keys.onPressed: function(event) {
                // Handle hint navigation first when active
                if (HintNavigationService.active) {
                    let key = ""
                    if (event.key === Qt.Key_Escape) {
                        key = "Escape"
                    } else if (event.key === Qt.Key_Backspace) {
                        key = "Backspace"
                    } else if (event.text && event.text.length === 1) {
                        key = event.text
                    }

                    if (key && HintNavigationService.handleKey(key, "wallpaper", event.modifiers)) {
                        event.accepted = true
                        return
                    }
                }

                switch (event.key) {
                    case Qt.Key_Escape:
                        WallpaperState.hide()
                        event.accepted = true
                        break
                    case Qt.Key_H:
                    case Qt.Key_Left:
                        if (event.modifiers & Qt.ControlModifier) {
                            WallpaperState.prevPage()
                        } else {
                            WallpaperState.selectPrev()
                        }
                        event.accepted = true
                        break
                    case Qt.Key_L:
                    case Qt.Key_Right:
                        if (event.modifiers & Qt.ControlModifier) {
                            WallpaperState.nextPage()
                        } else {
                            WallpaperState.selectNext()
                        }
                        event.accepted = true
                        break
                    case Qt.Key_J:
                    case Qt.Key_Down:
                        WallpaperState.selectNext()
                        event.accepted = true
                        break
                    case Qt.Key_K:
                    case Qt.Key_Up:
                        WallpaperState.selectPrev()
                        event.accepted = true
                        break
                    case Qt.Key_G:
                        if (event.modifiers & Qt.ShiftModifier) {
                            WallpaperState.selectLast()
                        } else {
                            WallpaperState.selectFirst()
                        }
                        event.accepted = true
                        break
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                    case Qt.Key_Space:
                        WallpaperState.applySelected()
                        event.accepted = true
                        break
                }
            }
        }
    }

    // Handle visibility changes for animations
    onExpandedChanged: {
        if (expanded) {
            slideInAnimation.start()
        } else {
            slideOutAnimation.start()
        }
    }
}
