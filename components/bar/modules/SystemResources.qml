import QtQuick
import Quickshell
import Quickshell.Io
import "../../../theme"
import ".."

BarGroup {
    id: sysResources

    implicitWidth: row.width + 16
    implicitHeight: 30

    // Resource values
    property int ramUsage: 0
    property int swapUsage: 0
    property int cpuUsage: 0
    property int netDownUsage: 0
    property int netUpUsage: 0

    // Details for tooltips
    property string ramDetails: ""
    property string swapDetails: ""
    property string cpuDetails: ""
    property string netDownDetails: ""
    property string netUpDetails: ""

    // Network speed tracking
    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property real downloadSpeed: 0  // bytes per second
    property real uploadSpeed: 0    // bytes per second

    // Max network speed in Mbps (configurable via env or IPC)
    property int maxNetworkMbps: {
        var envSpeed = Quickshell.env("QS_NET_SPEED_MBPS")
        return envSpeed ? parseInt(envSpeed) : 930
    }
    property real maxNetworkSpeed: maxNetworkMbps * 1024 * 1024 / 8  // Convert to bytes/sec

    // IPC handler for configuration
    IpcHandler {
        target: "sysresources"

        function setNetSpeed(mbps: int): string {
            sysResources.maxNetworkMbps = mbps
            return "Max network speed set to " + mbps + " Mbps"
        }

        function getNetSpeed(): string {
            return sysResources.maxNetworkMbps + " Mbps"
        }
    }

    // Helper to format bytes per second
    function formatBytes(bytes) {
        if (bytes < 1024) return bytes.toFixed(0) + " B/s"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB/s"
        return (bytes / 1024 / 1024).toFixed(1) + " MB/s"
    }

    // Helper to format max speed
    function formatMaxSpeed() {
        var mbps = (maxNetworkSpeed * 8) / (1024 * 1024)
        return mbps.toFixed(0) + " Mbps"
    }

    // RAM monitoring process
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

    // Swap monitoring process
    Process {
        id: swapProcess
        command: ["bash", "-c", "free -h | awk '/^Swap/ {if ($2 != \"0B\" && $2 != \"0\") printf \"%d|%s/%s\", ($3/$2)*100, $3, $2; else print \"0|0/0\"}'"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                var parts = data.split("|")
                sysResources.swapUsage = parseInt(parts[0]) || 0
                sysResources.swapDetails = parts[1] || "0/0"
            }
        }
    }

    // CPU monitoring process
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

    // Network monitoring process - get current rx/tx bytes
    Process {
        id: netProcess
        command: ["bash", "-c", "cat /proc/net/dev | awk '/^[[:space:]]*(eth|wlan|enp|wlp|eno)/ {rx+=$2; tx+=$10} END {print rx\"|\"tx}'"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                var parts = data.split("|")
                var rxBytes = parseFloat(parts[0]) || 0
                var txBytes = parseFloat(parts[1]) || 0

                if (sysResources.lastRxBytes > 0) {
                    // Calculate speed (bytes per 2 seconds, convert to per second)
                    sysResources.downloadSpeed = (rxBytes - sysResources.lastRxBytes) / 2
                    sysResources.uploadSpeed = (txBytes - sysResources.lastTxBytes) / 2

                    // Calculate percentage of max speed
                    sysResources.netDownUsage = Math.min(100, Math.round((sysResources.downloadSpeed / sysResources.maxNetworkSpeed) * 100))
                    sysResources.netUpUsage = Math.min(100, Math.round((sysResources.uploadSpeed / sysResources.maxNetworkSpeed) * 100))

                    // Format details with speed and percentage
                    sysResources.netDownDetails = formatBytes(sysResources.downloadSpeed) + "\n" + sysResources.netDownUsage + "% of " + formatMaxSpeed()
                    sysResources.netUpDetails = formatBytes(sysResources.uploadSpeed) + "\n" + sysResources.netUpUsage + "% of " + formatMaxSpeed()
                }

                sysResources.lastRxBytes = rxBytes
                sysResources.lastTxBytes = txBytes
            }
        }
    }

    // Refresh timer
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            ramProcess.running = true
            swapProcess.running = true
            cpuProcess.running = true
            netProcess.running = true
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        // RAM indicator - memory chip icon
        ResourceIndicator {
            icon: "󰍛"  // nf-md-memory
            label: "RAM"
            value: sysResources.ramUsage
            indicatorColor: Colors.info
            tooltipText: sysResources.ramDetails
        }

        // Swap indicator - swap arrows icon
        ResourceIndicator {
            icon: "󰓡"  // nf-md-swap_horizontal
            label: "Swap"
            value: sysResources.swapUsage
            indicatorColor: Colors.success
            tooltipText: sysResources.swapDetails
        }

        // CPU indicator - gauge/speedometer icon
        ResourceIndicator {
            icon: "󰘚"  // nf-md-chip
            label: "CPU"
            value: sysResources.cpuUsage
            indicatorColor: Colors.warning
            tooltipText: sysResources.cpuDetails
        }

        // Network download indicator
        ResourceIndicator {
            icon: "󰇚"  // nf-md-download
            label: "Download"
            value: sysResources.netDownUsage
            indicatorColor: Colors.primary
            tooltipText: sysResources.netDownDetails
        }

        // Network upload indicator
        ResourceIndicator {
            icon: "󰕒"  // nf-md-upload
            label: "Upload"
            value: sysResources.netUpUsage
            indicatorColor: Colors.rose
            tooltipText: sysResources.netUpDetails
        }
    }
}
