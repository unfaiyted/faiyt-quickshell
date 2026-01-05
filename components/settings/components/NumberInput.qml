import QtQuick
import QtQuick.Controls
import "../../../theme"
import "../../common"

Rectangle {
    id: numberInput

    property int value: 0
    property int min: 0
    property int max: 100
    property int step: 1
    property string hintScope: "settings"
    signal valueModified(int value)

    width: 100
    height: 32
    radius: 8
    color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
    border.width: 1
    border.color: inputField.activeFocus
        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.5)
        : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)

    Behavior on border.color { ColorAnimation { duration: 150 } }

    Row {
        anchors.fill: parent
        anchors.margins: 2
        spacing: 0

        // Decrease button
        Rectangle {
            width: 24
            height: parent.height
            radius: 6
            color: decreaseArea.containsMouse ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.5) : "transparent"

            Text {
                anchors.centerIn: parent
                text: "−"
                font.pixelSize: 16
                color: numberInput.value > numberInput.min ? Colors.foreground : Colors.foregroundMuted
            }

            MouseArea {
                id: decreaseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: numberInput.decrease()
            }

            HintTarget {
                targetElement: parent
                scope: numberInput.hintScope
                action: () => numberInput.decrease()
            }
        }

        // Value display/input
        TextInput {
            id: inputField
            width: parent.width - 48
            height: parent.height
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: numberInput.value.toString()
            font.pixelSize: 13
            color: Colors.foreground
            selectByMouse: true
            validator: IntValidator { bottom: numberInput.min; top: numberInput.max }

            onEditingFinished: {
                let newValue = parseInt(text) || numberInput.min
                newValue = Math.max(numberInput.min, Math.min(numberInput.max, newValue))
                numberInput.value = newValue
                text = newValue.toString()
                numberInput.valueModified(newValue)
            }
        }

        // Increase button
        Rectangle {
            width: 24
            height: parent.height
            radius: 6
            color: increaseArea.containsMouse ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.5) : "transparent"

            Text {
                anchors.centerIn: parent
                text: "+"
                font.pixelSize: 16
                color: numberInput.value < numberInput.max ? Colors.foreground : Colors.foregroundMuted
            }

            MouseArea {
                id: increaseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: numberInput.increase()
            }

            HintTarget {
                targetElement: parent
                scope: numberInput.hintScope
                action: () => numberInput.increase()
            }
        }
    }

    function decrease() {
        if (numberInput.value > numberInput.min) {
            numberInput.value = Math.max(numberInput.min, numberInput.value - numberInput.step)
            numberInput.valueModified(numberInput.value)
        }
    }

    function increase() {
        if (numberInput.value < numberInput.max) {
            numberInput.value = Math.min(numberInput.max, numberInput.value + numberInput.step)
            numberInput.valueModified(numberInput.value)
        }
    }
}
