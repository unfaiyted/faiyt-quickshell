pragma Singleton
import QtQuick
import Quickshell
import "../theme"

Singleton {
    id: themeService

    // Current theme name for persistence
    property string currentThemeName: "rose-pine"

    // Current active theme object with all color properties
    property var currentTheme: createThemeObject(ThemeDefinitions.getTheme("rose-pine"))

    // List of all available themes (builtin + custom)
    property var availableThemes: []

    // Signal when theme changes
    signal themeChanged(string themeName)

    // Track if we've initialized
    property bool initialized: false

    Component.onCompleted: {
        refreshAvailableThemes()
    }

    // Connection to ConfigService for loading saved theme
    Connections {
        target: ConfigService
        function onConfigLoadedChanged() {
            if (ConfigService.configLoaded && !themeService.initialized) {
                themeService.loadSavedTheme()
                themeService.initialized = true
            }
        }
    }

    // Create a theme object with all color properties from theme data
    function createThemeObject(themeData) {
        if (!themeData || !themeData.colors) {
            themeData = ThemeDefinitions.getTheme("rose-pine")
        }
        let colors = themeData.colors
        return {
            // Base Colors
            base: colors.base || "#191724",
            surface: colors.surface || "#1f1d2e",
            overlay: colors.overlay || "#26233a",
            // Text Colors
            text: colors.text || "#e0def4",
            muted: colors.muted || "#6e6a86",
            subtle: colors.subtle || "#908caa",
            // Accent Colors
            love: colors.love || "#eb6f92",
            gold: colors.gold || "#f6c177",
            rose: colors.rose || "#ebbcba",
            pine: colors.pine || "#31748f",
            foam: colors.foam || "#9ccfd8",
            iris: colors.iris || "#c4a7e7",
            // Semantic
            primary: colors.primary || colors.iris || "#c4a7e7",
            secondary: colors.secondary || colors.pine || "#31748f",
            accent: colors.accent || colors.love || "#eb6f92",
            success: colors.success || colors.foam || "#9ccfd8",
            warning: colors.warning || colors.gold || "#f6c177",
            error: colors.error || colors.love || "#eb6f92",
            info: colors.info || colors.pine || "#31748f",
            // UI Component
            background: colors.background || colors.base || "#191724",
            backgroundAlt: colors.backgroundAlt || colors.surface || "#1f1d2e",
            backgroundElevated: colors.backgroundElevated || colors.overlay || "#26233a",
            foreground: colors.foreground || colors.text || "#e0def4",
            foregroundAlt: colors.foregroundAlt || colors.subtle || "#908caa",
            foregroundMuted: colors.foregroundMuted || colors.muted || "#6e6a86",
            border: colors.border || colors.overlay || "#26233a",
            borderAlt: colors.borderAlt || colors.muted || "#6e6a86",
            // State
            hover: colors.hover || colors.overlay || "#26233a",
            active: colors.active || "#393552",
            focus: colors.focus || colors.primary || "#c4a7e7",
            disabled: colors.disabled || colors.muted || "#6e6a86"
        }
    }

    // Switch to a different theme
    function setTheme(themeName) {
        let themeData = getThemeDataOrDefault(themeName)
        currentTheme = createThemeObject(themeData)
        currentThemeName = themeName
        ConfigService.setValue("theme", themeName)
        ConfigService.saveConfig()
        themeChanged(themeName)
        console.log("[ThemeService] Switched to theme:", themeName)
    }

    // Get theme data by name (checks custom first, then builtin)
    // Returns null if theme doesn't exist
    // Always returns a deep copy to ensure QML detects changes
    function getThemeData(themeName) {
        // Check custom themes first
        let customThemes = ConfigService.getValue("customThemes") || {}
        if (customThemes[themeName]) {
            // Return a deep copy so QML detects changes
            return JSON.parse(JSON.stringify(customThemes[themeName]))
        }
        // Check builtin themes (returns null if not found)
        let builtin = ThemeDefinitions.getTheme(themeName)
        if (builtin) {
            return JSON.parse(JSON.stringify(builtin))
        }
        return null
    }

    // Get theme data with fallback to default
    function getThemeDataOrDefault(themeName) {
        let theme = getThemeData(themeName)
        return theme || ThemeDefinitions.getThemeOrDefault("rose-pine")
    }

    // Refresh list of available themes
    function refreshAvailableThemes() {
        let themes = []
        // Add builtin themes
        let builtinNames = ThemeDefinitions.getThemeNames()
        for (let name of builtinNames) {
            themes.push(ThemeDefinitions.themes[name])
        }
        // Add custom themes
        let customThemes = ConfigService.getValue("customThemes") || {}
        for (let name in customThemes) {
            themes.push(customThemes[name])
        }
        availableThemes = themes
    }

    // Save a custom theme
    function saveCustomTheme(themeData) {
        let customThemes = ConfigService.getValue("customThemes") || {}
        customThemes[themeData.name] = themeData
        ConfigService.setValue("customThemes", customThemes)
        ConfigService.saveConfig()
        refreshAvailableThemes()
        console.log("[ThemeService] Saved custom theme:", themeData.name)
    }

    // Delete a custom theme
    function deleteCustomTheme(themeName) {
        // Don't delete builtin themes
        if (ThemeDefinitions.isBuiltinTheme(themeName)) {
            console.log("[ThemeService] Cannot delete builtin theme:", themeName)
            return false
        }

        let customThemes = ConfigService.getValue("customThemes") || {}
        if (customThemes[themeName]) {
            delete customThemes[themeName]
            ConfigService.setValue("customThemes", customThemes)
            ConfigService.saveConfig()
            // Switch to default if deleting current theme
            if (currentThemeName === themeName) {
                setTheme("rose-pine")
            }
            refreshAvailableThemes()
            console.log("[ThemeService] Deleted custom theme:", themeName)
            return true
        }
        return false
    }

    // Create a new custom theme with default Rose Pine colors
    function createNewTheme() {
        let baseName = generateUniqueName("custom-theme")
        let baseTheme = ThemeDefinitions.getThemeOrDefault("rose-pine")

        let newTheme = JSON.parse(JSON.stringify(baseTheme))
        newTheme.name = baseName
        newTheme.displayName = "My Custom Theme"
        newTheme.description = "A new custom theme"
        newTheme.isBuiltin = false
        newTheme.baseTheme = "rose-pine"
        newTheme.icon = "󰏘"

        saveCustomTheme(newTheme)
        console.log("[ThemeService] Created new theme:", baseName)
        return newTheme
    }

    // Duplicate a theme as base for customization
    function duplicateTheme(sourceName, newName, newDisplayName) {
        let source = getThemeData(sourceName)
        if (source) {
            let newTheme = JSON.parse(JSON.stringify(source))
            newTheme.name = newName
            newTheme.displayName = newDisplayName || ("Copy of " + source.displayName)
            newTheme.description = "Based on " + source.displayName
            newTheme.isBuiltin = false
            newTheme.baseTheme = sourceName
            newTheme.icon = "󰏘" // Custom theme icon
            saveCustomTheme(newTheme)
            console.log("[ThemeService] Duplicated theme:", sourceName, "->", newName)
            return newTheme
        }
        return null
    }

    // Update a single color in a custom theme
    function updateThemeColor(themeName, colorKey, colorValue) {
        // Don't modify builtin themes
        if (ThemeDefinitions.isBuiltinTheme(themeName)) {
            console.log("[ThemeService] Cannot modify builtin theme:", themeName)
            return false
        }

        let customThemes = ConfigService.getValue("customThemes") || {}
        if (customThemes[themeName]) {
            customThemes[themeName].colors[colorKey] = colorValue
            ConfigService.setValue("customThemes", customThemes)
            ConfigService.saveConfig()
            // Update live if this is current theme
            if (currentThemeName === themeName) {
                currentTheme = createThemeObject(customThemes[themeName])
            }
            console.log("[ThemeService] Updated color:", themeName, colorKey, "->", colorValue)
            return true
        }
        return false
    }

    // Update theme metadata (displayName, description, icon)
    function updateThemeMetadata(themeName, metadata) {
        if (ThemeDefinitions.isBuiltinTheme(themeName)) {
            return false
        }

        let customThemes = ConfigService.getValue("customThemes") || {}
        if (customThemes[themeName]) {
            if (metadata.displayName !== undefined) {
                customThemes[themeName].displayName = metadata.displayName
            }
            if (metadata.description !== undefined) {
                customThemes[themeName].description = metadata.description
            }
            if (metadata.icon !== undefined) {
                customThemes[themeName].icon = metadata.icon
            }
            ConfigService.setValue("customThemes", customThemes)
            ConfigService.saveConfig()
            refreshAvailableThemes()
            return true
        }
        return false
    }

    // Load saved theme on startup
    function loadSavedTheme() {
        let savedTheme = ConfigService.theme || "rose-pine"
        console.log("[ThemeService] Loading saved theme:", savedTheme)

        // Verify theme exists, fall back if not
        let themeData = getThemeData(savedTheme)
        if (!themeData) {
            console.log("[ThemeService] Saved theme not found, falling back to rose-pine")
            savedTheme = "rose-pine"
            themeData = getThemeDataOrDefault(savedTheme)
        }

        currentTheme = createThemeObject(themeData)
        currentThemeName = savedTheme
        refreshAvailableThemes()
        themeChanged(savedTheme)
    }

    // Generate a unique theme name
    function generateUniqueName(baseName) {
        let counter = 1
        let name = baseName + "-custom"
        while (getThemeData(name) !== null) {
            counter++
            name = baseName + "-custom-" + counter
        }
        return name
    }

    // Check if a theme name is available
    function isNameAvailable(name) {
        return getThemeData(name) === null || getThemeData(name) === undefined
    }
}
