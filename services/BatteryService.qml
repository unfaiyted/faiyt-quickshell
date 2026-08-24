pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "." as Services

QtObject {
    id: root

    // UPower reports percentage as a 0.0-1.0 fraction, NOT 0-100.
    // Without the *100 every reading collapsed to 0 or 1, so the critical
    // threshold was permanently satisfied and fired on every change.
    readonly property int percentage: UPower.displayDevice
        ? Math.round(UPower.displayDevice.percentage * 100)
        : 100

    readonly property int state: UPower.displayDevice ? UPower.displayDevice.state : UPowerDeviceState.Unknown
    readonly property bool charging: state === UPowerDeviceState.Charging
    readonly property bool discharging: state === UPowerDeviceState.Discharging
    readonly property bool hasBattery: UPower.displayDevice
        ? (UPower.displayDevice.isLaptopBattery && UPower.displayDevice.isPresent)
        : false

    // Warning level, then a descending ladder of critical levels.
    readonly property int warnLevel: Services.ConfigService.batteryLow

    readonly property var criticalLevels: {
        const first = Services.ConfigService.batteryCritical
        const configured = Services.ConfigService.batteryCriticalLevels
        const levels = (Array.isArray(configured) ? configured : [])
            .filter(v => typeof v === "number" && v > 0 && v <= first)
        if (levels.indexOf(first) === -1) levels.push(first)
        return [...new Set(levels)].sort((a, b) => b - a)
    }

    // Track notification state to avoid spam
    property bool warnNotificationSent: false
    property int lastCriticalLevelSent: 0   // 0 = none sent this discharge cycle


    // Alerts only run while actually on battery. Gating on state rather than
    // "not charging" also skips the Unknown/unpopulated startup window, where
    // UPower reports 0% before the device has been read. Kept as its own bound
    // property so the ladder can be exercised without a draining battery.
    property bool monitoringActive: hasBattery && discharging

    // Re-arm the whole ladder whenever we stop running on battery
    onMonitoringActiveChanged: {
        if (!monitoringActive) {
            warnNotificationSent = false
            lastCriticalLevelSent = 0
        }
    }

    onPercentageChanged: evaluateThresholds()

    function evaluateThresholds(pct) {
        if (pct === undefined) pct = percentage
        if (!monitoringActive) return
        if (pct <= 0) return

        // criticalLevels is descending, so this settles on the deepest level crossed
        let level = 0
        for (const l of criticalLevels) {
            if (pct <= l) level = l
        }

        if (level > 0) {
            // Fire once per level, and only as the battery drops further
            if (lastCriticalLevelSent === 0 || level < lastCriticalLevelSent) {
                sendCriticalNotification(pct)
                lastCriticalLevelSent = level
            }
            return
        }

        // Above every critical level - allow the ladder to re-arm
        lastCriticalLevelSent = 0

        if (pct <= warnLevel) {
            if (!warnNotificationSent) {
                sendWarnNotification(pct)
                warnNotificationSent = true
            }
        } else {
            warnNotificationSent = false
        }
    }

    function sendWarnNotification(pct) {
        notify("normal", "Low Battery",
               "Battery at " + pct + "%. Connect charger soon.")
    }

    function sendCriticalNotification(pct) {
        notify("critical", "Critical Battery",
               "Battery at " + pct + "%. Connect charger immediately!")
    }

    // Detached so two alerts in quick succession can't cancel each other,
    // which a single shared Process would do
    function notify(urgency, summary, body) {
        Quickshell.execDetached([
            "notify-send",
            "-a", "Battery",
            "-u", urgency,
            summary,
            body
        ])
    }
}
