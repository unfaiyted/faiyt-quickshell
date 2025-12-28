import QtQuick
import Quickshell.Io
import "../theme"

BarGroup {
    id: weather

    implicitWidth: weatherText.width + 16
    implicitHeight: 24

    property string weatherData: "..."

    Process {
        id: weatherProcess
        command: ["curl", "-s", "wttr.in/?format=%c%t"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                let trimmed = data.trim()
                if (trimmed.length > 0 && !trimmed.includes("Unknown")) {
                    weather.weatherData = trimmed
                }
            }
        }
    }

    Timer {
        interval: 600000  // 10 minutes
        running: true
        repeat: true
        onTriggered: weatherProcess.running = true
    }

    Text {
        id: weatherText
        anchors.centerIn: parent
        text: weather.weatherData
        color: Colors.foreground
        font.pixelSize: 11
    }
}
