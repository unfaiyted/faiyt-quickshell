import QtQuick
import Qt5Compat.GraphicalEffects
import "../../theme"
import "../../services"
import "../common"

Item {
    id: stickerGridView

    property var results: []
    property int selectedIndex: 0
    property int columns: 6
    property int cellWidth: 95
    property int cellHeight: 90  // More compact without description
    property int maxRows: 4

    // Check if we're showing info/empty state instead of stickers
    property bool isInfoMode: results.length > 0 && (results[0].type === "sticker-info" || results[0].type === "sticker-add")

    signal stickerClicked(int index)
    signal stickerActivated(int index)

    // Properties for preview panel size
    property int previewPanelHeight: 210  // carousel height including padding and copy hint

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
                    font.family: Fonts.emoji
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
                                font.family: Fonts.mono
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
                            font.family: Fonts.icon
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
                font.family: Fonts.icon
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

    // Carousel-style preview with adjacent stickers
    Item {
        id: previewPanel
        visible: !stickerGridView.isInfoMode && results.length > 0 && selectedIndex >= 0 && selectedIndex < results.length
        anchors.top: packBar.bottom
        anchors.topMargin: packBar.visible ? 16 : 12
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 32
        height: 190

        // Previous sticker (left side)
        Item {
            id: prevSticker
            visible: selectedIndex > 0
            anchors.right: centerSticker.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 70
            height: 70
            opacity: 0.4

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.6)
                border.width: 1
                border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.5)

                Image {
                    anchors.fill: parent
                    anchors.margins: 8
                    source: {
                        if (selectedIndex > 0 && results[selectedIndex - 1]) {
                            return results[selectedIndex - 1]?.imagePath ? "file://" + results[selectedIndex - 1].imagePath : ""
                        }
                        return ""
                    }
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    mipmap: true
                }
            }

            // Navigation hint
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 4
                text: "←"
                font.pixelSize: 10
                color: Colors.foregroundMuted
            }
        }

        // Center sticker (main preview)
        Item {
            id: centerSticker
            anchors.centerIn: parent
            width: 150
            height: 150

            // Outer glow layers
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 20
                height: parent.height + 20
                radius: 22
                color: Qt.rgba(Colors.iris.r, Colors.iris.g, Colors.iris.b, 0.08)
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 10
                height: parent.height + 10
                radius: 18
                color: Qt.rgba(Colors.iris.r, Colors.iris.g, Colors.iris.b, 0.12)
            }

            // Main card
            Rectangle {
                id: previewCard
                anchors.fill: parent
                radius: 14
                color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.95)
                border.width: 1
                border.color: Qt.rgba(Colors.iris.r, Colors.iris.g, Colors.iris.b, 0.3)

                Image {
                    id: previewImage
                    anchors.fill: parent
                    anchors.margins: 10
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

                    scale: 1.0
                    Behavior on source {
                        SequentialAnimation {
                            NumberAnimation { target: previewImage; property: "scale"; to: 0.85; duration: 80; easing.type: Easing.InQuad }
                            NumberAnimation { target: previewImage; property: "scale"; to: 1.0; duration: 150; easing.type: Easing.OutBack }
                        }
                    }
                }

                // Fallback emoji
                Text {
                    anchors.centerIn: parent
                    text: {
                        if (results.length > 0 && selectedIndex >= 0 && selectedIndex < results.length) {
                            return results[selectedIndex]?.emoji || "?"
                        }
                        return "?"
                    }
                    font.pixelSize: 64
                    font.family: Fonts.emoji
                    visible: previewImage.status !== Image.Ready
                }

                // Emoji badge
                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 6
                    anchors.bottomMargin: 6
                    width: 28
                    height: 28
                    radius: 14
                    color: Colors.overlay
                    border.width: 1
                    border.color: Colors.border

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (results.length > 0 && selectedIndex >= 0 && selectedIndex < results.length) {
                                return results[selectedIndex]?.emoji || ""
                            }
                            return ""
                        }
                        font.pixelSize: 14
                        font.family: Fonts.emoji
                    }
                }
            }

            // Copy hint below
            Rectangle {
                anchors.top: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 6
                width: hintRow.width + 14
                height: 22
                radius: 11
                color: Colors.surface
                border.width: 1
                border.color: Colors.border

                Row {
                    id: hintRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: "↵"
                        font.pixelSize: 11
                        font.bold: true
                        color: Colors.iris
                    }

                    Text {
                        text: "copy"
                        font.pixelSize: 10
                        color: Colors.foregroundMuted
                    }
                }
            }
        }

        // Next sticker (right side)
        Item {
            id: nextSticker
            visible: selectedIndex < results.length - 1
            anchors.left: centerSticker.right
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 70
            height: 70
            opacity: 0.4

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.6)
                border.width: 1
                border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.5)

                Image {
                    anchors.fill: parent
                    anchors.margins: 8
                    source: {
                        if (selectedIndex < results.length - 1 && results[selectedIndex + 1]) {
                            return results[selectedIndex + 1]?.imagePath ? "file://" + results[selectedIndex + 1].imagePath : ""
                        }
                        return ""
                    }
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    mipmap: true
                }
            }

            // Navigation hint
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 4
                text: "→"
                font.pixelSize: 10
                color: Colors.foregroundMuted
            }
        }
    }

    GridView {
        id: gridView
        visible: !stickerGridView.isInfoMode
        anchors.top: previewPanel.visible ? previewPanel.bottom : packBar.bottom
        anchors.topMargin: previewPanel.visible ? 16 : (packBar.visible ? 8 : 0)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width, stickerGridView.columns * stickerGridView.cellWidth)
        height: Math.min(contentHeight, stickerGridView.cellHeight * stickerGridView.maxRows)
        clip: true

        cellWidth: stickerGridView.cellWidth
        cellHeight: stickerGridView.cellHeight

        model: results

        delegate: Item {
            width: gridView.cellWidth
            height: stickerGridView.cellHeight

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

                // Sticker image with rounded mask
                Image {
                    id: stickerImage
                    anchors.fill: parent
                    anchors.margins: 2  // Leave room for selection border
                    source: modelData?.imagePath ? "file://" + modelData.imagePath : ""
                    fillMode: Image.PreserveAspectCrop  // Fill cell, crop overflow
                    asynchronous: true
                    visible: false  // Hidden, rendered through mask
                    smooth: true
                    mipmap: true
                    layer.enabled: true
                }

                Rectangle {
                    id: stickerImageMask
                    anchors.fill: parent
                    anchors.margins: 2  // Match image margins
                    radius: cellBackground.radius - 2
                    visible: false
                    layer.enabled: true
                }

                OpacityMask {
                    anchors.fill: parent
                    anchors.margins: 2  // Match image margins
                    source: stickerImage
                    maskSource: stickerImageMask
                    visible: stickerImage.status === Image.Ready
                }

                // Fallback when image not loaded - large centered emoji
                Text {
                    anchors.centerIn: parent
                    text: modelData?.emoji || "?"
                    font.pixelSize: 48
                    font.family: Fonts.emoji
                    visible: stickerImage.status !== Image.Ready && stickerImage.status !== Image.Loading
                }

                // Loading indicator
                Text {
                    anchors.centerIn: parent
                    text: "󰋚"
                    font.family: Fonts.icon
                    font.pixelSize: 24
                    color: Colors.foregroundMuted
                    visible: stickerImage.status === Image.Loading

                    SequentialAnimation on opacity {
                        running: stickerImage.status === Image.Loading
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 500 }
                        NumberAnimation { to: 1; duration: 500 }
                    }
                }

                // Emoji overlay badge (bottom-right corner)
                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 4
                    anchors.bottomMargin: 4
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
                        font.family: Fonts.emoji
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

                HintTarget {
                    targetElement: cellBackground
                    scope: "launcher"
                    enabled: LauncherState.visible && !stickerGridView.isInfoMode
                    action: () => {
                        HintNavigationService.deactivate()
                        stickerGridView.stickerClicked(index)
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
