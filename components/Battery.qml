import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../theme"

BarGroup {
    id: batteryModule

    implicitWidth: row.width + 16
    implicitHeight: 24

    // Only show if there's a laptop battery
    visible: UPower.displayDevice && UPower.displayDevice.isLaptopBattery

    property int percentage: UPower.displayDevice
        ? Math.round(UPower.displayDevice.percentage)
        : 0

    property bool charging: UPower.displayDevice
        ? UPower.displayDevice.state === UPowerDeviceState.Charging
        : false

    property int timeRemaining: UPower.displayDevice
        ? (charging ? UPower.displayDevice.timeToFull : UPower.displayDevice.timeToEmpty)
        : 0

    property string timeRemainingText: {
        if (timeRemaining <= 0) return "Calculating..."
        const hours = Math.floor(timeRemaining / 3600)
        const minutes = Math.floor((timeRemaining % 3600) / 60)
        if (hours > 0) {
            return hours + "h " + minutes + "m"
        }
        return minutes + " min"
    }

    property string statusText: {
        if (charging) return "Charging"
        if (percentage === 100) return "Fully charged"
        return "Discharging"
    }

    property color batteryColor: {
        if (charging) return Colors.success
        if (percentage <= 15) return Colors.error
        if (percentage <= 30) return Colors.warning
        return Colors.foreground
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        // Battery circle indicator
        Rectangle {
            width: 20
            height: 20
            radius: 10
            color: "transparent"
            border.width: 2
            border.color: batteryModule.batteryColor

            Text {
                anchors.centerIn: parent
                text: batteryModule.percentage
                font.pixelSize: 8
                font.bold: true
                color: batteryModule.batteryColor
            }
        }

        // Charging indicator or percent sign
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: batteryModule.charging ? "⚡" : "%"
            font.pixelSize: 10
            color: batteryModule.batteryColor
        }
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
            const pos = batteryModule.mapToItem(QsWindow.window.contentItem, 0, batteryModule.height)
            anchor.rect = Qt.rect(pos.x, pos.y, batteryModule.width, 1)
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
                    text: batteryModule.percentage + "%"
                    color: batteryModule.batteryColor
                    font.pixelSize: 14
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: batteryModule.statusText
                    color: Colors.subtle
                    font.pixelSize: 11
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    width: tooltipColumn.width
                    height: 1
                    color: Colors.overlay
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: batteryModule.timeRemaining > 0
                }

                Text {
                    visible: batteryModule.timeRemaining > 0
                    text: (batteryModule.charging ? "󱐋 " : "󰁾 ") + batteryModule.timeRemainingText + (batteryModule.charging ? " until full" : " remaining")
                    color: Colors.muted
                    font.pixelSize: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
