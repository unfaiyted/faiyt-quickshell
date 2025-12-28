import QtQuick
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
}
