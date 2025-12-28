import QtQuick
import Quickshell.Io
import "../../../theme"
import ".."

BarGroup {
    id: sysResources

    implicitWidth: row.width + 16
    implicitHeight: 24

    property int ramUsage: 0
    property int cpuUsage: 0

    // RAM monitoring process
    Process {
        id: ramProcess
        command: ["bash", "-c", "free | awk '/^Mem/ {printf(\"%.0f\", ($3/$2) * 100)}'"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                sysResources.ramUsage = parseInt(data) || 0
            }
        }
    }

    // CPU monitoring process
    Process {
        id: cpuProcess
        command: ["bash", "-c", "top -bn1 | grep Cpu | sed 's/,/./g' | awk '{print int($2)}'"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                sysResources.cpuUsage = parseInt(data) || 0
            }
        }
    }

    // Refresh timer
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            ramProcess.running = true
            cpuProcess.running = true
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        // RAM indicator
        ResourceIndicator {
            label: "RAM"
            value: sysResources.ramUsage
            indicatorColor: Colors.info
        }

        // CPU indicator
        ResourceIndicator {
            label: "CPU"
            value: sysResources.cpuUsage
            indicatorColor: Colors.warning
        }
    }
}
