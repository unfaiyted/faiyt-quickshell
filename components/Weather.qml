import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

BarGroup {
    id: weather

    implicitWidth: weatherText.width + 16
    implicitHeight: 24

    property string weatherData: "..."
    property string condition: ""
    property string humidity: ""
    property string wind: ""
    property string location: ""
    property string feelsLike: ""

    Process {
        id: weatherProcess
        command: ["curl", "-s", "wttr.in/?format=%c%t|%C|%h|%w|%l|%f"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                let trimmed = data.trim()
                if (trimmed.length > 0 && !trimmed.includes("Unknown")) {
                    const parts = trimmed.split("|")
                    if (parts.length >= 5) {
                        weather.weatherData = parts[0].trim()
                        weather.condition = parts[1].trim()
                        weather.humidity = parts[2].trim()
                        weather.wind = parts[3].trim()
                        weather.location = parts[4].trim()
                        weather.feelsLike = parts[5] ? parts[5].trim() : ""
                    } else {
                        weather.weatherData = trimmed
                    }
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

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }

    // Custom tooltip popup
    PopupWindow {
        id: tooltip
        anchor.window: QsWindow.window
        anchor.onAnchoring: {
            const pos = weather.mapToItem(QsWindow.window.contentItem, 0, weather.height)
            anchor.rect = Qt.rect(pos.x, pos.y, weather.width, 1)
        }
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        visible: mouseArea.containsMouse

        implicitWidth: tooltipContent.width
        implicitHeight: tooltipContent.height
        color: "transparent"

        Rectangle {
            id: tooltipContent
            width: tooltipColumn.width + 24
            height: tooltipColumn.height + 16
            color: Colors.surface
            radius: 8
            border.width: 1
            border.color: Colors.overlay

            Column {
                id: tooltipColumn
                anchors.centerIn: parent
                spacing: 4

                Text {
                    visible: weather.condition.length > 0
                    text: weather.condition
                    color: Colors.foreground
                    font.pixelSize: 12
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    visible: weather.location.length > 0
                    text: weather.location
                    color: Colors.subtle
                    font.pixelSize: 11
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    width: tooltipColumn.width
                    height: 1
                    color: Colors.overlay
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    visible: weather.feelsLike.length > 0
                    text: "󰔏 Feels like " + weather.feelsLike
                    color: Colors.muted
                    font.pixelSize: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    visible: weather.humidity.length > 0
                    text: "󰖎 Humidity " + weather.humidity
                    color: Colors.muted
                    font.pixelSize: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    visible: weather.wind.length > 0
                    text: "󰖝 Wind " + weather.wind
                    color: Colors.muted
                    font.pixelSize: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
