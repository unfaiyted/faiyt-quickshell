pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

QtObject {
    id: root

    // Track battery state
    readonly property int percentage: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage) : 100
    readonly property bool charging: UPower.displayDevice ? UPower.displayDevice.state === UPowerDeviceState.Charging : false
    readonly property bool hasBattery: UPower.displayDevice && UPower.displayDevice.isLaptopBattery

    // Track notification state to avoid spam
    property bool lowNotificationSent: false
    property bool criticalNotificationSent: false

    // Reset notification flags when charging
    onChargingChanged: {
        if (charging) {
            lowNotificationSent = false
            criticalNotificationSent = false
        }
    }

    onPercentageChanged: {
        if (!hasBattery || charging) return

        const lowThreshold = ConfigService.batteryLow
        const criticalThreshold = ConfigService.batteryCritical

        // Reset flags if battery rises above thresholds
        if (percentage > lowThreshold) lowNotificationSent = false
        if (percentage > criticalThreshold) criticalNotificationSent = false

        // Send notifications when crossing thresholds
        if (percentage <= criticalThreshold && !criticalNotificationSent) {
            sendCriticalNotification()
            criticalNotificationSent = true
        } else if (percentage <= lowThreshold && !lowNotificationSent) {
            sendLowNotification()
            lowNotificationSent = true
        }
    }

    function sendLowNotification() {
        lowNotifyProcess.command = [
            "notify-send",
            "-a", "Battery",
            "-u", "normal",
            "Low Battery",
            "Battery at " + percentage + "%. Connect charger soon."
        ]
        lowNotifyProcess.running = true
    }

    function sendCriticalNotification() {
        criticalNotifyProcess.command = [
            "notify-send",
            "-a", "Battery",
            "-u", "critical",
            "Critical Battery",
            "Battery at " + percentage + "%. Connect charger immediately!"
        ]
        criticalNotifyProcess.running = true
    }

    property var lowNotifyProcess: Process {
        id: lowNotifyProcess
    }

    property var criticalNotifyProcess: Process {
        id: criticalNotifyProcess
    }
}
