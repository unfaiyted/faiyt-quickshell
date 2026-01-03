pragma Singleton
import QtQuick
import "../services"

QtObject {
    // Font family bindings - bound to ThemeService
    property string ui: ThemeService.fonts.ui || ""
    property string mono: ThemeService.fonts.mono || "monospace"
    property string icon: ThemeService.fonts.icon || "Symbols Nerd Font"
    property string emoji: ThemeService.fonts.emoji || "Noto Color Emoji"

    // Global scale factor (0.75 to 1.5, default 1.0)
    property real scale: ThemeService.fonts.scale || 1.0

    // Scaled text sizes
    property int tiny: Math.round(9 * scale)       // Labels, hints
    property int small: Math.round(11 * scale)     // Secondary text
    property int body: Math.round(13 * scale)      // Default body text
    property int medium: Math.round(14 * scale)    // Emphasized text
    property int large: Math.round(16 * scale)     // Headings
    property int xlarge: Math.round(18 * scale)    // Large headings
    property int huge: Math.round(24 * scale)      // Titles

    // Scaled icon sizes
    property int iconTiny: Math.round(10 * scale)
    property int iconSmall: Math.round(12 * scale)
    property int iconMedium: Math.round(16 * scale)
    property int iconLarge: Math.round(20 * scale)
    property int iconHuge: Math.round(24 * scale)
}
