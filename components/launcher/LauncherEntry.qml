import QtQuick
import QtQuick.Controls
import "../../theme"
import "../../services"
import "../common"

Rectangle {
    id: entryContainer

    height: 48
    radius: 12
    color: Colors.surface
    border.width: 1
    border.color: searchField.activeFocus ? Colors.overlay : Qt.rgba(Colors.overlay.r, Colors.overlay.g, Colors.overlay.b, 0.5)

    // Copied feedback state
    property bool showCopied: false

    Behavior on border.color {
        ColorAnimation { duration: 150 }
    }

    Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Search icon
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            font.family: Fonts.icon
            font.pixelSize: Fonts.iconLarge
            color: Colors.foregroundMuted
        }

        // Text input container
        Item {
            id: inputContainer
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 30  // Leave room for search icon
            height: parent.height

            // Text input - takes left portion
            TextInput {
                id: searchField
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(100, parent.width - rightContent.width - 12)
                height: parent.height

                text: LauncherState.searchText
                font.family: Fonts.ui
                font.pixelSize: Fonts.large
                color: Colors.foreground
                selectionColor: Colors.primary
                selectedTextColor: Colors.background
                clip: true
                verticalAlignment: TextInput.AlignVCenter

                onTextChanged: {
                    LauncherState.searchText = text
                }

                // Focus when launcher opens
                Connections {
                    target: LauncherState
                    function onVisibleChanged() {
                        if (LauncherState.visible && !HintNavigationService.active) {
                            searchField.forceActiveFocus()
                            // Delay selectAll to ensure text binding has updated
                            selectAllTimer.restart()
                        }
                    }
                }

                // Manage focus based on hint navigation state
                // Note: Focus transfer is handled by LauncherWindow.windowFocusScope
                Connections {
                    target: HintNavigationService
                    function onActiveChanged() {
                        if (!HintNavigationService.active && LauncherState.visible) {
                            // Refocus input when hints are deactivated
                            searchField.forceActiveFocus()
                        }
                    }
                }

                Timer {
                    id: selectAllTimer
                    interval: 10
                    onTriggered: searchField.selectAll()
                }

                // Placeholder text
                Text {
                    anchors.fill: parent
                    anchors.verticalCenter: parent.verticalCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "Search apps, commands, files..."
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.large
                    color: Colors.foregroundMuted
                    visible: searchField.text.length === 0
                }

                // Handle all key events - pass to hint system when active
                Keys.onPressed: function(event) {
                    // Handle hint toggle (Ctrl+;) from anywhere
                    if (event.key === Qt.Key_Semicolon && (event.modifiers & Qt.ControlModifier)) {
                        HintNavigationService.toggle()
                        event.accepted = true
                        return
                    }

                    // When hints are active, pass all keys to hint system
                    if (HintNavigationService.active) {
                        let key = event.text || ""
                        if (event.key === Qt.Key_Escape) key = "Escape"
                        else if (event.key === Qt.Key_Backspace) key = "Backspace"

                        if (key === "Escape") {
                            // Escape deactivates hints, keeps launcher open
                            HintNavigationService.deactivate()
                            event.accepted = true
                            return
                        }

                        if (key && HintNavigationService.handleKey(key, "launcher", event.modifiers)) {
                            event.accepted = true
                            return
                        }
                        // Consume all letter keys when hints active to prevent typing
                        if (event.text && event.text.length === 1) {
                            event.accepted = true
                            return
                        }
                    }
                }

                // Handle special keys
                Keys.onEscapePressed: function(event) {
                    // If hints are active, already handled above
                    if (HintNavigationService.active) {
                        event.accepted = true
                        return
                    }
                    LauncherState.hide()
                    event.accepted = true
                }

                Keys.onDownPressed: function(event) {
                    if (HintNavigationService.active) return
                    LauncherState.selectNext()
                    event.accepted = true
                }

                Keys.onUpPressed: function(event) {
                    if (HintNavigationService.active) return
                    LauncherState.selectPrevious()
                    event.accepted = true
                }

                Keys.onLeftPressed: function(event) {
                    if (HintNavigationService.active) return
                    // If text is selected, deselect and move cursor to start
                    if (searchField.selectedText.length > 0) {
                        searchField.cursorPosition = searchField.selectionStart
                        searchField.deselect()
                        event.accepted = true
                        return
                    }
                    if (LauncherState.isGridMode && LauncherState.results.length > 0) {
                        LauncherState.selectLeft()
                        event.accepted = true
                    }
                    // Otherwise let it move cursor in text input
                }

                Keys.onRightPressed: function(event) {
                    if (HintNavigationService.active) return
                    // If text is selected, deselect and move cursor to end
                    if (searchField.selectionStart !== searchField.selectionEnd) {
                        searchField.cursorPosition = searchField.selectionEnd
                        searchField.deselect()
                        event.accepted = true
                        return
                    }
                    if (LauncherState.isGridMode && LauncherState.results.length > 0) {
                        LauncherState.selectRight()
                        event.accepted = true
                    }
                    // Otherwise let it move cursor in text input
                }

                Keys.onReturnPressed: function(event) {
                    if (HintNavigationService.active) return
                    handleEnter()
                    event.accepted = true
                }

                Keys.onEnterPressed: function(event) {
                    if (HintNavigationService.active) return
                    handleEnter()
                    event.accepted = true
                }
            }

            // Right side content (eval result + clear button)
            Row {
                id: rightContent
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // Evaluation result container (color swatch + result)
                Rectangle {
                    id: evalContainer
                    visible: LauncherState.evalResult && searchField.text.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: evalRow.width + 8
                    height: 24
                    radius: 4
                    color: evalMouseArea.containsMouse ? Colors.overlay : "transparent"

                    Row {
                        id: evalRow
                        anchors.centerIn: parent
                        spacing: 6

                        // Color swatch (only for color evaluator results)
                        Rectangle {
                            id: colorSwatch
                            width: 16
                            height: 16
                            radius: 3
                            visible: !!(LauncherState.evalResult && LauncherState.evalResult.color)
                            color: (LauncherState.evalResult && LauncherState.evalResult.color) || "transparent"
                            border.width: 1
                            border.color: Colors.border
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Copied indicator
                        Text {
                            id: copiedText
                            visible: showCopied
                            text: "Copied!"
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.body
                            font.bold: true
                            color: Colors.success
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Evaluation result display
                        Text {
                            id: evalDisplay
                            visible: !showCopied && LauncherState.evalResult
                            text: LauncherState.evalResult ? LauncherState.evalResult.value : ""
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.body
                            color: Colors.primary
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideMiddle
                            maximumLineCount: 1
                            width: Math.min(implicitWidth, 180)
                        }
                    }

                    // Click to copy
                    MouseArea {
                        id: evalMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (LauncherState.evalResult) {
                                copyEvalAndShowFeedback()
                            }
                        }
                    }

                    HintTarget {
                        targetElement: evalContainer
                        scope: "launcher"
                        enabled: LauncherState.visible && evalContainer.visible
                        action: () => {
                            HintNavigationService.deactivate()
                            if (LauncherState.evalResult) {
                                copyEvalAndShowFeedback()
                            }
                        }
                    }
                }

                // Clear button
                Rectangle {
                    id: clearBtn
                    width: 24
                    height: 24
                    radius: 6
                    color: clearArea.containsMouse ? Colors.overlay : "transparent"
                    visible: searchField.text.length > 0
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Fonts.icon
                        font.pixelSize: Fonts.iconSmall
                        color: Colors.foregroundMuted
                    }

                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            LauncherState.searchText = ""
                            searchField.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }

    // Timer to hide copied feedback
    Timer {
        id: copiedTimer
        interval: 1000
        onTriggered: showCopied = false
    }

    function copyEvalAndShowFeedback() {
        if (LauncherState.copyEvalResult()) {
            showCopied = true
            copiedTimer.restart()
        }
    }

    // Timer to auto-hide after copying
    Timer {
        id: hideTimer
        interval: 600
        onTriggered: LauncherState.hide()
    }

    function handleEnter() {
        // Check for pack bar focus in sticker mode first
        if (LauncherState.packBarFocused && LauncherState.isStickerMode) {
            LauncherState.activatePackBarSelection()
            return
        }

        // If we have an eval result and no search results, copy and close
        if (LauncherState.evalResult && LauncherState.results.length === 0) {
            copyEvalAndShowFeedback()
            hideTimer.restart()
        } else if (LauncherState.evalResult && LauncherState.selectedIndex === -1) {
            // Eval result exists but nothing selected - copy eval result
            copyEvalAndShowFeedback()
        } else {
            // Activate selected result
            LauncherState.activateSelected()
        }
    }
}
