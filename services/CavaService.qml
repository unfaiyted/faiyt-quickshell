pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: cavaService

    property int barCount: 40
    property var values: []
    property var rawValues: []  // Raw cava values
    property var simulatedValues: []  // Simulated animation values

    // Detect if cava is picking up audio (sum of values above threshold)
    property bool hasAudio: {
        if (rawValues.length === 0) return false
        let sum = rawValues.reduce((a, b) => a + b, 0)
        return sum > 10  // Threshold to detect actual audio
    }

    // Use simulated values when no audio detected
    property bool useSimulation: !hasAudio && cavaProc.running

    // Animation phase for simulation
    property real phase: 0

    // Simulation timer - creates smooth wave animation
    Timer {
        id: simulationTimer
        interval: 50
        running: cavaService.useSimulation
        repeat: true
        onTriggered: {
            cavaService.phase += 0.15
            let newValues = []
            for (let i = 0; i < cavaService.barCount; i++) {
                // Create wave pattern with different phases per bar
                let wave = Math.sin(cavaService.phase + i * 0.8) * 0.5 + 0.5
                // Add some variation
                let variation = Math.sin(cavaService.phase * 1.7 + i * 1.2) * 0.2 + 0.8
                newValues.push(Math.floor(wave * variation * 60 + 20))
            }
            cavaService.simulatedValues = newValues
            cavaService.values = newValues
        }
    }

    // Update values based on source
    onRawValuesChanged: {
        if (hasAudio) {
            values = rawValues
        }
    }

    Process {
        id: cavaProc
        command: ["sh", "-c",
            "cat > /tmp/cava-qs.conf << 'EOF'\n" +
            "[general]\n" +
            "framerate = 60\n" +
            "bars = " + cavaService.barCount + "\n" +
            "[input]\n" +
            "method = pulse\n" +
            "source = auto\n" +
            "[output]\n" +
            "method = raw\n" +
            "channels = mono\n" +
            "data_format = ascii\n" +
            "ascii_max_range = 100\n" +
            "[smoothing]\n" +
            "noise_reduction = 20\n" +
            "EOF\n" +
            "exec cava -p /tmp/cava-qs.conf"
        ]
        running: false

        stdout: SplitParser {
            onRead: data => {
                // Parse semicolon-separated values
                cavaService.rawValues = data.split(";")
                    .filter(v => v.length > 0)
                    .map(v => parseInt(v))
            }
        }
    }

    function open() {
        values = Array(barCount).fill(0)
        rawValues = Array(barCount).fill(0)
        simulatedValues = Array(barCount).fill(0)
        phase = 0
        cavaProc.running = true
    }

    function close() {
        cavaProc.running = false
        values = Array(barCount).fill(0)
        rawValues = Array(barCount).fill(0)
        simulatedValues = Array(barCount).fill(0)
    }

    onBarCountChanged: {
        if (cavaProc.running) {
            close()
            open()
        }
    }
}
