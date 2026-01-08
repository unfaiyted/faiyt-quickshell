import QtQuick
import "../../../theme"
import "../../common"

Item {
    id: calendar

    property date currentDate: new Date()
    property date viewDate: new Date()
    property int firstDayOfWeek: 0  // 0 = Sunday, 1 = Monday

    // Get days in month
    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate()
    }

    // Get first day of month (0 = Sunday, 6 = Saturday)
    function firstDayOfMonth(year, month) {
        return new Date(year, month, 1).getDay()
    }

    // Get month name
    function monthName(month) {
        const months = ["January", "February", "March", "April", "May", "June",
                       "July", "August", "September", "October", "November", "December"]
        return months[month]
    }

    // Check if date is today
    function isToday(day) {
        return day === currentDate.getDate() &&
               viewDate.getMonth() === currentDate.getMonth() &&
               viewDate.getFullYear() === currentDate.getFullYear()
    }

    // Navigate months
    function previousMonth() {
        let newDate = new Date(viewDate)
        newDate.setMonth(newDate.getMonth() - 1)
        viewDate = newDate
    }

    function nextMonth() {
        let newDate = new Date(viewDate)
        newDate.setMonth(newDate.getMonth() + 1)
        viewDate = newDate
    }

    function goToToday() {
        viewDate = new Date()
    }

    // Build calendar grid data
    function getCalendarDays() {
        let days = []
        let year = viewDate.getFullYear()
        let month = viewDate.getMonth()
        let totalDays = daysInMonth(year, month)
        let startDay = firstDayOfMonth(year, month)

        // Previous month padding
        let prevMonth = month === 0 ? 11 : month - 1
        let prevYear = month === 0 ? year - 1 : year
        let prevDays = daysInMonth(prevYear, prevMonth)

        for (let i = startDay - 1; i >= 0; i--) {
            days.push({ day: prevDays - i, current: false, today: false })
        }

        // Current month days
        for (let i = 1; i <= totalDays; i++) {
            days.push({ day: i, current: true, today: isToday(i) })
        }

        // Next month padding (fill to 42 cells = 6 weeks)
        let remaining = 42 - days.length
        for (let i = 1; i <= remaining; i++) {
            days.push({ day: i, current: false, today: false })
        }

        return days
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 16

        // Month header with navigation
        Row {
            width: parent.width
            height: 36

            // Previous month button
            Rectangle {
                id: prevMonthBtn
                width: 32
                height: 32
                radius: 8
                color: prevArea.containsMouse ? Colors.surface : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    font.family: Fonts.icon
                    font.pixelSize: Fonts.iconMedium
                    color: Colors.foreground
                }

                MouseArea {
                    id: prevArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: previousMonth()
                }

                HintTarget {
                    targetElement: prevMonthBtn
                    scope: "sidebar-right"
                    action: () => previousMonth()
                }
            }

            // Month and year
            Item {
                width: parent.width - 100
                height: parent.height

                Column {
                    anchors.centerIn: parent
                    spacing: 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: monthName(viewDate.getMonth()) + " " + viewDate.getFullYear()
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.medium
                        font.bold: true
                        color: Colors.foreground
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: goToToday()
                }
            }

            // Next month button
            Rectangle {
                id: nextMonthBtn
                width: 32
                height: 32
                radius: 8
                color: nextArea.containsMouse ? Colors.surface : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰅂"
                    font.family: Fonts.icon
                    font.pixelSize: Fonts.iconMedium
                    color: Colors.foreground
                }

                MouseArea {
                    id: nextArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: nextMonth()
                }

                HintTarget {
                    targetElement: nextMonthBtn
                    scope: "sidebar-right"
                    action: () => nextMonth()
                }
            }

            // Today button
            Rectangle {
                id: todayBtn
                width: 32
                height: 32
                radius: 8
                color: todayArea.containsMouse ? Colors.surface : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰃭"
                    font.family: Fonts.icon
                    font.pixelSize: Fonts.iconMedium
                    color: Colors.primary
                }

                MouseArea {
                    id: todayArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: goToToday()
                }

                HintTarget {
                    targetElement: todayBtn
                    scope: "sidebar-right"
                    action: () => goToToday()
                }
            }
        }

        // Day headers
        Row {
            width: parent.width
            height: 24

            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                Text {
                    width: parent.width / 7
                    text: modelData
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    font.bold: true
                    color: Colors.foregroundMuted
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Calendar grid
        Grid {
            id: calendarGrid
            width: parent.width
            columns: 7
            spacing: 4

            Repeater {
                model: getCalendarDays()

                Rectangle {
                    width: (calendarGrid.width - 24) / 7
                    height: width
                    radius: width / 2
                    color: modelData.today ? Colors.primary :
                           dayArea.containsMouse && modelData.current ? Colors.surface : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.small
                        font.bold: modelData.today
                        color: modelData.today ? Colors.background :
                               modelData.current ? Colors.foreground : Colors.foregroundMuted
                    }

                    MouseArea {
                        id: dayArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: modelData.current ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (modelData.current) {
                                // Could emit signal for date selection
                                console.log("Selected:", modelData.day, monthName(viewDate.getMonth()), viewDate.getFullYear())
                            }
                        }
                    }
                }
            }
        }

        // Current time display
        Rectangle {
            width: parent.width
            height: 48
            radius: 10
            color: Colors.surface

            Row {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    text: "󰥔"
                    font.family: Fonts.icon
                    font.pixelSize: Fonts.iconLarge
                    color: Colors.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    Text {
                        id: timeText
                        text: Qt.formatTime(currentDate, "hh:mm:ss")
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.large
                        font.bold: true
                        color: Colors.foreground
                    }

                    Text {
                        text: Qt.formatDate(currentDate, "dddd, MMMM d")
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.small
                        color: Colors.foregroundAlt
                    }
                }
            }
        }
    }

    // Update current time
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: currentDate = new Date()
    }
}
