import QtQuick
import "../../theme"
import "../../services"
import "../common"

Item {
    id: packBar

    property string selectedPackId: StickerService.selectedPackId
    property bool keyboardFocused: LauncherState.packBarFocused
    property int keyboardIndex: LauncherState.selectedPackIndex  // -1 = All, 0+ = pack index

    signal packSelected(string packId)

    width: parent.width
    height: visible ? 40 : 0

    Rectangle {
        anchors.fill: parent
        color: Colors.surface
        radius: 8

        Row {
            id: packRow
            anchors.centerIn: parent
            spacing: 8

            // "All" button
            Rectangle {
                id: allButton
                property bool isKeyboardFocused: packBar.keyboardFocused && packBar.keyboardIndex === -1

                width: 32
                height: 32
                radius: 6
                color: packBar.selectedPackId === ""
                    ? Qt.rgba(Colors.iris.r, Colors.iris.g, Colors.iris.b, 0.2)
                    : (allMouseArea.containsMouse || isKeyboardFocused ? Colors.overlay : "transparent")
                border.width: (packBar.selectedPackId === "" || isKeyboardFocused) ? 2 : 0
                border.color: isKeyboardFocused ? Colors.gold : Colors.iris

                Text {
                    anchors.centerIn: parent
                    text: "All"
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.tiny
                    font.bold: true
                    color: packBar.selectedPackId === "" ? Colors.iris : Colors.foreground
                }

                MouseArea {
                    id: allMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        StickerService.selectedPackId = ""
                        packBar.packSelected("")
                    }
                }

                HintTarget {
                    targetElement: allButton
                    scope: "launcher"
                    enabled: LauncherState.visible && packBar.visible
                    action: () => {
                        HintNavigationService.deactivate()
                        StickerService.selectedPackId = ""
                        packBar.packSelected("")
                    }
                }
            }

            // Pack buttons
            Repeater {
                model: StickerService.stickerPacks

                Rectangle {
                    id: packButton
                    property bool isKeyboardFocused: packBar.keyboardFocused && packBar.keyboardIndex === index

                    width: 32
                    height: 32
                    radius: 6
                    color: packBar.selectedPackId === modelData.id
                        ? Qt.rgba(Colors.iris.r, Colors.iris.g, Colors.iris.b, 0.2)
                        : (packMouseArea.containsMouse || isKeyboardFocused ? Colors.overlay : "transparent")
                    border.width: (packBar.selectedPackId === modelData.id || isKeyboardFocused) ? 2 : 0
                    border.color: isKeyboardFocused ? Colors.gold : Colors.iris

                    Text {
                        anchors.centerIn: parent
                        text: modelData.coverEmoji || "📦"
                        font.pixelSize: Fonts.iconLarge
                        font.family: Fonts.emoji
                    }

                    MouseArea {
                        id: packMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            StickerService.selectedPackId = modelData.id
                            packBar.packSelected(modelData.id)
                        }
                    }

                    HintTarget {
                        targetElement: packButton
                        scope: "launcher"
                        enabled: LauncherState.visible && packBar.visible
                        action: () => {
                            HintNavigationService.deactivate()
                            StickerService.selectedPackId = modelData.id
                            packBar.packSelected(modelData.id)
                        }
                    }

                    // Tooltip
                    Rectangle {
                        visible: packMouseArea.containsMouse || isKeyboardFocused
                        anchors.top: parent.bottom
                        anchors.topMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: packTooltipText.width + 12
                        height: packTooltipText.height + 8
                        radius: 4
                        color: Colors.overlay
                        border.width: 1
                        border.color: Colors.border
                        z: 100

                        Text {
                            id: packTooltipText
                            anchors.centerIn: parent
                            text: modelData.name || "Sticker Pack"
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            color: Colors.foreground
                        }
                    }
                }
            }
        }
    }
}
