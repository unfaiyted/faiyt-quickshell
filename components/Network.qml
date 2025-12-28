import QtQuick
import Quickshell.Io
import "../theme"

BarGroup {
    id: network

    implicitWidth: networkText.width + 16
    implicitHeight: 24

    property string status: "?"
    property bool connected: false

    Process {
        id: netProcess
        command: ["bash", "-c", "nmcli -t -f TYPE,STATE d | grep -E '^(wifi|ethernet):connected' | head -1"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                if (data.includes("wifi")) {
                    network.status = "󰤨"
                    network.connected = true
                } else if (data.includes("ethernet")) {
                    network.status = "󰈀"
                    network.connected = true
                } else {
                    network.status = "󰤭"
                    network.connected = false
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: netProcess.running = true
    }

    Text {
        id: networkText
        anchors.centerIn: parent
        text: network.status
        color: network.connected ? Colors.foreground : Colors.error
        font.pixelSize: 14
        font.family: "Symbols Nerd Font"
    }
}
