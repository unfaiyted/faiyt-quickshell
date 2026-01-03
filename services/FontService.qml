pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: fontService

    // All available system fonts
    property var allFonts: []

    // Filtered font lists by category
    property var uiFonts: []        // All fonts suitable for UI
    property var monoFonts: []      // Monospace fonts
    property var nerdFonts: []      // Nerd Font variants (for icons)
    property var emojiFonts: []     // Emoji fonts

    // Loading state
    property bool loaded: false
    property bool loading: false

    // Font list model for dropdowns (format: [{label, value}])
    property var uiFontModel: []
    property var monoFontModel: []
    property var nerdFontModel: []
    property var emojiFontModel: []

    Component.onCompleted: {
        loadFonts()
    }

    function loadFonts() {
        if (loading) return
        loading = true
        fontBuffer = ""
        fontListProcess.running = true
    }

    function refresh() {
        loaded = false
        loadFonts()
    }

    property string fontBuffer: ""

    Process {
        id: fontListProcess
        command: ["fc-list", "--format=%{family}\n"]

        stdout: SplitParser {
            onRead: data => {
                fontService.fontBuffer += data + "\n"
            }
        }

        onRunningChanged: {
            if (!running) {
                fontService.parseFonts()
            }
        }
    }

    function parseFonts() {
        let lines = fontBuffer.split("\n")
        let fontSet = new Set()

        for (let line of lines) {
            let name = line.trim()
            if (name.length > 0) {
                // fc-list may return comma-separated families
                let families = name.split(",")
                for (let family of families) {
                    let trimmed = family.trim()
                    if (trimmed.length > 0) {
                        fontSet.add(trimmed)
                    }
                }
            }
        }

        // Sort alphabetically
        allFonts = Array.from(fontSet).sort((a, b) => a.localeCompare(b))

        // Filter by category
        nerdFonts = allFonts.filter(f =>
            f.includes("Nerd Font") || f.includes("NerdFont")
        )

        monoFonts = allFonts.filter(f => {
            let lower = f.toLowerCase()
            return lower.includes("mono") ||
                   lower.includes("consolas") ||
                   lower.includes("courier") ||
                   lower.includes("code") ||
                   lower.includes("fixed") ||
                   lower.includes("terminal") ||
                   lower.includes("hack") ||
                   lower.includes("fira code") ||
                   lower.includes("jetbrains")
        })

        emojiFonts = allFonts.filter(f => {
            let lower = f.toLowerCase()
            return lower.includes("emoji") ||
                   lower.includes("color") ||
                   lower.includes("symbola")
        })

        // UI fonts = all fonts (user can pick any)
        uiFonts = allFonts

        // Build dropdown models
        uiFontModel = buildFontModel(uiFonts, "System Default")
        monoFontModel = buildFontModel(monoFonts, "monospace")
        nerdFontModel = buildFontModel(nerdFonts, "Symbols Nerd Font")
        emojiFontModel = buildFontModel(emojiFonts, "Noto Color Emoji")

        fontBuffer = ""
        loading = false
        loaded = true

        console.log("[FontService] Loaded", allFonts.length, "fonts")
        console.log("[FontService] Categories - UI:", uiFonts.length,
                    "Mono:", monoFonts.length,
                    "Nerd:", nerdFonts.length,
                    "Emoji:", emojiFonts.length)
    }

    function buildFontModel(fonts, defaultLabel) {
        let model = []

        // Add default/empty option first
        model.push({
            label: defaultLabel,
            value: ""
        })

        // Add all fonts
        for (let font of fonts) {
            model.push({
                label: font,
                value: font
            })
        }

        return model
    }

    // Check if a font is available
    function isFontAvailable(fontName) {
        if (!fontName || fontName === "") return true // Empty = system default
        return allFonts.includes(fontName)
    }

    // Get font with fallback
    function getFontOrFallback(fontName, fallback) {
        if (isFontAvailable(fontName)) {
            return fontName
        }
        return fallback
    }

    // Find index in model by value
    function findIndexByValue(model, value) {
        for (let i = 0; i < model.length; i++) {
            if (model[i].value === value) {
                return i
            }
        }
        return 0 // Default to first item
    }
}
