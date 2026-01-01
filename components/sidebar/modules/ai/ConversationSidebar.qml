import QtQuick
import QtQuick.Controls
import "../../../../theme"
import "../../../../services"
import "../.."

Item {
    id: conversationSidebar

    property string provider: "claude"

    // Track which conversation menu is open and its position
    property string activeMenuId: ""
    property real activeMenuY: 0
    // Track which conversation is being renamed
    property string editingConversationId: ""

    function openMenu(convId, globalY) {
        activeMenuId = convId
        activeMenuY = globalY
    }

    function closeMenu() {
        activeMenuId = ""
    }

    function startRename(convId) {
        editingConversationId = convId
    }

    function finishRename() {
        editingConversationId = ""
    }

    Column {
        anchors.fill: parent
        spacing: 0

        // Header
        Item {
            width: parent.width
            height: 40

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "Conversations"
                font.pixelSize: 11
                font.bold: true
                color: Colors.foregroundAlt
            }

            // New conversation button
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24
                radius: 6
                color: newConvArea.containsMouse ? Colors.surface : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰐕"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 12
                    color: newConvArea.containsMouse ? Colors.primary : Colors.foregroundMuted
                }

                MouseArea {
                    id: newConvArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AIState.createConversation()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Colors.border
        }

        // Conversation list
        Flickable {
            width: parent.width
            height: parent.height - 41
            clip: true
            contentHeight: convColumn.height
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                active: true
                policy: ScrollBar.AsNeeded
            }

            Column {
                id: convColumn
                width: parent.width
                spacing: 2
                topPadding: 4
                bottomPadding: 4

                Repeater {
                    model: AIState.conversations

                    Rectangle {
                        id: convItem
                        width: convColumn.width - 8
                        height: 48
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: 8
                        color: {
                            if (modelData.id === AIState.activeConversationId) {
                                return Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                            }
                            return convItemArea.containsMouse ? Colors.surface : "transparent"
                        }

                        property bool isEditing: conversationSidebar.editingConversationId === modelData.id
                        property bool showMenu: conversationSidebar.activeMenuId === modelData.id

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 2

                            // Title row
                            Row {
                                width: parent.width
                                spacing: 4

                                Text {
                                    width: parent.width - 20
                                    text: modelData.name || "Untitled"
                                    font.pixelSize: 11
                                    font.weight: modelData.id === AIState.activeConversationId ? Font.DemiBold : Font.Normal
                                    color: modelData.id === AIState.activeConversationId ? Colors.primary : Colors.foreground
                                    elide: Text.ElideRight
                                    visible: !convItem.isEditing
                                }

                                TextInput {
                                    id: renameInput
                                    width: parent.width - 20
                                    text: modelData.name || ""
                                    font.pixelSize: 11
                                    color: Colors.foreground
                                    visible: convItem.isEditing
                                    selectByMouse: true

                                    onAccepted: {
                                        AIState.renameConversation(modelData.id, text)
                                        conversationSidebar.finishRename()
                                    }

                                    Keys.onEscapePressed: {
                                        conversationSidebar.finishRename()
                                    }

                                    onVisibleChanged: {
                                        if (visible) {
                                            text = modelData.name || ""
                                            forceActiveFocus()
                                            selectAll()
                                        }
                                    }
                                }

                                // Menu button
                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 4
                                    color: menuArea.containsMouse ? Colors.overlay : "transparent"
                                    visible: convItemArea.containsMouse || convItem.showMenu

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰇙"
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: 10
                                        color: Colors.foregroundMuted
                                    }

                                    MouseArea {
                                        id: menuArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (convItem.showMenu) {
                                                conversationSidebar.closeMenu()
                                            } else {
                                                const globalPos = mapToItem(conversationSidebar, 0, height)
                                                conversationSidebar.openMenu(modelData.id, globalPos.y)
                                            }
                                        }
                                    }
                                }
                            }

                            // Message count and time
                            Text {
                                text: {
                                    const count = modelData.messages ? modelData.messages.length : 0
                                    const time = formatRelativeTime(modelData.updatedAt)
                                    return count + " messages • " + time
                                }
                                font.pixelSize: 9
                                color: Colors.foregroundMuted
                            }
                        }

                        MouseArea {
                            id: convItemArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            onClicked: function(mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    const globalPos = mapToItem(conversationSidebar, mouse.x, mouse.y)
                                    conversationSidebar.openMenu(modelData.id, globalPos.y)
                                } else if (!convItem.isEditing) {
                                    AIState.switchConversation(modelData.id)
                                    // Auto-collapse the conversation sidebar
                                    AIState.conversationSidebarOpen = false
                                }
                            }

                            onDoubleClicked: {
                                conversationSidebar.startRename(modelData.id)
                            }
                        }

                    }
                }

                // Empty state
                Item {
                    width: parent.width
                    height: 80
                    visible: AIState.conversations.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰍉"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 24
                            color: Colors.foregroundMuted
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No conversations"
                            font.pixelSize: 10
                            color: Colors.foregroundMuted
                        }
                    }
                }
            }
        }
    }

    function formatRelativeTime(timestamp) {
        if (!timestamp) return ""
        const now = Date.now()
        const diff = now - timestamp
        const minutes = Math.floor(diff / 60000)
        const hours = Math.floor(diff / 3600000)
        const days = Math.floor(diff / 86400000)

        if (minutes < 1) return "just now"
        if (minutes < 60) return minutes + "m ago"
        if (hours < 24) return hours + "h ago"
        if (days < 7) return days + "d ago"
        return new Date(timestamp).toLocaleDateString()
    }

    // Click catcher to close menu when clicking outside
    MouseArea {
        anchors.fill: parent
        visible: activeMenuId !== ""
        onClicked: closeMenu()
        z: 99
    }

    // Global context menu (outside Flickable to avoid clipping)
    Rectangle {
        id: contextMenu
        visible: activeMenuId !== ""
        x: 8
        y: Math.min(activeMenuY, conversationSidebar.height - height - 8)
        width: parent.width - 16
        height: menuColumn.height + 8
        radius: 8
        color: Colors.surface
        border.color: Colors.border
        border.width: 1
        z: 100

        Column {
            id: menuColumn
            anchors.centerIn: parent
            width: parent.width - 8
            spacing: 2

            // Rename button
            Rectangle {
                width: parent.width
                height: 28
                radius: 6
                color: renameArea.containsMouse ? Colors.overlay : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰏫"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 12
                        color: Colors.foreground
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Rename"
                        font.pixelSize: 11
                        color: Colors.foreground
                    }
                }

                MouseArea {
                    id: renameArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const convId = activeMenuId
                        closeMenu()
                        startRename(convId)
                    }
                }
            }

            // Delete button
            Rectangle {
                width: parent.width
                height: 28
                radius: 6
                color: deleteArea.containsMouse ? Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.15) : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰆴"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 12
                        color: deleteArea.containsMouse ? Colors.error : Colors.foreground
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Delete"
                        font.pixelSize: 11
                        color: deleteArea.containsMouse ? Colors.error : Colors.foreground
                    }
                }

                MouseArea {
                    id: deleteArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const convId = activeMenuId
                        closeMenu()
                        AIState.deleteConversation(convId)
                    }
                }
            }
        }
    }
}
