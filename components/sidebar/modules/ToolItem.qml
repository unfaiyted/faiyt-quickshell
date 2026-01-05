import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../../../theme"
import "../../../services"
import "../../common"

Rectangle {
    id: toolItem

    property string toolId: ""
    property string toolName: ""
    property string toolIcon: ""
    property string toolDescription: ""
    property bool expanded: false
    property bool loading: false
    property string result: ""
    property string error: ""

    height: expanded ? (80 + resultArea.height) : 64
    radius: 12
    color: itemArea.containsMouse ? Colors.overlay : Colors.surface
    clip: true

    Behavior on height {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    // Tool commands
    Process {
        id: toolProcess

        property var commands: ({
            "git-status": ["bash", "-c", "cd ~/Projects 2>/dev/null && git status -s || echo 'Not a git repository'"],
            "docker-status": ["bash", "-c", "docker ps --format 'table {{.Names}}\\t{{.Status}}' 2>/dev/null || echo 'Docker not running'"],
            "port-scanner": ["bash", "-c", "for port in 3000 5000 5173 8000 8080 9000; do echo -n \"Port $port: \"; lsof -i :$port 2>/dev/null | grep LISTEN | head -1 | awk '{print $1}' || echo 'free'; done"],
            "clear-cache": ["bash", "-c", "rm -rf ~/.cache/thumbnails/* 2>/dev/null && echo 'Cache cleared successfully'"],
            "system-info": ["bash", "-c", "echo \"CPU: $(nproc) cores\nMemory: $(free -h | grep Mem | awk '{print $3\"/\"$2}')\nDisk: $(df -h / | tail -1 | awk '{print $3\"/\"$2}')\nUptime: $(uptime -p)\""],
            "process-monitor": ["bash", "-c", "ps aux --sort=-%cpu 2>/dev/null | head -6 | tail -5 | awk '{printf \"%-15s %5s%% %5s%%\\n\", substr($11,1,15), $3, $4}'"],
            "dns-flush": ["bash", "-c", "resolvectl flush-caches 2>/dev/null && echo 'DNS cache flushed' || echo 'Could not flush DNS'"],
            "node-version": ["bash", "-c", "echo \"Node: $(node -v 2>/dev/null || echo 'not installed')\nnpm: $(npm -v 2>/dev/null || echo 'not installed')\nBun: $(bun -v 2>/dev/null || echo 'not installed')\""],
            "disk-usage": ["bash", "-c", "df -h / /home 2>/dev/null | tail -2 | awk '{print $6\": \"$3\"/\"$2\" (\"$5\" used)\"}'"],
            "network-info": ["bash", "-c", "ip -br addr 2>/dev/null | grep -v '^lo' | awk '{print $1\": \"$3}' | head -5"]
        })

        command: commands[toolId] || ["echo", "Unknown tool"]

        property string output: ""

        stdout: SplitParser {
            onRead: data => {
                toolProcess.output += data + "\n"
            }
        }

        stderr: SplitParser {
            onRead: data => {
                toolItem.error += data + "\n"
            }
        }

        onRunningChanged: {
            if (!running) {
                toolItem.loading = false
                if (toolProcess.output) {
                    toolItem.result = toolProcess.output.trim()
                }
                toolProcess.output = ""
            }
        }
    }

    function execute() {
        if (expanded) {
            expanded = false
            return
        }

        expanded = true
        loading = true
        result = ""
        error = ""
        toolProcess.output = ""
        toolProcess.running = true
    }

    Column {
        anchors.fill: parent
        spacing: 0

        // Main tool row
        Item {
            width: parent.width
            height: 64

            Row {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // Tool icon
                Rectangle {
                    width: 40
                    height: 40
                    radius: 10
                    color: Colors.primary
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: toolIcon
                        font.family: Fonts.icon
                        font.pixelSize: 18
                        color: Colors.background
                    }
                }

                // Tool info
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    width: parent.width - 100

                    Text {
                        text: toolName
                        font.pixelSize: 13
                        font.bold: true
                        color: Colors.foreground
                    }

                    Text {
                        text: toolDescription
                        font.pixelSize: 11
                        color: Colors.foregroundAlt
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                // Expand indicator
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: expanded ? "󰅃" : "󰅀"
                    font.family: Fonts.icon
                    font.pixelSize: 16
                    color: Colors.foregroundMuted
                }
            }
        }

        // Result area
        Item {
            id: resultArea
            width: parent.width
            height: expanded ? Math.max(60, resultText.implicitHeight + 24) : 0
            visible: expanded
            clip: true

            Rectangle {
                anchors.fill: parent
                anchors.margins: 8
                anchors.topMargin: 0
                radius: 8
                color: Colors.background

                // Loading spinner
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: loading

                    Text {
                        text: "󰑓"
                        font.family: Fonts.icon
                        font.pixelSize: 16
                        color: Colors.primary

                        RotationAnimation on rotation {
                            running: loading
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 1000
                        }
                    }

                    Text {
                        text: "Running..."
                        font.pixelSize: 12
                        color: Colors.foregroundAlt
                    }
                }

                // Result text
                Text {
                    id: resultText
                    anchors.fill: parent
                    anchors.margins: 12
                    text: error ? error : result
                    font.family: Fonts.mono
                    font.pixelSize: 11
                    color: error ? Colors.error : Colors.foreground
                    wrapMode: Text.WrapAnywhere
                    visible: !loading && (result || error)
                }

                // Copy button
                Rectangle {
                    id: copyButton
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 4
                    width: 24
                    height: 24
                    radius: 6
                    color: copyArea.containsMouse ? Colors.surface : "transparent"
                    visible: !loading && result

                    Text {
                        anchors.centerIn: parent
                        text: "󰆏"
                        font.family: Fonts.icon
                        font.pixelSize: 12
                        color: Colors.foregroundMuted
                    }

                    MouseArea {
                        id: copyArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Copy to clipboard would require additional setup
                            copyProcess.running = true
                        }
                    }

                    HintTarget {
                        targetElement: copyButton
                        scope: "sidebar-left"
                        enabled: !loading && result
                        action: () => copyProcess.running = true
                    }

                    Process {
                        id: copyProcess
                        command: ["bash", "-c", "echo -n '" + result.replace(/'/g, "'\\''") + "' | wl-copy"]
                    }
                }
            }
        }
    }

    MouseArea {
        id: itemArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: execute()
    }

    HintTarget {
        targetElement: toolItem
        scope: "sidebar-left"
        action: () => execute()
    }
}
