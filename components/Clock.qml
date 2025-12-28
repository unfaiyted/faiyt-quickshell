import QtQuick
import "../theme"

BarGroup {
    id: clockContainer

    implicitWidth: timeText.width + 24
    implicitHeight: 32

    property string currentTime: Qt.formatTime(new Date(), "HH:mm")

    Text {
        id: timeText
        anchors.centerIn: parent
        text: clockContainer.currentTime
        color: Colors.foreground
        font.pixelSize: 12
        font.bold: true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockContainer.currentTime = Qt.formatTime(new Date(), "HH:mm")
    }
}
