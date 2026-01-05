import QtQuick
import Quickshell.Io
import "../../theme"
import "../common"

Rectangle {
    id: wallpaperItem

    property string wallpaperPath: ""
    property string thumbnailPath: ""
    property int itemIndex: 0
    property bool isSelected: WallpaperState.selectedIndex === itemIndex

    width: WallpaperState.thumbnailWidth + 8
    height: WallpaperState.thumbnailHeight + 8
    radius: 14
    color: itemArea.containsMouse ? Colors.overlay : Colors.surface
    border.width: isSelected ? 2 : 1
    border.color: isSelected ? Colors.primary : Colors.border

    Behavior on border.color {
        ColorAnimation { duration: 150 }
    }

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    // Selected glow effect
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: 18
        color: "transparent"
        border.width: 3
        border.color: isSelected ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3) : "transparent"
        visible: isSelected

        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }
    }

    // Create cache directory first
    Process {
        id: mkdirProcess
        command: ["mkdir", "-p", WallpaperState.cacheDir]
        onRunningChanged: {
            if (!running && needsThumbnail) {
                // Directory created, now generate thumbnail
                generateThumbnail.running = true
            }
        }
    }

    property bool needsThumbnail: false

    // Generate thumbnail
    Process {
        id: generateThumbnail
        command: ["convert", wallpaperPath,
                  "-resize", WallpaperState.thumbnailWidth + "x" + WallpaperState.thumbnailHeight + "^",
                  "-gravity", "center",
                  "-extent", WallpaperState.thumbnailWidth + "x" + WallpaperState.thumbnailHeight,
                  "-quality", "85",
                  thumbnailPath]

        onRunningChanged: {
            if (!running) {
                wallpaperItem.needsThumbnail = false
                // Force image reload after generation
                reloadTimer.start()
            }
        }
    }

    function requestThumbnail() {
        if (!needsThumbnail && !generateThumbnail.running) {
            needsThumbnail = true
            mkdirProcess.running = true
        }
    }

    // Timer to reload image after thumbnail generation
    Timer {
        id: reloadTimer
        interval: 100
        onTriggered: {
            thumbnailImage.source = ""
            thumbnailImage.source = "file://" + thumbnailPath
        }
    }

    // Thumbnail image container
    Item {
        anchors.fill: parent
        anchors.margins: 4
        clip: true

        // Placeholder background
        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Colors.overlay
            visible: thumbnailImage.status !== Image.Ready

            // Loading indicator
            Text {
                anchors.centerIn: parent
                property bool isGenerating: generateThumbnail.running || mkdirProcess.running || wallpaperItem.needsThumbnail
                text: isGenerating ? "󰑓" : "󰋩"
                font.family: Fonts.icon
                font.pixelSize: isGenerating ? 24 : 32
                color: Colors.foregroundMuted

                RotationAnimation on rotation {
                    running: generateThumbnail.running || mkdirProcess.running
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 1000
                }
            }
        }

        // Thumbnail image
        Image {
            id: thumbnailImage
            anchors.fill: parent
            anchors.margins: 2
            source: thumbnailPath ? "file://" + thumbnailPath : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            visible: status === Image.Ready

            onStatusChanged: {
                if (status === Image.Error && wallpaperPath) {
                    // Thumbnail doesn't exist or failed, generate it
                    wallpaperItem.requestThumbnail()
                }
            }
        }
    }

    // Hover scale effect
    transform: Scale {
        origin.x: wallpaperItem.width / 2
        origin.y: wallpaperItem.height / 2
        xScale: itemArea.containsMouse ? 1.02 : 1.0
        yScale: itemArea.containsMouse ? 1.02 : 1.0

        Behavior on xScale {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
        Behavior on yScale {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: itemArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            WallpaperState.selectedIndex = itemIndex
            WallpaperState.setWallpaper(wallpaperPath)
        }
    }

    HintTarget {
        targetElement: wallpaperItem
        scope: "wallpaper"
        action: () => {
            WallpaperState.selectedIndex = itemIndex
            WallpaperState.setWallpaper(wallpaperPath)
        }
    }
}
