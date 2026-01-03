import QtQuick
import Quickshell
import Quickshell.Io
import "../../../theme"
import "../../../services"
import ".."

BarGroup {
    id: clockContainer

    implicitWidth: timeText.width + 20
    implicitHeight: 30

    property date now: new Date()
    property bool popupOpen: false

    // Timezone times cache - updated by timer
    property var timezoneTimes: ({})

    // Hover state tracking
    property bool hoverModule: false
    property bool hoverTimezoneRow: false  // Set by timezone row MouseAreas
    property bool hoverPopup: tooltipMouseArea.containsMouse ||
                              dateRowArea.containsMouse ||
                              localTimeArea.containsMouse ||
                              timestampArea.containsMouse ||
                              hoverTimezoneRow

    // Format time using config (convert strftime to Qt format)
    property string currentTime: {
        let fmt = ConfigService.timeFormat
        fmt = fmt.replace(/%H/g, "HH").replace(/%M/g, "mm").replace(/%S/g, "ss")
        fmt = fmt.replace(/%I/g, "hh").replace(/%p/g, "AP")
        return Qt.formatTime(now, fmt)
    }

    property string fullDate: Qt.formatDateTime(now, "dddd, MMMM d, yyyy")
    property string fullTime: Qt.formatDateTime(now, "hh:mm:ss AP")
    property string timestamp: Math.floor(now.getTime() / 1000).toString()

    // Clipboard process
    Process {
        id: copyProcess
        command: ["wl-copy", ""]
    }

    function copyToClipboard(text) {
        copyProcess.command = ["wl-copy", text]
        copyProcess.running = true
        popupOpen = false
    }

    // Get cached time for a timezone
    function getTimeInTimezone(tzId) {
        return timezoneTimes[tzId]?.time || "--:--"
    }

    // Get cached offset for a timezone
    function getTimezoneOffset(tzId) {
        return timezoneTimes[tzId]?.offset || ""
    }

    // Update all timezone times - processes one at a time
    property int tzUpdateIndex: 0

    function updateTimezoneTimes() {
        if (ConfigService.timezones.length === 0) return
        tzUpdateIndex = 0
        updateNextTimezone()
    }

    function updateNextTimezone() {
        if (tzUpdateIndex >= ConfigService.timezones.length) return

        let tz = ConfigService.timezones[tzUpdateIndex]
        tzProcess.currentTzId = tz.id
        tzProcess.command = ["bash", "-c", "TZ='" + tz.id + "' date '+%H:%M|%Z'"]
        tzProcess.running = true
    }

    Process {
        id: tzProcess

        property string currentTzId: ""
        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                tzProcess.buffer = data.trim()
            }
        }

        onRunningChanged: {
            if (!running && buffer.length > 0) {
                // Parse "HH:MM|TZ" format
                let parts = buffer.split("|")
                if (parts.length === 2) {
                    let newTimes = JSON.parse(JSON.stringify(clockContainer.timezoneTimes))
                    newTimes[currentTzId] = {
                        time: parts[0],
                        offset: parts[1]
                    }
                    clockContainer.timezoneTimes = newTimes
                }
                buffer = ""

                // Process next timezone
                clockContainer.tzUpdateIndex++
                clockContainer.updateNextTimezone()
            }
        }
    }

    // Close timer
    Timer {
        id: closeTimer
        interval: 300
        repeat: false
        onTriggered: {
            if (!clockContainer.hoverModule && !clockContainer.hoverPopup) {
                clockContainer.popupOpen = false
            }
        }
    }

    // Time update timer
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            clockContainer.now = new Date()
            // Update timezone times every minute or when popup is open
            if (clockContainer.popupOpen || clockContainer.now.getSeconds() === 0) {
                clockContainer.updateTimezoneTimes()
            }
        }
    }

    // Update timezone times when timezones config changes
    Connections {
        target: ConfigService
        function onTimezonesChanged() {
            clockContainer.updateTimezoneTimes()
        }
    }

    // Initial timezone update
    Component.onCompleted: {
        updateTimezoneTimes()
    }

    Text {
        id: timeText
        anchors.centerIn: parent
        text: clockContainer.currentTime
        color: Colors.foreground
        font.pixelSize: 12
        font.bold: true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            closeTimer.stop()
            clockContainer.hoverModule = true
            clockContainer.popupOpen = true
            clockContainer.updateTimezoneTimes()
        }

        onExited: {
            clockContainer.hoverModule = false
            closeTimer.start()
        }
    }

    // Custom tooltip popup window
    PopupWindow {
        id: tooltip
        anchor.window: QsWindow.window
        anchor.onAnchoring: {
            const pos = clockContainer.mapToItem(QsWindow.window.contentItem, 0, clockContainer.height)
            anchor.rect = Qt.rect(pos.x, pos.y, clockContainer.width, 7)
        }
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        visible: clockContainer.popupOpen

        implicitWidth: tooltipContent.width
        implicitHeight: tooltipContent.height
        color: "transparent"

        Rectangle {
            id: tooltipContent
            width: Math.max(tooltipColumn.width + 24, 220)
            height: tooltipColumn.height + 16
            color: Colors.surface
            radius: 8
            border.width: 1
            border.color: Colors.overlay

            MouseArea {
                id: tooltipMouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton

                onEntered: closeTimer.stop()
                onExited: closeTimer.start()
            }

            Column {
                id: tooltipColumn
                anchors.centerIn: parent
                spacing: 6

                // Date row - clickable to copy
                Rectangle {
                    width: dateRow.width + 16
                    height: 28
                    radius: 4
                    color: dateRowArea.containsMouse ? Colors.overlay : "transparent"
                    anchors.horizontalCenter: parent.horizontalCenter

                    Row {
                        id: dateRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: clockContainer.fullDate
                            color: Colors.foreground
                            font.pixelSize: 12
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "󰆏"
                            font.family: Fonts.icon
                            font.pixelSize: 10
                            color: dateRowArea.containsMouse ? Colors.primary : Colors.muted
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: dateRowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: closeTimer.stop()
                        onExited: closeTimer.start()
                        onClicked: clockContainer.copyToClipboard(clockContainer.fullDate)
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Colors.overlay
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Local time row
                Rectangle {
                    width: localTimeRow.width + 16
                    height: 28
                    radius: 4
                    color: localTimeArea.containsMouse ? Colors.overlay : "transparent"
                    anchors.horizontalCenter: parent.horizontalCenter

                    Row {
                        id: localTimeRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "󰥔"
                            font.family: Fonts.icon
                            font.pixelSize: 12
                            color: Colors.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Local"
                            color: Colors.foregroundAlt
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: clockContainer.fullTime
                            color: Colors.foreground
                            font.pixelSize: 11
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "󰆏"
                            font.family: Fonts.icon
                            font.pixelSize: 10
                            color: localTimeArea.containsMouse ? Colors.primary : Colors.muted
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: localTimeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: closeTimer.stop()
                        onExited: closeTimer.start()
                        onClicked: clockContainer.copyToClipboard(clockContainer.fullTime)
                    }
                }

                // Timezone rows
                Repeater {
                    model: ConfigService.timezones

                    Rectangle {
                        required property var modelData
                        required property int index

                        width: tzRow.width + 16
                        height: 28
                        radius: 4
                        color: tzArea.containsMouse ? Colors.overlay : "transparent"
                        anchors.horizontalCenter: parent.horizontalCenter

                        Row {
                            id: tzRow
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: "󰗶"
                                font.family: Fonts.icon
                                font.pixelSize: 12
                                color: Colors.foam
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.label
                                color: Colors.foregroundAlt
                                font.pixelSize: 11
                                width: 80
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: clockContainer.getTimezoneOffset(modelData.id)
                                color: Colors.muted
                                font.pixelSize: 9
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: clockContainer.getTimeInTimezone(modelData.id)
                                color: Colors.foreground
                                font.pixelSize: 11
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "󰆏"
                                font.family: Fonts.icon
                                font.pixelSize: 10
                                color: tzArea.containsMouse ? Colors.primary : Colors.muted
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: tzArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: {
                                closeTimer.stop()
                                clockContainer.hoverTimezoneRow = true
                            }
                            onExited: {
                                clockContainer.hoverTimezoneRow = false
                                closeTimer.start()
                            }
                            onClicked: clockContainer.copyToClipboard(clockContainer.getTimeInTimezone(modelData.id))
                        }
                    }
                }

                // Separator before timestamp (only if we have content above)
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Colors.overlay
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Unix timestamp row
                Rectangle {
                    width: timestampRow.width + 16
                    height: 24
                    radius: 4
                    color: timestampArea.containsMouse ? Colors.overlay : "transparent"
                    anchors.horizontalCenter: parent.horizontalCenter

                    Row {
                        id: timestampRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "Unix: " + clockContainer.timestamp
                            color: Colors.muted
                            font.pixelSize: 10
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "󰆏"
                            font.family: Fonts.icon
                            font.pixelSize: 10
                            color: timestampArea.containsMouse ? Colors.primary : Colors.muted
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: timestampArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: closeTimer.stop()
                        onExited: closeTimer.start()
                        onClicked: clockContainer.copyToClipboard(clockContainer.timestamp)
                    }
                }
            }
        }
    }
}
