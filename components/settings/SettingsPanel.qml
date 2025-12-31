import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import "../../theme"
import "../../services"
import "components"

Rectangle {
    id: settingsPanel

    property string searchQuery: ""

    width: 600
    height: parent ? parent.height * 0.75 : 500
    radius: 20
    color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.85)
    border.width: 1
    border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)

    // Shadow layers
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        z: -1
        radius: parent.radius + 1
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.05)
    }

    Column {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            width: parent.width
            height: headerContent.height + 32
            color: "transparent"

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)
            }

            Column {
                id: headerContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 12

                // Title row
                Row {
                    width: parent.width
                    spacing: 12

                    Text {
                        text: "Settings"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                        color: Colors.foreground
                    }

                    Item { width: 1; Layout.fillWidth: true }

                    // Close button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 8
                        color: closeArea.containsMouse ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.5) : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                        border.width: 1
                        border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 14
                            color: Colors.foregroundAlt
                        }

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SettingsState.close()
                        }
                    }
                }

                // Search box
                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 12
                    color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                    border.width: 1
                    border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "󰍉"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 14
                            color: Colors.foregroundAlt
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextInput {
                            id: searchInput
                            width: parent.width - 30
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            color: Colors.foreground
                            selectByMouse: true
                            clip: true

                            onTextChanged: settingsPanel.searchQuery = text.toLowerCase()

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Search settings..."
                                font.pixelSize: 14
                                color: Colors.foregroundMuted
                                visible: searchInput.text.length === 0
                            }
                        }
                    }
                }
            }
        }

        // Scrollable content
        Flickable {
            width: parent.width
            height: parent.height - headerContent.height - 48
            contentHeight: contentColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 6

                contentItem: Rectangle {
                    implicitWidth: 6
                    radius: 3
                    color: Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.2)
                }
            }

            Column {
                id: contentColumn
                width: parent.width - 40
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 20
                bottomPadding: 20
                spacing: 16

                // Helper function for search filtering
                function matchesSearch(text) {
                    return settingsPanel.searchQuery === "" || text.toLowerCase().includes(settingsPanel.searchQuery)
                }

                // Appearance Section
                SettingsSection {
                    visible: contentColumn.matchesSearch("appearance") || contentColumn.matchesSearch("theme") || contentColumn.matchesSearch("bar")
                    title: "Appearance"

                    ThemeSelector {
                        visible: contentColumn.matchesSearch("theme")
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("bar mode")
                        label: "Bar Mode"
                        description: "Default bar display mode"

                        DropdownSelect {
                            model: [
                                {label: "Normal", value: "normal"},
                                {label: "Focus", value: "focus"},
                                {label: "Nothing", value: "nothing"}
                            ]
                            currentIndex: {
                                const mode = ConfigService.barMode
                                if (mode === "focus") return 1
                                if (mode === "nothing") return 2
                                return 0
                            }
                            onSelected: (index, value) => {
                                ConfigService.setValue("bar.mode", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }
                }

                // Time & Weather Section
                SettingsSection {
                    visible: contentColumn.matchesSearch("time") || contentColumn.matchesSearch("weather") || contentColumn.matchesSearch("clock") || contentColumn.matchesSearch("temperature")
                    title: "Time & Weather"

                    SettingRow {
                        visible: contentColumn.matchesSearch("time format")
                        label: "Time Format"
                        description: "Clock display format"

                        SettingsTextInput {
                            text: ConfigService.timeFormat
                            placeholder: "%H:%M"
                            onTextEdited: (value) => {
                                ConfigService.setValue("time.format", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("weather city")
                        label: "Weather City"
                        description: "City for weather data"

                        SettingsTextInput {
                            text: ConfigService.weatherCity
                            placeholder: "New York"
                            onTextEdited: (value) => {
                                ConfigService.setValue("weather.city", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("temperature unit")
                        label: "Temperature Unit"
                        description: "Celsius or Fahrenheit"

                        DropdownSelect {
                            model: [
                                {label: "Celsius", value: "C"},
                                {label: "Fahrenheit", value: "F"}
                            ]
                            currentIndex: ConfigService.temperatureUnit === "F" ? 1 : 0
                            onSelected: (index, value) => {
                                ConfigService.setValue("weather.preferredUnit", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }
                }

                // Search Section
                SettingsSection {
                    visible: contentColumn.matchesSearch("search") || contentColumn.matchesSearch("launcher") || contentColumn.matchesSearch("results")
                    title: "Search"

                    SettingRow {
                        visible: contentColumn.matchesSearch("max results")
                        label: "Max Results"
                        description: "Maximum search results to display"

                        NumberInput {
                            value: ConfigService.launcherMaxResults
                            min: 5
                            max: 50
                            step: 5
                            onValueModified: (v) => {
                                ConfigService.setValue("launcher.maxResults", v)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("actions")
                        label: "Actions"
                        description: "Enable system actions"

                        ToggleSwitch {
                            checked: ConfigService.getValue("search.enableFeatures.actions") ?? true
                            onToggled: (value) => {
                                ConfigService.setValue("search.enableFeatures.actions", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("commands")
                        label: "Commands"
                        description: "Enable shell commands"

                        ToggleSwitch {
                            checked: ConfigService.getValue("search.enableFeatures.commands") ?? true
                            onToggled: (value) => {
                                ConfigService.setValue("search.enableFeatures.commands", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("math")
                        label: "Math Results"
                        description: "Show calculator results"

                        ToggleSwitch {
                            checked: ConfigService.getValue("search.enableFeatures.mathResults") ?? true
                            onToggled: (value) => {
                                ConfigService.setValue("search.enableFeatures.mathResults", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("directory")
                        label: "Directory Search"
                        description: "Enable directory browsing"

                        ToggleSwitch {
                            checked: ConfigService.getValue("search.enableFeatures.directorySearch") ?? false
                            onToggled: (value) => {
                                ConfigService.setValue("search.enableFeatures.directorySearch", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }
                }

                // Search Evaluators Section
                SettingsSection {
                    visible: contentColumn.matchesSearch("evaluator") || contentColumn.matchesSearch("calculator") || contentColumn.matchesSearch("converter")
                    title: "Search Evaluators"

                    SettingRow {
                        visible: contentColumn.matchesSearch("math evaluator")
                        label: "Math Evaluator"
                        description: "Calculate math expressions"

                        ToggleSwitch {
                            checked: ConfigService.getValue("search.evaluators.mathEvaluator") ?? true
                            onToggled: (value) => {
                                ConfigService.setValue("search.evaluators.mathEvaluator", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("base converter")
                        label: "Base Converter"
                        description: "Convert between number bases"

                        ToggleSwitch {
                            checked: ConfigService.getValue("search.evaluators.baseConverter") ?? true
                            onToggled: (value) => {
                                ConfigService.setValue("search.evaluators.baseConverter", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("color converter")
                        label: "Color Converter"
                        description: "Convert between color formats"

                        ToggleSwitch {
                            checked: ConfigService.getValue("search.evaluators.colorConverter") ?? true
                            onToggled: (value) => {
                                ConfigService.setValue("search.evaluators.colorConverter", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("unit converter")
                        label: "Unit Converter"
                        description: "Convert between units"

                        ToggleSwitch {
                            checked: ConfigService.getValue("search.evaluators.unitConverter") ?? true
                            onToggled: (value) => {
                                ConfigService.setValue("search.evaluators.unitConverter", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("time calculator")
                        label: "Time Calculator"
                        description: "Calculate time differences"

                        ToggleSwitch {
                            checked: ConfigService.getValue("search.evaluators.timeCalculator") ?? true
                            onToggled: (value) => {
                                ConfigService.setValue("search.evaluators.timeCalculator", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("percentage")
                        label: "Percentage Calculator"
                        description: "Calculate percentages"

                        ToggleSwitch {
                            checked: ConfigService.getValue("search.evaluators.percentageCalculator") ?? true
                            onToggled: (value) => {
                                ConfigService.setValue("search.evaluators.percentageCalculator", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }
                }

                // Battery Section
                SettingsSection {
                    visible: contentColumn.matchesSearch("battery") || contentColumn.matchesSearch("power")
                    title: "Battery"

                    SettingRow {
                        visible: contentColumn.matchesSearch("low battery")
                        label: "Low Battery"
                        description: "Low battery warning threshold (%)"

                        NumberInput {
                            value: ConfigService.batteryLow
                            min: 5
                            max: 50
                            step: 5
                            onValueModified: (v) => {
                                ConfigService.setValue("battery.low", v)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("critical battery")
                        label: "Critical Battery"
                        description: "Critical battery threshold (%)"

                        NumberInput {
                            value: ConfigService.batteryCritical
                            min: 5
                            max: 20
                            step: 5
                            onValueModified: (v) => {
                                ConfigService.setValue("battery.critical", v)
                                ConfigService.saveConfig()
                            }
                        }
                    }
                }

                // Animations Section
                SettingsSection {
                    visible: contentColumn.matchesSearch("animation") || contentColumn.matchesSearch("duration")
                    title: "Animations"

                    SettingRow {
                        visible: contentColumn.matchesSearch("animation duration")
                        label: "Animation Duration"
                        description: "Small animation duration (ms)"

                        NumberInput {
                            value: ConfigService.animationDuration
                            min: 100
                            max: 1000
                            step: 50
                            onValueModified: (v) => {
                                ConfigService.setValue("animations.durationSmall", v)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("choreography delay")
                        label: "Choreography Delay"
                        description: "Delay between animations (ms)"

                        NumberInput {
                            value: ConfigService.getValue("animations.choreographyDelay") ?? 20
                            min: 0
                            max: 100
                            step: 10
                            onValueModified: (v) => {
                                ConfigService.setValue("animations.choreographyDelay", v)
                                ConfigService.saveConfig()
                            }
                        }
                    }
                }

                // Windows & Components Section
                SettingsSection {
                    visible: contentColumn.matchesSearch("window") || contentColumn.matchesSearch("component") || contentColumn.matchesSearch("bar") || contentColumn.matchesSearch("sidebar") || contentColumn.matchesSearch("launcher")
                    title: "Windows & Components"

                    SettingRow {
                        visible: contentColumn.matchesSearch("top bar")
                        label: "Top Bar"
                        description: "Enable the top status bar"

                        ToggleSwitch {
                            checked: ConfigService.getValue("windows.bar.enabled") ?? true
                            onToggled: (value) => {
                                ConfigService.setValue("windows.bar.enabled", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("bar corners")
                        label: "Bar Corners"
                        description: "Enable decorative bar corners"

                        ToggleSwitch {
                            checked: ConfigService.getValue("windows.bar.corners") ?? true
                            onToggled: (value) => {
                                ConfigService.setValue("windows.bar.corners", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("launcher")
                        label: "Launcher"
                        description: "Enable application launcher"

                        ToggleSwitch {
                            checked: ConfigService.getValue("windows.launcher.enabled") ?? true
                            onToggled: (value) => {
                                ConfigService.setValue("windows.launcher.enabled", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("left sidebar")
                        label: "Left Sidebar"
                        description: "Enable left sidebar panel"

                        ToggleSwitch {
                            checked: ConfigService.getValue("windows.sidebar.leftEnabled") ?? true
                            onToggled: (value) => {
                                ConfigService.setValue("windows.sidebar.leftEnabled", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("right sidebar")
                        label: "Right Sidebar"
                        description: "Enable right sidebar panel"

                        ToggleSwitch {
                            checked: ConfigService.getValue("windows.sidebar.rightEnabled") ?? true
                            onToggled: (value) => {
                                ConfigService.setValue("windows.sidebar.rightEnabled", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("notifications")
                        label: "Notifications"
                        description: "Show notification popups"

                        ToggleSwitch {
                            checked: ConfigService.getValue("windows.overlays.notifications") ?? true
                            onToggled: (value) => {
                                ConfigService.setValue("windows.overlays.notifications", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    // Restart notice
                    Rectangle {
                        width: parent.width
                        height: restartContent.height + 24
                        radius: 8
                        color: Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.1)
                        border.width: 1
                        border.color: Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.2)

                        Column {
                            id: restartContent
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: "Note: Window changes require a restart to take effect."
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: Colors.warning
                            }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: restartText.width + 24
                                height: 32
                                radius: 6
                                color: Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.2)
                                border.width: 1
                                border.color: Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.3)

                                Text {
                                    id: restartText
                                    anchors.centerIn: parent
                                    text: "Restart QuickShell"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: Colors.foreground
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        // Restart QuickShell
                                        restartProcess.running = true
                                    }
                                }

                                Process {
                                    id: restartProcess
                                    command: ["bash", "-c", "quickshell --reload"]
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Keyboard handler
    Keys.onEscapePressed: SettingsState.close()
}
