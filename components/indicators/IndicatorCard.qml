import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../../theme"

Rectangle {
    id: card

    property string icon: ""
    property real value: 0  // 0-100
    property string label: ""

    width: 280
    height: 80
    radius: 16
    color: Qt.rgba(Colors.backgroundElevated.r, Colors.backgroundElevated.g, Colors.backgroundElevated.b, 0.95)
    border.width: 1
    border.color: Colors.border

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.3)
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 8
        shadowBlur: 1.0
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Icon
            Text {
                font.family: "Symbols Nerd Font"
                font.pixelSize: 28
                color: Colors.foreground
                text: card.icon
            }

            // Spacer
            Item { Layout.fillWidth: true }

            // Value text
            Text {
                font.family: "monospace"
                font.pixelSize: 24
                font.weight: Font.Bold
                color: Colors.foreground
                text: (isNaN(card.value) ? 0 : Math.round(card.value)) + "%"
            }
        }

        // Label (optional)
        Text {
            visible: card.label !== ""
            font.pixelSize: 11
            color: Colors.foregroundAlt
            text: card.label
            Layout.fillWidth: true
        }

        // Progress bar
        ProgressBar {
            Layout.fillWidth: true
            value: card.value
            barHeight: 8
            barRadius: 4
        }
    }
}
