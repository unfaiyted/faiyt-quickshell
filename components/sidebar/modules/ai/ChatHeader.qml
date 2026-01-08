import QtQuick
import QtQuick.Controls
import "../../../../theme"
import "../../../../services"
import "../.."
import "../../../common"

Item {
    id: chatHeader

    property string provider: "claude"
    property bool stubMode: false

    height: 48

    Row {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        spacing: 6

        // Conversation sidebar toggle
        Rectangle {
            id: sidebarToggleBtn
            width: 32
            height: 32
            radius: 8
            color: toggleArea.containsMouse ? Colors.surface : "transparent"
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: AIState.conversationSidebarOpen ? "󰧛" : "󰧜"
                font.family: Fonts.icon
                font.pixelSize: Fonts.iconMedium
                color: Colors.foreground
            }

            MouseArea {
                id: toggleArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: AIState.toggleConversationSidebar()
            }

            HintTarget {
                targetElement: sidebarToggleBtn
                scope: "sidebar-left"
                action: () => AIState.toggleConversationSidebar()
            }
        }

        // Model selector
        Rectangle {
            id: modelSelectorBtn
            width: modelRow.width + 16
            height: 32
            radius: 8
            color: modelArea.containsMouse ? Colors.surface : Colors.backgroundAlt
            anchors.verticalCenter: parent.verticalCenter
            visible: !stubMode

            Row {
                id: modelRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "󰧑"
                    font.family: Fonts.icon
                    font.pixelSize: Fonts.iconSmall
                    color: Colors.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: formatModelName(AIState.getCurrentModel())
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    color: Colors.foreground
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "󰅀"
                    font.family: Fonts.icon
                    font.pixelSize: Fonts.iconTiny
                    color: Colors.foregroundMuted
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: modelArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: modelPopup.open()
            }

            HintTarget {
                targetElement: modelSelectorBtn
                scope: "sidebar-left"
                enabled: !stubMode
                action: () => modelPopup.open()
            }

            Popup {
                id: modelPopup
                y: parent.height + 4
                width: 200
                padding: 4

                background: Rectangle {
                    color: Colors.surface
                    radius: 8
                    border.width: 1
                    border.color: Colors.border
                }

                Column {
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: AIState.getModels()

                        Rectangle {
                            id: modelItem
                            width: parent.width
                            height: 32
                            radius: 6
                            color: modelItemArea.containsMouse ? Colors.overlay : "transparent"

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: formatModelName(modelData)
                                font.family: Fonts.ui
                                font.pixelSize: Fonts.small
                                color: modelData === AIState.getCurrentModel() ? Colors.primary : Colors.foreground
                                font.weight: modelData === AIState.getCurrentModel() ? Font.DemiBold : Font.Normal
                            }

                            MouseArea {
                                id: modelItemArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    AIState.setModel(modelData)
                                    modelPopup.close()
                                }
                            }

                            HintTarget {
                                targetElement: modelItem
                                scope: "sidebar-left"
                                enabled: modelPopup.visible
                                action: () => {
                                    AIState.setModel(modelData)
                                    modelPopup.close()
                                }
                            }
                        }
                    }
                }
            }
        }

        // Separator
        Rectangle {
            width: 1
            height: 20
            color: Colors.border
            anchors.verticalCenter: parent.verticalCenter
            visible: !stubMode
        }

        // Conversation name - fills remaining space
        Text {
            id: conversationNameText
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            visible: !stubMode
            // Fill remaining space: header width - margins - toggle - model selector - separator - buttons - spacing
            width: Math.max(40, chatHeader.width - 16 - 32 - (modelRow.width + 16) - 1 - 32 - 32 - (6 * 6))
            verticalAlignment: Text.AlignVCenter
            text: {
                const conv = AIState.activeConversation
                return (conv && conv.name) ? conv.name : "New Conversation"
            }
            font.family: Fonts.ui
            font.pixelSize: Fonts.small
            color: Colors.foregroundAlt
            elide: Text.ElideRight
        }

        // Clear chat button
        Rectangle {
            id: clearChatBtn
            width: 32
            height: 32
            radius: 8
            color: clearArea.containsMouse ? Colors.surface : "transparent"
            anchors.verticalCenter: parent.verticalCenter
            visible: !stubMode

            Text {
                anchors.centerIn: parent
                text: "󰃢"
                font.family: Fonts.icon
                font.pixelSize: Fonts.iconMedium
                color: clearArea.containsMouse ? Colors.error : Colors.foregroundMuted
            }

            MouseArea {
                id: clearArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: AIState.clearConversation()
            }

            HintTarget {
                targetElement: clearChatBtn
                scope: "sidebar-left"
                enabled: !stubMode
                action: () => AIState.clearConversation()
            }
        }

        // New chat button
        Rectangle {
            id: newChatBtn
            width: 32
            height: 32
            radius: 8
            color: newChatArea.containsMouse ? Colors.primary : Colors.surface
            anchors.verticalCenter: parent.verticalCenter
            visible: !stubMode

            Text {
                anchors.centerIn: parent
                text: "󰐕"
                font.family: Fonts.icon
                font.pixelSize: Fonts.iconMedium
                color: newChatArea.containsMouse ? Colors.background : Colors.foreground
            }

            MouseArea {
                id: newChatArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: AIState.createConversation()
            }

            HintTarget {
                targetElement: newChatBtn
                scope: "sidebar-left"
                enabled: !stubMode
                action: () => AIState.createConversation()
            }
        }
    }

    // Separator
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Colors.border
    }

    function formatModelName(modelId) {
        if (!modelId) return "Select Model"
        // claude-sonnet-4-5-20250929 → Sonnet 4.5
        // claude-opus-4-1-20250805 → Opus 4.1
        const parts = modelId.split("-")
        if (parts.length < 3) return modelId

        let tier = parts[1].charAt(0).toUpperCase() + parts[1].slice(1) // "Sonnet", "Opus", "Haiku"

        // Parse version - could be "4" or "4-5" (meaning 4.5)
        let version = parts[2]
        if (parts.length > 3 && !parts[3].match(/^\d{8}$/)) {
            // parts[3] is not a date, so it's part of the version (e.g., "5" in "4-5")
            version += "." + parts[3]
        }

        return tier + " " + version
    }
}
