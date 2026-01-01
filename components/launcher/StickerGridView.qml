import QtQuick
import "../../theme"
import "../../services"

Item {
    id: stickerGridView

    property var results: []
    property int selectedIndex: 0
    property int columns: 6
    property int cellWidth: 100
    property int cellHeight: 110
    property int imageSize: 64
    property int maxRows: 6

    // Check if we're showing info/empty state instead of stickers
    property bool isInfoMode: results.length > 0 && (results[0].type === "sticker-info" || results[0].type === "sticker-add")

    signal stickerClicked(int index)
    signal stickerActivated(int index)

    // Properties for preview panel size
    property int previewSize: 128
    property int previewPanelHeight: previewSize + 16 + 8  // image + padding + margin

    width: parent.width
    height: isInfoMode ? emptyState.height : (
        (loadingIndicator.visible ? loadingIndicator.height + 6 : 0) +
        packBar.height +
        (previewPanel.visible ? previewPanelHeight : 0) +
        Math.min(gridView.contentHeight, cellHeight * maxRows) + 8
    )

    // Empty/Info state - shown when no stickers installed or adding pack
    Rectangle {
        id: emptyState
        visible: stickerGridView.isInfoMode
        width: parent.width
        height: emptyCard.height + 32
        color: "transparent"

        Rectangle {
            id: emptyCard
            anchors.centerIn: parent
            width: Math.min(parent.width - 32, 400)
            height: emptyContent.height + 48
            radius: 16
            color: Colors.surface
            border.width: 1
            border.color: Colors.border

            Column {
                id: emptyContent
                anchors.centerIn: parent
                spacing: 16
                width: parent.width - 48

                // Icon
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: results.length > 0 && results[0].type === "sticker-add" ? "📦" : "🎨"
                    font.pixelSize: 48
                    font.family: "Noto Color Emoji"
                }

                // Title
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: results.length > 0 ? results[0].title : "Stickers"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    color: Colors.foreground
                }

                // Description
                Text {
                    width: parent.width
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: results.length > 0 ? results[0].description : ""
                    font.pixelSize: 13
                    color: Colors.foregroundMuted
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                // Instructions for empty state
                Column {
                    visible: results.length > 0 && results[0].type === "sticker-info"
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Colors.border
                    }

                    Text {
                        width: parent.width
                        text: "How to add stickers:"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Colors.foreground
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Rectangle {
                            width: codeText.width + 16
                            height: 24
                            radius: 6
                            color: Colors.overlay

                            Text {
                                id: codeText
                                anchors.centerIn: parent
                                text: "s: add <signal-url>"
                                font.pixelSize: 12
                                font.family: "monospace"
                                color: Colors.primary
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: "Find stickers at signalstickers.org"
                        font.pixelSize: 11
                        color: Colors.foregroundAlt
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Add button for sticker-add type
                Rectangle {
                    visible: results.length > 0 && results[0].type === "sticker-add"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: addButtonRow.width + 32
                    height: 40
                    radius: 10
                    color: addButtonArea.containsMouse ? Colors.iris : Colors.overlay
                    border.width: 1
                    border.color: addButtonArea.containsMouse ? Colors.iris : Colors.border

                    Row {
                        id: addButtonRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "󰋚"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 16
                            color: addButtonArea.containsMouse ? Colors.background : Colors.iris
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Download & Add Pack"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: addButtonArea.containsMouse ? Colors.background : Colors.foreground
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: addButtonArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (results.length > 0 && results[0].action) {
                                results[0].action()
                            }
                        }
                    }
                }
            }
        }
    }

    // Loading indicator - shown when stickers are being downloaded
    Rectangle {
        id: loadingIndicator
        visible: !stickerGridView.isInfoMode && StickerService.isDownloading
        width: parent.width
        height: 28
        color: Qt.rgba(Colors.iris.r, Colors.iris.g, Colors.iris.b, 0.1)
        radius: 6

        Row {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "󰋚"
                font.family: "Symbols Nerd Font"
                font.pixelSize: 14
                color: Colors.iris
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on opacity {
                    running: loadingIndicator.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 400 }
                    NumberAnimation { to: 1; duration: 400 }
                }
            }

            Text {
                text: "Downloading stickers..."
                font.pixelSize: 12
                color: Colors.iris
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Pack selection bar
    StickerPackBar {
        id: packBar
        anchors.top: loadingIndicator.visible ? loadingIndicator.bottom : parent.top
        anchors.topMargin: loadingIndicator.visible ? 6 : 0
        width: parent.width
        visible: !stickerGridView.isInfoMode && StickerService.stickerPacks.length >= 1
        z: 10  // Above preview panel so tooltips show

        onPackSelected: function(packId) {
            StickerService.selectPack(packId)
            // Trigger re-search to filter by selected pack
            LauncherState.performSearch()
        }
    }

    // Large preview panel for selected sticker
    Rectangle {
        id: previewPanel
        visible: !stickerGridView.isInfoMode && results.length > 0 && selectedIndex >= 0 && selectedIndex < results.length
        anchors.top: packBar.bottom
        anchors.topMargin: packBar.visible ? 8 : 4
        anchors.horizontalCenter: parent.horizontalCenter
        width: previewContent.width + 24
        height: previewContent.height + 16
        radius: 12
        color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.95)
        border.width: 1
        border.color: Colors.border

        Row {
            id: previewContent
            anchors.centerIn: parent
            spacing: 16

            // Large sticker preview
            Item {
                width: 128
                height: 128
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: previewImage
                    anchors.fill: parent
                    source: {
                        if (results.length > 0 && selectedIndex >= 0 && selectedIndex < results.length) {
                            const item = results[selectedIndex]
                            return item?.imagePath ? "file://" + item.imagePath : ""
                        }
                        return ""
                    }
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: status === Image.Ready
                    smooth: true
                    mipmap: true
                }

                // Fallback emoji when image not loaded
                Text {
                    anchors.centerIn: parent
                    text: {
                        if (results.length > 0 && selectedIndex >= 0 && selectedIndex < results.length) {
                            return results[selectedIndex]?.emoji || "?"
                        }
                        return "?"
                    }
                    font.pixelSize: 72
                    font.family: "Noto Color Emoji"
                    visible: previewImage.status !== Image.Ready
                }
            }

            // Sticker info
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                width: 140

                // Emoji badge
                Rectangle {
                    width: emojiText.width + 16
                    height: 32
                    radius: 16
                    color: Colors.overlay
                    border.width: 1
                    border.color: Colors.border

                    Text {
                        id: emojiText
                        anchors.centerIn: parent
                        text: {
                            if (results.length > 0 && selectedIndex >= 0 && selectedIndex < results.length) {
                                return results[selectedIndex]?.emoji || ""
                            }
                            return ""
                        }
                        font.pixelSize: 18
                        font.family: "Noto Color Emoji"
                    }
                }

                // Pack title
                Text {
                    width: parent.width
                    text: {
                        if (results.length > 0 && selectedIndex >= 0 && selectedIndex < results.length) {
                            return results[selectedIndex]?.description || ""
                        }
                        return ""
                    }
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Colors.foreground
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                // Hint
                Text {
                    text: "Enter to copy"
                    font.pixelSize: 11
                    color: Colors.foregroundMuted
                }
            }
        }
    }

    GridView {
        id: gridView
        visible: !stickerGridView.isInfoMode
        anchors.top: previewPanel.visible ? previewPanel.bottom : packBar.bottom
        anchors.topMargin: previewPanel.visible ? 8 : (packBar.visible ? 8 : 0)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width, stickerGridView.columns * stickerGridView.cellWidth)
        height: Math.min(contentHeight, stickerGridView.cellHeight * stickerGridView.maxRows)
        clip: true

        cellWidth: stickerGridView.cellWidth
        cellHeight: stickerGridView.cellHeight

        model: results

        delegate: Item {
            id: delegateItem
            width: gridView.cellWidth
            height: stickerGridView.cellHeight
            z: mouseArea.containsMouse ? 10 : 1

            Rectangle {
                id: cellBackground
                anchors.centerIn: parent
                width: stickerGridView.cellWidth - 8
                height: stickerGridView.cellHeight - 8
                radius: 8
                color: index === stickerGridView.selectedIndex
                    ? Qt.rgba(Colors.iris.r, Colors.iris.g, Colors.iris.b, 0.15)
                    : mouseArea.containsMouse
                        ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.8)
                        : "transparent"
                border.width: index === stickerGridView.selectedIndex ? 2 : 0
                border.color: Colors.iris

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }

                Behavior on border.width {
                    NumberAnimation { duration: 100 }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    // Sticker image with emoji overlay
                    Item {
                        width: stickerGridView.imageSize
                        height: stickerGridView.imageSize
                        anchors.horizontalCenter: parent.horizontalCenter

                        Image {
                            id: stickerImage
                            anchors.fill: parent
                            source: modelData?.imagePath ? "file://" + modelData.imagePath : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            visible: status === Image.Ready
                            smooth: true
                            mipmap: true
                        }

                        // Fallback when image not loaded - large centered emoji
                        Text {
                            anchors.centerIn: parent
                            text: modelData?.emoji || "?"
                            font.pixelSize: 40
                            font.family: "Noto Color Emoji"
                            visible: stickerImage.status !== Image.Ready && stickerImage.status !== Image.Loading
                        }

                        // Loading indicator
                        Rectangle {
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            radius: 14
                            color: Colors.surface
                            visible: stickerImage.status === Image.Loading

                            Text {
                                anchors.centerIn: parent
                                text: "..."
                                font.pixelSize: 12
                                color: Colors.foregroundMuted
                            }
                        }

                        // Emoji overlay badge (bottom-right corner)
                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: -2
                            anchors.bottomMargin: -2
                            width: 22
                            height: 22
                            radius: 11
                            color: Colors.overlay
                            border.width: 1
                            border.color: Colors.border
                            visible: stickerImage.status === Image.Ready && modelData?.emoji

                            Text {
                                anchors.centerIn: parent
                                text: modelData?.emoji || ""
                                font.pixelSize: 12
                                font.family: "Noto Color Emoji"
                            }
                        }
                    }

                    // Pack title (truncated)
                    Text {
                        width: stickerGridView.cellWidth - 16
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData?.description || ""
                        font.pixelSize: 10
                        color: Colors.foregroundMuted
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        stickerGridView.stickerClicked(index)
                    }

                    onDoubleClicked: {
                        stickerGridView.stickerActivated(index)
                    }
                }

                // Tooltip with emoji
                Rectangle {
                    id: tooltip
                    visible: mouseArea.containsMouse && modelData?.sticker
                    anchors.top: parent.bottom
                    anchors.topMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: tooltipText.width + 16
                    height: tooltipText.height + 8
                    radius: 4
                    color: Colors.overlay
                    border.width: 1
                    border.color: Colors.border
                    z: 100

                    Row {
                        id: tooltipText
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: modelData?.emoji || ""
                            font.pixelSize: 14
                            font.family: "Noto Color Emoji"
                        }

                        Text {
                            text: modelData?.description || ""
                            font.pixelSize: 11
                            color: Colors.foreground
                        }
                    }
                }
            }
        }

        // Auto-scroll to selected item
        Connections {
            target: stickerGridView
            function onSelectedIndexChanged() {
                gridView.positionViewAtIndex(stickerGridView.selectedIndex, GridView.Contain)
            }
        }
    }

    // Navigation functions
    function selectNext() {
        if (results.length > 0) {
            selectedIndex = (selectedIndex + 1) % results.length
        }
    }

    function selectPrevious() {
        if (results.length > 0) {
            selectedIndex = selectedIndex > 0 ? selectedIndex - 1 : results.length - 1
        }
    }

    function selectDown() {
        if (results.length > 0) {
            let newIndex = selectedIndex + columns
            if (newIndex < results.length) {
                selectedIndex = newIndex
            }
        }
    }

    function selectUp() {
        if (results.length > 0) {
            let newIndex = selectedIndex - columns
            if (newIndex >= 0) {
                selectedIndex = newIndex
            }
        }
    }

    function selectLeft() {
        if (results.length > 0 && selectedIndex > 0) {
            selectedIndex = selectedIndex - 1
        }
    }

    function selectRight() {
        if (results.length > 0 && selectedIndex < results.length - 1) {
            selectedIndex = selectedIndex + 1
        }
    }
}
