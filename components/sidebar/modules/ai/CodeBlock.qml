import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../../theme"
import "SyntaxHighlighter.js" as SyntaxHighlighter

Rectangle {
    id: codeBlock

    property string code: ""
    property string language: "text"
    property bool showLineNumbers: true

    width: parent.width
    height: codeColumn.height
    radius: 8
    color: Colors.backgroundAlt
    border.width: 1
    border.color: Colors.border

    Column {
        id: codeColumn
        width: parent.width
        spacing: 0

        // Header bar
        Rectangle {
            width: parent.width
            height: 28
            radius: 8
            color: Colors.surface

            // Bottom corners should be square
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 8
                color: parent.color
            }

            // Language label
            Text {
                id: languageLabel
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: language || "text"
                font.pixelSize: 10
                font.family: "monospace"
                color: Colors.foregroundMuted
            }

            // Copy button
            Rectangle {
                id: copyButton
                width: 24
                height: 24
                radius: 4
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                color: copyArea.containsMouse ? Colors.overlay : "transparent"

                property bool copySuccess: false

                Text {
                    anchors.centerIn: parent
                    text: copyButton.copySuccess ? "󰄬" : "󰆏"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 12
                    color: copyButton.copySuccess ? Colors.success : Colors.foregroundMuted
                }

                MouseArea {
                    id: copyArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        copyProcess.running = true
                        copyButton.copySuccess = true
                        copyResetTimer.restart()
                    }
                }

                Timer {
                    id: copyResetTimer
                    interval: 2000
                    onTriggered: copyButton.copySuccess = false
                }
            }
        }

        // Code content
        Flickable {
            id: codeFlickable
            width: parent.width
            height: Math.min(codeText.height + 16, 400)
            contentWidth: codeText.width + 16
            contentHeight: codeText.height + 16
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                active: true
                policy: codeText.height > 400 ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
            }

            ScrollBar.horizontal: ScrollBar {
                active: true
                policy: codeText.width > codeFlickable.width ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            }

            Row {
                x: 8
                y: 8
                spacing: 8

                // Line numbers
                Text {
                    id: lineNumbers
                    visible: showLineNumbers && code.length > 0
                    text: {
                        const lines = code.split('\n')
                        let nums = []
                        for (let i = 1; i <= lines.length; i++) {
                            nums.push(i.toString().padStart(lines.length.toString().length, ' '))
                        }
                        return nums.join('\n')
                    }
                    font.family: "JetBrains Mono, monospace"
                    font.pixelSize: 11
                    color: Colors.foregroundMuted
                    textFormat: Text.PlainText
                    lineHeight: 1.4
                }

                // Separator
                Rectangle {
                    visible: showLineNumbers && code.length > 0
                    width: 1
                    height: codeText.height
                    color: Colors.border
                }

                // Highlighted code
                Text {
                    id: codeText
                    text: SyntaxHighlighter.highlight(code, language)
                    font.family: "JetBrains Mono, monospace"
                    font.pixelSize: 11
                    color: Colors.foreground
                    textFormat: Text.RichText
                    lineHeight: 1.4
                    wrapMode: Text.NoWrap
                }
            }
        }
    }

    // Copy to clipboard process
    Process {
        id: copyProcess
        command: ["wl-copy", code]
    }
}
