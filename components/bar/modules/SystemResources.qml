import QtQuick
import Quickshell.Io
import "../../../theme"
import ".."

BarGroup {
    id: sysResources

    implicitWidth: row.width + 16
    implicitHeight: 30

    property int ramUsage: 0
    property int cpuUsage: 0
    property string ramDetails: ""
    property string cpuDetails: ""

    // RAM monitoring process - get percentage and details
    Process {
        id: ramProcess
        command: ["bash", "-c", "free -h | awk '/^Mem/ {printf \"%d|%s/%s\", ($3/$2)*100, $3, $2}'"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                var parts = data.split("|")
                sysResources.ramUsage = parseInt(parts[0]) || 0
                sysResources.ramDetails = parts[1] || ""
            }
        }
    }

    // CPU monitoring process - get percentage and load average
    Process {
        id: cpuProcess
        command: ["bash", "-c", "echo \"$(top -bn1 | grep Cpu | sed 's/,/./g' | awk '{print int($2)}')|$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | xargs)\""]
        running: true

        stdout: SplitParser {
            onRead: data => {
                var parts = data.split("|")
                sysResources.cpuUsage = parseInt(parts[0]) || 0
                sysResources.cpuDetails = "Load: " + (parts[1] || "0")
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
            tooltipText: sysResources.ramDetails
        }

        // CPU indicator
        ResourceIndicator {
            label: "CPU"
            value: sysResources.cpuUsage
            indicatorColor: Colors.warning
            tooltipText: sysResources.cpuDetails
        }
    }
}
