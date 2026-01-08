import QtQuick
import "../../../../theme"
import "../../../../services"
import "../.."

Item {
    id: chatContainer

    property string provider: "claude"
    property bool stubMode: false

    Row {
        anchors.fill: parent
        spacing: 0

        // Collapsible conversation sidebar
        Rectangle {
            id: conversationSidebar
            width: AIState.conversationSidebarOpen ? 180 : 0
            height: parent.height
            color: Colors.backgroundAlt
            clip: true

            Behavior on width {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            ConversationSidebar {
                anchors.fill: parent
                provider: chatContainer.provider
                visible: AIState.conversationSidebarOpen
            }
        }

        // Separator line
        Rectangle {
            width: AIState.conversationSidebarOpen ? 1 : 0
            height: parent.height
            color: Colors.border
            visible: AIState.conversationSidebarOpen

            Behavior on width {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
        }

        // Main chat area
        Rectangle {
            id: mainChatArea
            width: parent.width - conversationSidebar.width - (AIState.conversationSidebarOpen ? 1 : 0)
            height: parent.height
            color: "transparent"

            Column {
                anchors.fill: parent
                spacing: 0

                // Header with model selector
                ChatHeader {
                    width: parent.width
                    provider: chatContainer.provider
                    stubMode: chatContainer.stubMode
                }

                // Stub message for non-implemented providers
                Item {
                    width: parent.width
                    height: parent.height - 48 - 72
                    visible: stubMode

                    Column {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰋗"
                            font.family: Fonts.icon
                            font.pixelSize: Fonts.iconHuge
                            color: Colors.foregroundMuted
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Coming Soon"
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.large
                            font.bold: true
                            color: Colors.foreground
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: provider.charAt(0).toUpperCase() + provider.slice(1) + " integration\nis under development"
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            color: Colors.foregroundMuted
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // Messages area (active chat)
                ChatMessages {
                    width: parent.width
                    height: parent.height - 48 - 72
                    provider: chatContainer.provider
                    visible: !stubMode
                }

                // Input area
                ChatInput {
                    width: parent.width
                    provider: chatContainer.provider
                    enabled: !stubMode && AIState.hasApiKey()
                }
            }

            // Overlay to close conversation sidebar when clicking main area
            MouseArea {
                anchors.fill: parent
                visible: AIState.conversationSidebarOpen
                onClicked: AIState.conversationSidebarOpen = false
                z: 100
            }
        }
    }
}
