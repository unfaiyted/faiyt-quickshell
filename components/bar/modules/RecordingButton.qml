import QtQuick
import "../../../theme"

Item {
    id: recordBtn

    width: 20
    height: 20

    // Icon text element
    Text {
        id: iconText
        anchors.centerIn: parent
        // Video camera when idle, record dot when recording
        text: RecordingState.isRecording ? "󰑋" : "󰕧"
        font.pixelSize: 14
        font.family: "Symbols Nerd Font"
        color: RecordingState.isRecording ? Colors.error :
               (mouseArea.containsMouse ? Colors.rose : Colors.foreground)

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    // Pulsing animation when recording
    SequentialAnimation {
        id: pulseAnimation
        running: RecordingState.isRecording
        loops: Animation.Infinite

        NumberAnimation {
            target: iconText
            property: "opacity"
            to: 0.4
            duration: 500
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: iconText
            property: "opacity"
            to: 1.0
            duration: 500
            easing.type: Easing.InOutQuad
        }
    }

    // Reset opacity when not recording
    Connections {
        target: RecordingState
        function onIsRecordingChanged() {
            if (!RecordingState.isRecording) {
                iconText.opacity = 1.0
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            RecordingState.toggle()
        }
    }

}
