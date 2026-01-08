import QtQuick
import QtQuick.Controls
import "../../../../theme"
import "../../../../services"
import "../.."

Item {
    id: chatMessages
    objectName: "chatMessages"

    property string provider: "claude"

    // Scroll functions for keyboard navigation from ChatInput
    function scrollUp() {
        scrollAnim.to = Math.max(0, flickable.contentY - 80)
        scrollAnim.restart()
    }

    function scrollDown() {
        scrollAnim.to = Math.min(flickable.contentHeight - flickable.height, flickable.contentY + 80)
        scrollAnim.restart()
    }
    property var messages: AIState.activeConversation ? AIState.activeConversation.messages : []
    property bool loading: AIState.isProcessing

    // Empty state
    Item {
        anchors.fill: parent
        visible: messages.length === 0 && !loading

        Column {
            anchors.centerIn: parent
            spacing: 16

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰭻"
                font.family: Fonts.icon
                font.pixelSize: Fonts.iconHuge
                color: Colors.foregroundMuted
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: AIState.hasApiKey() ? "Start a conversation" : "API Key Required"
                font.family: Fonts.ui
                font.pixelSize: Fonts.medium
                font.bold: true
                color: Colors.foreground
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: AIState.hasApiKey()
                    ? "Type a message below to begin"
                    : "Go to Settings tab to add your API key"
                font.family: Fonts.ui
                font.pixelSize: Fonts.small
                color: Colors.foregroundMuted
            }
        }
    }

    // Messages list
    Flickable {
        id: flickable
        anchors.fill: parent
        anchors.margins: 8
        clip: true
        contentHeight: messagesColumn.height
        boundsBehavior: Flickable.StopAtBounds
        visible: messages.length > 0 || loading

        ScrollBar.vertical: ScrollBar {
            active: true
            policy: ScrollBar.AsNeeded
        }

        // Smooth scroll animation for keyboard navigation
        NumberAnimation {
            id: scrollAnim
            target: flickable
            property: "contentY"
            duration: 150
            easing.type: Easing.OutCubic
        }

        Column {
            id: messagesColumn
            width: flickable.width
            spacing: 12

            Repeater {
                model: messages

                ChatMessage {
                    width: messagesColumn.width
                    role: modelData.role
                    content: modelData.content || ""
                    timestamp: modelData.timestamp || Date.now()
                    isStreaming: modelData.isStreaming || false
                    isError: modelData.isError || false
                }
            }

            // Loading indicator
            Row {
                spacing: 8
                visible: loading && (messages.length === 0 || !messages[messages.length - 1]?.isStreaming)
                anchors.horizontalCenter: parent.horizontalCenter
                height: visible ? 32 : 0

                Text {
                    id: spinnerIcon
                    text: "󰑓"
                    font.family: Fonts.icon
                    font.pixelSize: Fonts.iconMedium
                    color: Colors.primary
                    anchors.verticalCenter: parent.verticalCenter

                    RotationAnimation on rotation {
                        running: loading
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1000
                    }
                }

                Text {
                    text: "Thinking..."
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    color: Colors.foregroundAlt
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Auto-scroll to bottom on new messages
        onContentHeightChanged: {
            if (contentHeight > height) {
                contentY = contentHeight - height
            }
        }
    }

    // Re-bind messages when conversation changes
    Connections {
        target: ConversationManager

        function onConversationChanged(id) {
            messages = Qt.binding(() => AIState.activeConversation ? AIState.activeConversation.messages : [])
        }

        function onMessageAdded(conversationId, message) {
            if (conversationId === AIState.activeConversationId) {
                messages = Qt.binding(() => AIState.activeConversation ? AIState.activeConversation.messages : [])
            }
        }

        function onMessageUpdated(conversationId, messageId) {
            if (conversationId === AIState.activeConversationId) {
                messages = Qt.binding(() => AIState.activeConversation ? AIState.activeConversation.messages : [])
            }
        }
    }
}
