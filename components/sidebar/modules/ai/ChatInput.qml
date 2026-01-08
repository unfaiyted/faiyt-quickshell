import QtQuick
import QtQuick.Controls
import "../../../../theme"
import "../../../../services"
import "../.."
import "../../../common"

Item {
    id: chatInput

    property string provider: "claude"
    property bool enabled: true

    height: 72

    // Find ChatMessages sibling for keyboard scrolling
    function findChatMessages() {
        for (let i = 0; i < chatInput.parent.children.length; i++) {
            if (chatInput.parent.children[i].objectName === "chatMessages") {
                return chatInput.parent.children[i]
            }
        }
        return null
    }

    Rectangle {
        id: inputContainer
        anchors.fill: parent
        anchors.margins: 8
        radius: 12
        color: Colors.surface
        border.width: inputArea.activeFocus ? 2 : 1
        border.color: inputArea.activeFocus ? Colors.primary : Colors.border

        Behavior on border.color { ColorAnimation { duration: 150 } }
        Behavior on border.width { NumberAnimation { duration: 150 } }

        Row {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            // Text input
            ScrollView {
                width: parent.width - 44
                height: parent.height
                clip: true

                TextArea {
                    id: inputArea
                    width: parent.width
                    placeholderText: enabled
                        ? (AIState.isProcessing ? "Waiting for response..." : "Type a message...")
                        : "Configure API key in Settings"
                    placeholderTextColor: Colors.foregroundMuted
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    color: Colors.foreground
                    background: null
                    wrapMode: TextEdit.Wrap
                    enabled: chatInput.enabled && !AIState.isProcessing
                    selectByMouse: true

                    // Remove focus when hint navigation becomes active
                    Connections {
                        target: HintNavigationService
                        function onActiveChanged() {
                            if (HintNavigationService.active && inputArea.activeFocus) {
                                inputArea.focus = false
                            }
                        }
                    }

                    // Auto-focus input when conversation is selected
                    Connections {
                        target: ConversationManager
                        function onConversationChanged(id) {
                            if (chatInput.enabled && !AIState.isProcessing) {
                                inputArea.forceActiveFocus()
                            }
                        }
                    }

                    // Auto-focus input when sidebar opens on a chat tab
                    Connections {
                        target: SidebarState
                        function onLeftOpenChanged() {
                            if (SidebarState.leftOpen && chatInput.enabled && !AIState.isProcessing && AIState.activeProviderTab < 4) {
                                inputArea.forceActiveFocus()
                            }
                        }
                    }

                    Keys.onReturnPressed: function(event) {
                        if (!(event.modifiers & Qt.ShiftModifier)) {
                            if (text.trim().length > 0) {
                                AIState.sendMessage(text)
                                text = ""
                            }
                            event.accepted = true
                        }
                    }

                    Keys.onUpPressed: function(event) {
                        const chatMessages = findChatMessages()
                        if (chatMessages) chatMessages.scrollUp()
                        event.accepted = true
                    }

                    Keys.onDownPressed: function(event) {
                        const chatMessages = findChatMessages()
                        if (chatMessages) chatMessages.scrollDown()
                        event.accepted = true
                    }

                    Keys.onEscapePressed: function(event) {
                        SidebarState.leftOpen = false
                        event.accepted = true
                    }
                }
            }

            // Send/Cancel button
            Rectangle {
                id: sendButton
                width: 36
                height: 36
                radius: 8
                color: {
                    if (AIState.isProcessing) {
                        return sendArea.containsMouse ? Colors.error : Colors.surface
                    }
                    return sendArea.containsMouse && inputArea.text.trim().length > 0
                        ? Colors.primary
                        : Colors.backgroundAlt
                }
                anchors.verticalCenter: parent.verticalCenter
                opacity: chatInput.enabled ? 1 : 0.5

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: AIState.isProcessing ? "󰅖" : "󰒊"
                    font.family: Fonts.icon
                    font.pixelSize: Fonts.iconLarge
                    color: {
                        if (AIState.isProcessing) {
                            return sendArea.containsMouse ? Colors.background : Colors.error
                        }
                        return sendArea.containsMouse && inputArea.text.trim().length > 0
                            ? Colors.background
                            : Colors.foreground
                    }
                }

                MouseArea {
                    id: sendArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: (AIState.isProcessing || inputArea.text.trim().length > 0)
                        ? Qt.PointingHandCursor
                        : Qt.ArrowCursor
                    enabled: chatInput.enabled

                    onClicked: {
                        if (AIState.isProcessing) {
                            AIState.cancelRequest()
                        } else if (inputArea.text.trim().length > 0) {
                            AIState.sendMessage(inputArea.text)
                            inputArea.text = ""
                        }
                    }
                }

                HintTarget {
                    targetElement: sendButton
                    scope: "sidebar-left"
                    enabled: chatInput.enabled
                    action: () => {
                        if (AIState.isProcessing) {
                            AIState.cancelRequest()
                        } else if (inputArea.text.trim().length > 0) {
                            AIState.sendMessage(inputArea.text)
                            inputArea.text = ""
                        }
                    }
                }
            }
        }

        HintTarget {
            targetElement: inputContainer
            scope: "sidebar-left"
            enabled: chatInput.enabled && !AIState.isProcessing
            action: () => inputArea.forceActiveFocus()
        }
    }
}
