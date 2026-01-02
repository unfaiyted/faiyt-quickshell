pragma Singleton
import QtQuick
import "../services"

QtObject {
    // Base Colors - bound to ThemeService
    property color base: ThemeService.currentTheme.base
    property color surface: ThemeService.currentTheme.surface
    property color overlay: ThemeService.currentTheme.overlay

    // Text Colors
    property color text: ThemeService.currentTheme.text
    property color muted: ThemeService.currentTheme.muted
    property color subtle: ThemeService.currentTheme.subtle

    // Accent Colors
    property color love: ThemeService.currentTheme.love
    property color gold: ThemeService.currentTheme.gold
    property color rose: ThemeService.currentTheme.rose
    property color pine: ThemeService.currentTheme.pine
    property color foam: ThemeService.currentTheme.foam
    property color iris: ThemeService.currentTheme.iris

    // Semantic Color Roles
    property color primary: ThemeService.currentTheme.primary
    property color secondary: ThemeService.currentTheme.secondary
    property color accent: ThemeService.currentTheme.accent
    property color success: ThemeService.currentTheme.success
    property color warning: ThemeService.currentTheme.warning
    property color error: ThemeService.currentTheme.error
    property color info: ThemeService.currentTheme.info

    // UI Component Colors
    property color background: ThemeService.currentTheme.background
    property color backgroundAlt: ThemeService.currentTheme.backgroundAlt
    property color backgroundElevated: ThemeService.currentTheme.backgroundElevated
    property color foreground: ThemeService.currentTheme.foreground
    property color foregroundAlt: ThemeService.currentTheme.foregroundAlt
    property color foregroundMuted: ThemeService.currentTheme.foregroundMuted
    property color border: ThemeService.currentTheme.border
    property color borderAlt: ThemeService.currentTheme.borderAlt

    // State Colors
    property color hover: ThemeService.currentTheme.hover
    property color active: ThemeService.currentTheme.active
    property color focus: ThemeService.currentTheme.focus
    property color disabled: ThemeService.currentTheme.disabled
}
