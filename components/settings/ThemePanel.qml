import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../../services"
import "components"

Rectangle {
    id: themePanel

    // Current editing state
    property var editingTheme: null
    property bool isEditMode: editingTheme !== null

    // Color picker state
    property var activePickerRow: null
    property string activePickerKey: ""
    property string activePickerValue: "#000000"
    property bool pickerVisible: false

    function openPicker(rowItem, colorKey, colorValue) {
        activePickerRow = rowItem
        activePickerKey = colorKey
        activePickerValue = colorValue
        pickerVisible = true
        if (rowItem) rowItem.pickerOpen = true
    }

    function closePicker() {
        if (activePickerRow) activePickerRow.pickerOpen = false
        activePickerRow = null
        activePickerKey = ""
        pickerVisible = false
    }

    // Color conversion helpers
    function hexToRgb(hex) {
        if (!hex) return null
        let result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
        return result ? {
            r: parseInt(result[1], 16),
            g: parseInt(result[2], 16),
            b: parseInt(result[3], 16)
        } : null
    }

    function rgbToHsl(hex) {
        let rgb = hexToRgb(hex)
        if (!rgb) return {h: 0, s: 0.5, l: 0.5}
        let r = rgb.r / 255, g = rgb.g / 255, b = rgb.b / 255
        let max = Math.max(r, g, b), min = Math.min(r, g, b)
        let h = 0, s = 0, l = (max + min) / 2
        if (max !== min) {
            let d = max - min
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
            if (max === r) h = ((g - b) / d + (g < b ? 6 : 0)) / 6
            else if (max === g) h = ((b - r) / d + 2) / 6
            else h = ((r - g) / d + 4) / 6
        }
        return {h: h, s: s, l: l}
    }

    function hslToHex(h, s, l) {
        let r, g, b
        if (s === 0) {
            r = g = b = l
        } else {
            function hue2rgb(p, q, t) {
                if (t < 0) t += 1
                if (t > 1) t -= 1
                if (t < 1/6) return p + (q - p) * 6 * t
                if (t < 1/2) return q
                if (t < 2/3) return p + (q - p) * (2/3 - t) * 6
                return p
            }
            let q = l < 0.5 ? l * (1 + s) : l + s - l * s
            let p = 2 * l - q
            r = hue2rgb(p, q, h + 1/3)
            g = hue2rgb(p, q, h)
            b = hue2rgb(p, q, h - 1/3)
        }
        return "#" + Math.round(r * 255).toString(16).padStart(2, '0') +
               Math.round(g * 255).toString(16).padStart(2, '0') +
               Math.round(b * 255).toString(16).padStart(2, '0')
    }

    function applyPickerColor(color) {
        activePickerValue = color.toUpperCase()
        // Update the theme directly
        if (editingTheme && activePickerKey) {
            ThemeService.updateThemeColor(editingTheme.name, activePickerKey, color.toUpperCase())
            // Refresh local copy to trigger UI updates
            editingTheme = ThemeService.getThemeData(editingTheme.name)
        }
    }

    function getHue() {
        let hsl = rgbToHsl(activePickerValue)
        return hsl.h
    }

    function getSaturation() {
        let hsl = rgbToHsl(activePickerValue)
        return hsl.s
    }

    function getLightness() {
        let hsl = rgbToHsl(activePickerValue)
        return hsl.l
    }

    width: 700
    height: parent ? parent.height * 0.85 : 600
    radius: 20
    color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.9)
    border.width: 1
    border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.15)

    // Shadow layer
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
            height: 60
            color: "transparent"

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)
            }

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 16
                spacing: 12

                // Back button (visible in edit mode)
                Rectangle {
                    visible: themePanel.isEditMode
                    width: 28
                    height: 28
                    radius: 8
                    color: backArea.containsMouse ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.5) : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                    border.width: 1
                    border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.1)

                    Text {
                        anchors.centerIn: parent
                        text: "󰅁"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 14
                        color: Colors.foregroundAlt
                    }

                    MouseArea {
                        id: backArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: themePanel.editingTheme = null
                    }
                }

                // Theme icon
                Text {
                    text: "󰏘"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 20
                    color: Colors.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Title
                Text {
                    text: themePanel.isEditMode ? ("Editing: " + (themePanel.editingTheme?.displayName || "")) : "Theme Manager"
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    color: Colors.foreground
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { Layout.fillWidth: true; width: 1 }

                // Create New button (visible in list mode)
                Rectangle {
                    visible: !themePanel.isEditMode
                    width: createNewContent.width + 16
                    height: 28
                    radius: 8
                    color: createNewArea.containsMouse ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2) : Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.3)
                    border.width: 1
                    border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3)
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: createNewContent
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰐕"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 14
                            color: Colors.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Create New"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Colors.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: createNewArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let newTheme = ThemeService.createNewTheme()
                            if (newTheme) {
                                themePanel.editingTheme = newTheme
                            }
                        }
                    }
                }

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
                        onClicked: {
                            ThemePanelState.close()
                            SettingsState.open()
                        }
                    }
                }
            }
        }

        // Main content area
        Item {
            width: parent.width
            height: parent.height - 60

            // Theme list view
            Flickable {
                id: themeListView
                visible: !themePanel.isEditMode
                anchors.fill: parent
                anchors.margins: 16
                contentHeight: themeListColumn.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: themeListColumn
                    width: parent.width
                    spacing: 12

                    // Section: Built-in Themes
                    Text {
                        text: "Built-in Themes"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: Colors.foregroundAlt
                    }

                    Repeater {
                        model: ThemeService.availableThemes.filter(t => t.isBuiltin)

                        ThemeCard {
                            width: themeListColumn.width
                            themeData: modelData
                            isActive: ThemeService.currentThemeName === modelData.name
                            isBuiltin: true
                            onSelected: ThemeService.setTheme(modelData.name)
                            onDuplicate: {
                                let newName = ThemeService.generateUniqueName(modelData.name)
                                let newTheme = ThemeService.duplicateTheme(modelData.name, newName, "Custom " + modelData.displayName)
                                if (newTheme) {
                                    themePanel.editingTheme = newTheme
                                }
                            }
                        }
                    }

                    // Section: Custom Themes
                    Item {
                        width: parent.width
                        height: 20
                        visible: ThemeService.availableThemes.filter(t => !t.isBuiltin).length > 0
                    }

                    Text {
                        visible: ThemeService.availableThemes.filter(t => !t.isBuiltin).length > 0
                        text: "Custom Themes"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: Colors.foregroundAlt
                    }

                    Repeater {
                        model: ThemeService.availableThemes.filter(t => !t.isBuiltin)

                        ThemeCard {
                            width: themeListColumn.width
                            themeData: modelData
                            isActive: ThemeService.currentThemeName === modelData.name
                            isBuiltin: false
                            onSelected: ThemeService.setTheme(modelData.name)
                            onEdit: themePanel.editingTheme = ThemeService.getThemeData(modelData.name)
                            onDuplicate: {
                                let newName = ThemeService.generateUniqueName(modelData.name)
                                let newTheme = ThemeService.duplicateTheme(modelData.name, newName, "Copy of " + modelData.displayName)
                                if (newTheme) {
                                    themePanel.editingTheme = newTheme
                                }
                            }
                            onDeleteTheme: {
                                ThemeService.deleteCustomTheme(modelData.name)
                            }
                        }
                    }

                    // Bottom padding
                    Item { width: 1; height: 20 }
                }
            }

            // Theme editor view
            ThemeEditorView {
                id: themeEditorView
                visible: themePanel.isEditMode
                anchors.fill: parent
                anchors.margins: 16
                theme: themePanel.editingTheme
                onColorChanged: (colorKey, colorValue) => {
                    ThemeService.updateThemeColor(themePanel.editingTheme.name, colorKey, colorValue)
                    // Refresh local copy
                    themePanel.editingTheme = ThemeService.getThemeData(themePanel.editingTheme.name)
                }
                onThemeMetadataChanged: (displayName, description) => {
                    ThemeService.updateThemeMetadata(themePanel.editingTheme.name, {
                        displayName: displayName,
                        description: description
                    })
                    themePanel.editingTheme = ThemeService.getThemeData(themePanel.editingTheme.name)
                }
                onPickerRequested: (rowItem, colorKey, colorValue) => {
                    themePanel.openPicker(rowItem, colorKey, colorValue)
                }
            }
        }
    }

    // Click-outside backdrop to close picker
    MouseArea {
        anchors.fill: parent
        visible: themePanel.pickerVisible
        z: 100
        onClicked: themePanel.closePicker()
    }

    // Color picker overlay
    Rectangle {
        id: colorPickerOverlay
        visible: themePanel.pickerVisible
        z: 101
        width: 280
        height: 320
        radius: 12
        color: Qt.rgba(Colors.backgroundElevated.r, Colors.backgroundElevated.g, Colors.backgroundElevated.b, 0.98)
        border.width: 1
        border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.3)

        // Position near the active row
        x: Math.min(themePanel.width - width - 20, Math.max(20, activePickerRow ? themePanel.mapFromItem(activePickerRow, 50, 0).x : 100))
        y: {
            if (!activePickerRow) return 100
            let mapped = themePanel.mapFromItem(activePickerRow, 0, activePickerRow.height)
            // Show above if too close to bottom
            if (mapped.y + height > themePanel.height - 20) {
                return Math.max(20, mapped.y - activePickerRow.height - height - 8)
            }
            return Math.min(themePanel.height - height - 20, mapped.y + 8)
        }

        // Prevent clicks from closing
        MouseArea {
            anchors.fill: parent
            onClicked: (event) => event.accepted = true
        }

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            // Header
            Row {
                width: parent.width
                spacing: 8

                Text {
                    text: formatColorName(themePanel.activePickerKey)
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: Colors.foreground

                    function formatColorName(key) {
                        if (!key) return ""
                        return key
                            .replace(/([A-Z])/g, ' $1')
                            .replace(/^./, str => str.toUpperCase())
                            .trim()
                    }
                }

                Item { width: 1; height: 1; Layout.fillWidth: true }

                // Close button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 6
                    color: closePickerArea.containsMouse ? Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.5) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 12
                        color: Colors.foregroundAlt
                    }

                    MouseArea {
                        id: closePickerArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: themePanel.closePicker()
                    }
                }
            }

            // Color preview
            Rectangle {
                width: parent.width
                height: 40
                radius: 8
                color: themePanel.activePickerValue

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.3)
                }
            }

            // Hue slider
            Column {
                width: parent.width
                spacing: 4

                Text {
                    text: "Hue"
                    font.pixelSize: 11
                    color: Colors.foregroundAlt
                }

                Rectangle {
                    width: parent.width
                    height: 24
                    radius: 6

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#FF0000" }
                        GradientStop { position: 0.166; color: "#FFFF00" }
                        GradientStop { position: 0.333; color: "#00FF00" }
                        GradientStop { position: 0.5; color: "#00FFFF" }
                        GradientStop { position: 0.666; color: "#0000FF" }
                        GradientStop { position: 0.833; color: "#FF00FF" }
                        GradientStop { position: 1.0; color: "#FF0000" }
                    }

                    Rectangle {
                        width: 8
                        height: parent.height + 4
                        y: -2
                        x: themePanel.getHue() * (parent.width - width)
                        radius: 4
                        color: "white"
                        border.width: 2
                        border.color: "#333"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: (mouse) => updateHue(mouse.x)
                        onPositionChanged: (mouse) => updateHue(mouse.x)

                        function updateHue(mouseX) {
                            let h = Math.max(0, Math.min(1, mouseX / width))
                            let currentHsl = themePanel.rgbToHsl(themePanel.activePickerValue)
                            let newColor = themePanel.hslToHex(h, currentHsl.s, currentHsl.l)
                            themePanel.applyPickerColor(newColor)
                        }
                    }
                }
            }

            // Saturation slider
            Column {
                width: parent.width
                spacing: 4

                Text {
                    text: "Saturation"
                    font.pixelSize: 11
                    color: Colors.foregroundAlt
                }

                Rectangle {
                    width: parent.width
                    height: 24
                    radius: 6

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.hsla(themePanel.getHue(), 0, 0.5, 1) }
                        GradientStop { position: 1.0; color: Qt.hsla(themePanel.getHue(), 1, 0.5, 1) }
                    }

                    Rectangle {
                        width: 8
                        height: parent.height + 4
                        y: -2
                        x: themePanel.getSaturation() * (parent.width - width)
                        radius: 4
                        color: "white"
                        border.width: 2
                        border.color: "#333"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: (mouse) => updateSat(mouse.x)
                        onPositionChanged: (mouse) => updateSat(mouse.x)

                        function updateSat(mouseX) {
                            let s = Math.max(0, Math.min(1, mouseX / width))
                            let currentHsl = themePanel.rgbToHsl(themePanel.activePickerValue)
                            let newColor = themePanel.hslToHex(currentHsl.h, s, currentHsl.l)
                            themePanel.applyPickerColor(newColor)
                        }
                    }
                }
            }

            // Lightness slider
            Column {
                width: parent.width
                spacing: 4

                Text {
                    text: "Lightness"
                    font.pixelSize: 11
                    color: Colors.foregroundAlt
                }

                Rectangle {
                    width: parent.width
                    height: 24
                    radius: 6

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#000000" }
                        GradientStop { position: 0.5; color: Qt.hsla(themePanel.getHue(), 1, 0.5, 1) }
                        GradientStop { position: 1.0; color: "#FFFFFF" }
                    }

                    Rectangle {
                        width: 8
                        height: parent.height + 4
                        y: -2
                        x: themePanel.getLightness() * (parent.width - width)
                        radius: 4
                        color: "white"
                        border.width: 2
                        border.color: "#333"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: (mouse) => updateLight(mouse.x)
                        onPositionChanged: (mouse) => updateLight(mouse.x)

                        function updateLight(mouseX) {
                            let l = Math.max(0, Math.min(1, mouseX / width))
                            let currentHsl = themePanel.rgbToHsl(themePanel.activePickerValue)
                            let newColor = themePanel.hslToHex(currentHsl.h, currentHsl.s, l)
                            themePanel.applyPickerColor(newColor)
                        }
                    }
                }
            }
        }
    }
}
