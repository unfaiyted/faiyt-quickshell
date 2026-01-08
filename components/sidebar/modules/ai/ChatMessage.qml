import QtQuick
import "../../../../theme"

Rectangle {
    id: chatMessage

    property string role: "user"  // "user" or "assistant"
    property string content: ""
    property var timestamp: Date.now()
    property bool isStreaming: false
    property bool isError: false

    width: parent.width
    height: messageColumn.height + 16
    radius: 10
    color: role === "user"
        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.08)
        : isError
            ? Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.08)
            : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.6)

    Row {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10

        // Avatar
        Rectangle {
            width: 28
            height: 28
            radius: 6
            color: role === "user"
                ? Colors.primary
                : isError
                    ? Colors.error
                    : Colors.accent

            Text {
                anchors.centerIn: parent
                text: role === "user" ? "󰀄" : "󰧑"
                font.family: Fonts.icon
                font.pixelSize: Fonts.iconMedium
                color: Colors.background
            }
        }

        // Content
        Column {
            id: messageColumn
            width: parent.width - 38
            spacing: 4

            // Role label
            Text {
                text: role === "user" ? "You" : "Claude"
                font.family: Fonts.ui
                font.pixelSize: Fonts.tiny
                font.bold: true
                color: role === "user"
                    ? Colors.primary
                    : isError
                        ? Colors.error
                        : Colors.accent
            }

            // Message content with markdown support
            MessageContent {
                width: parent.width
                content: chatMessage.content
                isStreaming: chatMessage.isStreaming
                isError: chatMessage.isError
            }

            // Timestamp
            Text {
                text: formatTime(timestamp)
                font.family: Fonts.ui
                font.pixelSize: Fonts.tiny
                color: Colors.foregroundMuted
                visible: !isStreaming
            }
        }
    }

    function formatTime(ts) {
        const date = new Date(ts)
        let hours = date.getHours()
        const minutes = date.getMinutes().toString().padStart(2, '0')
        const ampm = hours >= 12 ? 'pm' : 'am'
        hours = hours % 12
        hours = hours ? hours : 12
        return hours + ':' + minutes + ' ' + ampm
    }
}
