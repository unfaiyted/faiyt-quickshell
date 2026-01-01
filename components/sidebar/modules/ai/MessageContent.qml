import QtQuick
import "../../../../theme"
import "MarkdownParser.js" as MarkdownParser

Item {
    id: messageContent

    property string content: ""
    property bool isStreaming: false
    property bool isError: false

    width: parent.width
    height: contentColumn.height

    // Parse content into blocks
    property var parsedBlocks: {
        if (!content) return []

        // During streaming, if there's an incomplete code block, show as text
        if (isStreaming && MarkdownParser.hasIncompleteCodeBlock(content)) {
            return [{ type: 'text', content: content }]
        }

        return MarkdownParser.parseContent(content)
    }

    // Color values for markdown conversion
    property var themeColors: ({
        primary: Colors.primary.toString(),
        accent: Colors.accent.toString(),
        success: Colors.success.toString(),
        error: Colors.error.toString(),
        foreground: Colors.foreground.toString(),
        foregroundMuted: Colors.foregroundMuted.toString(),
        backgroundAlt: Colors.backgroundAlt.toString(),
        border: Colors.border.toString()
    })

    Column {
        id: contentColumn
        width: parent.width
        spacing: 8

        Repeater {
            model: parsedBlocks

            Loader {
                width: contentColumn.width
                sourceComponent: modelData.type === "code" ? codeBlockComponent : textBlockComponent

                property var blockData: modelData
                property bool isLastBlock: index === parsedBlocks.length - 1
            }
        }

        // Streaming cursor (shown after last block)
        Text {
            visible: isStreaming && parsedBlocks.length > 0
            text: cursorVisible ? "▌" : " "
            font.pixelSize: 12
            color: Colors.foreground

            property bool cursorVisible: true

            Timer {
                running: isStreaming
                interval: 500
                repeat: true
                onTriggered: parent.cursorVisible = !parent.cursorVisible
            }
        }

        // Empty streaming state
        Text {
            visible: isStreaming && parsedBlocks.length === 0
            text: cursorVisible ? "▌" : " "
            font.pixelSize: 12
            color: Colors.foreground

            property bool cursorVisible: true

            Timer {
                running: isStreaming && parsedBlocks.length === 0
                interval: 500
                repeat: true
                onTriggered: parent.cursorVisible = !parent.cursorVisible
            }
        }
    }

    // Text block component
    Component {
        id: textBlockComponent

        Text {
            width: parent.width
            text: {
                const formatted = MarkdownParser.markdownToRichText(blockData.content, themeColors)
                // Add streaming cursor if this is the last text block during streaming
                if (isStreaming && isLastBlock && blockData.type === 'text') {
                    return formatted
                }
                return formatted
            }
            font.pixelSize: 12
            color: isError ? Colors.error : Colors.foreground
            wrapMode: Text.WordWrap
            textFormat: Text.RichText
            lineHeight: 1.4

            // Handle link clicks
            onLinkActivated: function(link) {
                Qt.openUrlExternally(link)
            }

            // Show pointer cursor on links
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }

    // Code block component
    Component {
        id: codeBlockComponent

        CodeBlock {
            width: parent.width
            code: blockData.content
            language: blockData.lang || "text"
        }
    }
}
