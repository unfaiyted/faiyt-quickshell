import QtQuick
import Quickshell
import Quickshell.Io
import "../../../theme"
import "../../../services"
import ".."
import "../../common"

BarGroup {
    id: weather

    implicitWidth: barContent.width + 16
    implicitHeight: 30

    property bool popupOpen: false

    // Hover state tracking
    property bool hoverModule: false
    property bool hoverTempRow: false
    property bool hoverPopup: tooltipMouseArea.containsMouse || hoverTempRow

    // Weather data
    property var currentWeather: ({
        temp: "",
        feelsLike: "",
        condition: "",
        conditionCode: 0,
        humidity: "",
        wind: "",
        windDir: "",
        uvIndex: "",
        visibility: "",
        pressure: ""
    })

    property var forecast: []
    property string location: ""
    property string sunrise: ""
    property string sunset: ""
    property bool loading: true

    // Get weather icon based on condition code (wttr.in WWO codes)
    function getWeatherIcon(code) {
        let c = parseInt(code)
        // WWO condition codes from wttr.in
        if (c === 113) return "󰖙"      // Sunny/Clear
        if (c === 116) return "󰖕"      // Partly cloudy
        if (c === 119) return "󰖐"      // Cloudy
        if (c === 122) return "󰖐"      // Overcast
        if (c === 143) return "󰖑"      // Mist
        if (c === 176) return "󰖗"      // Patchy rain
        if (c === 179) return "󰖘"      // Patchy snow
        if (c === 182) return "󰙿"      // Patchy sleet
        if (c === 185) return "󰖗"      // Patchy freezing drizzle
        if (c === 200) return "󰖓"      // Thundery outbreaks
        if (c === 227) return "󰖘"      // Blowing snow
        if (c === 230) return "󰖘"      // Blizzard
        if (c === 248) return "󰖑"      // Fog
        if (c === 260) return "󰖑"      // Freezing fog
        if (c === 263) return "󰖗"      // Patchy light drizzle
        if (c === 266) return "󰖗"      // Light drizzle
        if (c === 281) return "󰖗"      // Freezing drizzle
        if (c === 284) return "󰖗"      // Heavy freezing drizzle
        if (c === 293) return "󰖖"      // Patchy light rain
        if (c === 296) return "󰖖"      // Light rain
        if (c === 299) return "󰖖"      // Moderate rain at times
        if (c === 302) return "󰖖"      // Moderate rain
        if (c === 305) return "󰖖"      // Heavy rain at times
        if (c === 308) return "󰖖"      // Heavy rain
        if (c === 311) return "󰖖"      // Light freezing rain
        if (c === 314) return "󰖖"      // Moderate/heavy freezing rain
        if (c === 317) return "󰙿"      // Light sleet
        if (c === 320) return "󰙿"      // Moderate/heavy sleet
        if (c === 323) return "󰖘"      // Patchy light snow
        if (c === 326) return "󰖘"      // Light snow
        if (c === 329) return "󰖘"      // Patchy moderate snow
        if (c === 332) return "󰖘"      // Moderate snow
        if (c === 335) return "󰖘"      // Patchy heavy snow
        if (c === 338) return "󰖘"      // Heavy snow
        if (c === 350) return "󰖒"      // Ice pellets
        if (c === 353) return "󰖖"      // Light rain shower
        if (c === 356) return "󰖖"      // Moderate/heavy rain shower
        if (c === 359) return "󰖖"      // Torrential rain shower
        if (c === 362) return "󰙿"      // Light sleet showers
        if (c === 365) return "󰙿"      // Moderate/heavy sleet showers
        if (c === 368) return "󰖘"      // Light snow showers
        if (c === 371) return "󰖘"      // Moderate/heavy snow showers
        if (c === 374) return "󰖒"      // Light ice pellet showers
        if (c === 377) return "󰖒"      // Moderate/heavy ice pellet showers
        if (c === 386) return "󰖓"      // Patchy light rain with thunder
        if (c === 389) return "󰖓"      // Moderate/heavy rain with thunder
        if (c === 392) return "󰖓"      // Patchy light snow with thunder
        if (c === 395) return "󰖓"      // Moderate/heavy snow with thunder
        return "󰖐"                     // Default cloudy
    }

    // Get accent color based on weather condition
    function getWeatherColor(code) {
        let c = parseInt(code)
        if (c === 113) return Colors.gold      // Sunny
        if (c === 116) return Colors.foam      // Partly cloudy
        if (c >= 176 && c <= 185) return Colors.iris  // Rain/drizzle
        if (c >= 200 && c <= 200) return Colors.love  // Thunder
        if (c >= 227 && c <= 338) return Colors.subtle // Snow
        if (c >= 386) return Colors.love       // Thunderstorms
        return Colors.foreground
    }

    // Get day name from date string
    function getDayName(dateStr) {
        let d = new Date(dateStr)
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[d.getDay()]
    }

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

    function copyWeatherSummary() {
        let unit = ConfigService.temperatureUnit === "F" ? "°F" : "°C"
        let summary = location + ": " + currentWeather.temp + unit + " - " + currentWeather.condition
        copyToClipboard(summary)
    }

    // Build wttr.in URL with city and unit
    function getWeatherUrl() {
        let city = ConfigService.weatherCity || ""
        let unit = ConfigService.temperatureUnit === "F" ? "u" : "m"
        let loc = city ? city.replace(/ /g, "+") : ""
        return "https://wttr.in/" + loc + "?format=j1&" + unit
    }

    // Fetch weather data
    Process {
        id: weatherProcess
        command: ["curl", "-s", weather.getWeatherUrl()]
        running: true

        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                weatherProcess.buffer += data + "\n"
            }
        }

        onRunningChanged: {
            if (!running && buffer.length > 0) {
                try {
                    let data = JSON.parse(buffer)

                    // Current conditions
                    let current = data.current_condition[0]
                    let tempKey = ConfigService.temperatureUnit === "F" ? "temp_F" : "temp_C"
                    let feelsKey = ConfigService.temperatureUnit === "F" ? "FeelsLikeF" : "FeelsLikeC"
                    let windKey = ConfigService.temperatureUnit === "F" ? "windspeedMiles" : "windspeedKmph"
                    let windUnit = ConfigService.temperatureUnit === "F" ? " mph" : " km/h"

                    weather.currentWeather = {
                        temp: current[tempKey],
                        feelsLike: current[feelsKey],
                        condition: current.weatherDesc[0].value,
                        conditionCode: current.weatherCode,
                        humidity: current.humidity,
                        wind: current[windKey] + windUnit,
                        windDir: current.winddir16Point,
                        uvIndex: current.uvIndex,
                        visibility: current.visibility,
                        pressure: current.pressure
                    }

                    // Location
                    weather.location = data.nearest_area[0].areaName[0].value

                    // Forecast (next 3 days)
                    let maxKey = ConfigService.temperatureUnit === "F" ? "maxtempF" : "maxtempC"
                    let minKey = ConfigService.temperatureUnit === "F" ? "mintempF" : "mintempC"

                    weather.forecast = data.weather.slice(0, 3).map(function(day) {
                        return {
                            date: day.date,
                            high: day[maxKey],
                            low: day[minKey],
                            conditionCode: day.hourly[4].weatherCode,
                            condition: day.hourly[4].weatherDesc[0].value
                        }
                    })

                    // Sun times
                    weather.sunrise = data.weather[0].astronomy[0].sunrise
                    weather.sunset = data.weather[0].astronomy[0].sunset

                    weather.loading = false

                } catch (e) {
                    console.log("Weather: Failed to parse data:", e)
                    weather.loading = false
                }
                buffer = ""
            }
        }
    }

    // Refresh timer - every 10 minutes
    Timer {
        interval: 600000
        running: true
        repeat: true
        onTriggered: weather.refreshWeather()
    }

    // Watch for config changes
    Connections {
        target: ConfigService
        function onTemperatureUnitChanged() {
            weather.refreshWeather()
        }
        function onWeatherCityChanged() {
            weather.refreshWeather()
        }
    }

    // Refresh weather data
    function refreshWeather() {
        loading = true
        weatherProcess.buffer = ""
        weatherProcess.command = ["curl", "-s", getWeatherUrl()]
        weatherProcess.running = true
    }

    // Close timer
    Timer {
        id: closeTimer
        interval: 300
        repeat: false
        onTriggered: {
            if (!weather.hoverModule && !weather.hoverPopup) {
                weather.popupOpen = false
            }
        }
    }

    // Bar display
    Row {
        id: barContent
        anchors.centerIn: parent
        spacing: 4

        Text {
            visible: !weather.loading
            text: weather.getWeatherIcon(weather.currentWeather.conditionCode)
            font.family: Fonts.icon
            font.pixelSize: Fonts.iconMedium
            color: weather.getWeatherColor(weather.currentWeather.conditionCode)
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: weather.loading ? "..." : weather.currentWeather.temp + "°"
            font.family: Fonts.ui
            font.pixelSize: Fonts.small
            color: Colors.foreground
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            closeTimer.stop()
            weather.hoverModule = true
            weather.popupOpen = true
        }

        onExited: {
            weather.hoverModule = false
            closeTimer.start()
        }
    }

    HintTarget {
        targetElement: weather
        scope: "bar"
        action: () => {
            weather.popupOpen = true
        }
    }

    // Weather popup
    PopupWindow {
        id: tooltip
        anchor.window: QsWindow.window
        anchor.onAnchoring: {
            const pos = weather.mapToItem(QsWindow.window.contentItem, 0, weather.height)
            anchor.rect = Qt.rect(pos.x - 100, pos.y, weather.width, 7)
        }
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        visible: weather.popupOpen

        implicitWidth: tooltipContent.width
        implicitHeight: tooltipContent.height
        color: "transparent"

        Rectangle {
            id: tooltipContent
            width: 260
            height: tooltipColumn.height + 24
            color: Colors.surface
            radius: 12
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
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 12
                spacing: 10
                width: parent.width - 24

                // Header: Icon + Location + Condition
                Row {
                    spacing: 12
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        text: weather.getWeatherIcon(weather.currentWeather.conditionCode)
                        font.family: Fonts.icon
                        font.pixelSize: Fonts.iconHuge
                        color: weather.getWeatherColor(weather.currentWeather.conditionCode)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: weather.location
                            color: Colors.foreground
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.medium
                            font.bold: true
                        }

                        Text {
                            text: weather.currentWeather.condition
                            color: Colors.foregroundAlt
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                        }
                    }
                }

                // Temperature (clickable to copy)
                Rectangle {
                    id: tempRowRect
                    width: tempRow.width + 20
                    height: 50
                    radius: 8
                    color: tempRowArea.containsMouse ? Colors.overlay : "transparent"
                    anchors.horizontalCenter: parent.horizontalCenter

                    Row {
                        id: tempRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: weather.currentWeather.temp + "°" + ConfigService.temperatureUnit
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.huge
                            font.bold: true
                            color: Colors.foreground
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "󰆏"
                            font.family: Fonts.icon
                            font.pixelSize: Fonts.iconSmall
                            color: tempRowArea.containsMouse ? Colors.primary : Colors.muted
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: tempRowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: {
                            closeTimer.stop()
                            weather.hoverTempRow = true
                        }
                        onExited: {
                            weather.hoverTempRow = false
                            closeTimer.start()
                        }
                        onClicked: weather.copyWeatherSummary()
                    }

                    HintTarget {
                        targetElement: tempRowRect
                        scope: "bar"
                        enabled: tooltip.visible
                        action: () => weather.copyWeatherSummary()
                    }
                }

                // Feels like
                Text {
                    visible: weather.currentWeather.feelsLike.length > 0
                    text: "Feels like " + weather.currentWeather.feelsLike + "°"
                    color: Colors.muted
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.small
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Colors.overlay
                }

                // Weather details grid
                Grid {
                    columns: 2
                    spacing: 8
                    anchors.horizontalCenter: parent.horizontalCenter

                    // Humidity
                    Row {
                        spacing: 4
                        width: 100

                        Text {
                            text: "󰖎"
                            font.family: Fonts.icon
                            font.pixelSize: Fonts.iconSmall
                            color: Colors.foam
                        }
                        Text {
                            text: weather.currentWeather.humidity + "%"
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            color: Colors.foregroundAlt
                        }
                    }

                    // Wind
                    Row {
                        spacing: 4
                        width: 100

                        Text {
                            text: "󰖝"
                            font.family: Fonts.icon
                            font.pixelSize: Fonts.iconSmall
                            color: Colors.iris
                        }
                        Text {
                            text: weather.currentWeather.wind + " " + weather.currentWeather.windDir
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            color: Colors.foregroundAlt
                        }
                    }

                    // UV Index
                    Row {
                        spacing: 4
                        width: 100

                        Text {
                            text: "󰖙"
                            font.family: Fonts.icon
                            font.pixelSize: Fonts.iconSmall
                            color: Colors.gold
                        }
                        Text {
                            text: "UV " + weather.currentWeather.uvIndex
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            color: Colors.foregroundAlt
                        }
                    }

                    // Pressure
                    Row {
                        spacing: 4
                        width: 100

                        Text {
                            text: "󰁕"
                            font.family: Fonts.icon
                            font.pixelSize: Fonts.iconSmall
                            color: Colors.subtle
                        }
                        Text {
                            text: weather.currentWeather.pressure + " hPa"
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            color: Colors.foregroundAlt
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Colors.overlay
                }

                // 3-Day Forecast
                Text {
                    text: "3-Day Forecast"
                    font.family: Fonts.ui
                    font.pixelSize: Fonts.tiny
                    font.bold: true
                    color: Colors.muted
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Row {
                    spacing: 8
                    anchors.horizontalCenter: parent.horizontalCenter

                    Repeater {
                        model: weather.forecast

                        Rectangle {
                            width: 70
                            height: 70
                            radius: 8
                            color: Colors.overlay
                            opacity: 0.5

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: weather.getDayName(modelData.date)
                                    font.family: Fonts.ui
                                    font.pixelSize: Fonts.tiny
                                    font.bold: true
                                    color: Colors.foreground
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: weather.getWeatherIcon(modelData.conditionCode)
                                    font.family: Fonts.icon
                                    font.pixelSize: Fonts.xlarge
                                    color: weather.getWeatherColor(modelData.conditionCode)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: modelData.high + "° / " + modelData.low + "°"
                                    font.family: Fonts.ui
                                    font.pixelSize: Fonts.tiny
                                    color: Colors.foregroundAlt
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Colors.overlay
                }

                // Sunrise / Sunset
                Row {
                    spacing: 20
                    anchors.horizontalCenter: parent.horizontalCenter

                    Row {
                        spacing: 6

                        Text {
                            text: "󰖛"
                            font.family: Fonts.icon
                            font.pixelSize: Fonts.iconMedium
                            color: Colors.gold
                        }
                        Text {
                            text: weather.sunrise
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            color: Colors.foregroundAlt
                        }
                    }

                    Row {
                        spacing: 6

                        Text {
                            text: "󰖚"
                            font.family: Fonts.icon
                            font.pixelSize: Fonts.iconMedium
                            color: Colors.love
                        }
                        Text {
                            text: weather.sunset
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.small
                            color: Colors.foregroundAlt
                        }
                    }
                }
            }
        }
    }
}
