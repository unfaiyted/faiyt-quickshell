import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../services"
import "../../components/monitors"
import "../../components/requirements"
import "components"
import "../common"

Rectangle {
    id: settingsPanel

    property string searchQuery: ""

    // Expose scroll functions for keyboard navigation
    function scrollUp() { settingsFlickable.scrollUp() }
    function scrollDown() { settingsFlickable.scrollDown() }
    function scrollPageUp() { settingsFlickable.scrollPageUp() }
    function scrollPageDown() { settingsFlickable.scrollPageDown() }
    function scrollToTop() { settingsFlickable.scrollToTop() }
    function scrollToBottom() { settingsFlickable.scrollToBottom() }

    // Expose dropdown overlay for child components to find
    property alias dropdownOverlayRef: dropdownOverlay

    width: 600
    height: parent ? parent.height * 0.75 : 500
    radius: 20
    color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.85)
    border.width: 1
    border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)
    clip: true

    // Dropdown overlay for all dropdowns in this panel
    DropdownOverlay {
        id: dropdownOverlay
        anchors.fill: parent
        z: 1000
    }

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
                        font.family: Fonts.ui
                        font.pixelSize: Fonts.xlarge
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
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.medium
                            color: Colors.foregroundAlt
                        }

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SettingsState.close()
                        }

                        HintTarget {
                            targetElement: parent
                            scope: "settings"
                            action: () => {
                                HintNavigationService.deactivate()
                                SettingsState.close()
                            }
                        }
                    }
                }

                // Search box
                Rectangle {
                    id: searchBox
                    width: parent.width
                    height: 40
                    radius: 12
                    color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                    border.width: 1
                    border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

                    HintTarget {
                        targetElement: searchBox
                        scope: "settings"
                        action: () => searchInput.forceActiveFocus()
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "󰍉"
                            font.family: Fonts.icon
                            font.pixelSize: Fonts.iconMedium
                            color: Colors.foregroundAlt
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextInput {
                            id: searchInput
                            width: parent.width - 30
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.medium
                            color: Colors.foreground
                            selectByMouse: true
                            clip: true

                            onTextChanged: settingsPanel.searchQuery = text.toLowerCase()

                            // Handle scrolling keys while keeping focus
                            Keys.onPressed: function(event) {
                                // Ctrl+Space activates hint navigation
                                if (event.key === Qt.Key_Space && (event.modifiers & Qt.ControlModifier)) {
                                    HintNavigationService.activate()
                                    event.accepted = true
                                    return
                                }

                                if (event.key === Qt.Key_Up) {
                                    settingsFlickable.scrollUp()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Down) {
                                    settingsFlickable.scrollDown()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_PageUp) {
                                    settingsFlickable.scrollPageUp()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_PageDown) {
                                    settingsFlickable.scrollPageDown()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Escape) {
                                    if (searchInput.text.length > 0) {
                                        searchInput.text = ""
                                        event.accepted = true
                                    } else {
                                        SettingsState.close()
                                        event.accepted = true
                                    }
                                }
                            }

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Search settings..."
                                font.family: Fonts.ui
                                font.pixelSize: Fonts.medium
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
            id: settingsFlickable
            width: parent.width
            height: parent.height - headerContent.height - 48
            contentHeight: contentColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            // Scroll functions for keyboard navigation
            function scrollUp() {
                scrollAnim.to = Math.max(0, contentY - 100)
                scrollAnim.restart()
            }
            function scrollDown() {
                scrollAnim.to = Math.min(contentHeight - height, contentY + 100)
                scrollAnim.restart()
            }
            function scrollPageUp() {
                scrollAnim.to = Math.max(0, contentY - height * 0.8)
                scrollAnim.restart()
            }
            function scrollPageDown() {
                scrollAnim.to = Math.min(contentHeight - height, contentY + height * 0.8)
                scrollAnim.restart()
            }
            function scrollToTop() {
                scrollAnim.to = 0
                scrollAnim.restart()
            }
            function scrollToBottom() {
                scrollAnim.to = contentHeight - height
                scrollAnim.restart()
            }

            Behavior on contentY {
                id: scrollBehavior
                enabled: false
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            NumberAnimation {
                id: scrollAnim
                target: settingsFlickable
                property: "contentY"
                duration: 150
                easing.type: Easing.OutCubic
            }

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

                // ═══════════════════════════════════════════════════════════════
                // SECTION 1: GENERAL SETTINGS
                // ═══════════════════════════════════════════════════════════════
                SettingsSection {
                    visible: contentColumn.matchesSearch("general") ||
                             contentColumn.matchesSearch("theme") ||
                             contentColumn.matchesSearch("display") ||
                             contentColumn.matchesSearch("animation") ||
                             contentColumn.matchesSearch("requirements") ||
                             contentColumn.matchesSearch("dependencies")
                    title: "General"

                    ThemeSelector {
                        visible: contentColumn.matchesSearch("theme")
                    }

                    // Display Settings button
                    SettingRow {
                        visible: contentColumn.matchesSearch("display") || contentColumn.matchesSearch("monitor")
                        label: "Display Settings"
                        description: "Configure monitor layout and resolution"

                        Rectangle {
                            width: displayBtnText.width + 24
                            height: 32
                            radius: 8
                            color: displayBtnArea.containsMouse
                                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2)
                                : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                            border.width: 1
                            border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "󰍹"
                                    font.family: Fonts.icon
                                    font.pixelSize: 14
                                    color: Colors.foreground
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    id: displayBtnText
                                    text: "Open Display Settings"
                                    font.family: Fonts.ui
                                    font.pixelSize: Fonts.small
                                    color: Colors.foreground
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: displayBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    SettingsState.close()
                                    MonitorsState.openedFromSettings = true
                                    MonitorsState.open()
                                }
                            }

                            HintTarget {
                                targetElement: parent
                                scope: "settings"
                                action: () => {
                                    HintNavigationService.deactivate()
                                    SettingsState.close()
                                    MonitorsState.openedFromSettings = true
                                    MonitorsState.open()
                                }
                            }
                        }
                    }

                    // System Requirements button
                    SettingRow {
                        visible: contentColumn.matchesSearch("requirements") || contentColumn.matchesSearch("dependencies")
                        label: "System Requirements"
                        description: "Check installed dependencies and tools"

                        Rectangle {
                            width: reqBtnText.width + 24
                            height: 32
                            radius: 8
                            color: reqBtnArea.containsMouse
                                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2)
                                : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                            border.width: 1
                            border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: ""
                                    font.family: Fonts.icon
                                    font.pixelSize: 14
                                    color: RequirementsService.hasMissingRequired
                                        ? Colors.error
                                        : (RequirementsService.hasMissingOptional ? Colors.warning : Colors.foreground)
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    id: reqBtnText
                                    text: "View Requirements"
                                    font.family: Fonts.ui
                                    font.pixelSize: Fonts.small
                                    color: Colors.foreground
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: reqBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    SettingsState.close()
                                    RequirementsState.open()
                                }
                            }

                            HintTarget {
                                targetElement: parent
                                scope: "settings"
                                action: () => {
                                    HintNavigationService.deactivate()
                                    SettingsState.close()
                                    RequirementsState.open()
                                }
                            }
                        }
                    }

                    // Animations subsection
                    CollapsibleSection {
                        visible: contentColumn.matchesSearch("animation") || contentColumn.matchesSearch("duration")
                        title: "Animations"
                        icon: "󰑮"

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
                }

                // ═══════════════════════════════════════════════════════════════
                // SECTION 2: TOP BAR
                // ═══════════════════════════════════════════════════════════════
                SettingsSection {
                    visible: contentColumn.matchesSearch("bar") ||
                             contentColumn.matchesSearch("top bar") ||
                             contentColumn.matchesSearch("module") ||
                             contentColumn.matchesSearch("clock") ||
                             contentColumn.matchesSearch("weather") ||
                             contentColumn.matchesSearch("battery") ||
                             contentColumn.matchesSearch("workspace") ||
                             contentColumn.matchesSearch("utility") ||
                             contentColumn.matchesSearch("resource") ||
                             contentColumn.matchesSearch("recording") ||
                             contentColumn.matchesSearch("screenshot")
                    title: "Top Bar"

                    // Main bar settings
                    SettingRow {
                        visible: contentColumn.matchesSearch("enable") || contentColumn.matchesSearch("top bar")
                        label: "Enable Top Bar"
                        description: "Show the top status bar"

                        ToggleSwitch {
                            checked: ConfigService.getValue("windows.bar.enabled") ?? true
                            onToggled: (value) => {
                                ConfigService.setValue("windows.bar.enabled", value)
                                ConfigService.saveConfig()
                            }
                        }
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
                        visible: contentColumn.matchesSearch("workspaces") || contentColumn.matchesSearch("per page")
                        label: "Workspaces Per Page"
                        description: "Number of workspaces shown at once"

                        NumberInput {
                            value: ConfigService.workspacesPerPage
                            min: 3
                            max: 20
                            step: 1
                            onValueModified: (v) => {
                                ConfigService.setValue("bar.workspacesPerPage", v)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    // Bar Modules subsection
                    CollapsibleSection {
                        visible: contentColumn.matchesSearch("module") ||
                                 contentColumn.matchesSearch("distro") ||
                                 contentColumn.matchesSearch("window title") ||
                                 contentColumn.matchesSearch("workspaces") ||
                                 contentColumn.matchesSearch("mic") ||
                                 contentColumn.matchesSearch("music") ||
                                 contentColumn.matchesSearch("tray") ||
                                 contentColumn.matchesSearch("network") ||
                                 contentColumn.matchesSearch("battery") ||
                                 contentColumn.matchesSearch("clock") ||
                                 contentColumn.matchesSearch("weather")
                        title: "Bar Modules"
                        icon: "󰕰"

                        SettingRow {
                            visible: contentColumn.matchesSearch("distro") || contentColumn.matchesSearch("icon")
                            label: "Distro Icon"
                            description: "Show distribution icon"

                            ToggleSwitch {
                                checked: ConfigService.barModuleDistroIcon
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.modules.distroIcon", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("window title")
                            label: "Window Title"
                            description: "Show active window title"

                            ToggleSwitch {
                                checked: ConfigService.barModuleWindowTitle
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.modules.windowTitle", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("workspaces")
                            label: "Workspaces"
                            description: "Show workspace indicators"

                            ToggleSwitch {
                                checked: ConfigService.barModuleWorkspaces
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.modules.workspaces", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("mic") || contentColumn.matchesSearch("microphone") || contentColumn.matchesSearch("mute")
                            label: "Mic Mute Indicator"
                            description: "Show indicator when microphone is muted"

                            ToggleSwitch {
                                checked: ConfigService.barModuleMicIndicator
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.modules.micIndicator", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("system resources")
                            label: "System Resources"
                            description: "Show CPU and memory usage"

                            ToggleSwitch {
                                checked: ConfigService.barModuleSystemResources
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.modules.systemResources", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("utilities")
                            label: "Utilities"
                            description: "Show utility buttons section"

                            ToggleSwitch {
                                checked: ConfigService.barModuleUtilities
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.modules.utilities", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("music")
                            label: "Music"
                            description: "Show music controls"

                            ToggleSwitch {
                                checked: ConfigService.barModuleMusic
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.modules.music", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("system tray")
                            label: "System Tray"
                            description: "Show system tray icons"

                            ToggleSwitch {
                                checked: ConfigService.barModuleSystemTray
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.modules.systemTray", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("network")
                            label: "Network"
                            description: "Show network status"

                            ToggleSwitch {
                                checked: ConfigService.barModuleNetwork
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.modules.network", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("battery")
                            label: "Battery"
                            description: "Show battery status"

                            ToggleSwitch {
                                checked: ConfigService.barModuleBattery
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.modules.battery", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("clock")
                            label: "Clock"
                            description: "Show time display"

                            ToggleSwitch {
                                checked: ConfigService.barModuleClock
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.modules.clock", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("weather")
                            label: "Weather"
                            description: "Show weather information"

                            ToggleSwitch {
                                checked: ConfigService.barModuleWeather
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.modules.weather", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }
                    }

                    // Utility Buttons subsection
                    CollapsibleSection {
                        visible: ConfigService.barModuleUtilities && (
                            contentColumn.matchesSearch("utility button") ||
                            contentColumn.matchesSearch("screenshot") ||
                            contentColumn.matchesSearch("recording") ||
                            contentColumn.matchesSearch("color picker") ||
                            contentColumn.matchesSearch("wallpaper"))
                        title: "Utility Buttons"
                        icon: "󰨇"

                        SettingRow {
                            visible: contentColumn.matchesSearch("screenshot")
                            label: "Screenshot"
                            description: "Show screenshot button"

                            ToggleSwitch {
                                checked: ConfigService.barUtilityScreenshot
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.utilities.screenshot", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("recording")
                            label: "Recording"
                            description: "Show screen recording button"

                            ToggleSwitch {
                                checked: ConfigService.barUtilityRecording
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.utilities.recording", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("color picker")
                            label: "Color Picker"
                            description: "Show color picker button"

                            ToggleSwitch {
                                checked: ConfigService.barUtilityColorPicker
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.utilities.colorPicker", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("wallpaper")
                            label: "Wallpaper"
                            description: "Show wallpaper button"

                            ToggleSwitch {
                                checked: ConfigService.barUtilityWallpaper
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.utilities.wallpaper", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }
                    }

                    // System Resources Display subsection
                    CollapsibleSection {
                        visible: ConfigService.barModuleSystemResources && (
                            contentColumn.matchesSearch("resource") ||
                            contentColumn.matchesSearch("ram") ||
                            contentColumn.matchesSearch("swap") ||
                            contentColumn.matchesSearch("cpu") ||
                            contentColumn.matchesSearch("download") ||
                            contentColumn.matchesSearch("upload") ||
                            contentColumn.matchesSearch("gpu") ||
                            contentColumn.matchesSearch("temp") ||
                            contentColumn.matchesSearch("thermal"))
                        title: "System Resources Display"
                        icon: "󰍛"

                        SettingRow {
                            visible: contentColumn.matchesSearch("ram") || contentColumn.matchesSearch("memory")
                            label: "RAM"
                            description: "Show memory usage indicator"

                            ToggleSwitch {
                                checked: ConfigService.barResourceRam
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.systemResources.ram", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("swap")
                            label: "Swap"
                            description: "Show swap usage indicator"

                            ToggleSwitch {
                                checked: ConfigService.barResourceSwap
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.systemResources.swap", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("cpu") || contentColumn.matchesSearch("processor")
                            label: "CPU"
                            description: "Show CPU usage indicator"

                            ToggleSwitch {
                                checked: ConfigService.barResourceCpu
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.systemResources.cpu", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("download") || contentColumn.matchesSearch("network")
                            label: "Download"
                            description: "Show network download indicator"

                            ToggleSwitch {
                                checked: ConfigService.barResourceDownload
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.systemResources.download", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("upload") || contentColumn.matchesSearch("network")
                            label: "Upload"
                            description: "Show network upload indicator"

                            ToggleSwitch {
                                checked: ConfigService.barResourceUpload
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.systemResources.upload", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("gpu") || contentColumn.matchesSearch("graphics")
                            label: "GPU Usage"
                            description: "Show GPU utilization (NVIDIA)"

                            ToggleSwitch {
                                checked: ConfigService.barResourceGpu
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.systemResources.gpu", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("gpu") || contentColumn.matchesSearch("temp")
                            label: "GPU Temperature"
                            description: "Show GPU temperature (NVIDIA)"

                            ToggleSwitch {
                                checked: ConfigService.barResourceGpuTemp
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.systemResources.gpuTemp", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("cpu") || contentColumn.matchesSearch("temp") || contentColumn.matchesSearch("thermal")
                            label: "CPU Temperature"
                            description: "Show CPU temperature"

                            ToggleSwitch {
                                checked: ConfigService.barResourceCpuTemp
                                onToggled: (value) => {
                                    ConfigService.setValue("bar.systemResources.cpuTemp", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }
                    }

                    // Clock & Weather subsection
                    CollapsibleSection {
                        visible: contentColumn.matchesSearch("time") ||
                                 contentColumn.matchesSearch("clock") ||
                                 contentColumn.matchesSearch("weather") ||
                                 contentColumn.matchesSearch("temperature") ||
                                 contentColumn.matchesSearch("timezone")
                        title: "Clock & Weather"
                        icon: "󰥔"

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

                        SettingRow {
                            visible: contentColumn.matchesSearch("timezone") || contentColumn.matchesSearch("world clock")
                            label: "World Clock Timezones"
                            description: "Additional timezones to display"

                            Column {
                                spacing: 8

                                // List of configured timezones
                                Repeater {
                                    model: ConfigService.timezones

                                    Rectangle {
                                        width: 240
                                        height: 36
                                        radius: 8
                                        color: Colors.surface
                                        border.width: 1
                                        border.color: Colors.border

                                        Row {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 8

                                            Text {
                                                text: "󰗶"
                                                font.family: Fonts.icon
                                                font.pixelSize: 14
                                                color: Colors.foam
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Text {
                                                text: modelData.label + " (" + modelData.id + ")"
                                                font.pixelSize: 12
                                                color: Colors.foreground
                                                width: parent.width - 50
                                                elide: Text.ElideRight
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Rectangle {
                                                width: 20
                                                height: 20
                                                radius: 4
                                                color: tzRemoveArea.containsMouse ? Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.2) : "transparent"
                                                anchors.verticalCenter: parent.verticalCenter

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "✕"
                                                    font.pixelSize: 10
                                                    color: tzRemoveArea.containsMouse ? Colors.error : Colors.foregroundMuted
                                                }

                                                MouseArea {
                                                    id: tzRemoveArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        let tzs = ConfigService.timezones.filter((_, i) => i !== index)
                                                        ConfigService.setValue("time.timezones", tzs)
                                                        ConfigService.saveConfig()
                                                    }
                                                }

                                                HintTarget {
                                                    targetElement: parent
                                                    scope: "settings"
                                                    action: () => {
                                                        let tzs = ConfigService.timezones.filter((_, i) => i !== index)
                                                        ConfigService.setValue("time.timezones", tzs)
                                                        ConfigService.saveConfig()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Add timezone row
                                Row {
                                    spacing: 8

                                    Rectangle {
                                        width: 130
                                        height: 32
                                        radius: 6
                                        color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                                        border.width: 1
                                        border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

                                        TextInput {
                                            id: newTimezoneId
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 12
                                            color: Colors.foreground
                                            clip: true

                                            Text {
                                                anchors.fill: parent
                                                verticalAlignment: Text.AlignVCenter
                                                text: "America/New_York"
                                                font.pixelSize: 12
                                                color: Colors.foregroundMuted
                                                visible: newTimezoneId.text.length === 0
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 80
                                        height: 32
                                        radius: 6
                                        color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                                        border.width: 1
                                        border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

                                        TextInput {
                                            id: newTimezoneLabel
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 12
                                            color: Colors.foreground
                                            clip: true

                                            Text {
                                                anchors.fill: parent
                                                verticalAlignment: Text.AlignVCenter
                                                text: "New York"
                                                font.pixelSize: 12
                                                color: Colors.foregroundMuted
                                                visible: newTimezoneLabel.text.length === 0
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 6
                                        color: addTzArea.containsMouse ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2) : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                                        border.width: 1
                                        border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰐕"
                                            font.family: Fonts.icon
                                            font.pixelSize: 14
                                            color: Colors.primary
                                        }

                                        MouseArea {
                                            id: addTzArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (newTimezoneId.text && newTimezoneLabel.text) {
                                                    let tzs = ConfigService.timezones.slice()
                                                    tzs.push({id: newTimezoneId.text, label: newTimezoneLabel.text})
                                                    ConfigService.setValue("time.timezones", tzs)
                                                    ConfigService.saveConfig()
                                                    newTimezoneId.text = ""
                                                    newTimezoneLabel.text = ""
                                                }
                                            }
                                        }

                                        HintTarget {
                                            targetElement: parent
                                            scope: "settings"
                                            action: () => {
                                                if (newTimezoneId.text && newTimezoneLabel.text) {
                                                    let tzs = ConfigService.timezones.slice()
                                                    tzs.push({id: newTimezoneId.text, label: newTimezoneLabel.text})
                                                    ConfigService.setValue("time.timezones", tzs)
                                                    ConfigService.saveConfig()
                                                    newTimezoneId.text = ""
                                                    newTimezoneLabel.text = ""
                                                }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: "Use IANA timezone IDs (e.g., Europe/London)"
                                    font.family: Fonts.ui
                                    font.pixelSize: Fonts.small
                                    font.italic: true
                                    color: Colors.foregroundMuted
                                }
                            }
                        }
                    }

                    // Capture Defaults subsection
                    CollapsibleSection {
                        visible: contentColumn.matchesSearch("recording") ||
                                 contentColumn.matchesSearch("screenshot") ||
                                 contentColumn.matchesSearch("capture") ||
                                 contentColumn.matchesSearch("annotate")
                        title: "Capture Defaults"
                        icon: "󰄀"

                        SettingRow {
                            visible: contentColumn.matchesSearch("recording mode")
                            label: "Recording Mode"
                            description: "Default mode when starting a recording"

                            DropdownSelect {
                                model: [
                                    {label: "Standard", value: "record"},
                                    {label: "High Quality", value: "record-hq"},
                                    {label: "GIF", value: "record-gif"}
                                ]
                                currentIndex: {
                                    const mode = ConfigService.recordingDefaultMode
                                    if (mode === "record-hq") return 1
                                    if (mode === "record-gif") return 2
                                    return 0
                                }
                                onSelected: (index, value) => {
                                    ConfigService.setValue("utilities.recording.defaultMode", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("screenshot mode") || contentColumn.matchesSearch("annotate")
                            label: "Screenshot Mode"
                            description: "Default screenshot behavior"

                            DropdownSelect {
                                model: [
                                    {label: "Screenshot", value: false},
                                    {label: "Annotate", value: true}
                                ]
                                currentIndex: ConfigService.screenshotAnnotateEnabled ? 1 : 0
                                onSelected: (index, value) => {
                                    ConfigService.setValue("utilities.screenshot.annotateEnabled", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("screenshot path") ||
                                     contentColumn.matchesSearch("screenshot save") ||
                                     contentColumn.matchesSearch("screenshot directory") ||
                                     contentColumn.matchesSearch("screenshot folder") ||
                                     contentColumn.matchesSearch("screenshot location")
                            label: "Screenshot Save Path"
                            description: "Leave empty for ~/Pictures/Screenshots"

                            SettingsTextInput {
                                text: ConfigService.screenshotSavePath
                                placeholder: "~/Pictures/Screenshots"
                                onTextEdited: (value) => {
                                    ConfigService.setValue("utilities.screenshot.savePath", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("recording path") ||
                                     contentColumn.matchesSearch("recording save") ||
                                     contentColumn.matchesSearch("recording directory") ||
                                     contentColumn.matchesSearch("recording folder") ||
                                     contentColumn.matchesSearch("recording location") ||
                                     contentColumn.matchesSearch("video path") ||
                                     contentColumn.matchesSearch("video save")
                            label: "Recording Save Path"
                            description: "Leave empty for ~/Videos/Recordings"

                            SettingsTextInput {
                                text: ConfigService.recordingSavePath
                                placeholder: "~/Videos/Recordings"
                                onTextEdited: (value) => {
                                    ConfigService.setValue("utilities.recording.savePath", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }
                    }

                    // Battery subsection
                    CollapsibleSection {
                        visible: contentColumn.matchesSearch("battery") || contentColumn.matchesSearch("power")
                        title: "Battery Thresholds"
                        icon: "󰁹"

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

                }

                // ═══════════════════════════════════════════════════════════════
                // SECTION 3: SIDEBARS
                // ═══════════════════════════════════════════════════════════════
                SettingsSection {
                    visible: contentColumn.matchesSearch("sidebar") ||
                             contentColumn.matchesSearch("quick toggle") ||
                             contentColumn.matchesSearch("focus mode") ||
                             contentColumn.matchesSearch("power saver") ||
                             contentColumn.matchesSearch("vpn") ||
                             contentColumn.matchesSearch("night light")
                    title: "Sidebars"

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

                    // Quick Toggles subsection
                    CollapsibleSection {
                        visible: contentColumn.matchesSearch("quick toggle") ||
                                 contentColumn.matchesSearch("focus mode") ||
                                 contentColumn.matchesSearch("power saver") ||
                                 contentColumn.matchesSearch("vpn") ||
                                 contentColumn.matchesSearch("night light")
                        title: "Quick Toggles"
                        icon: "󰔡"

                        SettingRow {
                            visible: contentColumn.matchesSearch("focus mode")
                            label: "Focus Mode"
                            description: "Show Focus Mode toggle (DND + minimal bar)"

                            ToggleSwitch {
                                checked: ConfigService.quickToggleFocusMode
                                onToggled: (value) => {
                                    ConfigService.setValue("sidebar.quickToggles.showFocusMode", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("power saver")
                            label: "Power Saver"
                            description: "Show Power Saver toggle"

                            ToggleSwitch {
                                checked: ConfigService.quickTogglePowerSaver
                                onToggled: (value) => {
                                    ConfigService.setValue("sidebar.quickToggles.showPowerSaver", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("vpn") || contentColumn.matchesSearch("wireguard")
                            label: "VPN Type"
                            description: "VPN management method"

                            DropdownSelect {
                                model: [
                                    {label: "Auto (detect)", value: "auto"},
                                    {label: "NetworkManager", value: "nmcli"},
                                    {label: "WireGuard (wg-quick)", value: "wg-quick"}
                                ]
                                currentIndex: {
                                    const t = ConfigService.quickToggleVpnType
                                    if (t === "nmcli") return 1
                                    if (t === "wg-quick") return 2
                                    return 0
                                }
                                onSelected: (index, value) => {
                                    ConfigService.setValue("sidebar.quickToggles.vpnType", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: (contentColumn.matchesSearch("vpn") || contentColumn.matchesSearch("networkmanager")) &&
                                     ConfigService.quickToggleVpnType !== "wg-quick"
                            label: "VPN Connection Name"
                            description: "NetworkManager VPN connection name"

                            SettingsTextInput {
                                text: ConfigService.quickToggleVpnName
                                placeholder: "my-vpn"
                                onTextEdited: (value) => {
                                    ConfigService.setValue("sidebar.quickToggles.vpnConnectionName", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: (contentColumn.matchesSearch("vpn") || contentColumn.matchesSearch("wireguard") || contentColumn.matchesSearch("wg0")) &&
                                     ConfigService.quickToggleVpnType !== "nmcli"
                            label: "WireGuard Interface"
                            description: "Interface name for wg-quick (e.g., wg0)"

                            SettingsTextInput {
                                text: ConfigService.quickToggleVpnInterface
                                placeholder: "wg0"
                                onTextEdited: (value) => {
                                    ConfigService.setValue("sidebar.quickToggles.vpnInterface", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("night light") || contentColumn.matchesSearch("temperature")
                            label: "Night Light Temperature"
                            description: "Color temperature in Kelvin (lower = warmer)"

                            NumberInput {
                                value: ConfigService.quickToggleNightTemp
                                min: 2500
                                max: 6500
                                step: 500
                                onValueModified: (v) => {
                                    ConfigService.setValue("sidebar.quickToggles.nightLightTemp", v)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        // Auto Night Mode subsection
                        CollapsibleSection {
                            visible: contentColumn.matchesSearch("night light") ||
                                     contentColumn.matchesSearch("auto") ||
                                     contentColumn.matchesSearch("schedule")
                            title: "Auto Night Mode"
                            icon: "󰔄"

                            SettingRow {
                                visible: contentColumn.matchesSearch("night light") ||
                                         contentColumn.matchesSearch("auto") ||
                                         contentColumn.matchesSearch("schedule")
                                label: "Enable Auto Mode"
                                description: "Automatically enable night light on schedule"

                                ToggleSwitch {
                                    checked: ConfigService.nightLightAutoEnabled
                                    onToggled: (value) => {
                                        ConfigService.setValue("sidebar.quickToggles.nightLight.autoEnabled", value)
                                        ConfigService.saveConfig()
                                    }
                                }
                            }

                            SettingRow {
                                visible: ConfigService.nightLightAutoEnabled && (
                                         contentColumn.matchesSearch("night light") ||
                                         contentColumn.matchesSearch("start") ||
                                         contentColumn.matchesSearch("schedule"))
                                label: "Start Time"
                                description: "When to enable night light (24h format)"

                                SettingsTextInput {
                                    text: ConfigService.nightLightStartTime
                                    placeholder: "20:00"
                                    onTextEdited: (value) => {
                                        // Validate 24h time format
                                        if (/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/.test(value)) {
                                            ConfigService.setValue("sidebar.quickToggles.nightLight.startTime", value)
                                            ConfigService.saveConfig()
                                        }
                                    }
                                }
                            }

                            SettingRow {
                                visible: ConfigService.nightLightAutoEnabled && (
                                         contentColumn.matchesSearch("night light") ||
                                         contentColumn.matchesSearch("end") ||
                                         contentColumn.matchesSearch("schedule"))
                                label: "End Time"
                                description: "When to disable night light (24h format)"

                                SettingsTextInput {
                                    text: ConfigService.nightLightEndTime
                                    placeholder: "06:00"
                                    onTextEdited: (value) => {
                                        // Validate 24h time format
                                        if (/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/.test(value)) {
                                            ConfigService.setValue("sidebar.quickToggles.nightLight.endTime", value)
                                            ConfigService.saveConfig()
                                        }
                                    }
                                }
                            }

                            // Status indicator
                            SettingRow {
                                visible: ConfigService.nightLightAutoEnabled
                                label: "Current Status"
                                description: NightLightService.isInWindow ? "Currently in scheduled window" : "Outside scheduled window"

                                Rectangle {
                                    width: statusText.width + 16
                                    height: 24
                                    radius: 6
                                    color: NightLightService.isInWindow
                                        ? Qt.rgba(Colors.gold.r, Colors.gold.g, Colors.gold.b, 0.15)
                                        : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                                    border.width: 1
                                    border.color: NightLightService.isInWindow
                                        ? Qt.rgba(Colors.gold.r, Colors.gold.g, Colors.gold.b, 0.3)
                                        : Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)

                                    Text {
                                        id: statusText
                                        anchors.centerIn: parent
                                        text: NightLightService.isInWindow ? "󱩌 Active" : "󰖨 Inactive"
                                        font.family: Fonts.icon
                                        font.pixelSize: Fonts.small
                                        color: NightLightService.isInWindow ? Colors.gold : Colors.foregroundMuted
                                    }
                                }
                            }
                        }
                    }
                }

                // ═══════════════════════════════════════════════════════════════
                // SECTION 4: OVERVIEW
                // ═══════════════════════════════════════════════════════════════
                SettingsSection {
                    visible: contentColumn.matchesSearch("overview") ||
                             contentColumn.matchesSearch("items per row") ||
                             contentColumn.matchesSearch("total items") ||
                             contentColumn.matchesSearch("grid")
                    title: "Overview"

                    SettingRow {
                        visible: contentColumn.matchesSearch("items per row") || contentColumn.matchesSearch("columns")
                        label: "Items Per Row"
                        description: "Number of workspaces shown per row"

                        NumberInput {
                            value: ConfigService.overviewItemsPerRow
                            min: 2
                            max: 10
                            step: 1
                            onValueModified: (v) => {
                                ConfigService.setValue("overview.itemsPerRow", v)
                                ConfigService.saveConfig()
                            }
                        }
                    }

                    SettingRow {
                        visible: contentColumn.matchesSearch("total items") || contentColumn.matchesSearch("workspaces")
                        label: "Total Items"
                        description: "Total number of workspaces shown in overview"

                        NumberInput {
                            value: ConfigService.overviewTotalItems
                            min: 4
                            max: 20
                            step: 1
                            onValueModified: (v) => {
                                ConfigService.setValue("overview.totalItems", v)
                                ConfigService.saveConfig()
                            }
                        }
                    }
                }

                // ═══════════════════════════════════════════════════════════════
                // SECTION 5: LAUNCHER
                // ═══════════════════════════════════════════════════════════════
                SettingsSection {
                    id: launcherSection
                    visible: contentColumn.matchesSearch("launcher") ||
                             contentColumn.matchesSearch("search") ||
                             contentColumn.matchesSearch("evaluator") ||
                             contentColumn.matchesSearch("sticker") ||
                             contentColumn.matchesSearch("gif") ||
                             contentColumn.matchesSearch("tmux")
                    title: "Launcher"

                    // Check for API key
                    property string tenorApiKey: Quickshell.env("TENOR_API_KEY") || ""
                    property bool hasTenorKey: tenorApiKey.length > 0

                    SettingRow {
                        visible: contentColumn.matchesSearch("launcher") || contentColumn.matchesSearch("enable")
                        label: "Enable Launcher"
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

                    // Search Features subsection
                    CollapsibleSection {
                        visible: contentColumn.matchesSearch("search") ||
                                 contentColumn.matchesSearch("actions") ||
                                 contentColumn.matchesSearch("commands") ||
                                 contentColumn.matchesSearch("math") ||
                                 contentColumn.matchesSearch("directory") ||
                                 contentColumn.matchesSearch("sticker") ||
                                 contentColumn.matchesSearch("gif") ||
                                 contentColumn.matchesSearch("tmux")
                        title: "Search Features"
                        icon: "󰍉"

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

                        SettingRow {
                            visible: contentColumn.matchesSearch("sticker") || contentColumn.matchesSearch("enable")
                            label: "Stickers"
                            description: "Enable Signal sticker picker in launcher"

                            ToggleSwitch {
                                checked: ConfigService.stickersEnabled
                                onToggled: (value) => {
                                    ConfigService.setValue("stickers.enabled", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("gif") || contentColumn.matchesSearch("enable")
                            label: "GIF Search"
                            description: "Search and copy GIFs using gif: prefix"

                            ToggleSwitch {
                                checked: ConfigService.getValue("search.enableFeatures.gifSearch") ?? true
                                onToggled: (value) => {
                                    ConfigService.setValue("search.enableFeatures.gifSearch", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("gif") || contentColumn.matchesSearch("tenor") || contentColumn.matchesSearch("api key")
                            label: "Tenor API Key"
                            description: launcherSection.hasTenorKey ? "API key configured" : "Set TENOR_API_KEY env variable"

                            Row {
                                spacing: 8

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 6
                                    color: launcherSection.hasTenorKey
                                        ? Qt.rgba(Colors.foam.r, Colors.foam.g, Colors.foam.b, 0.15)
                                        : Qt.rgba(Colors.gold.r, Colors.gold.g, Colors.gold.b, 0.15)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: launcherSection.hasTenorKey ? "󰄬" : "󰀦"
                                        font.family: Fonts.icon
                                        font.pixelSize: 14
                                        color: launcherSection.hasTenorKey ? Colors.foam : Colors.gold
                                    }
                                }

                                Rectangle {
                                    visible: !launcherSection.hasTenorKey
                                    width: getKeyText.width + 16
                                    height: 28
                                    radius: 6
                                    color: getKeyArea.containsMouse
                                        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2)
                                        : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                                    border.width: 1
                                    border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        id: getKeyText
                                        anchors.centerIn: parent
                                        text: "Get API Key"
                                        font.pixelSize: 12
                                        color: Colors.primary
                                    }

                                    MouseArea {
                                        id: getKeyArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.openUrlExternally("https://developers.google.com/tenor/guides/quickstart")
                                    }

                                    HintTarget {
                                        targetElement: parent
                                        scope: "settings"
                                        action: () => Qt.openUrlExternally("https://developers.google.com/tenor/guides/quickstart")
                                    }
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("tmux") || contentColumn.matchesSearch("enable")
                            label: "Tmux Search"
                            description: "Search and attach to tmux sessions"

                            ToggleSwitch {
                                checked: ConfigService.getValue("search.enableFeatures.tmuxSearch") ?? true
                                onToggled: (value) => {
                                    ConfigService.setValue("search.enableFeatures.tmuxSearch", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }
                    }

                    // Evaluators subsection
                    CollapsibleSection {
                        visible: contentColumn.matchesSearch("evaluator") ||
                                 contentColumn.matchesSearch("calculator") ||
                                 contentColumn.matchesSearch("converter")
                        title: "Evaluators"
                        icon: "󰃬"

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

                    // Sticker Packs subsection
                    CollapsibleSection {
                        visible: ConfigService.stickersEnabled && (
                            contentColumn.matchesSearch("sticker") || contentColumn.matchesSearch("pack"))
                        title: "Sticker Packs"
                        icon: "󰏫"

                        Column {
                            id: stickerPacksColumn
                            width: parent.width - (parent.leftPadding || 0) - (parent.rightPadding || 0)
                            spacing: 12

                            // Add pack function
                            function addPack() {
                                const url = stickerUrlInput.text.trim()
                                if (!url) return

                                const result = StickerService.addPackFromUrl(url)
                                if (result) {
                                    if (!result.exists) {
                                        const currentPacks = (ConfigService.config?.stickers?.packs || []).slice()
                                        if (!currentPacks.some(p => p.id === result.id)) {
                                            currentPacks.push({ id: result.id, key: result.key, name: result.name })
                                            ConfigService.setValue("stickers.packs", currentPacks)
                                            ConfigService.saveConfig()
                                        }
                                    }
                                    stickerUrlInput.text = ""
                                }
                            }

                            // URL input row
                            Row {
                                width: parent.width
                                spacing: 8

                                Rectangle {
                                    width: parent.width - addPackButton.width - 8
                                    height: 36
                                    radius: 8
                                    color: Colors.surface
                                    border.width: 1
                                    border.color: stickerUrlInput.activeFocus ? Colors.primary : Colors.border

                                    TextInput {
                                        id: stickerUrlInput
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        verticalAlignment: TextInput.AlignVCenter
                                        font.pixelSize: 12
                                        color: Colors.foreground
                                        clip: true
                                        selectByMouse: true

                                        property string placeholderText: "Paste Signal sticker URL..."

                                        Text {
                                            anchors.fill: parent
                                            verticalAlignment: Text.AlignVCenter
                                            text: stickerUrlInput.placeholderText
                                            font.pixelSize: 12
                                            color: Colors.foregroundMuted
                                            visible: !stickerUrlInput.text && !stickerUrlInput.activeFocus
                                        }

                                        onAccepted: stickerPacksColumn.addPack()
                                    }
                                }

                                Rectangle {
                                    id: addPackButton
                                    width: 36
                                    height: 36
                                    radius: 8
                                    color: addPackArea.containsMouse ? Colors.primary : Colors.surface
                                    border.width: 1
                                    border.color: addPackArea.containsMouse ? Colors.primary : Colors.border

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰐕"
                                        font.family: Fonts.icon
                                        font.pixelSize: 16
                                        color: addPackArea.containsMouse ? Colors.background : Colors.foreground
                                    }

                                    MouseArea {
                                        id: addPackArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: stickerPacksColumn.addPack()
                                    }

                                    HintTarget {
                                        targetElement: parent
                                        scope: "settings"
                                        action: () => stickerPacksColumn.addPack()
                                    }
                                }
                            }

                            // Download indicator
                            Rectangle {
                                visible: StickerService.isDownloading
                                width: parent.width
                                height: 28
                                radius: 6
                                color: Qt.rgba(Colors.iris.r, Colors.iris.g, Colors.iris.b, 0.1)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        text: "󰋚"
                                        font.family: Fonts.icon
                                        font.pixelSize: 14
                                        color: Colors.iris
                                        anchors.verticalCenter: parent.verticalCenter

                                        SequentialAnimation on opacity {
                                            running: StickerService.isDownloading
                                            loops: Animation.Infinite
                                            NumberAnimation { to: 0.3; duration: 400 }
                                            NumberAnimation { to: 1; duration: 400 }
                                        }
                                    }

                                    Text {
                                        text: "Downloading stickers..."
                                        font.pixelSize: 12
                                        color: Colors.iris
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            // Pack count
                            Text {
                                text: StickerService.stickerPacks.length === 0 ? "No packs installed" :
                                      StickerService.stickerPacks.length + " pack(s) installed"
                                font.pixelSize: 12
                                color: Colors.foregroundMuted
                            }

                            // 2-column grid of sticker packs
                            Grid {
                                id: stickerPacksGrid
                                columns: 2
                                spacing: 8
                                width: parent.width
                                visible: StickerService.stickerPacks.length > 0

                                Repeater {
                                    model: StickerService.stickerPacks

                                    Rectangle {
                                        width: (stickerPacksGrid.width - stickerPacksGrid.spacing) / 2
                                        height: 40
                                        radius: 8
                                        color: Colors.surface
                                        border.width: 1
                                        border.color: Colors.border

                                        Row {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 4
                                            spacing: 6

                                            Text {
                                                text: modelData.coverEmoji || "📦"
                                                font.pixelSize: 16
                                                font.family: Fonts.emoji
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Text {
                                                text: modelData.name || "Sticker Pack"
                                                font.pixelSize: 11
                                                color: Colors.foreground
                                                elide: Text.ElideRight
                                                width: parent.width - 54
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Rectangle {
                                                width: 22
                                                height: 22
                                                radius: 4
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: packRemoveArea.containsMouse ? Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.2) : "transparent"

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "✕"
                                                    font.pixelSize: 10
                                                    color: packRemoveArea.containsMouse ? Colors.error : Colors.foregroundMuted
                                                }

                                                MouseArea {
                                                    id: packRemoveArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: StickerService.removePack(modelData.id)
                                                }

                                                HintTarget {
                                                    targetElement: parent
                                                    scope: "settings"
                                                    action: () => StickerService.removePack(modelData.id)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Help text
                            Column {
                                spacing: 2

                                Text {
                                    text: "Find packs at signalstickers.org"
                                    font.family: Fonts.ui
                                    font.pixelSize: Fonts.small
                                    font.italic: true
                                    color: Colors.foregroundMuted
                                }

                                Text {
                                    text: "Right-click 'Add to Signal' → Copy link"
                                    font.pixelSize: 10
                                    color: Colors.foregroundMuted
                                    opacity: 0.7
                                }

                                Text {
                                    text: "Or use 's: add <url>' in launcher"
                                    font.pixelSize: 10
                                    color: Colors.foregroundMuted
                                    opacity: 0.7
                                }
                            }
                        }
                    }
                }

                // ═══════════════════════════════════════════════════════════════
                // SECTION 6: NOTIFICATIONS
                // ═══════════════════════════════════════════════════════════════
                SettingsSection {
                    visible: contentColumn.matchesSearch("notification")
                    title: "Notifications"

                    SettingRow {
                        visible: contentColumn.matchesSearch("notifications")
                        label: "Enable Notifications"
                        description: "Show notification popups"

                        ToggleSwitch {
                            checked: ConfigService.getValue("windows.overlays.notifications") ?? true
                            onToggled: (value) => {
                                ConfigService.setValue("windows.overlays.notifications", value)
                                ConfigService.saveConfig()
                            }
                        }
                    }
                }

                // ═══════════════════════════════════════════════════════════════
                // SECTION 7: EXTERNAL PROGRAMS
                // ═══════════════════════════════════════════════════════════════
                SettingsSection {
                    id: externalProgramsSection
                    visible: contentColumn.matchesSearch("external") ||
                             contentColumn.matchesSearch("programs") ||
                             contentColumn.matchesSearch("terminal") ||
                             contentColumn.matchesSearch("browser") ||
                             contentColumn.matchesSearch("file manager") ||
                             contentColumn.matchesSearch("annotator") ||
                             contentColumn.matchesSearch("kitty") ||
                             contentColumn.matchesSearch("alacritty")
                    title: "External Programs"

                    // Terminal preset model with exec flags
                    property var terminalPresets: [
                        {label: "kitty (Recommended)", value: "kitty", execFlag: "-e"},
                        {label: "Alacritty", value: "alacritty", execFlag: "-e"},
                        {label: "WezTerm", value: "wezterm", execFlag: "start --"},
                        {label: "foot", value: "foot", execFlag: "--"},
                        {label: "GNOME Terminal", value: "gnome-terminal", execFlag: "--"},
                        {label: "Konsole", value: "konsole", execFlag: "-e"},
                        {label: "xterm", value: "xterm", execFlag: "-e"},
                        {label: "Custom", value: "custom", execFlag: "-e"}
                    ]

                    property var fileManagerPresets: [
                        {label: "System Default (Recommended)", value: "xdg-open"},
                        {label: "Dolphin", value: "dolphin"},
                        {label: "Nautilus", value: "nautilus"},
                        {label: "Thunar", value: "thunar"},
                        {label: "Nemo", value: "nemo"},
                        {label: "PCManFM", value: "pcmanfm"},
                        {label: "Custom", value: "custom"}
                    ]

                    property var browserPresets: [
                        {label: "System Default (Recommended)", value: "xdg-open"},
                        {label: "Firefox", value: "firefox"},
                        {label: "Chromium", value: "chromium"},
                        {label: "Brave", value: "brave"},
                        {label: "Google Chrome", value: "google-chrome-stable"},
                        {label: "Vivaldi", value: "vivaldi"},
                        {label: "Custom", value: "custom"}
                    ]

                    property var annotatorPresets: [
                        {label: "Napkin (Recommended)", value: "napkin"},
                        {label: "Swappy", value: "swappy"},
                        {label: "Satty", value: "satty"},
                        {label: "Custom", value: "custom"}
                    ]

                    // ─────────────────────────────────────────────────────────────
                    // Terminal Emulator
                    // ─────────────────────────────────────────────────────────────
                    CollapsibleSection {
                        title: "Terminal Emulator"
                        icon: "󰆍"
                        expanded: true

                        SettingRow {
                            visible: contentColumn.matchesSearch("terminal") ||
                                     contentColumn.matchesSearch("kitty") ||
                                     contentColumn.matchesSearch("alacritty")
                            label: "Terminal"
                            description: "Terminal emulator for running commands"

                            DropdownSelect {
                                id: terminalDropdown
                                model: externalProgramsSection.terminalPresets
                                currentIndex: {
                                    let current = ConfigService.getValue("externalPrograms.terminal") || "kitty"
                                    let presets = externalProgramsSection.terminalPresets
                                    for (let i = 0; i < presets.length; i++) {
                                        if (presets[i].value === current) return i
                                    }
                                    return 0
                                }
                                onSelected: (index, value) => {
                                    let presets = externalProgramsSection.terminalPresets
                                    ConfigService.setValue("externalPrograms.terminal", value)
                                    // Auto-update exec flag when preset changes
                                    if (value !== "custom") {
                                        ConfigService.setValue("externalPrograms.terminalExecFlag", presets[index].execFlag)
                                    }
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: (ConfigService.getValue("externalPrograms.terminal") === "custom") &&
                                     (contentColumn.matchesSearch("terminal") || contentColumn.matchesSearch("custom"))
                            label: "Custom Command"
                            description: "Terminal executable name or path"

                            SettingsTextInput {
                                text: ConfigService.getValue("externalPrograms.terminalCustom") || ""
                                placeholder: "e.g., /usr/bin/myterminal"
                                onTextEdited: (value) => {
                                    ConfigService.setValue("externalPrograms.terminalCustom", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: contentColumn.matchesSearch("terminal") ||
                                     contentColumn.matchesSearch("exec") ||
                                     contentColumn.matchesSearch("flag")
                            label: "Exec Flag"
                            description: "Flag to execute a command (-e, --, start --)"

                            SettingsTextInput {
                                text: ConfigService.getValue("externalPrograms.terminalExecFlag") || "-e"
                                placeholder: "-e"
                                onTextEdited: (value) => {
                                    ConfigService.setValue("externalPrograms.terminalExecFlag", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }
                    }

                    // ─────────────────────────────────────────────────────────────
                    // File Manager
                    // ─────────────────────────────────────────────────────────────
                    CollapsibleSection {
                        title: "File Manager"
                        icon: "󰉋"

                        SettingRow {
                            visible: contentColumn.matchesSearch("file") ||
                                     contentColumn.matchesSearch("manager") ||
                                     contentColumn.matchesSearch("dolphin") ||
                                     contentColumn.matchesSearch("nautilus")
                            label: "File Manager"
                            description: "Application for opening files and folders"

                            DropdownSelect {
                                model: externalProgramsSection.fileManagerPresets
                                currentIndex: {
                                    let current = ConfigService.getValue("externalPrograms.fileManager") || "xdg-open"
                                    let presets = externalProgramsSection.fileManagerPresets
                                    for (let i = 0; i < presets.length; i++) {
                                        if (presets[i].value === current) return i
                                    }
                                    return 0
                                }
                                onSelected: (index, value) => {
                                    ConfigService.setValue("externalPrograms.fileManager", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: (ConfigService.getValue("externalPrograms.fileManager") === "custom") &&
                                     (contentColumn.matchesSearch("file") || contentColumn.matchesSearch("custom"))
                            label: "Custom Command"
                            description: "File manager executable name or path"

                            SettingsTextInput {
                                text: ConfigService.getValue("externalPrograms.fileManagerCustom") || ""
                                placeholder: "e.g., ranger"
                                onTextEdited: (value) => {
                                    ConfigService.setValue("externalPrograms.fileManagerCustom", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }
                    }

                    // ─────────────────────────────────────────────────────────────
                    // Browser
                    // ─────────────────────────────────────────────────────────────
                    CollapsibleSection {
                        title: "Browser"
                        icon: "󰈹"

                        SettingRow {
                            visible: contentColumn.matchesSearch("browser") ||
                                     contentColumn.matchesSearch("firefox") ||
                                     contentColumn.matchesSearch("chrome")
                            label: "Browser"
                            description: "Web browser for opening URLs"

                            DropdownSelect {
                                model: externalProgramsSection.browserPresets
                                currentIndex: {
                                    let current = ConfigService.getValue("externalPrograms.browser") || "xdg-open"
                                    let presets = externalProgramsSection.browserPresets
                                    for (let i = 0; i < presets.length; i++) {
                                        if (presets[i].value === current) return i
                                    }
                                    return 0
                                }
                                onSelected: (index, value) => {
                                    ConfigService.setValue("externalPrograms.browser", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: (ConfigService.getValue("externalPrograms.browser") === "custom") &&
                                     (contentColumn.matchesSearch("browser") || contentColumn.matchesSearch("custom"))
                            label: "Custom Command"
                            description: "Browser executable name or path"

                            SettingsTextInput {
                                text: ConfigService.getValue("externalPrograms.browserCustom") || ""
                                placeholder: "e.g., qutebrowser"
                                onTextEdited: (value) => {
                                    ConfigService.setValue("externalPrograms.browserCustom", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }
                    }

                    // ─────────────────────────────────────────────────────────────
                    // Screenshot Annotator
                    // ─────────────────────────────────────────────────────────────
                    CollapsibleSection {
                        title: "Screenshot Annotator"
                        icon: "󰏬"

                        SettingRow {
                            visible: contentColumn.matchesSearch("annotator") ||
                                     contentColumn.matchesSearch("screenshot") ||
                                     contentColumn.matchesSearch("napkin")
                            label: "Annotator"
                            description: "Application for annotating screenshots"

                            DropdownSelect {
                                model: externalProgramsSection.annotatorPresets
                                currentIndex: {
                                    let current = ConfigService.getValue("externalPrograms.annotator") || "napkin"
                                    let presets = externalProgramsSection.annotatorPresets
                                    for (let i = 0; i < presets.length; i++) {
                                        if (presets[i].value === current) return i
                                    }
                                    return 0
                                }
                                onSelected: (index, value) => {
                                    ConfigService.setValue("externalPrograms.annotator", value)
                                    ConfigService.saveConfig()
                                }
                            }
                        }

                        SettingRow {
                            visible: (ConfigService.getValue("externalPrograms.annotator") === "custom") &&
                                     (contentColumn.matchesSearch("annotator") || contentColumn.matchesSearch("custom"))
                            label: "Custom Command"
                            description: "Annotator executable name or path"

                            SettingsTextInput {
                                text: ConfigService.getValue("externalPrograms.annotatorCustom") || ""
                                placeholder: "e.g., flameshot"
                                onTextEdited: (value) => {
                                    ConfigService.setValue("externalPrograms.annotatorCustom", value)
                                    ConfigService.saveConfig()
                                }
                            }
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
                            text: "Some changes require a restart to take effect."
                            font.family: Fonts.ui
                            font.pixelSize: Fonts.body
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
                                font.family: Fonts.ui
                                font.pixelSize: Fonts.body
                                font.weight: Font.Medium
                                color: Colors.foreground
                            }

                            MouseArea {
                                id: restartArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    restartProcess.running = true
                                }
                            }

                            HintTarget {
                                targetElement: parent
                                scope: "settings"
                                action: () => restartProcess.running = true
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

    // Keyboard handler
    Keys.onEscapePressed: SettingsState.close()

    // Focus search bar when panel opens
    Connections {
        target: SettingsState
        function onSettingsOpenChanged() {
            if (SettingsState.settingsOpen) {
                searchInput.forceActiveFocus()
            }
        }
    }

    Component.onCompleted: {
        if (SettingsState.settingsOpen) {
            searchInput.forceActiveFocus()
        }
    }
}
