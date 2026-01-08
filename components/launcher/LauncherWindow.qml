import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"
import "../common"

PanelWindow {
    id: launcherWindow

    // Center the window
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    property bool expanded: LauncherState.visible
    property int baseWidth: LauncherState.isStickerMode ? 640 : 600

    // Hint navigation state
    property bool launcherHintsActive: {
        const popupScope = HintNavigationService.activePopupScope
        return HintNavigationService.active && expanded &&
               (popupScope === "" || popupScope === "launcher" || popupScope === "launcher-menu")
    }

    // Context menu state
    property var contextMenuResult: null
    property Item contextMenuAnchor: null

    function showContextMenu(result, anchorItem) {
        contextMenuResult = result
        contextMenuAnchor = anchorItem
        resultContextMenu.result = result
        resultContextMenu.visible = true
        HintNavigationService.setPopupScope("launcher-menu")
    }

    function hideContextMenu() {
        resultContextMenu.visible = false
        contextMenuResult = null
        contextMenuAnchor = null
    }

    implicitWidth: baseWidth
    implicitHeight: expanded ? Math.min(contentColumn.implicitHeight + 32, 650) : 0
    exclusiveZone: 0
    color: "transparent"

    // Layer shell configuration
    WlrLayershell.namespace: "quickshell:launcher"
    WlrLayershell.keyboardFocus: expanded ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    visible: ConfigService.windowLauncherEnabled && (expanded || hideAnimation.running || overlayAnimation.running)

    // Darkening overlay that fades in with launcher
    Rectangle {
        id: darkenOverlay
        anchors.fill: parent
        color: launcherWindow.expanded ? Qt.rgba(0, 0, 0, 0.4) : Qt.rgba(0, 0, 0, 0)

        Behavior on color {
            ColorAnimation {
                id: overlayAnimation
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        // Click outside to close
        MouseArea {
            anchors.fill: parent
            onClicked: LauncherState.hide()
        }
    }

    // Animated gradient border wrapper
    Item {
        id: gradientWrapper
        width: launcherWindow.baseWidth + 6  // 3px border on each side
        height: contentColumn.implicitHeight + 32 + 6
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(80, (parent.height - height) / 2.2)

        opacity: launcherWindow.expanded ? 1 : 0
        scale: launcherWindow.expanded ? 1 : 0.95

        Behavior on opacity {
            NumberAnimation {
                id: hideAnimation
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        // Animated gradient offset (0 to 1, loops continuously)
        property real gradientOffset: 0
        NumberAnimation on gradientOffset {
            from: 0
            to: 1
            duration: 6000  // 6 seconds for full cycle
            loops: Animation.Infinite
            running: launcherWindow.expanded
        }

        // Helper functions for gradient colors
        function lerpColor(c1, c2, t) {
            return Qt.rgba(
                c1.r + (c2.r - c1.r) * t,
                c1.g + (c2.g - c1.g) * t,
                c1.b + (c2.b - c1.b) * t,
                1.0
            )
        }

        function getGradientColor(baseOffset) {
            let colors = [Colors.love, Colors.pine, Colors.rose, Colors.iris]
            let offset = (baseOffset + gradientWrapper.gradientOffset) % 1.0
            let scaledPos = offset * 4
            let idx = Math.floor(scaledPos) % 4
            let nextIdx = (idx + 1) % 4
            let t = scaledPos - Math.floor(scaledPos)
            return lerpColor(colors[idx], colors[nextIdx], t)
        }

        // Soft glow layers - 5 layers for smooth falloff
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 40
            height: parent.height + 40
            radius: 29
            color: "transparent"
            border.width: 10
            border.color: Qt.rgba(Colors.iris.r, Colors.iris.g, Colors.iris.b, 0.03)
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 28
            height: parent.height + 28
            radius: 26
            color: "transparent"
            border.width: 7
            border.color: Qt.rgba(Colors.iris.r, Colors.iris.g, Colors.iris.b, 0.05)
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 18
            height: parent.height + 18
            radius: 23
            color: "transparent"
            border.width: 5
            border.color: Qt.rgba(Colors.iris.r, Colors.iris.g, Colors.iris.b, 0.08)
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 10
            height: parent.height + 10
            radius: 21
            color: "transparent"
            border.width: 3
            border.color: Qt.rgba(Colors.iris.r, Colors.iris.g, Colors.iris.b, 0.11)
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 4
            height: parent.height + 4
            radius: 20
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(Colors.iris.r, Colors.iris.g, Colors.iris.b, 0.14)
        }

        // Gradient border rectangle
        Rectangle {
            id: gradientBorder
            anchors.fill: parent
            radius: 19

            // Smooth animated gradient
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: gradientWrapper.getGradientColor(0.0) }
                GradientStop { position: 0.2; color: gradientWrapper.getGradientColor(0.2) }
                GradientStop { position: 0.4; color: gradientWrapper.getGradientColor(0.4) }
                GradientStop { position: 0.6; color: gradientWrapper.getGradientColor(0.6) }
                GradientStop { position: 0.8; color: gradientWrapper.getGradientColor(0.8) }
                GradientStop { position: 1.0; color: gradientWrapper.getGradientColor(1.0) }
            }
        }

        // Main content panel sits on top, revealing gradient border
        Rectangle {
            id: contentPanel
            anchors.fill: parent
            anchors.margins: 3  // 3px gradient border visible
            radius: 16
            color: Colors.background

            // Stop clicks from closing
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            Column {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

            // Search entry
            LauncherEntry {
                id: searchEntry
                width: parent.width
                focus: launcherWindow.expanded
            }

            // Results display - grid (emoji/sticker/gif) or list (other)
            Loader {
                id: resultsLoader
                width: parent.width
                sourceComponent: LauncherState.isGifMode ? gifGridComponent :
                                 LauncherState.isStickerMode ? stickerGridComponent :
                                 LauncherState.isEmojiMode ? emojiGridComponent : listComponent

                Component {
                    id: gifGridComponent
                    GifGridView {
                        width: parent.width
                        results: LauncherState.results
                        selectedIndex: LauncherState.selectedIndex
                        columns: LauncherState.gridColumns

                        onSelectedIndexChanged: {
                            LauncherState.selectedIndex = selectedIndex
                        }

                        onGifClicked: function(index) {
                            LauncherState.selectedIndex = index
                            // Don't activate - let the grid view handle the popup
                        }

                        onGifActivated: function(index) {
                            LauncherState.selectedIndex = index
                            LauncherState.activateSelected()
                        }

                        onCategorySelected: function(searchTerm) {
                            // Update search text to search for the category
                            LauncherState.searchText = "gif: " + searchTerm
                        }
                    }
                }

                Component {
                    id: stickerGridComponent
                    StickerGridView {
                        width: parent.width
                        results: LauncherState.results
                        selectedIndex: LauncherState.selectedIndex
                        columns: LauncherState.gridColumns

                        onSelectedIndexChanged: {
                            LauncherState.selectedIndex = selectedIndex
                        }

                        onStickerClicked: function(index) {
                            LauncherState.selectedIndex = index
                            LauncherState.activateSelected()
                        }

                        onStickerActivated: function(index) {
                            LauncherState.selectedIndex = index
                            LauncherState.activateSelected()
                        }
                    }
                }

                Component {
                    id: emojiGridComponent
                    EmojiGridView {
                        width: parent.width
                        results: LauncherState.results
                        selectedIndex: LauncherState.selectedIndex
                        columns: LauncherState.gridColumns

                        onSelectedIndexChanged: {
                            LauncherState.selectedIndex = selectedIndex
                        }

                        onEmojiClicked: function(index) {
                            LauncherState.selectedIndex = index
                            LauncherState.activateSelected()
                        }

                        onEmojiActivated: function(index) {
                            LauncherState.selectedIndex = index
                            LauncherState.activateSelected()
                        }
                    }
                }

                Component {
                    id: listComponent
                    ListView {
                        id: resultsList
                        width: parent.width
                        height: Math.min(contentHeight, 480)
                        clip: true
                        spacing: 4
                        model: LauncherState.results

                        delegate: Loader {
                            width: resultsList.width
                            height: modelData?.type === "window" ? 70 : 52

                            sourceComponent: modelData?.type === "window" ? windowResultComponent : resultComponent

                            Component {
                                id: resultComponent
                                ResultItem {
                                    width: resultsList.width
                                    result: modelData
                                    isSelected: index === LauncherState.selectedIndex

                                    onClicked: {
                                        LauncherState.selectedIndex = index
                                        LauncherState.activateSelected()
                                    }

                                    onContextMenu: (result) => {
                                        launcherWindow.showContextMenu(result, this)
                                    }
                                }
                            }

                            Component {
                                id: windowResultComponent
                                WindowResultItem {
                                    width: resultsList.width
                                    result: modelData
                                    isSelected: index === LauncherState.selectedIndex

                                    onClicked: {
                                        LauncherState.selectedIndex = index
                                        LauncherState.activateSelected()
                                    }

                                    onContextMenu: (result) => {
                                        launcherWindow.showContextMenu(result, this)
                                    }
                                }
                            }
                        }

                        // Auto-scroll to selected item
                        onCurrentIndexChanged: {
                            positionViewAtIndex(LauncherState.selectedIndex, ListView.Contain)
                        }

                        Connections {
                            target: LauncherState
                            function onSelectedIndexChanged() {
                                resultsList.positionViewAtIndex(LauncherState.selectedIndex, ListView.Contain)
                            }
                        }
                    }
                }
            }

            // Empty state with delayed visibility
            Item {
                id: emptyState
                width: parent.width
                height: 60

                property bool shouldShow: LauncherState.results.length === 0 && LauncherState.searchText.length > 0 && !LauncherState.evalResult
                property bool delayedShow: false

                visible: shouldShow && delayedShow

                onShouldShowChanged: {
                    if (shouldShow) {
                        emptyStateTimer.restart()
                    } else {
                        emptyStateTimer.stop()
                        delayedShow = false
                    }
                }

                Timer {
                    id: emptyStateTimer
                    interval: 400  // 400ms delay before showing
                    onTriggered: emptyState.delayedShow = true
                }

                Text {
                    anchors.centerIn: parent
                    text: "No results found"
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.medium
                    color: Colors.foregroundMuted
                }
            }

            // Action bar
            Rectangle {
                width: parent.width
                height: 28
                radius: 8
                color: Colors.surface
                visible: LauncherState.results.length > 0

                Row {
                    anchors.centerIn: parent
                    spacing: 24

                    // Navigate hint
                    Row {
                        spacing: 6

                        Text {
                            text: LauncherState.isGridMode ? "←↑↓→" : "↑↓"
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            font.bold: true
                            color: Colors.foregroundMuted
                        }

                        Text {
                            text: "Navigate"
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            color: Colors.foregroundAlt
                        }
                    }

                    // Enter hint
                    Row {
                        spacing: 6

                        Text {
                            text: "↵"
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            font.bold: true
                            color: Colors.foregroundMuted
                        }

                        Text {
                            text: LauncherState.isGridMode ? "Copy" : "Open"
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            color: Colors.foregroundAlt
                        }
                    }

                    // Escape hint
                    Row {
                        spacing: 6

                        Text {
                            text: "Esc"
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.tiny
                            font.bold: true
                            color: Colors.foregroundMuted
                        }

                        Text {
                            text: "Close"
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            color: Colors.foregroundAlt
                        }
                    }

                    // Hints toggle
                    Row {
                        spacing: 6

                        Text {
                            text: "C-;"
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.tiny
                            font.bold: true
                            color: HintNavigationService.active ? Colors.iris : Colors.foregroundMuted
                        }

                        Text {
                            text: "Hints"
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            color: HintNavigationService.active ? Colors.iris : Colors.foregroundAlt
                        }
                    }
                }
            }
        }  // Column

        }  // contentPanel Rectangle

    }  // gradientWrapper Item

    // Hint overlay popup - renders hints above launcher content
    PopupWindow {
        id: hintPopup
        anchor.window: launcherWindow
        anchor.onAnchoring: {
            // Map contentPanel position to window coordinates for accurate hint placement
            const pos = contentPanel.mapToItem(launcherWindow.contentItem, 0, 0)
            anchor.rect = Qt.rect(pos.x, pos.y, contentPanel.width, contentPanel.height)
        }
        anchor.edges: Edges.Top | Edges.Left

        visible: launcherWindow.expanded && HintNavigationService.active
        color: "transparent"

        implicitWidth: contentPanel.width
        implicitHeight: contentPanel.height

        HintOverlay {
            anchors.fill: parent
            scope: "launcher"
            mapRoot: contentPanel
        }
    }

    // Force reassign hints when launcher visibility or results change
    Connections {
        target: HintNavigationService
        function onActiveChanged() {
            if (HintNavigationService.active && launcherWindow.expanded) {
                // Delay to ensure all delegates are ready
                hintReassignTimer.restart()
            }
        }
    }

    Connections {
        target: LauncherState
        function onResultsChanged() {
            if (HintNavigationService.active && launcherWindow.expanded) {
                hintReassignTimer.restart()
            }
        }
    }

    Timer {
        id: hintReassignTimer
        interval: 100
        onTriggered: HintNavigationService.reassignHints()
    }

    // Deactivate hints when launcher closes, reassign when opening
    onExpandedChanged: {
        if (!expanded && HintNavigationService.active) {
            HintNavigationService.deactivate()
        }
        if (!expanded) {
            hideContextMenu()
        }
        if (expanded && HintNavigationService.active) {
            hintReassignTimer.restart()
        }
    }

    // Result context menu
    ResultContextMenu {
        id: resultContextMenu
        anchor.window: launcherWindow
        anchor.rect: Qt.rect(
            gradientWrapper.x + (gradientWrapper.width - 200) / 2,
            gradientWrapper.anchors.topMargin + 100,
            200,
            1
        )
        anchor.edges: Edges.Top | Edges.Left

        onMenuClosed: {
            launcherWindow.contextMenuResult = null
            launcherWindow.contextMenuAnchor = null
        }
    }

    // Keyboard handler at window level
    FocusScope {
        id: windowFocusScope
        anchors.fill: parent
        focus: launcherWindow.expanded

        // Take focus when hints are active
        Connections {
            target: HintNavigationService
            function onActiveChanged() {
                if (HintNavigationService.active && launcherWindow.expanded) {
                    windowFocusScope.forceActiveFocus()
                }
            }
        }

        Keys.onPressed: function(event) {
            // Handle hint navigation toggle (Ctrl+;)
            if (event.key === Qt.Key_Semicolon && (event.modifiers & Qt.ControlModifier)) {
                HintNavigationService.toggle()
                event.accepted = true
                return
            }

            // When hints are active, handle Escape specially and pass other keys to hint service
            if (HintNavigationService.active) {
                // Escape deactivates hints but keeps launcher open
                if (event.key === Qt.Key_Escape) {
                    HintNavigationService.deactivate()
                    event.accepted = true
                    return
                }

                let key = event.text || ""
                if (event.key === Qt.Key_Backspace) key = "Backspace"

                if (key && HintNavigationService.handleKey(key, "launcher", event.modifiers)) {
                    event.accepted = true
                    return
                }
            }

            switch (event.key) {
                case Qt.Key_Escape:
                    LauncherState.hide()
                    event.accepted = true
                    break
                case Qt.Key_Down:
                    LauncherState.selectNext()
                    event.accepted = true
                    break
                case Qt.Key_Up:
                    LauncherState.selectPrevious()
                    event.accepted = true
                    break
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    if (LauncherState.packBarFocused && LauncherState.isStickerMode) {
                        LauncherState.activatePackBarSelection()
                    } else {
                        LauncherState.activateSelected()
                    }
                    event.accepted = true
                    break
                case Qt.Key_J:
                    if (event.modifiers & Qt.ControlModifier) {
                        LauncherState.selectNext()
                        event.accepted = true
                    }
                    break
                case Qt.Key_K:
                    if (event.modifiers & Qt.ControlModifier) {
                        LauncherState.selectPrevious()
                        event.accepted = true
                    }
                    break
                case Qt.Key_Left:
                    if (LauncherState.isGridMode) {
                        LauncherState.selectLeft()
                        event.accepted = true
                    }
                    break
                case Qt.Key_Right:
                    if (LauncherState.isGridMode) {
                        LauncherState.selectRight()
                        event.accepted = true
                    }
                    break
                case Qt.Key_H:
                    if (LauncherState.isGridMode && event.modifiers & Qt.ControlModifier) {
                        LauncherState.selectLeft()
                        event.accepted = true
                    }
                    break
                case Qt.Key_L:
                    if (LauncherState.isGridMode && event.modifiers & Qt.ControlModifier) {
                        LauncherState.selectRight()
                        event.accepted = true
                    }
                    break
            }
        }
    }
}
