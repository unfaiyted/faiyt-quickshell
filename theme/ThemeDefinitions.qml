pragma Singleton
import QtQuick

QtObject {
    // All color property names for validation
    readonly property var colorKeys: [
        "base", "surface", "overlay",
        "text", "muted", "subtle",
        "love", "gold", "rose", "pine", "foam", "iris",
        "primary", "secondary", "accent", "success", "warning", "error", "info",
        "background", "backgroundAlt", "backgroundElevated",
        "foreground", "foregroundAlt", "foregroundMuted",
        "border", "borderAlt",
        "hover", "active", "focus", "disabled"
    ]

    readonly property var themes: ({
        "rose-pine": {
            name: "rose-pine",
            displayName: "Rose Pine",
            description: "Dark theme with muted colors",
            icon: "󰽥",
            isBuiltin: true,
            colors: {
                // Base Colors
                base: "#191724",
                surface: "#1f1d2e",
                overlay: "#26233a",
                // Text Colors
                text: "#e0def4",
                muted: "#6e6a86",
                subtle: "#908caa",
                // Accent Colors
                love: "#eb6f92",
                gold: "#f6c177",
                rose: "#ebbcba",
                pine: "#31748f",
                foam: "#9ccfd8",
                iris: "#c4a7e7",
                // Semantic (derived from accents)
                primary: "#c4a7e7",
                secondary: "#31748f",
                accent: "#eb6f92",
                success: "#9ccfd8",
                warning: "#f6c177",
                error: "#eb6f92",
                info: "#31748f",
                // UI Component
                background: "#191724",
                backgroundAlt: "#1f1d2e",
                backgroundElevated: "#26233a",
                foreground: "#e0def4",
                foregroundAlt: "#908caa",
                foregroundMuted: "#6e6a86",
                border: "#26233a",
                borderAlt: "#6e6a86",
                // State
                hover: "#26233a",
                active: "#393552",
                focus: "#c4a7e7",
                disabled: "#6e6a86"
            }
        },
        "rose-pine-moon": {
            name: "rose-pine-moon",
            displayName: "Rose Pine Moon",
            description: "Darker variant with softer tones",
            icon: "󰽦",
            isBuiltin: true,
            colors: {
                // Base Colors
                base: "#232136",
                surface: "#2a273f",
                overlay: "#393552",
                // Text Colors
                text: "#e0def4",
                muted: "#6e6a86",
                subtle: "#908caa",
                // Accent Colors
                love: "#eb6f92",
                gold: "#f6c177",
                rose: "#ea9a97",
                pine: "#3e8fb0",
                foam: "#9ccfd8",
                iris: "#c4a7e7",
                // Semantic
                primary: "#c4a7e7",
                secondary: "#3e8fb0",
                accent: "#eb6f92",
                success: "#9ccfd8",
                warning: "#f6c177",
                error: "#eb6f92",
                info: "#3e8fb0",
                // UI Component
                background: "#232136",
                backgroundAlt: "#2a273f",
                backgroundElevated: "#393552",
                foreground: "#e0def4",
                foregroundAlt: "#908caa",
                foregroundMuted: "#6e6a86",
                border: "#393552",
                borderAlt: "#6e6a86",
                // State
                hover: "#393552",
                active: "#44415a",
                focus: "#c4a7e7",
                disabled: "#6e6a86"
            }
        },
        "rose-pine-dawn": {
            name: "rose-pine-dawn",
            displayName: "Rose Pine Dawn",
            description: "Light theme for daytime use",
            icon: "󰖨",
            isBuiltin: true,
            colors: {
                // Base Colors
                base: "#faf4ed",
                surface: "#fffaf3",
                overlay: "#f2e9e1",
                // Text Colors
                text: "#575279",
                muted: "#9893a5",
                subtle: "#797593",
                // Accent Colors
                love: "#b4637a",
                gold: "#ea9d34",
                rose: "#d7827e",
                pine: "#286983",
                foam: "#56949f",
                iris: "#907aa9",
                // Semantic
                primary: "#907aa9",
                secondary: "#286983",
                accent: "#b4637a",
                success: "#56949f",
                warning: "#ea9d34",
                error: "#b4637a",
                info: "#286983",
                // UI Component
                background: "#faf4ed",
                backgroundAlt: "#fffaf3",
                backgroundElevated: "#f2e9e1",
                foreground: "#575279",
                foregroundAlt: "#797593",
                foregroundMuted: "#9893a5",
                border: "#f2e9e1",
                borderAlt: "#9893a5",
                // State
                hover: "#f2e9e1",
                active: "#e4dcd4",
                focus: "#907aa9",
                disabled: "#9893a5"
            }
        }
    })

    function getTheme(name) {
        return themes[name] || null
    }

    function getThemeOrDefault(name) {
        return themes[name] || themes["rose-pine"]
    }

    function getThemeNames() {
        return Object.keys(themes)
    }

    function isBuiltinTheme(name) {
        return themes[name] && themes[name].isBuiltin === true
    }
}
