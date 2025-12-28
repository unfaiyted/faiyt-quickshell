import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"

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

    implicitWidth: 600
    implicitHeight: expanded ? Math.min(contentColumn.implicitHeight + 32, 500) : 0
    exclusiveZone: 0
    color: "transparent"

    // Keyboard focus
    WlrLayershell.keyboardFocus: expanded ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    visible: expanded || hideAnimation.running

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: LauncherState.hide()
    }

    // Main content container - centered
    Rectangle {
        id: contentPanel
        width: 600
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(100, (parent.height - height) / 3)
        height: contentColumn.implicitHeight + 32
        radius: 16
        color: Colors.background
        border.width: 1
        border.color: Colors.border

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

            // Results list
            ListView {
                id: resultsList
                width: parent.width
                height: Math.min(contentHeight, 350)
                clip: true
                spacing: 4
                model: LauncherState.results

                delegate: ResultItem {
                    width: resultsList.width
                    result: modelData
                    isSelected: index === LauncherState.selectedIndex

                    onClicked: {
                        LauncherState.selectedIndex = index
                        LauncherState.activateSelected()
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

            // Empty state
            Item {
                width: parent.width
                height: 60
                visible: LauncherState.results.length === 0 && LauncherState.searchText.length > 0

                Text {
                    anchors.centerIn: parent
                    text: "No results found"
                    font.pixelSize: 14
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
                            text: "↑↓"
                            font.pixelSize: 11
                            font.bold: true
                            color: Colors.foregroundMuted
                        }

                        Text {
                            text: "Navigate"
                            font.pixelSize: 11
                            color: Colors.foregroundAlt
                        }
                    }

                    // Enter hint
                    Row {
                        spacing: 6

                        Text {
                            text: "↵"
                            font.pixelSize: 12
                            font.bold: true
                            color: Colors.foregroundMuted
                        }

                        Text {
                            text: "Open"
                            font.pixelSize: 11
                            color: Colors.foregroundAlt
                        }
                    }

                    // Escape hint
                    Row {
                        spacing: 6

                        Text {
                            text: "Esc"
                            font.pixelSize: 10
                            font.bold: true
                            color: Colors.foregroundMuted
                        }

                        Text {
                            text: "Close"
                            font.pixelSize: 11
                            color: Colors.foregroundAlt
                        }
                    }
                }
            }
        }

    }

    // Keyboard handler at window level
    FocusScope {
        anchors.fill: parent
        focus: launcherWindow.expanded

        Keys.onPressed: function(event) {
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
                    LauncherState.activateSelected()
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
            }
        }
    }
}
