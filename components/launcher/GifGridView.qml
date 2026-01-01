import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "results"

Item {
    id: gifGridView

    property var results: []
    property int selectedIndex: 0
    property int columns: 4
    property int cellWidth: 140
    property int cellHeight: 120
    property int imageWidth: 120
    property int imageHeight: 80
    property int maxRows: 3

    // Check if we're showing info/loading state instead of grid
    property bool isInfoMode: results.length > 0 && (results[0].type === "gif-info" || results[0].type === "gif-loading")

    // Preview panel properties
    property int previewHeight: 160
    property int previewPanelHeight: previewHeight + 24
    property bool showPreview: !isInfoMode && results.length > 0 && selectedIndex >= 0 && selectedIndex < results.length && results[selectedIndex]?.type === "gif"

    signal gifClicked(int index)
    signal gifActivated(int index)

    width: parent.width
    height: isInfoMode ? infoState.height : (
        (showPreview ? previewPanelHeight : 0) +
        Math.min(gridView.contentHeight, cellHeight * maxRows) + 8
    )

    // Reference to GifResults for copy functions
    GifResults {
        id: gifResultsHelper
    }

    // Info/Loading state - shown when setup needed, loading, or error
    Rectangle {
        id: infoState
        visible: gifGridView.isInfoMode
        width: parent.width
        height: infoCard.height + 32
        color: "transparent"

        Rectangle {
            id: infoCard
            anchors.centerIn: parent
            width: Math.min(parent.width - 32, 400)
            height: infoContent.height + 48
            radius: 16
            color: Colors.surface
            border.width: 1
            border.color: Colors.border

            Column {
                id: infoContent
                anchors.centerIn: parent
                spacing: 16
                width: parent.width - 48

                // Icon
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        if (results.length === 0) return "󰵸"
                        if (results[0].data?.needsSetup) return "󰌉"
                        if (results[0].data?.isLoading) return "󰋚"
                        if (results[0].data?.isError) return "󰀦"
                        if (results[0].data?.isEmpty) return "󰋙"
                        return "󰵸"
                    }
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 48
                    color: {
                        if (results.length === 0) return Colors.foregroundMuted
                        if (results[0].data?.needsSetup) return Colors.gold
                        if (results[0].data?.isLoading) return Colors.iris
                        if (results[0].data?.isError) return Colors.love
                        return Colors.foregroundMuted
                    }

                    SequentialAnimation on opacity {
                        running: results.length > 0 && results[0].data?.isLoading
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.4; duration: 600 }
                        NumberAnimation { to: 1; duration: 600 }
                    }
                }

                // Title
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: results.length > 0 ? results[0].title : "GIF Search"
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

                // Setup instructions (only for needsSetup state)
                Column {
                    id: setupInstructions
                    visible: results.length > 0 && results[0].data?.needsSetup === true
                    width: parent.width
                    height: visible ? implicitHeight : 0
                    spacing: 12
                    clip: true

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Colors.border
                    }

                    Text {
                        width: parent.width
                        text: "How to set up:"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Colors.foreground
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Step 1: Get API key
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Text {
                            text: "1."
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Colors.primary
                        }

                        Text {
                            text: "Get a free API key from"
                            font.pixelSize: 12
                            color: Colors.foregroundMuted
                        }

                        Rectangle {
                            width: linkText.width + 12
                            height: 22
                            radius: 4
                            color: linkArea.containsMouse ? Colors.overlay : Colors.surface
                            border.width: 1
                            border.color: Colors.border

                            Text {
                                id: linkText
                                anchors.centerIn: parent
                                text: "developers.google.com/tenor"
                                font.pixelSize: 11
                                color: Colors.primary
                            }

                            MouseArea {
                                id: linkArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.openUrlExternally("https://developers.google.com/tenor/guides/quickstart")
                            }
                        }
                    }

                    // Step 2: Set env var
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Text {
                            text: "2."
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Colors.primary
                        }

                        Text {
                            text: "Add to your shell config:"
                            font.pixelSize: 12
                            color: Colors.foregroundMuted
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: envCode.width + 20
                        height: 26
                        radius: 6
                        color: Colors.overlay

                        Text {
                            id: envCode
                            anchors.centerIn: parent
                            text: "export TENOR_API_KEY=\"your-key\""
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: Colors.iris
                        }
                    }
                }
            }
        }
    }

    // Popup menu for copy options
    Rectangle {
        id: copyMenu
        visible: false
        z: 1000
        width: 170
        height: menuColumn.height + 16
        radius: 12
        color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.95)
        border.width: 1
        border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.5)

        property var currentGif: null
        property int menuIndex: -1

        // Shadow effect
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 16
            color: Qt.rgba(0, 0, 0, 0.25)
            z: -1
        }

        Column {
            id: menuColumn
            anchors.centerIn: parent
            width: parent.width - 16
            spacing: 4

            // Copy URL option
            Rectangle {
                width: parent.width
                height: 38
                radius: 8
                color: urlArea.containsMouse
                    ? Qt.rgba(Colors.foam.r, Colors.foam.g, Colors.foam.b, 0.15)
                    : "transparent"

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    spacing: 10

                    Text {
                        text: "󰌹"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 16
                        color: Colors.foam
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Copy URL"
                        font.pixelSize: 13
                        color: Colors.foreground
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: urlArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (copyMenu.currentGif) {
                            gifResultsHelper.copyUrl(copyMenu.currentGif.fullUrl)
                            copyMenu.visible = false
                            LauncherState.hide()
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                width: parent.width - 8
                anchors.horizontalCenter: parent.horizontalCenter
                height: 1
                color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.5)
            }

            // Copy Image option
            Rectangle {
                width: parent.width
                height: 38
                radius: 8
                color: imageArea.containsMouse
                    ? Qt.rgba(Colors.iris.r, Colors.iris.g, Colors.iris.b, 0.15)
                    : "transparent"

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    spacing: 10

                    Text {
                        text: "󰋩"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 16
                        color: Colors.iris
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Copy Image"
                        font.pixelSize: 13
                        color: Colors.foreground
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: imageArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (copyMenu.currentGif) {
                            gifResultsHelper.copyImage(copyMenu.currentGif.fullUrl)
                            copyMenu.visible = false
                            LauncherState.hide()
                        }
                    }
                }
            }
        }

        // Click outside to close
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: copyMenu.visible = false
        }
    }

    // Close menu when clicking outside
    MouseArea {
        anchors.fill: parent
        visible: copyMenu.visible
        z: 500
        onClicked: copyMenu.visible = false
    }

    // Large preview panel for selected GIF
    Rectangle {
        id: previewPanel
        visible: gifGridView.showPreview
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: previewContent.width + 32
        height: previewContent.height + 20
        radius: 12
        color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.95)
        border.width: 1
        border.color: Colors.border

        Row {
            id: previewContent
            anchors.centerIn: parent
            spacing: 20

            // Large GIF preview (animated)
            Rectangle {
                width: gifGridView.previewHeight
                height: gifGridView.previewHeight
                radius: 8
                color: Colors.overlay
                clip: true
                anchors.verticalCenter: parent.verticalCenter

                AnimatedImage {
                    id: previewGif
                    anchors.fill: parent
                    source: {
                        if (results.length > 0 && selectedIndex >= 0 && selectedIndex < results.length) {
                            const item = results[selectedIndex]
                            // Use full URL for preview for better quality
                            return item?.data?.fullUrl || item?.data?.previewUrl || ""
                        }
                        return ""
                    }
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: true
                    playing: true
                    visible: status === Image.Ready
                }

                // Loading state
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: previewGif.status === Image.Loading

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰋚"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 32
                        color: Colors.foregroundMuted

                        SequentialAnimation on opacity {
                            running: previewGif.status === Image.Loading
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 500 }
                            NumberAnimation { to: 1; duration: 500 }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Loading..."
                        font.pixelSize: 11
                        color: Colors.foregroundMuted
                    }
                }

                // Error state
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    visible: previewGif.status === Image.Error

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰀦"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 32
                        color: Colors.love
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Failed to load"
                        font.pixelSize: 11
                        color: Colors.foregroundMuted
                    }
                }
            }

            // GIF info
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                width: 180

                // Title
                Text {
                    width: parent.width
                    text: {
                        if (results.length > 0 && selectedIndex >= 0 && selectedIndex < results.length) {
                            return results[selectedIndex]?.title || "GIF"
                        }
                        return "GIF"
                    }
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Colors.foreground
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }

                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.5)
                }

                // Copy options hint
                Column {
                    spacing: 4

                    Row {
                        spacing: 6

                        Text {
                            text: "󰌹"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 12
                            color: Colors.foam
                        }

                        Text {
                            text: "Enter → Copy URL"
                            font.pixelSize: 11
                            color: Colors.foregroundMuted
                        }
                    }

                    Row {
                        spacing: 6

                        Text {
                            text: "󰋩"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 12
                            color: Colors.iris
                        }

                        Text {
                            text: "Click → Copy Options"
                            font.pixelSize: 11
                            color: Colors.foregroundMuted
                        }
                    }
                }
            }
        }
    }

    GridView {
        id: gridView
        visible: !gifGridView.isInfoMode
        anchors.top: previewPanel.visible ? previewPanel.bottom : parent.top
        anchors.topMargin: previewPanel.visible ? 8 : 0
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width, gifGridView.columns * gifGridView.cellWidth)
        height: Math.min(contentHeight, gifGridView.cellHeight * gifGridView.maxRows)
        clip: true

        cellWidth: gifGridView.cellWidth
        cellHeight: gifGridView.cellHeight

        model: results

        delegate: Item {
            width: gridView.cellWidth
            height: gifGridView.cellHeight

            Rectangle {
                id: cellBackground
                anchors.centerIn: parent
                width: gifGridView.cellWidth - 8
                height: gifGridView.cellHeight - 8
                radius: 8
                color: index === gifGridView.selectedIndex
                    ? Qt.rgba(Colors.iris.r, Colors.iris.g, Colors.iris.b, 0.15)
                    : mouseArea.containsMouse
                        ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.8)
                        : "transparent"
                border.width: index === gifGridView.selectedIndex ? 2 : 0
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

                    // GIF preview container with rounded corners
                    Rectangle {
                        width: gifGridView.imageWidth
                        height: gifGridView.imageHeight
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: 6
                        color: Colors.surface
                        clip: true

                        // Animated GIF preview
                        AnimatedImage {
                            id: gifImage
                            anchors.fill: parent
                            source: modelData?.data?.previewUrl || ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: true
                            playing: mouseArea.containsMouse || index === gifGridView.selectedIndex
                            visible: status === Image.Ready
                        }

                        // Loading placeholder
                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            visible: gifImage.status === Image.Loading || gifImage.status === Image.Null

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰋚"
                                font.family: "Symbols Nerd Font"
                                font.pixelSize: 24
                                color: Colors.foregroundMuted

                                SequentialAnimation on opacity {
                                    running: gifImage.status === Image.Loading
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.3; duration: 500 }
                                    NumberAnimation { to: 1; duration: 500 }
                                }
                            }
                        }

                        // Error state
                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            visible: gifImage.status === Image.Error

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰀦"
                                font.family: "Symbols Nerd Font"
                                font.pixelSize: 24
                                color: Colors.love
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Failed"
                                font.pixelSize: 9
                                color: Colors.foregroundMuted
                            }
                        }
                    }

                    // Title (truncated)
                    Text {
                        width: gifGridView.cellWidth - 16
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData?.title || ""
                        font.pixelSize: 10
                        color: Colors.foregroundMuted
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        maximumLineCount: 1
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        gifGridView.selectedIndex = index
                        // Show copy menu
                        if (modelData?.data && !modelData.data.isLoading && !modelData.data.isError) {
                            copyMenu.currentGif = modelData.data
                            copyMenu.x = cellBackground.mapToItem(gifGridView, cellBackground.width / 2, 0).x - copyMenu.width / 2
                            copyMenu.y = cellBackground.mapToItem(gifGridView, 0, cellBackground.height).y + 4
                            copyMenu.visible = true
                        }
                    }

                    onDoubleClicked: {
                        // Double click = copy URL (quick action)
                        if (modelData?.data && !modelData.data.isLoading && !modelData.data.isError) {
                            gifResultsHelper.copyUrl(modelData.data.fullUrl)
                            LauncherState.hide()
                        }
                    }
                }
            }
        }

        // Auto-scroll to selected item
        Connections {
            target: gifGridView
            function onSelectedIndexChanged() {
                gridView.positionViewAtIndex(gifGridView.selectedIndex, GridView.Contain)
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

    // Activate selected (show menu or copy URL)
    function activateSelected() {
        if (selectedIndex >= 0 && selectedIndex < results.length) {
            let result = results[selectedIndex]
            if (result?.data && !result.data.isLoading && !result.data.isError) {
                // Default action: copy URL
                gifResultsHelper.copyUrl(result.data.fullUrl)
                LauncherState.hide()
            }
        }
    }
}
