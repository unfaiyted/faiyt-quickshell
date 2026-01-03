import QtQuick
import QtQuick.Controls
import "../../theme"

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
            font.pixelSize: 18
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
                font.pixelSize: 16
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
                        if (LauncherState.visible) {
                            searchField.forceActiveFocus()
                            // Delay selectAll to ensure text binding has updated
                            selectAllTimer.restart()
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
                    font.pixelSize: 16
                    color: Colors.foregroundMuted
                    visible: searchField.text.length === 0
                }

                // Handle special keys
                Keys.onEscapePressed: function(event) {
                    LauncherState.hide()
                    event.accepted = true
                }

                Keys.onDownPressed: function(event) {
                    LauncherState.selectNext()
                    event.accepted = true
                }

                Keys.onUpPressed: function(event) {
                    LauncherState.selectPrevious()
                    event.accepted = true
                }

                Keys.onLeftPressed: function(event) {
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
                    handleEnter()
                    event.accepted = true
                }

                Keys.onEnterPressed: function(event) {
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
                            font.pixelSize: 13
                            font.bold: true
                            color: Colors.success
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Evaluation result display
                        Text {
                            id: evalDisplay
                            visible: !showCopied && LauncherState.evalResult
                            text: LauncherState.evalResult ? LauncherState.evalResult.value : ""
                            font.pixelSize: 13
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
                        font.pixelSize: 12
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
