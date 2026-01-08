import QtQuick
import "../../theme"
import "../../services"
import "../common"

Item {
    id: emojiGridView

    property var results: []
    property int selectedIndex: 0
    property int columns: 6
    property int cellSize: 80
    property int emojiSize: 72
    property int maxRows: 5

    signal emojiClicked(int index)
    signal emojiActivated(int index)

    width: parent.width
    height: Math.min(gridView.contentHeight, cellSize * maxRows)

    GridView {
        id: gridView
        anchors.fill: parent
        clip: true

        cellWidth: parent.width / columns
        cellHeight: emojiGridView.cellSize

        model: results

        delegate: Item {
            width: gridView.cellWidth
            height: emojiGridView.cellSize

            Rectangle {
                id: cellBackground
                anchors.centerIn: parent
                width: emojiGridView.cellSize - 4
                height: emojiGridView.cellSize - 4
                radius: 12
                color: index === emojiGridView.selectedIndex ? Qt.alpha(Colors.primary, 0.2) :
                       mouseArea.containsMouse ? Colors.surface : "transparent"
                border.width: index === emojiGridView.selectedIndex ? 2 : 0
                border.color: index === emojiGridView.selectedIndex ? Colors.primary : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }

                Behavior on border.width {
                    NumberAnimation { duration: 100 }
                }

                Text {
                    anchors.centerIn: parent
                    text: modelData?.emoji || ""
                    font.pixelSize: emojiGridView.emojiSize
                    font.family: Fonts.emoji
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        emojiGridView.emojiClicked(index)
                    }

                    onDoubleClicked: {
                        emojiGridView.emojiActivated(index)
                    }
                }

                HintTarget {
                    targetElement: cellBackground
                    scope: "launcher"
                    enabled: LauncherState.visible
                    action: () => {
                        HintNavigationService.deactivate()
                        emojiGridView.emojiClicked(index)
                    }
                }

                // Tooltip
                Rectangle {
                    id: tooltip
                    visible: mouseArea.containsMouse
                    anchors.top: parent.bottom
                    anchors.topMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: tooltipText.width + 12
                    height: tooltipText.height + 8
                    radius: 4
                    color: Colors.overlay
                    border.width: 1
                    border.color: Colors.border
                    z: 100

                    Text {
                        id: tooltipText
                        anchors.centerIn: parent
                        text: modelData?.title || ""
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.small
                        color: Colors.foreground
                    }
                }
            }
        }

        // Auto-scroll to selected item
        onCurrentIndexChanged: {
            positionViewAtIndex(emojiGridView.selectedIndex, GridView.Contain)
        }

        Connections {
            target: emojiGridView
            function onSelectedIndexChanged() {
                gridView.positionViewAtIndex(emojiGridView.selectedIndex, GridView.Contain)
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
